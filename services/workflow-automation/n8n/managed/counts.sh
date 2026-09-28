#!/usr/bin/env bash
# Entity counts and in-flight executions for this instance.
#
# This instance's data lives in the shared Postgres server, so the counts come
# from there. A service with its own database reports from its own.
set -Eeuo pipefail
q() { docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c "$1" 2>/dev/null | tr -d '[:space:]'; }
jq -cn \
  --argjson workflows   "$(q 'SELECT count(*) FROM workflow_entity;'   || echo 0)" \
  --argjson credentials "$(q 'SELECT count(*) FROM credentials_entity;' || echo 0)" \
  --argjson active      "$(q "SELECT count(*) FROM execution_entity WHERE status IN ('new','running','waiting','unknown');" || echo 0)" \
  '{workflows:$workflows, credentials:$credentials, active_executions:$active}'
