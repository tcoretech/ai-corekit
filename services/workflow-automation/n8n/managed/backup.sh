#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SERVICE_DIR/../../.." && pwd)}"
BACKUP_ROOT="${COREKIT_N8N_BACKUP_ROOT:-/home/services/backups/ai-corekit/n8n}"
PREVIOUS_GIT_COMMIT=""
BACKUP_LABEL="pre-upgrade"
CANDIDATE_IMAGE=""
RESTORE_CONTAINER=""
RESTORE_N8N_CONTAINER=""
RESTORE_NETWORK=""

log_event() {
  local level="$1"
  local event="$2"
  local message="$3"
  jq -cn \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg level "$level" \
    --arg event "$event" \
    --arg message "$message" \
    '{timestamp:$timestamp,level:$level,event:$event,message:$message}'
}

die() {
  log_event error backup_failed "$1" >&2
  exit 1
}

cleanup_restore_container() {
  if [[ -n "$RESTORE_N8N_CONTAINER" ]] && docker inspect "$RESTORE_N8N_CONTAINER" >/dev/null 2>&1; then
    docker rm --force "$RESTORE_N8N_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ -n "$RESTORE_CONTAINER" ]] && docker inspect "$RESTORE_CONTAINER" >/dev/null 2>&1; then
    docker rm --force "$RESTORE_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ -n "$RESTORE_NETWORK" ]] && docker network inspect "$RESTORE_NETWORK" >/dev/null 2>&1; then
    docker network rm "$RESTORE_NETWORK" >/dev/null 2>&1 || true
  fi
}
trap cleanup_restore_container EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-root)
      BACKUP_ROOT="$2"
      shift 2
      ;;
    --previous-git-commit)
      PREVIOUS_GIT_COMMIT="$2"
      shift 2
      ;;
    --label)
      BACKUP_LABEL="$2"
      shift 2
      ;;
    --candidate-image)
      CANDIDATE_IMAGE="$2"
      shift 2
      ;;
    *)
      die "Unknown backup option: $1"
      ;;
  esac
done

for command_name in docker git jq openssl sha256sum; do
  command -v "$command_name" >/dev/null 2>&1 || die "Required command is missing: $command_name"
done

docker inspect n8n postgres >/dev/null 2>&1 || die "n8n and postgres containers must exist"
[[ "$(docker inspect --format '{{.State.Running}}' n8n)" == "true" ]] || die "n8n must be running for encrypted exports"
[[ "$(docker inspect --format '{{.State.Running}}' postgres)" == "true" ]] || die "postgres must be running"

install -d -m 0700 "$BACKUP_ROOT"
chmod 0700 "$BACKUP_ROOT"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SET_NAME="${STAMP}-${BACKUP_LABEL}"
INCOMPLETE_DIR="$BACKUP_ROOT/.${SET_NAME}.incomplete"
FINAL_DIR="$BACKUP_ROOT/$SET_NAME"
[[ ! -e "$INCOMPLETE_DIR" && ! -e "$FINAL_DIR" ]] || die "Backup destination already exists"
install -d -m 0700 "$INCOMPLETE_DIR"

log_event info backup_started "Creating protected n8n recovery set"

N8N_VERSION="$(docker exec n8n n8n --version | tr -d '\r')"
WORKFLOW_COUNT="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;')"
CREDENTIAL_COUNT="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM credentials_entity;')"
EXECUTION_COUNT="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM execution_entity;')"
ACTIVE_OR_WAITING="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM execution_entity WHERE status IN ('new','running','waiting','unknown');")"
[[ "$ACTIVE_OR_WAITING" == "0" ]] || die "Active or waiting executions prevent a consistent recovery set"

POSTGRES_IMAGE_ID="$(docker inspect --format '{{.Image}}' postgres)"
N8N_IMAGE_ID="$(docker inspect --format '{{.Image}}' n8n)"
RUNNER_IMAGE_ID=""
if docker inspect n8n-runner >/dev/null 2>&1; then
  RUNNER_IMAGE_ID="$(docker inspect --format '{{.Image}}' n8n-runner)"
fi

# The custom-format dump is consistent without snapshotting the live database
# volume. Listing every archive entry proves pg_restore can read it.
docker exec postgres pg_dump -U postgres -d postgres --format=custom --no-owner --no-acl >"$INCOMPLETE_DIR/postgres.dump"
docker run --rm --network none -i "$POSTGRES_IMAGE_ID" pg_restore --list \
  <"$INCOMPLETE_DIR/postgres.dump" >"$INCOMPLETE_DIR/pg_restore.list"
