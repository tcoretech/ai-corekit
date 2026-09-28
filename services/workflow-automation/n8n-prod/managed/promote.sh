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
# Lives with the service rather than in lib/, because the work is n8n-specific:
# a generic verb, or a shared library, would promise more than it delivers.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
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
# Read only the promotion settings. Sourcing the whole file with `set -a` would
# export the encryption key and database password into every child process,
# including the import tool and each docker exec it runs.
if [[ -f "$SERVICE_DIR/.env" ]]; then
  while IFS='=' read -r _key _value; do
    case "$_key" in
      PROMOTION_REPOSITORY|PROMOTION_REPOSITORY_HOST|PROMOTION_TOKEN|PROMOTION_BRANCH|PROMOTION_PATH)
        _value="${_value%\'}"; _value="${_value#\'}"
        _value="${_value%\"}"; _value="${_value#\"}"
        printf -v "$_key" '%s' "$_value" ;;
    esac
  done < <(grep -E "^PROMOTION_[A-Z_]+=" "$SERVICE_DIR/.env" 2>/dev/null || true)
fi

REPOSITORY="${PROMOTION_REPOSITORY:-}"
REPOSITORY_HOST="${PROMOTION_REPOSITORY_HOST:-github.com}"

# Accept a bare owner/repo, a full URL, or a local path. Assuming one forge
# would rule out a self-hosted Git, which is a perfectly ordinary place to keep
# reviewed definitions.
repository_url() {
  case "$REPOSITORY" in
    *://*|/*) printf '%s\n' "$REPOSITORY" ;;
    *)        printf 'https://%s/%s.git\n' "$REPOSITORY_HOST" "$REPOSITORY" ;;
  esac
}
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

# Hand the import tool a container ID, not a name. It resolves names with
# `docker ps --filter name=`, which is a substring match, so a name like
# "svc" also matches "svc-runner" and "svc-tunnel" and it takes whichever
# Docker lists first. On a stack whose containers share a prefix that can send
# the import at a sidecar -- a distroless one has no shell, and the import dies
# confusingly. An ID matches exactly.
CONTAINER_ID="$(docker inspect --format '{{.Id}}' "$CONTAINER")"
[[ -n "$CONTAINER_ID" ]] || die "Could not resolve the container ID for '$CONTAINER'"

# Resolve the target commit. Without --commit this is the current tip of the
# protected branch, which is still pinned for the rest of the run: the SHA is
# resolved once and everything downstream uses it.
resolve_branch_tip() {
  local dir askpass out
  dir="$(mktemp -d -t promote-tip-XXXXXXXX)" || return 1
  askpass="$dir/.askpass"
  printf '%s' "$TOKEN" > "$dir/.token"; chmod 600 "$dir/.token"
  printf '#!/bin/sh\ncase "$1" in Username*) printf %%s "x-access-token";; *) cat "%s";; esac\n' \
    "$dir/.token" > "$askpass"; chmod 700 "$askpass"
  out="$(GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
        git ls-remote "$(repository_url)" "refs/heads/${BRANCH}" 2>/dev/null \
        | awk 'NR==1{print $1}')" || true
  rm -rf "$dir"
  printf '%s\n' "$out"
}

TARGET_COMMIT="$PIN_COMMIT"
if [[ -z "$TARGET_COMMIT" ]]; then
  # `|| true` matters: resolve_branch_tip pipes under `pipefail`, so without it
  # a bad token or unreachable remote fails the assignment and `set -e` exits
  # with no message -- exactly when the operator needs one.
  TARGET_COMMIT="$(resolve_branch_tip)" || true
  [[ -n "$TARGET_COMMIT" ]] \
    || die "Could not resolve branch '$BRANCH' in '$REPOSITORY'. Check the repository name, the token, and that the branch exists."
fi

PREVIOUS_COMMIT=""
[[ -f "$STATE_FILE" ]] && PREVIOUS_COMMIT="$(jq -r '.current.commit // empty' "$STATE_FILE")"

workflow_count() {
  # The service's counts hook queries the database directly. Counting lines from
  # the n8n CLI is unreliable: it prints status lines such as "Acquiring database
  # migration lock..." that are not workflows.
  if [[ -x "$SERVICE_DIR/managed/counts.sh" ]]; then
    COREKIT_SERVICE_DIR="$SERVICE_DIR" bash "$SERVICE_DIR/managed/counts.sh" 2>/dev/null \
      | jq -r '.workflows // "unknown"' 2>/dev/null || echo unknown
  else
    echo unknown
  fi
}

