#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

EXPECTED_WORKFLOWS=""
EXPECTED_CREDENTIALS=""
RUN_CANARY=false
TIMEOUT_SECONDS=420
if [[ -z "${COREKIT_MANAGED_STATE_ROOT:-}" ]]; then
  : "${HOME:?Set HOME or COREKIT_MANAGED_STATE_ROOT}"
fi
USER_STATE_HOME="${XDG_STATE_HOME:-${HOME:-}/.local/state}"
STATE_ROOT="${COREKIT_MANAGED_STATE_ROOT:-$USER_STATE_HOME/ai-corekit/managed-updates}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

fail() {
  log_event error health_failed "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-workflows)
      EXPECTED_WORKFLOWS="$2"
      shift 2
      ;;
    --expected-credentials)
      EXPECTED_CREDENTIALS="$2"
      shift 2
      ;;
    --canary)
      RUN_CANARY=true
      shift
      ;;
    --timeout)
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    *)
      fail "Unknown health-check option: $1"
      ;;
  esac
done

for command_name in curl docker jq; do
  command -v "$command_name" >/dev/null 2>&1 || fail "Required command is missing: $command_name"
done

deadline=$((SECONDS + TIMEOUT_SECONDS))
while (( SECONDS < deadline )); do
  n8n_running="$(docker inspect --format '{{.State.Running}}' n8n 2>/dev/null || true)"
  n8n_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' n8n 2>/dev/null || true)"
  runner_running="$(docker inspect --format '{{.State.Running}}' n8n-runner 2>/dev/null || true)"
  runner_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' n8n-runner 2>/dev/null || true)"
  if [[ "$n8n_running" == "true" && "$n8n_health" == "healthy" && "$runner_running" == "true" && "$runner_health" == "healthy" ]]; then
    break
  fi
  sleep 5
done

[[ "$(docker inspect --format '{{.State.Running}}' n8n 2>/dev/null || true)" == "true" ]] || fail "n8n is not running"
[[ "$(docker inspect --format '{{.State.Health.Status}}' n8n 2>/dev/null || true)" == "healthy" ]] || fail "n8n did not become healthy"
[[ "$(docker inspect --format '{{.State.Running}}' n8n-runner 2>/dev/null || true)" == "true" ]] || fail "n8n runner is not running"
[[ "$(docker inspect --format '{{.State.Health.Status}}' n8n-runner 2>/dev/null || true)" == "healthy" ]] || fail "n8n runner did not become healthy"

curl -fsS --max-time 10 http://127.0.0.1:5678/healthz >/dev/null || fail "/healthz failed"
curl -fsS --max-time 10 http://127.0.0.1:5678/healthz/readiness >/dev/null || fail "/healthz/readiness failed"
docker exec postgres pg_isready -U postgres -d postgres >/dev/null || fail "PostgreSQL readiness failed"
docker exec n8n wget -q -O /dev/null http://n8n-runner:5680/healthz || fail "Runner health endpoint is unreachable from n8n"

N8N_VERSION="$(docker exec n8n n8n --version | tr -d '\r')"
RUNNER_VERSION="$(docker inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' n8n-runner 2>/dev/null || true)"
RUNNER_UPSTREAM_VERSION="$(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' n8n-runner 2>/dev/null || true)"
[[ -n "$N8N_VERSION" && "$N8N_VERSION" == "$RUNNER_VERSION" && "$N8N_VERSION" == "$RUNNER_UPSTREAM_VERSION" ]] \
  || fail "n8n and runner versions do not match"

STARTED_AT="$(docker inspect --format '{{.State.StartedAt}}' n8n)"
N8N_STARTUP_LOGS="$(docker logs --since "$STARTED_AT" n8n 2>&1)"
RUNNER_STARTUP_LOGS="$(docker logs --since "$STARTED_AT" n8n-runner 2>&1)"
grep -F 'Registered runner "launcher-javascript"' <<<"$N8N_STARTUP_LOGS" >/dev/null \
  || fail "JavaScript runner did not register with the n8n broker"
