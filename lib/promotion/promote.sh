#!/usr/bin/env bash
# Promote workflow definitions into a service from a reviewed Git commit.
#
# The problem this solves: a service where definitions can be authored freely is
# a poor place to hold production credentials, and a service that holds them is a
# poor place to author freely. Splitting the two leaves a gap -- how a change
# crosses from one to the other without becoming a way to run arbitrary
# definitions against real credentials.
#
# This closes that gap by making the crossing deterministic and reviewable:
#   - the artefact is one commit, named by full SHA, not a moving branch tip
#   - that commit must already be merged into a protected branch, so whatever
#     review that branch requires has happened
#   - the target is backed up first and checked afterwards
#   - the run is recorded, so what is deployed can always be traced to a commit
#
# It is deliberately a host command. Anything that can be triggered from inside
# the service it promotes into is not a control.
#
# Exposed through each service's cli.sh rather than as a top-level corekit verb:
# the work is n8n-specific, so a generic verb would promise more than it does.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [[ -z "${COREKIT_PROMOTION_STATE_ROOT:-}" ]]; then
  : "${HOME:?Set HOME or COREKIT_PROMOTION_STATE_ROOT}"
fi
USER_STATE_HOME="${XDG_STATE_HOME:-${HOME:-}/.local/state}"
STATE_ROOT="${COREKIT_PROMOTION_STATE_ROOT:-$USER_STATE_HOME/ai-corekit/promotions}"
LOCK_FILE="${COREKIT_PROMOTION_LOCK_FILE:-$STATE_ROOT/promote.lock}"

COMMAND=""
SERVICE=""
PIN_COMMIT=""
PLAN_ONLY=false
DRY_RUN=false

log_event() {
  jq -cn \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg level "$1" --arg service "${SERVICE:-}" \
    --arg event "$2" --arg message "$3" \
    '{timestamp:$timestamp,level:$level,service:$service,event:$event,message:$message}'
}
die() { log_event error promotion_failed "$1" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Shared implementation behind a service's promote command. Invoked as:

  corekit run <service> promote [options]
  corekit run <service> status
  corekit run <service> rollback-plan

Import workflow definitions into a service from a commit that is already merged
into its protected branch.

Options:
  --commit <sha>    Promote this exact commit. Full 40-character SHA.
                    Defaults to the current tip of the protected branch.
  --plan            Show what would be promoted and exit. Changes nothing.
  --dry-run         Run the import in the tool's dry-run mode.
  --status          Show the last recorded promotion for the service.
  --rollback-plan   Print the recovery procedure for the service.
  -h, --help        Show this message.

Configuration lives in two places. Policy that is safe to publish goes in the
service's service.json under "promotion". Everything site-specific -- which
repository, which credential -- goes in the service's .env, which is not
tracked:

  PROMOTION_REPOSITORY   owner/repo holding the reviewed definitions
  PROMOTION_TOKEN        token with read access to that repository only
  PROMOTION_BRANCH       protected branch (overrides the policy default)
  PROMOTION_PATH         subdirectory within the repository to import

Give the token read access and nothing more. The protection that matters is the
branch protection on the repository, not the secrecy of this token: a token that
can only read cannot promote anything that has not been merged.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      [[ -n "${2:-}" ]] || die "--commit requires a value"
      [[ "$2" =~ ^[0-9a-fA-F]{40}$ ]] || die "--commit must be a full 40-character SHA, not a branch, tag or abbreviation"
      PIN_COMMIT="${2,,}"; shift 2 ;;
    --plan)          PLAN_ONLY=true; shift ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --status)        COMMAND=status; shift ;;
    --rollback-plan) COMMAND=rollback-plan; shift ;;
    -h|--help)       usage; exit 0 ;;
    -*)              die "Unknown option: $1" ;;
    *)               [[ -z "$SERVICE" ]] && SERVICE="$1" || die "Unexpected argument: $1"; shift ;;
  esac
done

[[ -n "$SERVICE" ]] || { usage; exit 1; }
command -v jq >/dev/null || die "jq is required"

find_service_dir() {
  local found
  found="$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -type d -name "$SERVICE" -print -quit 2>/dev/null || true)"
  [[ -n "$found" ]] || die "No such service: $SERVICE"
  printf '%s\n' "$found"
}

SERVICE_DIR="$(find_service_dir)"
POLICY_FILE="$SERVICE_DIR/service.json"
STATE_FILE="$STATE_ROOT/${SERVICE}.json"
mkdir -p "$STATE_ROOT"

[[ -f "$POLICY_FILE" ]] || die "No service.json for $SERVICE"
jq -e . "$POLICY_FILE" >/dev/null 2>&1 || die "service.json is not valid JSON"