if $PLAN_ONLY; then
  jq -n \
    --arg service "$SERVICE" --arg container "$CONTAINER" \
    --arg repository "$REPOSITORY" --arg branch "$BRANCH" \
    --arg path "${REPO_PATH:-<repository root>}" \
    --arg target "$TARGET_COMMIT" --arg previous "${PREVIOUS_COMMIT:-<none recorded>}" \
    --arg pinned "$( [[ -n "$PIN_COMMIT" ]] && echo explicit || echo "resolved from branch tip" )" \
    --arg counts "$(workflow_count)" \
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

log_event info ancestry_check_started "Verifying ${TARGET_COMMIT:0:12} is merged into '$BRANCH'"
SCRATCH="$(mktemp -d -t promote-verify-XXXXXXXX)"
# One cleanup for both temporary directories: the checkout and, separately, the
# credential helper. CREDS_DIR is created further down; the guards make this safe
# to run before it exists.
cleanup_temp() {
  [[ -n "${SCRATCH:-}"   && -d "${SCRATCH:-}"   ]] && rm -rf "$SCRATCH"
  [[ -n "${CREDS_DIR:-}" && -d "${CREDS_DIR:-}" ]] && rm -rf "$CREDS_DIR"
  return 0
}
trap cleanup_temp EXIT

git -C "$SCRATCH" init --quiet 2>/dev/null || die "Could not prepare a verification clone"
git -C "$SCRATCH" remote add origin "$(repository_url)" 2>/dev/null || true

# Credentials go via a helper, never on the command line where /proc exposes
# them -- and never inside $SCRATCH, whose working tree is later handed to the
# import tool. Keeping them in a separate directory also avoids a checkout
# failing because the promoted commit happens to contain a file of that name.
CREDS_DIR="$(mktemp -d -t promote-creds-XXXXXXXX)"
ASKPASS="$CREDS_DIR/askpass"
printf '%s' "$TOKEN" > "$CREDS_DIR/token"
printf '#!/bin/sh\ncase "$1" in Username*) printf %%s "x-access-token";; *) cat "%s";; esac\n' \
  "$CREDS_DIR/token" > "$ASKPASS"
chmod 700 "$ASKPASS"; chmod 600 "$CREDS_DIR/token"
export GIT_ASKPASS="$ASKPASS" GIT_TERMINAL_PROMPT=0

git -C "$SCRATCH" fetch --quiet --filter=blob:none --no-tags origin \
    "refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" \
  || die "Could not fetch branch '$BRANCH'. Check the repository, token and branch name."

if ! git -C "$SCRATCH" cat-file -e "${TARGET_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$SCRATCH" fetch --quiet --filter=blob:none --no-tags origin "$TARGET_COMMIT" 2>/dev/null || true
fi
git -C "$SCRATCH" cat-file -e "${TARGET_COMMIT}^{commit}" 2>/dev/null \
  || die "Commit ${TARGET_COMMIT:0:12} does not exist in $REPOSITORY"

git -C "$SCRATCH" merge-base --is-ancestor "$TARGET_COMMIT" "refs/remotes/origin/${BRANCH}" \
  || die "Refusing to promote: ${TARGET_COMMIT:0:12} is not merged into '$BRANCH'. Only reviewed, merged commits may be promoted."
log_event info ancestry_check_passed "${TARGET_COMMIT:0:12} is an ancestor of '$BRANCH'"

git -C "$SCRATCH" checkout --quiet --detach "$TARGET_COMMIT" \
  || die "Could not check out the verified commit"


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
    # A fresh target legitimately has nothing to export, and that is exactly
    # when the first promotion happens. Only treat an empty export as a failure
    # when the target actually holds workflows to lose.
    existing="$(workflow_count)"
    # A target that reports zero is genuinely new, which is exactly when the
    # first promotion happens. A target whose count cannot be read is the
    # opposite case: that is when a backup matters most, so it is a hard stop.
    if [[ "$existing" == "unknown" ]]; then
      die "Pre-promotion backup produced nothing and the target's workflow count could not be read. Refusing to import without a backup."
    fi
    if [[ "$existing" != "0" ]]; then
      die "Pre-promotion backup produced nothing although the target holds $existing workflow(s). Refusing to import without a backup."
    fi
    log_event warning backup_empty "Target holds no workflows; proceeding with an empty recovery set"
    printf 'no workflows present at %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$BACKUP_PATH/EMPTY"
  fi
  chmod -R go-rwx "$BACKUP_PATH"
  log_event info backup_complete "Backed up to $BACKUP_PATH"
