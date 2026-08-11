#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
STATE_ROOT="${COREKIT_MANAGED_STATE_ROOT:-/home/services/.local/state/ai-corekit/managed-updates}"
BACKUP_ROOT="${COREKIT_N8N_BACKUP_ROOT:-/home/services/backups/ai-corekit/n8n}"
LOCK_FILE="${COREKIT_MANAGED_LOCK_FILE:-$STATE_ROOT/managed-update.lock}"
N8N_DIR="$PROJECT_ROOT/services/workflow-automation/n8n"
POLICY_FILE="$N8N_DIR/service.json"
STATE_FILE="$STATE_ROOT/n8n.json"
COMMAND="${1:-help}"
SERVICE="${2:-n8n}"

shift || true
shift || true

OFFLINE=false
DRY_RUN=false
SECURITY_OVERRIDE=false
LOCAL_COMMIT=false
MANUAL_MAJOR=false
PREVIOUS_GIT_COMMIT=""

log_event() {
  local level="$1"
  local event="$2"
  local message="$3"
  jq -cn \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg level "$level" \
    --arg service "$SERVICE" \
    --arg event "$event" \
    --arg message "$message" \
    '{timestamp:$timestamp,level:$level,service:$service,event:$event,message:$message}'
}

die() {
  log_event error managed_update_failed "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: corekit managed-update <command> [service] [options]

Commands:
  check [service]          Compare the local deployment commit with the remote without mutating Git
  plan [service]           Validate policy and show the committed candidate deployment plan
  apply [service]          Fast-forward the deployment branch and apply an eligible committed candidate
  status [service]         Show redacted runtime state and live versions
  rollback-plan [service]  Show guarded recovery information; never restores a stateful DB automatically

Options:
  --offline                Do not contact the Git remote
  --dry-run                Plan only; never build, back up, or deploy
  --security-override      Manually bypass release age for a verified security update
  --manual-major           Manually approve a major update (all other gates still apply)
  --local-commit           Deploy the current clean committed feature branch (manual bootstrap only)
  --previous-git-commit X  Record the known previous live configuration commit in the recovery set
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline)
      OFFLINE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --security-override)
      SECURITY_OVERRIDE=true
      shift
      ;;
    --local-commit)
      LOCAL_COMMIT=true
      shift
      ;;
    --manual-major)
      MANUAL_MAJOR=true
      shift
      ;;
    --previous-git-commit)
      PREVIOUS_GIT_COMMIT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown managed-update option: $1"
      ;;
  esac
done

for command_name in docker flock git jq; do
  command -v "$command_name" >/dev/null 2>&1 || die "Required command is missing: $command_name"
done

if [[ "$COMMAND" == "apply" && "$DRY_RUN" != "true" ]]; then
  install -d -m 0700 "$STATE_ROOT"
  chmod 0700 "$STATE_ROOT"
  exec 9>"$LOCK_FILE"
  flock -n 9 || die "Another managed updater process is already running"
elif [[ -e "$LOCK_FILE" ]]; then
  exec 9<"$LOCK_FILE"
  flock -n -s 9 || die "Another managed updater process is already running"
fi

[[ "$SERVICE" == "n8n" ]] || die "Service '$SERVICE' is not opted in to managed updates"
[[ -f "$POLICY_FILE" ]] || die "n8n managed-update policy is missing"
[[ "$(jq -r '.managed_update.enabled // false' "$POLICY_FILE")" == "true" ]] || die "n8n managed updates are disabled"

DEPLOYMENT_BRANCH="$(jq -r '.managed_update.deployment_branch' "$POLICY_FILE")"
MINIMUM_RELEASE_AGE_DAYS="$(jq -r '.managed_update.minimum_release_age_days' "$POLICY_FILE")"
MINIMUM_FREE_SPACE_GB="$(jq -r '.managed_update.minimum_free_space_gb' "$POLICY_FILE")"
RECOVERY_SETS_TO_KEEP="$(jq -r '.managed_update.recovery_sets_to_keep' "$POLICY_FILE")"

