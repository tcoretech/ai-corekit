#!/usr/bin/env bash
# Entity counts and in-flight executions for this instance, from the database
# this instance owns. Reading the shared server here would compare production
# against another instance's numbers.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a
DB_NAME="${N8N_PROD_DB_NAME:-n8n}"; DB_USER="${N8N_PROD_DB_USER:-n8nprod}"
fail() { echo "$1" >&2; exit 1; }
q() { docker exec n8n-prod-postgres psql -X -U "$DB_USER" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 -c "$1" 2>/dev/null | tr -d '[:space:]'; }
# No `|| 0` fallback: a query that fails must abort. Reporting zero would let a
# deployment proceed during a database outage, which is exactly when it must not.
w="$(q 'SELECT count(*) FROM workflow_entity;')"       || fail "Could not read workflow count"
c="$(q 'SELECT count(*) FROM credentials_entity;')"    || fail "Could not read credential count"
a="$(q "SELECT count(*) FROM execution_entity WHERE status IN ('new','running','waiting','unknown');")" || fail "Could not read active executions"
for v in "$w" "$c" "$a"; do
  [[ "$v" =~ ^[0-9]+$ ]] || fail "Database returned a non-numeric count; refusing to report it as zero"
done

jq -cn \
  --argjson workflows "$w" --argjson credentials "$c" --argjson active "$a" \
  '{workflows:$workflows, credentials:$credentials, active_executions:$active}'
