#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
N8N_DIR="$PROJECT_ROOT/services/workflow-automation/n8n"
ONLINE=false
VALIDATION_TMP="$(mktemp -d /tmp/corekit-managed-validation.XXXXXX)"
trap 'rm -rf -- "$VALIDATION_TMP"' EXIT

if [[ "${1:-}" == "--online" ]]; then
  ONLINE=true
fi

for script in \
  "$PROJECT_ROOT/corekit.sh" \
  "$PROJECT_ROOT/lib/managed_updates/managed-update.sh" \
  "$N8N_DIR/managed/backup.sh" \
  "$N8N_DIR/managed/strict-healthcheck.sh" \
  "$PROJECT_ROOT/scripts/install-managed-update-systemd.sh"; do
  bash -n "$script"
done

jq -e . \
  "$PROJECT_ROOT/renovate.json" \
  "$N8N_DIR/service.json" \
  "$N8N_DIR/managed/canary.json" \
  "$N8N_DIR/task-runners-managed.json" >/dev/null
jq -e '.active == false and ([.nodes[].type] | sort) == ["n8n-nodes-base.manualTrigger","n8n-nodes-base.set"]' \
  "$N8N_DIR/managed/canary.json" >/dev/null

N8N_REF="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/n8n:/ {print $2; exit}' "$N8N_DIR/Dockerfile")"
RUNNER_REF="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/runners:/ {print $2; exit}' "$N8N_DIR/runner/Dockerfile")"
N8N_VERSION="${N8N_REF#*:}"
N8N_VERSION="${N8N_VERSION%%@*}"
RUNNER_VERSION="${RUNNER_REF#*:}"
RUNNER_VERSION="${RUNNER_VERSION%%@*}"
[[ "$N8N_VERSION" == "$RUNNER_VERSION" ]]
[[ "$N8N_REF" =~ @sha256:[0-9a-f]{64}$ ]]
[[ "$RUNNER_REF" =~ @sha256:[0-9a-f]{64}$ ]]

COMPOSE_N8N_VERSION="$(sed -n 's/.*corekit\/n8n:\([0-9][0-9.]*\)-git.*/\1/p' "$N8N_DIR/docker-compose.yml" | head -1)"
COMPOSE_RUNNER_VERSION="$(sed -n 's/.*corekit\/n8n-runners:\([0-9][0-9.]*\)-r.*/\1/p' "$N8N_DIR/docker-compose.yml" | head -1)"
RUNNER_LABEL_VERSION="$(sed -n 's/.*io\.corekit\.runner-for-n8n-version="\([0-9][0-9.]*\)".*/\1/p' "$N8N_DIR/runner/Dockerfile")"
[[ "$N8N_VERSION" == "$COMPOSE_N8N_VERSION" ]]
[[ "$N8N_VERSION" == "$COMPOSE_RUNNER_VERSION" ]]
[[ "$N8N_VERSION" == "$RUNNER_LABEL_VERSION" ]]

if grep -ERn '(^|[[:space:]:])latest([@[:space:]]|$)' \
  "$N8N_DIR/Dockerfile" "$N8N_DIR/runner/Dockerfile" "$N8N_DIR/docker-compose.yml"; then
  echo "Moving latest reference found in n8n bundle" >&2
  exit 1
fi

for required_pattern in '.env' '**/credentials/**' '**/backups/**' 'data/**' '.git'; do
  grep -Fxq "$required_pattern" "$N8N_DIR/.dockerignore"
done

FORBIDDEN_HOST_ROOT="/home/"services
FORBIDDEN_UNIT_USER="User="services
FORBIDDEN_UNIT_GROUP="Group="services
if grep -RnsF \
  -e "$FORBIDDEN_HOST_ROOT" \
  -e "$FORBIDDEN_UNIT_USER" \
  -e "$FORBIDDEN_UNIT_GROUP" \
  "$PROJECT_ROOT/docs/managed-updates" \
  "$PROJECT_ROOT/lib/managed_updates" \
  "$PROJECT_ROOT/scripts/install-managed-update-systemd.sh" \
  "$PROJECT_ROOT/systemd"; then
  echo "Host-specific managed-update path or account found" >&2
  exit 1
fi

RENDERED_UNITS="$VALIDATION_TMP/systemd"
VALIDATION_USER="$(stat -c '%U' "$PROJECT_ROOT")"
if [[ "$VALIDATION_USER" == "root" ]]; then
  VALIDATION_USER="nobody"
fi
VALIDATION_GROUP="$(id -gn "$VALIDATION_USER")"
"$PROJECT_ROOT/scripts/install-managed-update-systemd.sh" \
  --render-only "$RENDERED_UNITS" \
  --user "$VALIDATION_USER" \
  --group "$VALIDATION_GROUP" \
  --project-root "$PROJECT_ROOT" \
  --state-root "$VALIDATION_TMP/state" \
  --backup-root "$VALIDATION_TMP/backups"