fi

# Credentials are never imported: they are created once, by hand, on the target.
#
# The import tool takes a branch, not a commit. So rather than trusting it with
# the gate, we verify ancestry here and then hand it a ref we control: the commit
# is fetched into a scratch clone, checked to be an ancestor of the protected
# branch, and pushed nowhere. The tool is pointed at that local clone, so what it
# imports is the commit we verified rather than whatever the branch points at by
# the time it runs.
# Local mode: the tool imports from a directory rather than fetching a branch
# itself. That directory is the commit we verified above, so what is imported is
# exactly what was reviewed. It also means the token is never handed to the
# import tool at all.
IMPORT_SOURCE="$SCRATCH"
[[ -n "$REPO_PATH" ]] && IMPORT_SOURCE="$SCRATCH/${REPO_PATH#/}"
[[ -d "$IMPORT_SOURCE" ]] \
  || die "Path '${REPO_PATH:-/}' does not exist in commit ${TARGET_COMMIT:0:12}"

IMPORT_ARGS=(
  pull
  --container "$CONTAINER_ID"
  --workflows 1
  --local-path "$IMPORT_SOURCE"
  --credentials 0
  --environment 0
)
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

# The import tool can report success having changed nothing -- a malformed
# definition is rejected by the application after the tool has copied the file.
# A promotion that imported nothing is a failed promotion, so verify against the
# target rather than trusting the tool's summary.
verify_imported() {
  local missing=0 total=0 id name listing
  # Captured once. If this fails, say so: reporting every definition missing
  # would accuse a promotion that actually landed.
  # Assumes `n8n list:workflow` prints workflow ids. If a future version prints
  # names only, every promotion will fail here after a successful import --
  # that is the symptom to recognise.
  if ! listing="$(docker exec "$CONTAINER_ID" sh -c "n8n list:workflow" 2>/dev/null)"; then
    log_event error listing_unavailable "Could not list workflows in the target, so the import could not be verified either way"
    return 1
  fi

  while IFS= read -r file; do
    # Only files that are actually workflow definitions: a definition has both
    # an id and a name. Without this, package.json and friends are counted as
    # definitions and a good promotion is failed for not finding them.
    id="$(jq -r 'if type == "array" then .[0].id else .id end // empty' "$file" 2>/dev/null || true)"
    name="$(jq -r 'if type == "array" then .[0].name else .name end // empty' "$file" 2>/dev/null || true)"
    [[ -n "$id" && -n "$name" ]] || continue
    total=$((total + 1))
    # Match on id, which --preserve keeps, rather than on name: a substring name
    # match would accept an unrelated pre-existing workflow.
    if ! grep -qF -- "$id" <<<"$listing"; then
      log_event error import_unverified "Definition '$name' ($id) is not present in the target after import"
      missing=$((missing + 1))
    fi
  done < <(find "$IMPORT_SOURCE" -maxdepth 3 -name '*.json' -type f 2>/dev/null)

  # Verifying nothing is not success. If the path held no definitions, the
  # promotion did nothing and should say so rather than report a clean run.
  if (( total == 0 )); then
    log_event error nothing_to_verify "No workflow definitions found at '${REPO_PATH:-/}' in commit ${TARGET_COMMIT:0:12}"
    return 1
  fi
  (( missing == 0 )) || return 1
  log_event info import_verified "All $total definition(s) are present in the target"
}

if ! verify_imported; then
  log_event error promotion_unverified "The import reported success but the target does not contain the definitions. The pre-promotion backup is at $BACKUP_PATH"
  die "Promotion could not be verified against the target"
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
  --arg counts "$(workflow_count)" \
  --argjson previous "$( [[ -n "$PREVIOUS_COMMIT" ]] && jq -n --arg c "$PREVIOUS_COMMIT" '{commit:$c}' || echo null )" \
  '{schema_version:1,service:$service,
    current:{commit:$commit,branch:$branch,repository:$repository,path:$path,
             promoted_at:$at,workflow_count:$counts,result:"success"},
    previous:$previous,backup_path:$backup}' >"$tmp_state"
chmod 0600 "$tmp_state"
mv "$tmp_state" "$STATE_FILE"

log_event info promotion_succeeded "Promoted ${TARGET_COMMIT:0:12} into $SERVICE"