grep -F 'Registered runner "launcher-python"' <<<"$N8N_STARTUP_LOGS" >/dev/null \
  || fail "Python runner did not register with the n8n broker"

if docker ps --filter label=com.docker.compose.service=n8n-worker --format '{{.Names}}' | grep -q .; then
  fail "Queue workers are still running in the standard-mode topology"
fi

if grep -Ei 'migrations?[[:space:]:-]+(failed|failure|fatal|error)([[:space:]:.!]|$)|(failed|fatal|error)([[:space:]:-]+(to[[:space:]]+)?)?(run[[:space:]]+)?migrations?([[:space:]:.!]|$)' \
  <<<"$N8N_STARTUP_LOGS" >/dev/null; then
  fail "Migration errors were detected in n8n startup logs"
fi
if grep -Ei '(authentication|broker|connection).{0,80}(failed|fatal|error|refused)' \
  <<<"$RUNNER_STARTUP_LOGS" >/dev/null; then
  fail "Runner broker/authentication errors were detected"
fi

WORKFLOW_COUNT="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;')"
CREDENTIAL_COUNT="$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM credentials_entity;')"
if [[ -n "$EXPECTED_WORKFLOWS" && "$WORKFLOW_COUNT" != "$EXPECTED_WORKFLOWS" ]]; then
  fail "Workflow count changed unexpectedly"
fi
if [[ -n "$EXPECTED_CREDENTIALS" && "$CREDENTIAL_COUNT" != "$EXPECTED_CREDENTIALS" ]]; then
  fail "Credential count changed unexpectedly"
fi

if [[ "$RUN_CANARY" == "true" ]]; then
  CANARY_FILE="$SCRIPT_DIR/canary.json"
  jq -e '.active == false and ([.nodes[].type] | sort) == ["n8n-nodes-base.manualTrigger","n8n-nodes-base.set"]' \
    "$CANARY_FILE" >/dev/null || fail "Committed canary definition is missing or unsafe"
  install -d -m 0700 "$STATE_ROOT"
  chmod 0700 "$STATE_ROOT"
  CANARY_OUTPUT="$(mktemp "$STATE_ROOT/.canary.XXXXXX")"
  PROJECT_NAME="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' n8n 2>/dev/null || true)"
  [[ -n "$PROJECT_NAME" ]] || PROJECT_NAME=localai
  if ! docker compose -p "$PROJECT_NAME" --project-directory "$SERVICE_DIR" \
    --env-file "$SERVICE_DIR/../../data-services/postgres/.env" \
    --env-file "$SERVICE_DIR/.env" -f "$SERVICE_DIR/docker-compose.yml" \
    run --rm --no-deps -T -e N8N_RUNNERS_ENABLED=false \
    -v "$CANARY_FILE:/tmp/corekit-managed-canary.json:ro" n8n \
    execute --file=/tmp/corekit-managed-canary.json >"$CANARY_OUTPUT" 2>&1; then
    rm -f "$CANARY_OUTPUT"
    fail "Safe manual canary execution failed"
  fi
  rm -f "$CANARY_OUTPUT"
  [[ "$(docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM workflow_entity;')" == "$WORKFLOW_COUNT" ]] \
    || fail "Canary unexpectedly changed the workflow count"
  log_event info canary_passed "Safe inactive manual workflow executed successfully"
fi

install -d -m 0700 "$STATE_ROOT"
chmod 0700 "$STATE_ROOT"
AUDIT_RAW="$(mktemp "$STATE_ROOT/.audit.XXXXXX")"
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
  })' >"$STATE_ROOT/n8n-security-audit.redacted.json"
chmod 0600 "$STATE_ROOT/n8n-security-audit.redacted.json"
rm -f "$AUDIT_RAW"

log_event info health_passed "n8n readiness, runner, database, migrations, counts, and audit checks passed"
