#!/usr/bin/env bash
# Entity counts and in-flight executions for this instance.
#
# This instance's data lives in the shared Postgres server, so the counts come
# from there. A service with its own database reports from its own.
set -Eeuo pipefail
fail() { echo "$1" >&2; exit 1; }
q() { docker exec postgres psql -X -U postgres -d postgres -At -v ON_ERROR_STOP=1 -c "$1" 2>/dev/null | tr -d '[:space:]'; }
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
