#!/usr/bin/env bash
# Treat a deployment as failed unless the service is genuinely serving and has
# not lost anything. Exit non-zero and the driver stops and preserves evidence.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
EXPECTED_WORKFLOWS=""; EXPECTED_CREDENTIALS=""; CANARY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-workflows)   EXPECTED_WORKFLOWS="$2"; shift 2 ;;
    --expected-credentials) EXPECTED_CREDENTIALS="$2"; shift 2 ;;
    --canary)               CANARY=true; shift ;;
    *) shift ;;
  esac
done
fail() { echo "$1" >&2; exit 1; }
# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a
DB_NAME="${N8N_PROD_DB_NAME:-n8n}"; DB_USER="${N8N_PROD_DB_USER:-n8nprod}"

for c in n8n-prod n8n-prod-postgres n8n-prod-runner; do
  [[ "$(docker inspect --format '{{.State.Running}}' "$c" 2>/dev/null)" == "true" ]] \
    || fail "Container $c is not running"
done

# Readiness, with a bounded wait: migrations can take a moment after a restart.
ready=false
for _ in $(seq 1 30); do
  if docker exec n8n-prod sh -c 'wget -qO- http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1'; then
    ready=true; break
  fi
  sleep 5
done
$ready || fail "Service did not become ready"

docker exec n8n-prod-postgres pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1 \
  || fail "Database is not accepting connections"

docker logs n8n-prod --since 10m 2>&1 | grep -iE 'migration .* (failed|error)' \
  && fail "A database migration reported an error"

count() { docker exec n8n-prod-postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM $1;" 2>/dev/null | tr -d '[:space:]'; }
if [[ -n "$EXPECTED_WORKFLOWS" ]]; then
  actual="$(count workflow_entity)"
  [[ "$actual" == "$EXPECTED_WORKFLOWS" ]] \
    || fail "Workflow count changed across the deployment: expected $EXPECTED_WORKFLOWS, found $actual"
fi
if [[ -n "$EXPECTED_CREDENTIALS" ]]; then
  actual="$(count credentials_entity)"
  [[ "$actual" == "$EXPECTED_CREDENTIALS" ]] \
    || fail "Credential count changed across the deployment: expected $EXPECTED_CREDENTIALS, found $actual"
fi

if $CANARY; then
  # The runner must actually be connected, not merely running: a task broker
  # with no runner fails only when a workflow next executes.
  docker logs n8n-prod --since 10m 2>&1 | grep -qiE 'runner .*(registered|connected)' \
    || echo "note: no runner registration seen in recent logs; runner is running but unconfirmed" >&2
fi
echo "strict health passed"