N8N_REF="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/n8n:/ {print $2; exit}' "$N8N_DIR/Dockerfile")"
RUNNER_REF="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/runners:/ {print $2; exit}' "$N8N_DIR/runner/Dockerfile")"
TARGET_VERSION="${N8N_REF#*:}"
TARGET_VERSION="${TARGET_VERSION%%@*}"
TARGET_N8N_DIGEST="${N8N_REF##*@}"
TARGET_RUNNER_VERSION="${RUNNER_REF#*:}"
TARGET_RUNNER_VERSION="${TARGET_RUNNER_VERSION%%@*}"
TARGET_RUNNER_DIGEST="${RUNNER_REF##*@}"
N8N_GIT_VERSION="$(awk -F= '$1 == "ARG N8N_GIT_VERSION" {print $2}' "$N8N_DIR/Dockerfile")"
N8N_GIT_COMMIT="$(awk -F= '$1 == "ARG N8N_GIT_COMMIT" {print $2}' "$N8N_DIR/Dockerfile")"

validate_bundle() {
  [[ "$TARGET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Pinned n8n version is invalid"
  [[ "$TARGET_VERSION" == "$TARGET_RUNNER_VERSION" ]] || die "Pinned n8n and runner versions differ"
  [[ "$TARGET_N8N_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || die "Pinned n8n digest is invalid"
  [[ "$TARGET_RUNNER_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || die "Pinned runner digest is invalid"
  [[ "$N8N_GIT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Pinned n8n-git version is invalid"
  [[ "$N8N_GIT_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Pinned n8n-git commit is invalid"
  jq -e . "$POLICY_FILE" "$N8N_DIR/task-runners-managed.json" >/dev/null || die "Managed n8n JSON configuration is invalid"
  if grep -ERn '(^|[[:space:]:])latest([@[:space:]]|$)' \
    "$N8N_DIR/Dockerfile" "$N8N_DIR/runner/Dockerfile" "$N8N_DIR/docker-compose.yml" >/dev/null; then
    die "Moving latest reference found in the managed n8n bundle"
  fi
}

live_version() {
  if docker inspect n8n >/dev/null 2>&1 && [[ "$(docker inspect --format '{{.State.Running}}' n8n)" == "true" ]]; then
    docker exec n8n n8n --version 2>/dev/null | tr -d '\r'
  else
    printf 'unknown\n'
  fi
}

version_change_type() {
  local current="$1"
  local target="$2"
  if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'unknown\n'
    return
  fi
  IFS=. read -r current_major current_minor current_patch <<<"$current"
  IFS=. read -r target_major target_minor target_patch <<<"$target"
  if (( target_major != current_major )); then
    printf 'major\n'
  elif (( target_minor != current_minor )); then
    printf 'minor\n'
  elif (( target_patch != current_patch )); then
    printf 'patch\n'
  else
    printf 'none\n'
  fi
}

git_is_clean() {
  [[ -z "$(git -C "$PROJECT_ROOT" status --porcelain --untracked-files=normal)" ]]
}

remote_head() {
  if [[ "$OFFLINE" == "true" ]]; then
    printf 'offline\n'
  else
    git -C "$PROJECT_ROOT" ls-remote --heads origin "refs/heads/$DEPLOYMENT_BRANCH" | awk 'NR == 1 {print $1}'
  fi
}

release_age_days() {
  local committed_at now
  committed_at="$(git -C "$PROJECT_ROOT" log -1 --format=%ct -- "$N8N_DIR/Dockerfile")"
  [[ -n "$committed_at" ]] || die "Unable to determine candidate commit age"
  now="$(date +%s)"
  printf '%s\n' "$(( (now - committed_at) / 86400 ))"
}

free_space_gb() {
  df -Pk "$PROJECT_ROOT" | awk 'NR == 2 {printf "%d\n", $4 / 1024 / 1024}'
}

bundle_fingerprint() {
  git -C "$PROJECT_ROOT" ls-tree -r HEAD -- "${N8N_DIR#"$PROJECT_ROOT"/}" \
    | sha256sum | awk '{print $1}'
}

version_is_greater() {
  local current="$1"
  local target="$2"
  local current_major current_minor current_patch target_major target_minor target_patch
  IFS=. read -r current_major current_minor current_patch <<<"$current"
  IFS=. read -r target_major target_minor target_patch <<<"$target"
  (( target_major > current_major )) ||
    (( target_major == current_major && target_minor > current_minor )) ||
    (( target_major == current_major && target_minor == current_minor && target_patch > current_patch ))
}

active_execution_count() {
  docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 \
    -c "SELECT count(*) FROM execution_entity WHERE status IN ('new','running','waiting','unknown');"
}

entity_count() {
  local table="$1"
  docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 \
    -c "SELECT count(*) FROM ${table};"
}

load_required_environment() {
  set -a
  if [[ -f "$PROJECT_ROOT/config/.env.global" ]]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/config/.env.global"
  fi
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/services/data-services/postgres/.env"
  # shellcheck disable=SC1091
  source "$N8N_DIR/.env"
  set +a
  export PROJECT_ROOT
  export COMPOSE_PROFILES=n8n
}

compose_project() {
  docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' n8n 2>/dev/null || printf 'localai\n'
}

print_plan() {
  local current_version change_type current_branch head remote age free_gb active changed current_commit fingerprint
  validate_bundle
  current_version="$(live_version)"
  change_type="$(version_change_type "$current_version" "$TARGET_VERSION")"
  current_branch="$(git -C "$PROJECT_ROOT" branch --show-current)"
  current_commit="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
  fingerprint="$(bundle_fingerprint)"
  remote="$(remote_head)"
  age="$(release_age_days)"
  free_gb="$(free_space_gb)"
  active="unknown"
  if docker inspect postgres >/dev/null 2>&1; then
    active="$(active_execution_count)"
  fi
  changed=true
  if [[ "$change_type" == "none" && -f "$STATE_FILE" ]] && \
    [[ "$(jq -r '.current.config_fingerprint // empty' "$STATE_FILE")" == "$fingerprint" ]]; then
    changed=false
  fi
  head="$current_commit"
  jq -n \
    --arg service "$SERVICE" \
    --arg branch "$current_branch" \
    --arg expected_branch "$DEPLOYMENT_BRANCH" \
    --arg head "$head" \
    --arg config_fingerprint "$fingerprint" \
    --arg remote_head "$remote" \
    --arg current_version "$current_version" \
    --arg target_version "$TARGET_VERSION" \
    --arg update_type "$change_type" \
    --arg n8n_digest "$TARGET_N8N_DIGEST" \
    --arg runner_digest "$TARGET_RUNNER_DIGEST" \
    --arg n8n_git_version "$N8N_GIT_VERSION" \
    --argjson release_age_days "$age" \
    --argjson minimum_release_age_days "$MINIMUM_RELEASE_AGE_DAYS" \
    --argjson free_space_gb "$free_gb" \
    --argjson minimum_free_space_gb "$MINIMUM_FREE_SPACE_GB" \
    --arg active_executions "$active" \
    --argjson changed "$changed" \
    --argjson clean "$(git_is_clean && echo true || echo false)" \
    '{
      service:$service,
      policy_enabled:true,
      branch:$branch,
      expected_branch:$expected_branch,
      git_head:$head,
      config_fingerprint:$config_fingerprint,
      remote_head:$remote_head,
      clean_tree:$clean,
      changed:$changed,
      current_version:$current_version,
      target_version:$target_version,
      update_type:$update_type,
      candidate:{n8n_digest:$n8n_digest,runner_digest:$runner_digest,n8n_git_version:$n8n_git_version},
      gates:{
        release_age_days:$release_age_days,
        minimum_release_age_days:$minimum_release_age_days,
        free_space_gb:$free_space_gb,
        minimum_free_space_gb:$minimum_free_space_gb,
        active_executions:$active_executions,
        backup_required:true,
        guarded_stateful_rollback:true
      }
    }'
}

write_failure_state() {
  local stage="$1"
  local backup_manifest="${2:-}"
  local tmp_state
  tmp_state="$(mktemp "$STATE_ROOT/.n8n-state.XXXXXX")"
  if [[ -f "$STATE_FILE" ]]; then
    jq \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg stage "$stage" \
      --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
      --arg target_version "$TARGET_VERSION" \
      --arg backup_manifest "$backup_manifest" \
      '.last_result={result:"failed",timestamp:$timestamp,stage:$stage,git_commit:$git_commit,target_version:$target_version,backup_manifest:$backup_manifest,writes_possible:true,automatic_database_restore_permitted:false}' \
      "$STATE_FILE" >"$tmp_state"
  else
    jq -n \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg stage "$stage" \
      --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
      --arg target_version "$TARGET_VERSION" \
      --arg backup_manifest "$backup_manifest" \
      '{schema_version:1,service:"n8n",last_result:{result:"failed",timestamp:$timestamp,stage:$stage,git_commit:$git_commit,target_version:$target_version,backup_manifest:$backup_manifest,writes_possible:true,automatic_database_restore_permitted:false}}' \
      >"$tmp_state"
  fi
  chmod 0600 "$tmp_state"
  mv "$tmp_state" "$STATE_FILE"
}

write_success_state() {
  local previous_version="$1"
  local previous_n8n_image_id="$2"
  local previous_runner_image_id="$3"
  local backup_manifest="$4"
  local n8n_image_id runner_image_id tmp_state previous_state history fingerprint previous_git_commit
  n8n_image_id="$(docker inspect --format '{{.Image}}' n8n)"
  runner_image_id="$(docker inspect --format '{{.Image}}' n8n-runner)"
  fingerprint="$(bundle_fingerprint)"
  previous_git_commit="$(jq -r '.git.previous_live_commit // empty' "$backup_manifest")"
  previous_state='null'
  history='[]'
  if [[ -f "$STATE_FILE" ]]; then
    previous_state="$(jq -c '.current // null' "$STATE_FILE")"
    history="$(jq -c '.history // []' "$STATE_FILE")"
  fi
  if [[ "$previous_state" == "null" ]]; then
    previous_state="$(jq -cn \
      --arg version "$previous_version" \
      --arg n8n_image_id "$previous_n8n_image_id" \
      --arg runner_image_id "$previous_runner_image_id" \
      --arg git_commit "$previous_git_commit" \
      --arg backup_manifest "$backup_manifest" \
      '{version:$version,git_commit:$git_commit,n8n_image_id:$n8n_image_id,runner_image_id:$runner_image_id,backup_manifest:$backup_manifest}')"
  fi
  tmp_state="$(mktemp "$STATE_ROOT/.n8n-state.XXXXXX")"
  jq -n \
    --arg deployed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg version "$TARGET_VERSION" \
    --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
    --arg config_fingerprint "$fingerprint" \
    --arg n8n_image_id "$n8n_image_id" \
    --arg runner_image_id "$runner_image_id" \
    --arg n8n_base_digest "$TARGET_N8N_DIGEST" \
    --arg runner_base_digest "$TARGET_RUNNER_DIGEST" \
    --arg n8n_git_version "$N8N_GIT_VERSION" \
    --arg n8n_git_commit "$N8N_GIT_COMMIT" \
    --arg backup_manifest "$backup_manifest" \
    --argjson previous "$previous_state" \
    --argjson history "$history" \
    '{
      schema_version:1,
      service:"n8n",
      current:{
        version:$version,
        git_commit:$git_commit,
        config_fingerprint:$config_fingerprint,
        deployed_at:$deployed_at,
        n8n_image_id:$n8n_image_id,
        runner_image_id:$runner_image_id,
        n8n_base_digest:$n8n_base_digest,
        runner_base_digest:$runner_base_digest,
        n8n_git_version:$n8n_git_version,
        n8n_git_commit:$n8n_git_commit,
        backup_manifest:$backup_manifest,
        result:"success"
      },
      previous:$previous,
      last_result:{result:"success",timestamp:$deployed_at},
      history: (($history + [{version:$version,git_commit:$git_commit,deployed_at:$deployed_at,backup_manifest:$backup_manifest,result:"success"}]) | if length > 20 then .[-20:] else . end)
    }' >"$tmp_state"
  chmod 0600 "$tmp_state"
  mv "$tmp_state" "$STATE_FILE"
}

verify_recovery_retention() {
  local verified_count
  verified_count="$(find "$BACKUP_ROOT" -mindepth 2 -maxdepth 2 -name manifest.json -type f -print0 \
    | xargs -0 -r jq -r 'select(.verified == true) | .created_at' | wc -l)"
  log_event info recovery_retention "Verified recovery sets are preserved without automatic deletion; policy floor is ${RECOVERY_SETS_TO_KEEP}, current count is ${verified_count}"
}

apply_update() {
  validate_bundle
  git_is_clean || die "Git worktree is dirty; refusing managed deployment"

  local branch current_version change_type age free_gb current_commit short_commit fingerprint
  local candidate_image candidate_runner_image project_name workflow_count credential_count
  local previous_n8n_image_id previous_runner_image_id backup_manifest active

  branch="$(git -C "$PROJECT_ROOT" branch --show-current)"
  if [[ "$LOCAL_COMMIT" == "true" ]]; then
    [[ "$branch" == codex/* || "$branch" == agent/* ]] || die "--local-commit is limited to an explicit scoped feature branch"
    [[ "$SECURITY_OVERRIDE" == "true" || "$MANUAL_MAJOR" == "true" ]] || die "--local-commit requires an explicit manual security or major approval flag"
    log_event warning local_commit_bootstrap "Deploying a clean committed feature branch without updating Git"
  else
    [[ "$branch" == "$DEPLOYMENT_BRANCH" ]] || die "Unexpected deployment branch: $branch"
    [[ "$OFFLINE" == "false" ]] || die "Normal apply cannot run offline"
    git -C "$PROJECT_ROOT" fetch --no-tags origin "$DEPLOYMENT_BRANCH"
    git_is_clean || die "Git worktree became dirty after fetch"
    git -C "$PROJECT_ROOT" merge-base --is-ancestor HEAD "origin/$DEPLOYMENT_BRANCH" || die "Remote change is not fast-forwardable"
    git -C "$PROJECT_ROOT" merge --ff-only "origin/$DEPLOYMENT_BRANCH"
    validate_bundle
  fi

  current_version="$(live_version)"
  change_type="$(version_change_type "$current_version" "$TARGET_VERSION")"
  if [[ "$change_type" == "major" && "$MANUAL_MAJOR" != "true" ]]; then
    die "Major n8n updates require --manual-major"
  fi
  if [[ "$change_type" != "none" && "$change_type" != "patch" && "$change_type" != "minor" && "$change_type" != "major" ]]; then
    die "Unable to classify the live-to-candidate version change"
  fi
  if [[ "$change_type" != "none" ]] && ! version_is_greater "$current_version" "$TARGET_VERSION"; then
    die "Managed updates refuse version downgrades; use the guarded recovery procedure"
  fi

  current_commit="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
  fingerprint="$(bundle_fingerprint)"
  if [[ "$change_type" == "none" && -f "$STATE_FILE" ]] && \
    [[ "$(jq -r '.current.config_fingerprint // empty' "$STATE_FILE")" == "$fingerprint" ]]; then
    log_event info no_change "Committed n8n bundle is already deployed"
    return 0
  fi

  age="$(release_age_days)"
  if (( age < MINIMUM_RELEASE_AGE_DAYS )) && [[ "$SECURITY_OVERRIDE" != "true" ]]; then
    die "Candidate has not met the minimum release-age gate"
  fi
  if [[ "$SECURITY_OVERRIDE" == "true" ]]; then
    log_event warning security_override "Release-age gate bypassed for the manually approved security update; all other gates remain active"
  fi

  free_gb="$(free_space_gb)"
  (( free_gb >= MINIMUM_FREE_SPACE_GB )) || die "Insufficient free space for candidate build and recovery set"
  active="$(active_execution_count)"
  [[ "$active" == "0" ]] || die "Active or waiting executions prevent deployment"

  short_commit="$(git -C "$PROJECT_ROOT" rev-parse --short=12 HEAD)"
  candidate_image="corekit/n8n:${TARGET_VERSION}-git${short_commit}"
  candidate_runner_image="corekit/n8n-runners:${TARGET_VERSION}-git${short_commit}"
  log_event info candidate_build_started "Building exact committed n8n and runner candidates before downtime"
  docker build --pull=false --tag "$candidate_image" "$N8N_DIR"
  docker build --pull=false --tag "$candidate_runner_image" "$N8N_DIR/runner"

  [[ "$(docker run --rm --network none "$candidate_image" n8n --version | tr -d '\r')" == "$TARGET_VERSION" ]] || die "Candidate n8n version verification failed"
  [[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.n8n-git.version"}}' "$candidate_image")" == "$N8N_GIT_VERSION" ]] || die "Candidate n8n-git version verification failed"
  [[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.n8n-git.commit"}}' "$candidate_image")" == "$N8N_GIT_COMMIT" ]] || die "Candidate n8n-git commit verification failed"
  [[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' "$candidate_runner_image")" == "$TARGET_VERSION" ]] || die "Candidate runner version verification failed"
  [[ "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$candidate_runner_image")" == "$TARGET_VERSION" ]] || die "Candidate upstream runner version verification failed"

  workflow_count="$(entity_count workflow_entity)"
  credential_count="$(entity_count credentials_entity)"
  previous_n8n_image_id="$(docker inspect --format '{{.Image}}' n8n)"
  previous_runner_image_id="$(docker inspect --format '{{.Image}}' n8n-runner 2>/dev/null || true)"
  if [[ -z "$PREVIOUS_GIT_COMMIT" ]]; then
    if [[ -f "$STATE_FILE" ]]; then
      PREVIOUS_GIT_COMMIT="$(jq -r '.current.git_commit // empty' "$STATE_FILE")"
    fi
    if [[ -z "$PREVIOUS_GIT_COMMIT" ]] && git -C "$PROJECT_ROOT" rev-parse "origin/$DEPLOYMENT_BRANCH" >/dev/null 2>&1; then
      PREVIOUS_GIT_COMMIT="$(git -C "$PROJECT_ROOT" rev-parse "origin/$DEPLOYMENT_BRANCH")"
    fi
  fi

  log_event info backup_started "Creating mandatory final recovery set and isolated restore drill"
  backup_manifest="$(COREKIT_PROJECT_ROOT="$PROJECT_ROOT" COREKIT_N8N_BACKUP_ROOT="$BACKUP_ROOT" \
    bash "$N8N_DIR/managed/backup.sh" --label "pre-${TARGET_VERSION}" \
      --previous-git-commit "$PREVIOUS_GIT_COMMIT" --candidate-image "$candidate_image" | tail -n 1)"
  [[ -f "$backup_manifest" ]] || die "Backup script did not return a verified manifest"
  [[ "$(jq -r '.verified' "$backup_manifest")" == "true" ]] || die "Recovery set is not verified"
  [[ "$(jq -r '.restore_drill.result' "$backup_manifest")" == "passed" ]] || die "Recovery-set restore drill did not pass"
  [[ "$(jq -r '.candidate_migration_drill.result' "$backup_manifest")" == "passed" ]] || die "Candidate migration rehearsal did not pass"

  [[ "$(active_execution_count)" == "0" ]] || die "Executions became active after the backup gate"
  load_required_environment
  export N8N_MANAGED_IMAGE="$candidate_image"
  export N8N_MANAGED_RUNNER_IMAGE="$candidate_runner_image"
  project_name="$(compose_project)"
  [[ -n "$project_name" ]] || project_name=localai

  mapfile -t old_workers < <(docker ps -a --filter label=com.docker.compose.service=n8n-worker --format '{{.Names}}' | sort)
  if (( ${#old_workers[@]} > 0 )); then
    docker stop --time 60 "${old_workers[@]}" >/dev/null
  fi

  log_event info deployment_started "Recreating only the coordinated n8n main and runner bundle"
  if ! docker compose -p "$project_name" --project-directory "$N8N_DIR" -f "$N8N_DIR/docker-compose.yml" \
    up -d --no-deps n8n n8n-runner; then
    write_failure_state compose_up "$backup_manifest"
    die "Candidate Compose deployment failed; stateful recovery requires the guarded rollback plan"
  fi

  if ! COREKIT_MANAGED_STATE_ROOT="$STATE_ROOT" bash "$N8N_DIR/managed/strict-healthcheck.sh" \
    --expected-workflows "$workflow_count" \
    --expected-credentials "$credential_count" \
    --canary; then
    docker stop --time 30 n8n-runner n8n >/dev/null 2>&1 || true
    write_failure_state strict_health "$backup_manifest"
    die "Candidate failed strict health; stopped without automatic database restore because writes are conservatively possible"
  fi

  if (( ${#old_workers[@]} > 0 )); then
    docker rm "${old_workers[@]}" >/dev/null
  fi

  write_success_state "$current_version" "$previous_n8n_image_id" "$previous_runner_image_id" "$backup_manifest"
  verify_recovery_retention
  log_event info deployment_succeeded "n8n managed deployment passed readiness, canary, counts, audit, and restore gates"
}

show_status() {
  local current_version runner_version n8n_image_id runner_image_id
  current_version="$(live_version)"
  runner_version="unknown"
  n8n_image_id=""
  runner_image_id=""
  if docker inspect n8n >/dev/null 2>&1; then
    n8n_image_id="$(docker inspect --format '{{.Image}}' n8n)"
  fi
  if docker inspect n8n-runner >/dev/null 2>&1; then
    runner_version="$(docker inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' n8n-runner 2>/dev/null || true)"
    [[ -n "$runner_version" ]] || runner_version="$(docker inspect --format '{{.Config.Image}}' n8n-runner | sed -n 's/.*:\([0-9][0-9.]*\).*/\1/p')"
    runner_image_id="$(docker inspect --format '{{.Image}}' n8n-runner)"
  fi
  local state='null'
  [[ -f "$STATE_FILE" ]] && state="$(cat "$STATE_FILE")"
  jq -n \
    --arg live_n8n_version "$current_version" \
    --arg live_runner_version "$runner_version" \
    --arg n8n_image_id "$n8n_image_id" \
    --arg runner_image_id "$runner_image_id" \
    --argjson state "$state" \
    '{live:{n8n_version:$live_n8n_version,runner_version:$live_runner_version,n8n_image_id:$n8n_image_id,runner_image_id:$runner_image_id},state:$state}'
}

show_rollback_plan() {
  [[ -f "$STATE_FILE" ]] || die "No managed-update state exists"
  jq '{
    service,
    current,
    previous,
    last_result,
    recovery:{
      automatic_database_restore_permitted:false,
      writes_must_be_ruled_out:true,
      backup_manifest:(.current.backup_manifest // .last_result.backup_manifest // .previous.backup_manifest),
      procedure:[
        "Stop only n8n and n8n-runner and preserve their logs.",
        "Verify whether any post-upgrade workflow, credential, execution, user, webhook, or settings writes occurred.",
        "If writes may exist, do not restore: preserve the failed database and escalate.",
        "If writes are conclusively absent, verify checksums.sha256 and repeat an isolated pg_restore drill.",
        "Load previous-images.tar.gz, restore postgres.dump only during an approved maintenance window, then start the recorded previous n8n image and run strict health/count checks."
      ]
    }
  }' "$STATE_FILE"
}

case "$COMMAND" in
  check)
    validate_bundle
    LOCAL_HEAD="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
    REMOTE_HEAD="$(remote_head)"
    jq -n \
      --arg service "$SERVICE" \
      --arg branch "$(git -C "$PROJECT_ROOT" branch --show-current)" \
      --arg expected_branch "$DEPLOYMENT_BRANCH" \
      --arg local_head "$LOCAL_HEAD" \
      --arg remote_head "$REMOTE_HEAD" \
      --arg target_version "$TARGET_VERSION" \
      --arg live_version "$(live_version)" \
      '{service:$service,branch:$branch,expected_branch:$expected_branch,local_head:$local_head,remote_head:$remote_head,target_version:$target_version,live_version:$live_version,mutated:false}'
    ;;
  plan)
    print_plan
    ;;
  apply)
    if [[ "$DRY_RUN" == "true" ]]; then
      print_plan
    else
      apply_update
    fi
    ;;
  status)
    show_status
    ;;
  rollback-plan)
    show_rollback_plan
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    die "Unknown managed-update command: $COMMAND"
    ;;
esac
