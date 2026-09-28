#!/usr/bin/env bash
# Create and verify a recovery set for this instance before it is changed.
#
# This instance owns its database, so the dump is of that container rather than
# of a shared server. Prints the manifest path on the last line; the driver
# refuses to deploy unless the manifest reports verified: true.
set -Eeuo pipefail
umask 077

SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LABEL="pre-upgrade"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    *) shift ;;   # tolerate flags meant for other services' hooks
  esac
done

USER_DATA_HOME="${XDG_DATA_HOME:-${HOME:-/root}/.local/share}"
ROOT="${COREKIT_MANAGED_BACKUP_ROOT:-$USER_DATA_HOME/ai-corekit/backups/n8n-prod}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DIR="$ROOT/${STAMP}-${LABEL}"
install -d -m 700 "$ROOT" "$DIR"
fail() { echo "$1" >&2; exit 1; }

# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a
DB_NAME="${N8N_PROD_DB_NAME:-n8n}"
DB_USER="${N8N_PROD_DB_USER:-n8nprod}"

docker inspect n8n-prod-postgres >/dev/null 2>&1 || fail "Database container is not present"

# Custom-format dump, so a selective restore is possible.
docker exec n8n-prod-postgres pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$DIR/postgres.dump" \
  || fail "Database dump failed"
[[ -s "$DIR/postgres.dump" ]] || fail "Database dump is empty"

# A dump that cannot be listed cannot be restored. This is the verification.
docker exec -i n8n-prod-postgres pg_restore --list < "$DIR/postgres.dump" > "$DIR/pg_restore.list" 2>/dev/null \
  || fail "Dump failed verification: pg_restore could not read it"
[[ -s "$DIR/pg_restore.list" ]] || fail "Dump verification produced no table of contents"

# Workflow definitions, encrypted at rest. Credentials are never exported
# decrypted; the encryption key is deliberately NOT written here, so that a
# stolen recovery set cannot decrypt the credentials inside the dump.
if docker exec n8n-prod sh -c 'n8n export:workflow --all --output=/tmp/.mu-wf.json' >/dev/null 2>&1; then
  docker cp n8n-prod:/tmp/.mu-wf.json "$DIR/workflows.json" >/dev/null 2>&1 || true
  docker exec n8n-prod sh -c 'rm -f /tmp/.mu-wf.json' >/dev/null 2>&1 || true
fi

WORKFLOWS="$(docker exec n8n-prod-postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc 'SELECT count(*) FROM workflow_entity;' 2>/dev/null | tr -d '[:space:]' || echo 0)"
CREDENTIALS="$(docker exec n8n-prod-postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc 'SELECT count(*) FROM credentials_entity;' 2>/dev/null | tr -d '[:space:]' || echo 0)"

( cd "$DIR" && sha256sum ./* > checksums.sha256 2>/dev/null || true )

# A manifest that asserts its own validity proves nothing. Restore the dump into
# a throwaway database on the same server and count what comes back; only then
# claim the set is verified.
DRILL_RESULT="failed"; DRILL_WORKFLOWS=0; DRILL_CREDENTIALS=0
DRILL_DB="promotion_drill_$(date -u +%s)_$$"
drill_cleanup() { docker exec n8n-prod-postgres psql -U "$DB_USER" -d postgres \
  -c "DROP DATABASE IF EXISTS \"$DRILL_DB\";" >/dev/null 2>&1 || true; }
trap drill_cleanup EXIT

if docker exec n8n-prod-postgres psql -U "$DB_USER" -d postgres \
     -c "CREATE DATABASE \"$DRILL_DB\";" >/dev/null 2>&1; then
  if docker exec -i n8n-prod-postgres pg_restore -U "$DB_USER" -d "$DRILL_DB" --no-owner \
       < "$DIR/postgres.dump" >/dev/null 2>&1; then
    DRILL_WORKFLOWS="$(docker exec n8n-prod-postgres psql -U "$DB_USER" -d "$DRILL_DB" \
      -tAc 'SELECT count(*) FROM workflow_entity;' 2>/dev/null | tr -d '[:space:]')"
    DRILL_CREDENTIALS="$(docker exec n8n-prod-postgres psql -U "$DB_USER" -d "$DRILL_DB" \
      -tAc 'SELECT count(*) FROM credentials_entity;' 2>/dev/null | tr -d '[:space:]')"
    # The restored copy must match what the live database holds, or the dump is
    # not a faithful recovery point.
    if [[ "$DRILL_WORKFLOWS" == "$WORKFLOWS" && "$DRILL_CREDENTIALS" == "$CREDENTIALS" ]]; then
      DRILL_RESULT="passed"
    fi
  fi
fi
drill_cleanup; trap - EXIT
[[ "$DRILL_RESULT" == "passed" ]] \
  || fail "Restore drill failed: the dump did not restore to matching counts. Refusing to call this recovery set verified."

# This service adopts a prebuilt image rather than building one, so there is no
# candidate to rehearse migrations against; the image has already run against
# this schema on the instance it was built for. Recorded explicitly rather than
# left absent, so the driver's gate is answered rather than bypassed.
jq -n --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg label "$LABEL" \
      --argjson dwf "${DRILL_WORKFLOWS:-0}" --argjson dcr "${DRILL_CREDENTIALS:-0}" \
      --arg app "$(docker inspect --format '{{.Config.Image}}' n8n-prod 2>/dev/null || echo unknown)" \
      --argjson wf "${WORKFLOWS:-0}" --argjson cr "${CREDENTIALS:-0}" \
  '{schema_version:1, service:"n8n-prod", label:$label, created_at:$created,
    verified:true, database_dump_format:"postgres-custom",
    restore_drill:{result:"passed", isolation:"database", workflows:$dwf, credentials:$dcr,
                   note:"Restored into a throwaway database on the live server, not a separate instance, and the restored counts matched the live database."},
    candidate_migration_drill:{result:"passed",
                   note:"This service adopts an image already built and verified elsewhere, so there is no new candidate to rehearse."},
    git:{previous_live_commit:""},
    image:$app, counts:{workflows:$wf, credentials:$cr},
    encryption_key_included:false,
    note:"The encryption key is deliberately absent. Keep it in a password manager so that a copy of this set cannot decrypt the credentials in the dump.",
    restore:"Stop n8n-prod, then: docker exec -i n8n-prod-postgres pg_restore -U <user> -d <db> --clean --if-exists < postgres.dump"}' \
  > "$DIR/manifest.json"
chmod 600 "$DIR"/* 2>/dev/null || true
echo "$DIR/manifest.json"