[[ -s "$INCOMPLETE_DIR/pg_restore.list" ]] || die "pg_restore list verification was empty"

# Export through n8n so credentials remain encrypted with the instance key.
WORKFLOW_TMP="/tmp/corekit-managed-workflows-${STAMP}.json"
CREDENTIAL_TMP="/tmp/corekit-managed-credentials-${STAMP}.json"
docker exec n8n n8n export:workflow --all --output="$WORKFLOW_TMP" >/dev/null
docker exec n8n n8n export:credentials --all --output="$CREDENTIAL_TMP" >/dev/null
docker cp "n8n:$WORKFLOW_TMP" "$INCOMPLETE_DIR/workflows.json" >/dev/null
docker cp "n8n:$CREDENTIAL_TMP" "$INCOMPLETE_DIR/credentials.json" >/dev/null
docker exec n8n rm -f "$WORKFLOW_TMP" "$CREDENTIAL_TMP"
jq -e . "$INCOMPLETE_DIR/workflows.json" >/dev/null
jq -e . "$INCOMPLETE_DIR/credentials.json" >/dev/null

# Preserve only the n8n key required for credential recovery. Read that one
# value from the live n8n container rather than loading the service env file.
N8N_ENCRYPTION_KEY="$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' n8n \
  | sed -n 's/^N8N_ENCRYPTION_KEY=//p')"
[[ -n "${N8N_ENCRYPTION_KEY:-}" ]] || die "N8N_ENCRYPTION_KEY is unavailable"
printf '%s' "$N8N_ENCRYPTION_KEY" >"$INCOMPLETE_DIR/n8n-encryption-key.protected"
chmod 0600 "$INCOMPLETE_DIR/n8n-encryption-key.protected"

# Add encryption at rest to both exports. Credentials inside the credential
# export remain n8n-encrypted as well.
for export_name in workflows credentials; do
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
    -pass "file:$INCOMPLETE_DIR/n8n-encryption-key.protected" \
    -in "$INCOMPLETE_DIR/${export_name}.json" \
    -out "$INCOMPLETE_DIR/${export_name}.json.enc"
  rm -f "$INCOMPLETE_DIR/${export_name}.json"
done
unset N8N_ENCRYPTION_KEY

N8N_VOLUME="$(docker inspect n8n | jq -r '.[0].Mounts[] | select(.Destination=="/home/node/.n8n") | .Name // empty')"
[[ -n "$N8N_VOLUME" ]] || die "Unable to resolve the n8n persistent volume"
docker run --rm --network none \
  -v "$N8N_VOLUME:/source:ro" \
  alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b \
  tar -C /source -czf - . >"$INCOMPLETE_DIR/n8n-volume.tar.gz"

CURRENT_GIT_COMMIT="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
git -C "$PROJECT_ROOT" archive "$CURRENT_GIT_COMMIT" \
  services/workflow-automation/n8n lib/managed_updates docs/managed-updates 2>/dev/null \
  | gzip -9 >"$INCOMPLETE_DIR/current-configuration.tar.gz" || \
  git -C "$PROJECT_ROOT" archive "$CURRENT_GIT_COMMIT" services/workflow-automation/n8n \
    | gzip -9 >"$INCOMPLETE_DIR/current-configuration.tar.gz"

if [[ -n "$PREVIOUS_GIT_COMMIT" ]] && git -C "$PROJECT_ROOT" cat-file -e "$PREVIOUS_GIT_COMMIT^{commit}" 2>/dev/null; then
  git -C "$PROJECT_ROOT" archive "$PREVIOUS_GIT_COMMIT" services/workflow-automation/n8n \
    | gzip -9 >"$INCOMPLETE_DIR/previous-live-configuration.tar.gz"
fi

IMAGE_TAGS=()
ROLLBACK_N8N_TAG="corekit/rollback/n8n:${N8N_VERSION}-${STAMP}"
docker tag "$N8N_IMAGE_ID" "$ROLLBACK_N8N_TAG"
IMAGE_TAGS+=("$ROLLBACK_N8N_TAG")

while IFS= read -r worker_name; do
  [[ -n "$worker_name" ]] || continue
  worker_image_id="$(docker inspect --format '{{.Image}}' "$worker_name")"
  worker_tag="corekit/rollback/n8n-worker:${N8N_VERSION}-${STAMP}-${worker_name##*-}"
  docker tag "$worker_image_id" "$worker_tag"
  IMAGE_TAGS+=("$worker_tag")
