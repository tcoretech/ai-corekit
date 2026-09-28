#!/usr/bin/env bash
# Entity counts and in-flight executions for this instance, from the database
# this instance owns. Reading the shared server here would compare production
# against another instance's numbers.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a
DB_NAME="${N8N_PROD_DB_NAME:-n8n}"; DB_USER="${N8N_PROD_DB_USER:-n8nprod}"
q() { docker exec n8n-prod-postgres psql -X -U "$DB_USER" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 -c "$1" 2>/dev/null | tr -d '[:space:]'; }
jq -cn \
  --argjson workflows   "$(q 'SELECT count(*) FROM workflow_entity;'   || echo 0)" \
  --argjson credentials "$(q 'SELECT count(*) FROM credentials_entity;' || echo 0)" \
  --argjson active      "$(q "SELECT count(*) FROM execution_entity WHERE status IN ('new','running','waiting','unknown');" || echo 0)" \
  '{workflows:$workflows, credentials:$credentials, active_executions:$active}'