policy() { jq -r --arg k "$1" '.promotion[$k] // empty' "$POLICY_FILE"; }

if [[ "$COMMAND" == "status" ]]; then
  [[ -f "$STATE_FILE" ]] || die "No promotion has been recorded for $SERVICE"
  jq '.' "$STATE_FILE"; exit 0
fi

if [[ "$COMMAND" == "rollback-plan" ]]; then
  jq -n --arg s "$SERVICE" --argjson state "$( [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo null )" '{
    service:$s, state:$state,
    recovery:{
      automatic_restore_permitted:false,
      procedure:[
        "Identify the previous commit from .previous.commit in the state above.",
        "Confirm whether the target has accepted writes since the promotion. If it may have, do not restore over it: preserve the current state and escalate.",
        "If writes are conclusively absent, re-run the promotion pinned to the previous commit: corekit run <service> promote --commit <previous>.",
        "If the definitions themselves are not the problem, restore the backup recorded at .backup_path instead.",
        "Re-run the post-promotion checks before treating the service as recovered."
      ]
    }}'
  exit 0
fi

[[ "$(policy enabled)" == "true" ]] || die "Promotion is not enabled for $SERVICE in service.json"

# Site-specific configuration comes from the service .env, which is not tracked.
[[ -f "$SERVICE_DIR/.env" ]] && { set -a; # shellcheck disable=SC1091
  . "$SERVICE_DIR/.env"; set +a; }

REPOSITORY="${PROMOTION_REPOSITORY:-}"
TOKEN="${PROMOTION_TOKEN:-}"
BRANCH="${PROMOTION_BRANCH:-$(policy protected_branch)}"
BRANCH="${BRANCH:-main}"
REPO_PATH="${PROMOTION_PATH:-$(policy repository_path)}"
CONTAINER="$(policy container)"; CONTAINER="${CONTAINER:-$SERVICE}"
PRESERVE_IDS="$(policy preserve_ids)"; PRESERVE_IDS="${PRESERVE_IDS:-true}"
BACKUP_REQUIRED="$(policy backup_required)"; BACKUP_REQUIRED="${BACKUP_REQUIRED:-true}"

[[ -n "$REPOSITORY" ]] || die "PROMOTION_REPOSITORY is not set in $SERVICE_DIR/.env"
[[ -n "$TOKEN" ]] || die "PROMOTION_TOKEN is not set in $SERVICE_DIR/.env"

docker inspect "$CONTAINER" >/dev/null 2>&1 || die "Container '$CONTAINER' does not exist"
[[ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER")" == "true" ]] \
  || die "Container '$CONTAINER' is not running"

# Resolve the target commit. Without --commit this is the current tip of the
# protected branch, which is still pinned for the rest of the run: the SHA is
# resolved once and everything downstream uses it.
resolve_branch_tip() {
  git ls-remote "https://${TOKEN}@github.com/${REPOSITORY}.git" "refs/heads/${BRANCH}" 2>/dev/null \
    | awk 'NR==1{print $1}'
}

TARGET_COMMIT="$PIN_COMMIT"
if [[ -z "$TARGET_COMMIT" ]]; then
  TARGET_COMMIT="$(resolve_branch_tip)"
  [[ -n "$TARGET_COMMIT" ]] || die "Could not resolve branch '$BRANCH' in the repository. Check the repository name, token and branch."
fi

PREVIOUS_COMMIT=""
[[ -f "$STATE_FILE" ]] && PREVIOUS_COMMIT="$(jq -r '.current.commit // empty' "$STATE_FILE")"

entity_counts() {
  # Best-effort inventory, used to show that a promotion did not lose anything.
  docker exec "$CONTAINER" sh -c 'n8n list:workflow 2>/dev/null | wc -l' 2>/dev/null | tr -d '\r' || echo "unknown"
}

if $PLAN_ONLY; then
  jq -n \
    --arg service "$SERVICE" --arg container "$CONTAINER" \
    --arg repository "$REPOSITORY" --arg branch "$BRANCH" \
    --arg path "${REPO_PATH:-<repository root>}" \
    --arg target "$TARGET_COMMIT" --arg previous "${PREVIOUS_COMMIT:-<none recorded>}" \
    --arg pinned "$( [[ -n "$PIN_COMMIT" ]] && echo explicit || echo "resolved from branch tip" )" \
    --arg counts "$(entity_counts)" \
    --argjson preserve "$( [[ "$PRESERVE_IDS" == "true" ]] && echo true || echo false )" \
    --argjson backup "$( [[ "$BACKUP_REQUIRED" == "true" ]] && echo true || echo false )" \
    '{plan:{service:$service,container:$container,repository:$repository,
      protected_branch:$branch,path:$path,target_commit:$target,commit_source:$pinned,
      previous_commit:$previous,preserve_ids:$preserve,backup_first:$backup,
      credentials:"never imported",
      gate:"target commit must be an ancestor of the protected branch",
      current_workflow_count:$counts}}'
  exit 0