done < <(docker ps -a --filter label=com.docker.compose.service=n8n-worker --format '{{.Names}}' | sort)

if [[ -n "$RUNNER_IMAGE_ID" ]]; then
  ROLLBACK_RUNNER_TAG="corekit/rollback/n8n-runner:${STAMP}"
  docker tag "$RUNNER_IMAGE_ID" "$ROLLBACK_RUNNER_TAG"
  IMAGE_TAGS+=("$ROLLBACK_RUNNER_TAG")
fi

docker image save "${IMAGE_TAGS[@]}" | gzip -1 >"$INCOMPLETE_DIR/previous-images.tar.gz"

INVENTORY_NDJSON="$INCOMPLETE_DIR/.container-inventory.ndjson"
mapfile -t INVENTORY_CONTAINERS < <(
  printf '%s\n' n8n postgres
  docker ps -a --filter label=com.docker.compose.service=n8n-runner --format '{{.Names}}'
  docker ps -a --filter label=com.docker.compose.service=n8n-worker --format '{{.Names}}'
)
printf '%s\n' "${INVENTORY_CONTAINERS[@]}" | sort -u | while IFS= read -r container_name; do
  [[ -n "$container_name" ]] || continue
  container_record="$(docker inspect "$container_name" | jq -c '.[0] | {
    name:(.Name | ltrimstr("/")),
    configured_image:.Config.Image,
    image_id:.Image,
    state:.State.Status,
    health:(.State.Health.Status // "none"),
    started_at:.State.StartedAt
  }')"
  container_image_id="$(jq -r '.image_id' <<<"$container_record")"
  image_repo_digests="$(docker image inspect "$container_image_id" | jq -c '.[0].RepoDigests // []')"
  jq -cn --argjson container "$container_record" --argjson repo_digests "$image_repo_digests" \
    '$container + {repo_digests:$repo_digests}' >>"$INVENTORY_NDJSON"
done
jq -s . "$INVENTORY_NDJSON" >"$INCOMPLETE_DIR/container-inventory.json"
rm -f "$INVENTORY_NDJSON"

