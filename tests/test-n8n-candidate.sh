#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
N8N_DIR="$PROJECT_ROOT/services/workflow-automation/n8n"
CANARY_FILE="$N8N_DIR/managed/canary.json"
N8N_VERSION="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/n8n:/ {value=$2; sub(/^n8nio\/n8n:/,"",value); sub(/@.*/,"",value); print value; exit}' "$N8N_DIR/Dockerfile")"
N8N_GIT_VERSION="$(awk -F= '$1 == "ARG N8N_GIT_VERSION" {print $2}' "$N8N_DIR/Dockerfile")"
N8N_GIT_VERSION_PLAIN="${N8N_GIT_VERSION#v}"
N8N_TEST_IMAGE="${N8N_TEST_IMAGE:-corekit/n8n:${N8N_VERSION}-ci}"
N8N_TEST_RUNNER_IMAGE="${N8N_TEST_RUNNER_IMAGE:-corekit/n8n-runners:${N8N_VERSION}-ci}"
PROJECT_NAME="corekit-n8n-smoke-$$"
COMPOSE_FILE="$PROJECT_ROOT/tests/fixtures/n8n-smoke-compose.yml"

cleanup() {
  PROJECT_ROOT="$PROJECT_ROOT" N8N_TEST_IMAGE="$N8N_TEST_IMAGE" N8N_TEST_RUNNER_IMAGE="$N8N_TEST_RUNNER_IMAGE" \
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" down --volumes --timeout 10 >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ "${1:-}" != "--skip-build" ]]; then
  docker build --pull=false --tag "$N8N_TEST_IMAGE" "$N8N_DIR"
  docker build --pull=false --tag "$N8N_TEST_RUNNER_IMAGE" "$N8N_DIR/runner"
fi

[[ "$(docker run --rm --network none "$N8N_TEST_IMAGE" n8n --version | tr -d '\r')" == "$N8N_VERSION" ]]
[[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' "$N8N_TEST_RUNNER_IMAGE")" == "$N8N_VERSION" ]]
[[ "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$N8N_TEST_RUNNER_IMAGE")" == "$N8N_VERSION" ]]
[[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.n8n-git.version"}}' "$N8N_TEST_IMAGE")" == "$N8N_GIT_VERSION" ]]
N8N_GIT_OUTPUT="$(docker run --rm --network none --entrypoint /usr/local/bin/n8n-git "$N8N_TEST_IMAGE" --version 2>&1)"
grep -Fx "n8n-git version $N8N_GIT_VERSION_PLAIN" <<<"$N8N_GIT_OUTPUT" >/dev/null

export PROJECT_ROOT N8N_TEST_IMAGE N8N_TEST_RUNNER_IMAGE
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" up -d --wait --wait-timeout 360
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" cp \
  "$CANARY_FILE" n8n:/tmp/canary.json >/dev/null
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" exec -T n8n \
  n8n import:workflow --input=/tmp/canary.json >/dev/null
N8N_GIT_COMPAT_OUTPUT="$(mktemp /tmp/corekit-n8n-git-compat.XXXXXX)"
if ! docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" exec -T n8n \
  n8n-git push --dry-run --defaults --workflows 1 --credentials 0 --environment 0 \
    --local-path /tmp/corekit-n8n-git-compat >"$N8N_GIT_COMPAT_OUTPUT" 2>&1; then
  sed -E 's/(token|password|key)([=:])[A-Za-z0-9._-]+/\1\2<redacted>/Ig' "$N8N_GIT_COMPAT_OUTPUT" >&2
  rm -f "$N8N_GIT_COMPAT_OUTPUT"
  exit 1
fi
rm -f "$N8N_GIT_COMPAT_OUTPUT"
CANARY_OUTPUT="$(mktemp /tmp/corekit-n8n-canary.XXXXXX)"
if ! docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" run --rm --no-deps -T \
  -e N8N_RUNNERS_ENABLED=false -v "$CANARY_FILE:/tmp/corekit-managed-canary.json:ro" n8n \
  execute --file=/tmp/corekit-managed-canary.json >"$CANARY_OUTPUT" 2>&1; then
  sed -E 's/(token|password|key)([=:])[A-Za-z0-9._-]+/\1\2<redacted>/Ig' "$CANARY_OUTPUT" >&2
  rm -f "$CANARY_OUTPUT"
  exit 1
fi
rm -f "$CANARY_OUTPUT"
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" exec -T postgres \
  psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;' \
  | grep -qx 1
N8N_LOGS="$(docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" logs n8n 2>&1)"
grep -F 'Registered runner "launcher-javascript"' <<<"$N8N_LOGS" >/dev/null
grep -F 'Registered runner "launcher-python"' <<<"$N8N_LOGS" >/dev/null

MIGRATION_MATCHES="$(grep -Ei 'migrations?[[:space:]:-]+(failed|failure|fatal|error)([[:space:]:.!]|$)|(failed|fatal|error)([[:space:]:-]+(to[[:space:]]+)?)?(run[[:space:]]+)?migrations?([[:space:]:.!]|$)' \
  <<<"$N8N_LOGS" || true)"
if [[ -n "$MIGRATION_MATCHES" ]]; then
  echo "migration error detected in isolated candidate" >&2
  printf '%s\n' "$MIGRATION_MATCHES" | sed -E 's/(token|password|key)([=:])[A-Za-z0-9._-]+/\1\2<redacted>/Ig' >&2
  exit 1
fi

echo "isolated n8n candidate smoke test passed"