fi

exec 9>"$LOCK_FILE"
flock --nonblock 9 || die "Another promotion is already running"

log_event info promotion_started "Promoting $SERVICE from commit ${TARGET_COMMIT:0:12} on $BRANCH"

BACKUP_PATH=""
if [[ "$BACKUP_REQUIRED" == "true" ]]; then
  BACKUP_DIR="$STATE_ROOT/backups/$SERVICE"
  mkdir -p "$BACKUP_DIR"
  BACKUP_PATH="$BACKUP_DIR/$(date -u +%Y%m%dT%H%M%SZ)-pre-promotion"
  mkdir -p "$BACKUP_PATH"
  log_event info backup_started "Exporting current definitions before importing"
  if docker exec "$CONTAINER" sh -c 'n8n export:workflow --all --separate --output=/tmp/.promotion-backup' >/dev/null 2>&1; then
    docker cp "$CONTAINER:/tmp/.promotion-backup/." "$BACKUP_PATH/" >/dev/null 2>&1 || true
    docker exec "$CONTAINER" sh -c 'rm -rf /tmp/.promotion-backup' >/dev/null 2>&1 || true
  fi
  if [[ -z "$(ls -A "$BACKUP_PATH" 2>/dev/null)" ]]; then
    die "Pre-promotion backup produced nothing. Refusing to import without a backup."
  fi
  chmod -R go-rwx "$BACKUP_PATH"
  log_event info backup_complete "Backed up to $BACKUP_PATH"
fi

# The import tool enforces the ancestry gate. Credentials are never imported:
# they are created once, by hand, on the target.
IMPORT_ARGS=(
  pull
  --repo "$REPOSITORY"
  --token "$TOKEN"
  --branch "$BRANCH"
  --commit "$TARGET_COMMIT"
  --require-merged-into "$BRANCH"
  --container "$CONTAINER"
  --workflows 2
  --credentials 0
  --environment 0
)
[[ -n "$REPO_PATH" ]] && IMPORT_ARGS+=(--github-path "$REPO_PATH")
[[ "$PRESERVE_IDS" == "true" ]] && IMPORT_ARGS+=(--preserve)
$DRY_RUN && IMPORT_ARGS+=(--dry-run)

command -v n8n-git >/dev/null 2>&1 || die "The import tool (n8n-git) is not on PATH on this host"

log_event info import_started "Importing definitions, credentials excluded"
if ! n8n-git "${IMPORT_ARGS[@]}"; then
  log_event error import_failed "Import failed. The target was not modified beyond any partial import; the pre-promotion backup is at $BACKUP_PATH"
  die "Promotion failed during import"
fi

if $DRY_RUN; then
  log_event info dry_run_complete "Dry run finished; nothing was changed"
  exit 0
fi

# Post-promotion checks. A promotion that leaves the service unhealthy is a
# failed promotion regardless of what the import reported.
health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER")"
if [[ "$health" != "healthy" && "$health" != "none" ]]; then
  log_event error health_failed "Container health is '$health' after import"
  die "Service is not healthy after promotion. Recover with: corekit run $SERVICE rollback-plan"
fi

tmp_state="$(mktemp "$STATE_ROOT/.${SERVICE}.XXXXXX")"
jq -n \
  --arg service "$SERVICE" --arg commit "$TARGET_COMMIT" --arg branch "$BRANCH" \
  --arg repository "$REPOSITORY" --arg path "${REPO_PATH:-}" \
  --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg backup "$BACKUP_PATH" \
  --arg counts "$(entity_counts)" \
  --argjson previous "$( [[ -n "$PREVIOUS_COMMIT" ]] && jq -n --arg c "$PREVIOUS_COMMIT" '{commit:$c}' || echo null )" \
  '{schema_version:1,service:$service,
    current:{commit:$commit,branch:$branch,repository:$repository,path:$path,
             promoted_at:$at,workflow_count:$counts,result:"success"},
    previous:$previous,backup_path:$backup}' >"$tmp_state"
chmod 0600 "$tmp_state"
mv "$tmp_state" "$STATE_FILE"

log_event info promotion_succeeded "Promoted ${TARGET_COMMIT:0:12} into $SERVICE"