# Security-audit locations can contain workflow and credential names. Keep only
# category risk, generic recommendations, counts, and node types.
AUDIT_RAW="$INCOMPLETE_DIR/.security-audit.raw"
docker exec n8n n8n audit >"$AUDIT_RAW"
sed -n '/^{/,$p' "$AUDIT_RAW" | jq '
  with_entries(.value |= {
    risk,
    sections: [(.sections // [])[] | {
      title,
      description,
      recommendation,
      finding_count: ((.location // []) | length),
      node_types: ([.location[]?.nodeType] | map(select(. != null)) | unique),
      next_versions: (.nextVersions // [])
    }]
  })' >"$INCOMPLETE_DIR/security-audit.redacted.json"
rm -f "$AUDIT_RAW"

# Real restore drill in an isolated, internal-network-only disposable PostgreSQL
# container. When a candidate is supplied, it rehearses its migrations on the
# restored production schema. The clone's workflows are deactivated first,
# the network is internal-only, and no host port is published.
RESTORE_CONTAINER="corekit-n8n-restore-${STAMP,,}"
RESTORE_NETWORK="${RESTORE_CONTAINER}-network"
docker network create --internal "$RESTORE_NETWORK" >/dev/null
docker run -d --name "$RESTORE_CONTAINER" --network "$RESTORE_NETWORK" \
  -e POSTGRES_HOST_AUTH_METHOD=trust "$POSTGRES_IMAGE_ID" >/dev/null
for _ in $(seq 1 60); do
  if docker exec "$RESTORE_CONTAINER" pg_isready -U postgres -d postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec "$RESTORE_CONTAINER" pg_isready -U postgres -d postgres >/dev/null 2>&1 || die "Restore-drill PostgreSQL did not become ready"
docker cp "$INCOMPLETE_DIR/postgres.dump" "$RESTORE_CONTAINER:/tmp/postgres.dump" >/dev/null
docker exec "$RESTORE_CONTAINER" createdb -U postgres n8n_restore
docker exec "$RESTORE_CONTAINER" pg_restore -U postgres -d n8n_restore --no-owner --no-acl /tmp/postgres.dump
RESTORED_WORKFLOWS="$(docker exec "$RESTORE_CONTAINER" psql -X -U postgres -d n8n_restore -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;')"
RESTORED_CREDENTIALS="$(docker exec "$RESTORE_CONTAINER" psql -X -U postgres -d n8n_restore -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM credentials_entity;')"
[[ "$RESTORED_WORKFLOWS" == "$WORKFLOW_COUNT" ]] || die "Restore-drill workflow count mismatch"
[[ "$RESTORED_CREDENTIALS" == "$CREDENTIAL_COUNT" ]] || die "Restore-drill credential count mismatch"

CANDIDATE_DRILL_RESULT="not-requested"
CANDIDATE_IMAGE_ID=""
CANDIDATE_VERSION=""
if [[ -n "$CANDIDATE_IMAGE" ]]; then
  CANDIDATE_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "$CANDIDATE_IMAGE" 2>/dev/null)" \
    || die "Candidate image for migration drill is unavailable"
  CANDIDATE_VERSION="$(docker run --rm --network none "$CANDIDATE_IMAGE" n8n --version | tr -d '\r')"
  docker exec "$RESTORE_CONTAINER" psql -X -U postgres -d n8n_restore -v ON_ERROR_STOP=1 \
    -c 'UPDATE workflow_entity SET active = false WHERE active IS TRUE;' >/dev/null
  RESTORE_N8N_CONTAINER="${RESTORE_CONTAINER}-candidate"
  N8N_ENCRYPTION_KEY="$(<"$INCOMPLETE_DIR/n8n-encryption-key.protected")"
  export N8N_ENCRYPTION_KEY
  docker run -d --name "$RESTORE_N8N_CONTAINER" --network "$RESTORE_NETWORK" \
    -e DB_TYPE=postgresdb \
    -e DB_POSTGRESDB_HOST="$RESTORE_CONTAINER" \
    -e DB_POSTGRESDB_DATABASE=n8n_restore \
    -e DB_POSTGRESDB_USER=postgres \
    -e N8N_DIAGNOSTICS_ENABLED=false \
    -e N8N_ENCRYPTION_KEY \
    -e N8N_PERSONALIZATION_ENABLED=false \
    -e N8N_RUNNERS_ENABLED=false \
    "$CANDIDATE_IMAGE" >/dev/null
  unset N8N_ENCRYPTION_KEY
  for _ in $(seq 1 90); do
    if docker exec "$RESTORE_N8N_CONTAINER" wget -q -O /dev/null http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  docker exec "$RESTORE_N8N_CONTAINER" wget -q -O /dev/null http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1 \
    || die "Candidate failed readiness against the isolated restored database"
  CANDIDATE_LOGS="$(docker logs "$RESTORE_N8N_CONTAINER" 2>&1)"
  if grep -Ei 'migrations?[[:space:]:-]+(failed|failure|fatal|error)([[:space:]:.!]|$)|(failed|fatal|error)([[:space:]:-]+(to[[:space:]]+)?)?(run[[:space:]]+)?migrations?([[:space:]:.!]|$)' \
    <<<"$CANDIDATE_LOGS" >/dev/null; then
    die "Candidate migration errors were detected in the restore drill"
  fi
  RESTORED_WORKFLOWS_AFTER_MIGRATION="$(docker exec "$RESTORE_CONTAINER" psql -X -U postgres -d n8n_restore -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;')"
  RESTORED_CREDENTIALS_AFTER_MIGRATION="$(docker exec "$RESTORE_CONTAINER" psql -X -U postgres -d n8n_restore -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM credentials_entity;')"
  [[ "$RESTORED_WORKFLOWS_AFTER_MIGRATION" == "$WORKFLOW_COUNT" ]] || die "Candidate migration-drill workflow count mismatch"
  [[ "$RESTORED_CREDENTIALS_AFTER_MIGRATION" == "$CREDENTIAL_COUNT" ]] || die "Candidate migration-drill credential count mismatch"
  CANDIDATE_DRILL_RESULT="passed"
  docker rm --force "$RESTORE_N8N_CONTAINER" >/dev/null
  RESTORE_N8N_CONTAINER=""
fi
docker rm --force "$RESTORE_CONTAINER" >/dev/null
RESTORE_CONTAINER=""
docker network rm "$RESTORE_NETWORK" >/dev/null
RESTORE_NETWORK=""

if [[ -f "$PROJECT_ROOT/docs/managed-updates/n8n-recovery.md" ]]; then
  install -m 0600 "$PROJECT_ROOT/docs/managed-updates/n8n-recovery.md" "$INCOMPLETE_DIR/RESTORE.md"
else
  printf '%s\n' \
    'Restore only after proving no post-upgrade writes exist.' \
    'Load previous-images.tar.gz, restore postgres.dump into an isolated database first, then follow the committed n8n recovery runbook.' \
    >"$INCOMPLETE_DIR/RESTORE.md"
fi

(cd "$INCOMPLETE_DIR" && find . -maxdepth 1 -type f ! -name checksums.sha256 ! -name manifest.json -print0 \
  | sort -z | xargs -0 sha256sum >checksums.sha256)

jq -n \
  --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg service n8n \
  --arg label "$BACKUP_LABEL" \
  --arg git_commit "$CURRENT_GIT_COMMIT" \
  --arg previous_git_commit "$PREVIOUS_GIT_COMMIT" \
  --arg n8n_version "$N8N_VERSION" \
  --arg n8n_image_id "$N8N_IMAGE_ID" \
  --arg runner_image_id "$RUNNER_IMAGE_ID" \
  --arg postgres_image_id "$POSTGRES_IMAGE_ID" \
  --arg n8n_volume "$N8N_VOLUME" \
  --arg candidate_image "$CANDIDATE_IMAGE" \
  --arg candidate_image_id "$CANDIDATE_IMAGE_ID" \
  --arg candidate_version "$CANDIDATE_VERSION" \
  --arg candidate_drill_result "$CANDIDATE_DRILL_RESULT" \
  --argjson rollback_tags "$(printf '%s\n' "${IMAGE_TAGS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
  --argjson workflows "$WORKFLOW_COUNT" \
  --argjson credentials "$CREDENTIAL_COUNT" \
  --argjson executions "$EXECUTION_COUNT" \
  --argjson restored_workflows "$RESTORED_WORKFLOWS" \
  --argjson restored_credentials "$RESTORED_CREDENTIALS" \
  '{
    schema_version: 1,
    service: $service,
    label: $label,
    created_at: $created_at,
    verified: false,
    git: {commit: $git_commit, previous_live_commit: $previous_git_commit},
    versions: {n8n: $n8n_version},
    images: {
      n8n_image_id: $n8n_image_id,
      runner_image_id: $runner_image_id,
      postgres_image_id: $postgres_image_id,
      rollback_tags: $rollback_tags,
      inventory: "container-inventory.json",
      archive: "previous-images.tar.gz"
    },
    storage: {n8n_volume: $n8n_volume, database: "postgres", database_dump_format: "postgres-custom"},
    counts: {workflows: $workflows, credentials: $credentials, executions: $executions},
    restore_drill: {
      isolated: true,
      internal_network_only: true,
      restored_workflows_deactivated_before_candidate_start: ($candidate_drill_result == "passed"),
      result: "passed",
      workflows: $restored_workflows,
      credentials: $restored_credentials
    },
    candidate_migration_drill: {
      result: $candidate_drill_result,
      image: $candidate_image,
      image_id: $candidate_image_id,
      version: $candidate_version,
      host_ports_published: false,
      outbound_network_available: false
    },
    encryption: {
      workflow_export: "AES-256-CBC/PBKDF2",
      credential_export: "n8n-encrypted plus AES-256-CBC/PBKDF2",
      key_file: "n8n-encryption-key.protected"
    },
    checksums_file: "checksums.sha256",
    rollback_guard: "Do not restore over production until post-upgrade writes are ruled out."
  }' >"$INCOMPLETE_DIR/manifest.json"

chmod 0700 "$INCOMPLETE_DIR"
find "$INCOMPLETE_DIR" -maxdepth 1 -type f -exec chmod 0600 {} +
VERIFIED_MANIFEST="$(mktemp "$INCOMPLETE_DIR/.manifest.XXXXXX")"
jq '.verified = true' "$INCOMPLETE_DIR/manifest.json" >"$VERIFIED_MANIFEST"
chmod 0600 "$VERIFIED_MANIFEST"
mv "$VERIFIED_MANIFEST" "$INCOMPLETE_DIR/manifest.json"
mv "$INCOMPLETE_DIR" "$FINAL_DIR"

log_event info backup_verified "Recovery set and isolated restore drill verified"
printf '%s\n' "$FINAL_DIR/manifest.json"