systemd-analyze verify \
  "$RENDERED_UNITS/corekit-managed-update-check.service" \
  "$RENDERED_UNITS/corekit-managed-update-check.timer" \
  "$RENDERED_UNITS/corekit-managed-update-apply.service" \
  "$RENDERED_UNITS/corekit-managed-update-apply.timer"
if "$PROJECT_ROOT/scripts/install-managed-update-systemd.sh" \
  --render-only "$VALIDATION_TMP/root-units" \
  --user root \
  --project-root "$PROJECT_ROOT" \
  --state-root "$VALIDATION_TMP/root-state" \
  --backup-root "$VALIDATION_TMP/root-backups" >/dev/null 2>&1; then
  echo "Systemd installer accepted root as the scheduled runtime account" >&2
  exit 1
fi

ENABLED_POLICIES="$(find "$PROJECT_ROOT/services" -mindepth 3 -maxdepth 3 -name service.json -type f -print0 \
  | xargs -0 -r jq -r 'select(.managed_update.enabled == true) | .name')"
[[ "$ENABLED_POLICIES" == "n8n" ]]

if grep -RniE 'watchtower|corekit[.]sh update|corekit update' \
  "$PROJECT_ROOT/systemd" "$PROJECT_ROOT/lib/managed_updates" 2>/dev/null; then
  echo "Forbidden broad updater reference found in managed scheduling code" >&2
  exit 1
fi

export PROJECT_ROOT
export COMPOSE_PROFILES=n8n
export POSTGRES_PASSWORD=ci-placeholder
export N8N_ENCRYPTION_KEY=ci-placeholder-encryption-key
export N8N_RUNNERS_AUTH_TOKEN=ci-placeholder-runner-token
export N8N_USER_MANAGEMENT_JWT_SECRET=ci-placeholder-jwt
docker compose -p corekit-ci --project-directory "$N8N_DIR" -f "$N8N_DIR/docker-compose.yml" config -q
COMPOSE_JSON="$(docker compose -p corekit-ci --project-directory "$N8N_DIR" \
  -f "$N8N_DIR/docker-compose.yml" config --format json)"
jq -e '
  (.services | has("n8n-worker") | not) and
  (.services.n8n.environment.N8N_DEFAULT_BINARY_DATA_MODE == "filesystem") and
  (.services.n8n.environment | has("EXECUTIONS_MODE") | not) and
  (.services.n8n.environment | has("N8N_BINARY_DATA_MODE") | not) and
  (.services.n8n.environment | has("QUEUE_BULL_REDIS_HOST") | not) and
  (.services["n8n-runner"].read_only == true) and
  (.services["n8n-runner"].cap_drop == ["ALL"]) and
  (.services["n8n-runner"].security_opt == ["no-new-privileges:true"]) and
  ((.services["n8n-runner"].environment | keys) - [
    "GENERIC_TIMEZONE",
    "N8N_RUNNERS_AUTH_TOKEN",
    "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT",
    "N8N_RUNNERS_MAX_CONCURRENCY",
    "N8N_RUNNERS_TASK_BROKER_URI",
    "N8N_RUNNERS_TASK_TIMEOUT",
    "NODE_OPTIONS"
  ] | length == 0)
' <<<"$COMPOSE_JSON" >/dev/null

if [[ "$ONLINE" == "true" ]]; then
  STABLE_TAG="$(curl -fsSL --retry 3 https://api.github.com/repos/n8n-io/n8n/releases/latest | jq -r '.tag_name')"
  [[ "$STABLE_TAG" == "n8n@$N8N_VERSION" ]] || {
    echo "Candidate $N8N_VERSION is not the official stable release ($STABLE_TAG)" >&2
    exit 1
  }
  N8N_GIT_VERSION="$(awk -F= '$1 == "ARG N8N_GIT_VERSION" {print $2}' "$N8N_DIR/Dockerfile")"
  N8N_GIT_COMMIT="$(awk -F= '$1 == "ARG N8N_GIT_COMMIT" {print $2}' "$N8N_DIR/Dockerfile")"
  RESOLVED_N8N_GIT_COMMIT="$(git ls-remote https://github.com/tcoretech/n8n-git.git "refs/tags/$N8N_GIT_VERSION" | awk 'NR == 1 {print $1}')"
  [[ "$RESOLVED_N8N_GIT_COMMIT" == "$N8N_GIT_COMMIT" ]]
fi

git -C "$PROJECT_ROOT" diff --check
echo "managed update validation passed"
