#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [[ -z "${COREKIT_MANAGED_STATE_ROOT:-}" || -z "${COREKIT_N8N_BACKUP_ROOT:-}" ]]; then
  : "${HOME:?Set HOME or both managed-update root variables}"
fi
USER_STATE_HOME="${XDG_STATE_HOME:-${HOME:-}/.local/state}"
USER_DATA_HOME="${XDG_DATA_HOME:-${HOME:-}/.local/share}"
STATE_ROOT="${COREKIT_MANAGED_STATE_ROOT:-$USER_STATE_HOME/ai-corekit/managed-updates}"
LOCK_FILE="${COREKIT_MANAGED_LOCK_FILE:-$STATE_ROOT/managed-update.lock}"
COMMAND="${1:-help}"
SERVICE="${2:-n8n}"

# Resolved once the service name is known; see below.
SERVICE_DIR=""
POLICY_FILE=""
STATE_FILE=""
BACKUP_ROOT=""

shift || true
shift || true

OFFLINE=false
DRY_RUN=false
SECURITY_OVERRIDE=false
LOCAL_COMMIT=false
MANUAL_MAJOR=false
PREVIOUS_GIT_COMMIT=""

log_event() {
  local level="$1"
  local event="$2"
  local message="$3"
  jq -cn \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg level "$level" \
    --arg service "$SERVICE" \
    --arg event "$event" \
    --arg message "$message" \
    '{timestamp:$timestamp,level:$level,service:$service,event:$event,message:$message}'
}

die() {
  log_event error managed_update_failed "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: corekit managed-update <command> [service] [options]

Commands:
  check [service]          Compare the local deployment commit with the remote without mutating Git
  plan [service]           Validate policy and show the committed candidate deployment plan
  apply [service]          Fast-forward the deployment branch and apply an eligible committed candidate
  status [service]         Show redacted runtime state and live versions
  rollback-plan [service]  Show guarded recovery information; never restores a stateful DB automatically
  list                     List every service registered for managed updates

Options:
  --offline                Do not contact the Git remote
  --dry-run                Plan only; never build, back up, or deploy
  --security-override      Manually bypass release age for a verified security update
  --manual-major           Manually approve a major update (all other gates still apply)
  --local-commit           Deploy the current clean committed feature branch (manual bootstrap only)
  --previous-git-commit X  Record the known previous live configuration commit in the recovery set
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline)
      OFFLINE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --security-override)
      SECURITY_OVERRIDE=true
      shift
      ;;
    --local-commit)
      LOCAL_COMMIT=true
      shift
      ;;
    --manual-major)
      MANUAL_MAJOR=true
      shift
      ;;
    --previous-git-commit)
      PREVIOUS_GIT_COMMIT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown managed-update option: $1"
      ;;
  esac
done

for command_name in docker flock git jq; do
  command -v "$command_name" >/dev/null 2>&1 || die "Required command is missing: $command_name"
done

if [[ "$COMMAND" == "apply" && "$DRY_RUN" != "true" ]]; then
  install -d -m 0700 "$STATE_ROOT"
  chmod 0700 "$STATE_ROOT"
  exec 9>"$LOCK_FILE"
  flock -n 9 || die "Another managed updater process is already running"
elif [[ -e "$LOCK_FILE" ]]; then
  exec 9<"$LOCK_FILE"
  flock -n -s 9 || die "Another managed updater process is already running"
fi

if [[ "$COMMAND" == "list" ]]; then
  # Registration lives in each service's own service.json, so this is the one
  # place that answers "what will the timers touch, and is it ready?".
  while IFS= read -r dir; do
    policy="$dir/service.json"
    [[ -f "$policy" ]] || continue
    jq -e '.managed_update' "$policy" >/dev/null 2>&1 || continue
    missing=()
    for hook in version.sh deploy.sh strict-healthcheck.sh; do
      [[ -x "$dir/managed/$hook" ]] || missing+=("$hook")
    done
    if [[ "$(jq -r '.managed_update.backup_required // false' "$policy")" == "true" ]] \
       && [[ ! -x "$dir/managed/backup.sh" ]]; then
      missing+=("backup.sh")
    fi
    jq -cn \
      --arg service "$(basename "$dir")" \
      --argjson enabled "$(jq -r '.managed_update.enabled // false' "$policy")" \
      --arg branch "$(jq -r '.managed_update.deployment_branch // ""' "$policy")" \
      --argjson age "$(jq -r '.managed_update.minimum_release_age_days // null' "$policy")" \
      --argjson components "$(jq -c '.managed_update.components // []' "$policy")" \
      --argjson missing "$(printf '%s\n' "${missing[@]+"${missing[@]}"}" | jq -R . | jq -s 'map(select(. != ""))')" \
      '{service:$service, enabled:$enabled, deployment_branch:$branch,
        minimum_release_age_days:$age, components:$components,
        missing_hooks:$missing, ready:(($enabled) and ($missing|length)==0)}'
  done < <(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sort) \
  | jq -s '{registered: map(select(.enabled)), not_registered: map(select(.enabled|not))}'
  exit 0
fi

# A service is registered by a managed_update block in its own service.json.
# Nothing here knows which services exist.
SERVICE_DIR="$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -type d -name "$SERVICE" -print -quit 2>/dev/null || true)"
[[ -n "$SERVICE_DIR" ]] || die "No such service: $SERVICE"
POLICY_FILE="$SERVICE_DIR/service.json"
STATE_FILE="$STATE_ROOT/${SERVICE}.json"
# COREKIT_N8N_BACKUP_ROOT is honoured only for n8n itself. It predates
# multi-service support and is set in the systemd units, so applying it to every
# service would send one service's recovery sets into another's directory.
if [[ -n "${COREKIT_MANAGED_BACKUP_ROOT:-}" ]]; then
  BACKUP_ROOT="$COREKIT_MANAGED_BACKUP_ROOT"
elif [[ "$SERVICE" == "n8n" && -n "${COREKIT_N8N_BACKUP_ROOT:-}" ]]; then
  BACKUP_ROOT="$COREKIT_N8N_BACKUP_ROOT"
else
  BACKUP_ROOT="$USER_DATA_HOME/ai-corekit/backups/$SERVICE"
fi

[[ -f "$POLICY_FILE" ]] || die "Service '$SERVICE' has no service.json"
[[ "$(jq -r '.managed_update.enabled // false' "$POLICY_FILE")" == "true" ]] \
  || die "Service '$SERVICE' is not registered for managed updates. Set managed_update.enabled in its service.json."

# Everything service-specific is a hook in the service's own managed/ directory.
HOOK_DIR="$SERVICE_DIR/managed"
export COREKIT_PROJECT_ROOT="$PROJECT_ROOT"
export COREKIT_SERVICE_DIR="$SERVICE_DIR"
export COREKIT_SERVICE_NAME="$SERVICE"

have_hook() { [[ -x "$HOOK_DIR/$1" ]]; }
run_hook() {
  local hook="$1"; shift
  [[ -x "$HOOK_DIR/$hook" ]] || die "Service '$SERVICE' is registered for managed updates but has no $hook hook"
  bash "$HOOK_DIR/$hook" "$@"
}

VERSION_INFO="$(run_hook version.sh)" || die "Could not determine versions for '$SERVICE'"
jq -e . <<<"$VERSION_INFO" >/dev/null 2>&1 || die "version.sh did not return valid JSON"
TARGET_VERSION="$(jq -r '.target_version' <<<"$VERSION_INFO")"
BUNDLE_IDENTITY="$(jq -r '.identity' <<<"$VERSION_INFO")"

DEPLOYMENT_BRANCH="$(jq -r '.managed_update.deployment_branch' "$POLICY_FILE")"
MINIMUM_RELEASE_AGE_DAYS="$(jq -r '.managed_update.minimum_release_age_days' "$POLICY_FILE")"
MINIMUM_FREE_SPACE_GB="$(jq -r '.managed_update.minimum_free_space_gb' "$POLICY_FILE")"
RECOVERY_SETS_TO_KEEP="$(jq -r '.managed_update.recovery_sets_to_keep' "$POLICY_FILE")"

# Kept for the structured output below; sourced from the service's version hook
# rather than parsed here, so the driver stays service-agnostic.
TARGET_N8N_DIGEST="$(jq -r '.refs.n8n_digest // ""' <<<"$VERSION_INFO")"
TARGET_RUNNER_DIGEST="$(jq -r '.refs.runner_digest // ""' <<<"$VERSION_INFO")"
N8N_GIT_VERSION="$(jq -r '.refs.n8n_git_version // ""' <<<"$VERSION_INFO")"
N8N_GIT_COMMIT="$(jq -r '.refs.n8n_git_commit // ""' <<<"$VERSION_INFO")"

validate_bundle() {
  if have_hook validate.sh; then
    run_hook validate.sh || die "Committed bundle for '$SERVICE' failed validation"
  fi
}

live_version() {
  jq -r '.live_version // "unknown"' <<<"$VERSION_INFO"
}

version_change_type() {
  local current="$1"
  local target="$2"
  if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'unknown\n'
    return
  fi
  IFS=. read -r current_major current_minor current_patch <<<"$current"
  IFS=. read -r target_major target_minor target_patch <<<"$target"
  if (( target_major != current_major )); then
    printf 'major\n'
  elif (( target_minor != current_minor )); then
    printf 'minor\n'
  elif (( target_patch != current_patch )); then
    printf 'patch\n'
  else
    printf 'none\n'
  fi
}

git_is_clean() {
  [[ -z "$(git -C "$PROJECT_ROOT" status --porcelain --untracked-files=normal)" ]]
}

remote_head() {
  if [[ "$OFFLINE" == "true" ]]; then
    printf 'offline\n'
  else
    git -C "$PROJECT_ROOT" ls-remote --heads origin "refs/heads/$DEPLOYMENT_BRANCH" | awk 'NR == 1 {print $1}'
  fi
}

release_age_days() {
  local committed_at now
  committed_at="$(git -C "$PROJECT_ROOT" log -1 --format=%ct -- "$SERVICE_DIR")"
  [[ -n "$committed_at" ]] || die "Unable to determine candidate commit age"
  now="$(date +%s)"
  printf '%s\n' "$(( (now - committed_at) / 86400 ))"
}

free_space_gb() {
  df -Pk "$PROJECT_ROOT" | awk 'NR == 2 {printf "%d\n", $4 / 1024 / 1024}'
}

bundle_fingerprint() {
  # The committed tree plus the identity the service reports, so a change to
  # either is a change of candidate.
  {
    git -C "$PROJECT_ROOT" ls-tree -r HEAD -- "${SERVICE_DIR#"$PROJECT_ROOT"/}"
    printf '%s\n' "$BUNDLE_IDENTITY"
  } | sha256sum | awk '{print $1}'
}

version_is_greater() {
  local current="$1"
  local target="$2"
  local current_major current_minor current_patch target_major target_minor target_patch
  IFS=. read -r current_major current_minor current_patch <<<"$current"
  IFS=. read -r target_major target_minor target_patch <<<"$target"
  (( target_major > current_major )) ||
    (( target_major == current_major && target_minor > current_minor )) ||
    (( target_major == current_major && target_minor == current_minor && target_patch > current_patch ))
}

# Counts come from the service, because a service with its own database must
# not be measured against another instance's.
service_counts() {
  if have_hook counts.sh; then
    run_hook counts.sh
  else
    printf '{"workflows":null,"credentials":null,"active_executions":"0"}\n'
  fi
}
active_execution_count() { jq -r '.active_executions // "0"' <<<"$(service_counts)"; }
entity_count() {
  case "$1" in
    workflow_entity)    jq -r '.workflows // "unknown"'   <<<"$(service_counts)" ;;
    credentials_entity) jq -r '.credentials // "unknown"' <<<"$(service_counts)" ;;
    *)                  printf 'unknown\n' ;;
  esac
}


print_plan() {
  local current_version change_type current_branch head remote age free_gb active changed current_commit fingerprint
  validate_bundle
  current_version="$(live_version)"
  change_type="$(version_change_type "$current_version" "$TARGET_VERSION")"
  current_branch="$(git -C "$PROJECT_ROOT" branch --show-current)"
  current_commit="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
  fingerprint="$(bundle_fingerprint)"
  remote="$(remote_head)"
  age="$(release_age_days)"
  free_gb="$(free_space_gb)"
  active="unknown"
  if docker inspect postgres >/dev/null 2>&1; then
    active="$(active_execution_count)"
  fi
  changed=true
  if [[ "$change_type" == "none" && -f "$STATE_FILE" ]] && \
    [[ "$(jq -r '.current.config_fingerprint // empty' "$STATE_FILE")" == "$fingerprint" ]]; then
    changed=false
  fi
  head="$current_commit"
  jq -n \
    --arg service "$SERVICE" \
    --arg branch "$current_branch" \
    --arg expected_branch "$DEPLOYMENT_BRANCH" \
    --arg head "$head" \
    --arg config_fingerprint "$fingerprint" \
    --arg remote_head "$remote" \
    --arg current_version "$current_version" \
    --arg target_version "$TARGET_VERSION" \
    --arg update_type "$change_type" \
    --arg n8n_digest "$TARGET_N8N_DIGEST" \
    --arg runner_digest "$TARGET_RUNNER_DIGEST" \
    --arg n8n_git_version "$N8N_GIT_VERSION" \
    --argjson release_age_days "$age" \
    --argjson minimum_release_age_days "$MINIMUM_RELEASE_AGE_DAYS" \
    --argjson free_space_gb "$free_gb" \
    --argjson minimum_free_space_gb "$MINIMUM_FREE_SPACE_GB" \
    --arg active_executions "$active" \
    --argjson changed "$changed" \
    --argjson clean "$(git_is_clean && echo true || echo false)" \
    '{
      service:$service,
      policy_enabled:true,
      branch:$branch,
      expected_branch:$expected_branch,
      git_head:$head,
      config_fingerprint:$config_fingerprint,
      remote_head:$remote_head,
      clean_tree:$clean,
      changed:$changed,
      current_version:$current_version,
      target_version:$target_version,
      update_type:$update_type,
      candidate:{n8n_digest:$n8n_digest,runner_digest:$runner_digest,n8n_git_version:$n8n_git_version},
      gates:{
        release_age_days:$release_age_days,
        minimum_release_age_days:$minimum_release_age_days,
        free_space_gb:$free_space_gb,
        minimum_free_space_gb:$minimum_free_space_gb,
        active_executions:$active_executions,
        backup_required:true,
        guarded_stateful_rollback:true
      }
    }'
}

write_failure_state() {
  local stage="$1"
  local backup_manifest="${2:-}"
  local tmp_state
  tmp_state="$(mktemp "$STATE_ROOT/.n8n-state.XXXXXX")"
  if [[ -f "$STATE_FILE" ]]; then
    jq \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg stage "$stage" \
      --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
      --arg target_version "$TARGET_VERSION" \
      --arg backup_manifest "$backup_manifest" \
      '.last_result={result:"failed",timestamp:$timestamp,stage:$stage,git_commit:$git_commit,target_version:$target_version,backup_manifest:$backup_manifest,writes_possible:true,automatic_database_restore_permitted:false}' \
      "$STATE_FILE" >"$tmp_state"
  else
    jq -n \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg stage "$stage" \
      --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
      --arg target_version "$TARGET_VERSION" \
      --arg backup_manifest "$backup_manifest" \
      --arg service_name "$SERVICE" \
      '{schema_version:1,service:$service_name,last_result:{result:"failed",timestamp:$timestamp,stage:$stage,git_commit:$git_commit,target_version:$target_version,backup_manifest:$backup_manifest,writes_possible:true,automatic_database_restore_permitted:false}}' \
      >"$tmp_state"
  fi
  chmod 0600 "$tmp_state"
  mv "$tmp_state" "$STATE_FILE"
}

write_success_state() {
  local previous_version="$1"
  local previous_n8n_image_id="$2"
  local previous_runner_image_id="$3"
  local backup_manifest="$4"
  local n8n_image_id runner_image_id tmp_state previous_state history fingerprint previous_git_commit
  local -a components
  mapfile -t components < <(jq -r '.managed_update.components[]? // empty' "$POLICY_FILE")
  (( ${#components[@]} > 0 )) || components=("$SERVICE")
  # Guarded: a missing container must not abort after a successful deployment
  # and leave no record that it happened.
  n8n_image_id="$(docker inspect --format '{{.Image}}' "${components[0]}" 2>/dev/null || true)"
  runner_image_id=""
  (( ${#components[@]} > 1 )) && runner_image_id="$(docker inspect --format '{{.Image}}' "${components[1]}" 2>/dev/null || true)"
  fingerprint="$(bundle_fingerprint)"
  previous_git_commit="$(jq -r '.git.previous_live_commit // empty' "$backup_manifest")"
  previous_state='null'
  history='[]'
  if [[ -f "$STATE_FILE" ]]; then
    previous_state="$(jq -c '.current // null' "$STATE_FILE")"
    history="$(jq -c '.history // []' "$STATE_FILE")"
  fi
  if [[ "$previous_state" == "null" ]]; then
    previous_state="$(jq -cn \
      --arg version "$previous_version" \
      --arg n8n_image_id "$previous_n8n_image_id" \
      --arg runner_image_id "$previous_runner_image_id" \
      --arg git_commit "$previous_git_commit" \
      --arg backup_manifest "$backup_manifest" \
      '{version:$version,git_commit:$git_commit,n8n_image_id:$n8n_image_id,runner_image_id:$runner_image_id,backup_manifest:$backup_manifest}')"
  fi
  tmp_state="$(mktemp "$STATE_ROOT/.n8n-state.XXXXXX")"
  jq -n \
    --arg deployed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg version "$TARGET_VERSION" \
    --arg git_commit "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
    --arg config_fingerprint "$fingerprint" \
    --arg n8n_image_id "$n8n_image_id" \
    --arg runner_image_id "$runner_image_id" \
    --arg n8n_base_digest "$TARGET_N8N_DIGEST" \
    --arg runner_base_digest "$TARGET_RUNNER_DIGEST" \
    --arg n8n_git_version "$N8N_GIT_VERSION" \
    --arg n8n_git_commit "$N8N_GIT_COMMIT" \
    --arg backup_manifest "$backup_manifest" \
    --argjson previous "$previous_state" \
    --argjson history "$history" \
    --arg service_name "$SERVICE" \
    '{
      schema_version:1,
      service:$service_name,
      current:{
        version:$version,
        git_commit:$git_commit,
        config_fingerprint:$config_fingerprint,
        deployed_at:$deployed_at,
        n8n_image_id:$n8n_image_id,
        runner_image_id:$runner_image_id,
        n8n_base_digest:$n8n_base_digest,
        runner_base_digest:$runner_base_digest,
        n8n_git_version:$n8n_git_version,
        n8n_git_commit:$n8n_git_commit,
        backup_manifest:$backup_manifest,
        result:"success"
      },
      previous:$previous,
      last_result:{result:"success",timestamp:$deployed_at},
      history: (($history + [{version:$version,git_commit:$git_commit,deployed_at:$deployed_at,backup_manifest:$backup_manifest,result:"success"}]) | if length > 20 then .[-20:] else . end)
    }' >"$tmp_state"
  chmod 0600 "$tmp_state"
  mv "$tmp_state" "$STATE_FILE"
}

verify_recovery_retention() {
  local verified_count
  verified_count=0
  if [[ -d "$BACKUP_ROOT" ]]; then
    verified_count="$( { find "$BACKUP_ROOT" -mindepth 2 -maxdepth 2 -name manifest.json -type f -print0 \
      | xargs -0 -r jq -r 'select(.verified == true) | .created_at' | wc -l; } 2>/dev/null || echo 0)"
  fi
  log_event info recovery_retention "Verified recovery sets are preserved without automatic deletion; policy floor is ${RECOVERY_SETS_TO_KEEP}, current count is ${verified_count}"
}

apply_update() {
  validate_bundle
  git_is_clean || die "Git worktree is dirty; refusing managed deployment"

  local branch current_version change_type age free_gb current_commit fingerprint
  local candidate_image workflow_count credential_count
  local previous_n8n_image_id previous_runner_image_id backup_manifest active

  branch="$(git -C "$PROJECT_ROOT" branch --show-current)"
  if [[ "$LOCAL_COMMIT" == "true" ]]; then
    [[ "$branch" == codex/* || "$branch" == agent/* ]] || die "--local-commit is limited to an explicit scoped feature branch"
    [[ "$SECURITY_OVERRIDE" == "true" || "$MANUAL_MAJOR" == "true" ]] || die "--local-commit requires an explicit manual security or major approval flag"
    log_event warning local_commit_bootstrap "Deploying a clean committed feature branch without updating Git"
  else
    [[ "$branch" == "$DEPLOYMENT_BRANCH" ]] || die "Unexpected deployment branch: $branch"
    [[ "$OFFLINE" == "false" ]] || die "Normal apply cannot run offline"
    git -C "$PROJECT_ROOT" fetch --no-tags origin "$DEPLOYMENT_BRANCH"
    git_is_clean || die "Git worktree became dirty after fetch"
    git -C "$PROJECT_ROOT" merge-base --is-ancestor HEAD "origin/$DEPLOYMENT_BRANCH" || die "Remote change is not fast-forwardable"
    git -C "$PROJECT_ROOT" merge --ff-only "origin/$DEPLOYMENT_BRANCH"
    # The merge can change what is committed, so everything read from the tree
    # before it is now stale. Re-read before validating against it.
    VERSION_INFO="$(run_hook version.sh)" || die "Could not re-read versions after the update"
    jq -e . <<<"$VERSION_INFO" >/dev/null 2>&1 || die "version.sh did not return valid JSON after the update"
    TARGET_VERSION="$(jq -r '.target_version' <<<"$VERSION_INFO")"
    BUNDLE_IDENTITY="$(jq -r '.identity' <<<"$VERSION_INFO")"
    # Policy is part of the committed tree too. A commit that raises the
    # release-age floor, or changes the component list the recovery path stops,
    # must govern this run rather than the version it replaced.
    DEPLOYMENT_BRANCH="$(jq -r '.managed_update.deployment_branch' "$POLICY_FILE")"
    MINIMUM_RELEASE_AGE_DAYS="$(jq -r '.managed_update.minimum_release_age_days' "$POLICY_FILE")"
    MINIMUM_FREE_SPACE_GB="$(jq -r '.managed_update.minimum_free_space_gb' "$POLICY_FILE")"
    RECOVERY_SETS_TO_KEEP="$(jq -r '.managed_update.recovery_sets_to_keep' "$POLICY_FILE")"
    TARGET_N8N_DIGEST="$(jq -r '.refs.n8n_digest // ""' <<<"$VERSION_INFO")"
    TARGET_RUNNER_DIGEST="$(jq -r '.refs.runner_digest // ""' <<<"$VERSION_INFO")"
    N8N_GIT_VERSION="$(jq -r '.refs.n8n_git_version // ""' <<<"$VERSION_INFO")"
    N8N_GIT_COMMIT="$(jq -r '.refs.n8n_git_commit // ""' <<<"$VERSION_INFO")"
    validate_bundle
  fi

  current_version="$(live_version)"
  change_type="$(version_change_type "$current_version" "$TARGET_VERSION")"
  if [[ "$change_type" == "major" && "$MANUAL_MAJOR" != "true" ]]; then
    die "Major n8n updates require --manual-major"
  fi
  if [[ "$change_type" != "none" && "$change_type" != "patch" && "$change_type" != "minor" && "$change_type" != "major" ]]; then
    die "Unable to classify the live-to-candidate version change"
  fi
  if [[ "$change_type" != "none" ]] && ! version_is_greater "$current_version" "$TARGET_VERSION"; then
    die "Managed updates refuse version downgrades; use the guarded recovery procedure"
  fi

  current_commit="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
  fingerprint="$(bundle_fingerprint)"
  if [[ "$change_type" == "none" && -f "$STATE_FILE" ]] && \
    [[ "$(jq -r '.current.config_fingerprint // empty' "$STATE_FILE")" == "$fingerprint" ]]; then
    log_event info no_change "Committed n8n bundle is already deployed"
    return 0
  fi

  age="$(release_age_days)"
  if (( age < MINIMUM_RELEASE_AGE_DAYS )) && [[ "$SECURITY_OVERRIDE" != "true" ]]; then
    die "Candidate has not met the minimum release-age gate"
  fi
  if [[ "$SECURITY_OVERRIDE" == "true" ]]; then
    log_event warning security_override "Release-age gate bypassed for the manually approved security update; all other gates remain active"
  fi

  free_gb="$(free_space_gb)"
  (( free_gb >= MINIMUM_FREE_SPACE_GB )) || die "Insufficient free space for candidate build and recovery set"
  active="$(active_execution_count)"
  [[ "$active" == "0" ]] || die "Active or waiting executions prevent deployment"

  log_event info candidate_build_started "Building and verifying the committed candidate before any downtime"
  CANDIDATE_IMAGES="$(run_hook build.sh "$TARGET_VERSION" | tail -n 1)" \
    || die "Candidate build or verification failed"
  jq -e . <<<"$CANDIDATE_IMAGES" >/dev/null 2>&1 || die "build.sh did not return valid JSON"
  candidate_image="$(jq -r '.images.app // empty' <<<"$CANDIDATE_IMAGES")"
  [[ -n "$candidate_image" ]] || die "build.sh did not report a candidate image"

  workflow_count="$(entity_count workflow_entity)"
  credential_count="$(entity_count credentials_entity)"
  # Recovery points at the image to restart, so it must be THIS service's
  # container. Reading a fixed name would hand production the authoring
  # instance's image.
  mapfile -t _components < <(jq -r '.managed_update.components[]? // empty' "$POLICY_FILE")
  (( ${#_components[@]} > 0 )) || _components=("$SERVICE")
  previous_n8n_image_id="$(docker inspect --format '{{.Image}}' "${_components[0]}" 2>/dev/null || true)"
  previous_runner_image_id=""
  (( ${#_components[@]} > 1 )) && previous_runner_image_id="$(docker inspect --format '{{.Image}}' "${_components[1]}" 2>/dev/null || true)"
  if [[ -z "$PREVIOUS_GIT_COMMIT" ]]; then
    if [[ -f "$STATE_FILE" ]]; then
      PREVIOUS_GIT_COMMIT="$(jq -r '.current.git_commit // empty' "$STATE_FILE")"
    fi
    if [[ -z "$PREVIOUS_GIT_COMMIT" ]] && git -C "$PROJECT_ROOT" rev-parse "origin/$DEPLOYMENT_BRANCH" >/dev/null 2>&1; then
      PREVIOUS_GIT_COMMIT="$(git -C "$PROJECT_ROOT" rev-parse "origin/$DEPLOYMENT_BRANCH")"
    fi
  fi

  log_event info backup_started "Creating mandatory final recovery set and isolated restore drill"
  backup_manifest="$(COREKIT_PROJECT_ROOT="$PROJECT_ROOT" \
    COREKIT_MANAGED_BACKUP_ROOT="$BACKUP_ROOT" COREKIT_N8N_BACKUP_ROOT="$BACKUP_ROOT" \
    bash "$HOOK_DIR/backup.sh" --label "pre-${TARGET_VERSION}" \
      --previous-git-commit "$PREVIOUS_GIT_COMMIT" --candidate-image "$candidate_image" | tail -n 1)"
  [[ -f "$backup_manifest" ]] || die "Backup script did not return a verified manifest"
  [[ "$(jq -r '.verified' "$backup_manifest")" == "true" ]] || die "Recovery set is not verified"
  [[ "$(jq -r '.restore_drill.result' "$backup_manifest")" == "passed" ]] || die "Recovery-set restore drill did not pass"
  [[ "$(jq -r '.candidate_migration_drill.result' "$backup_manifest")" == "passed" ]] || die "Candidate migration rehearsal did not pass"

  [[ "$(active_execution_count)" == "0" ]] || die "Executions became active after the backup gate"
  # The environment a deployment needs is service-specific, so the deploy hook
  # assembles it. The driver supplies only the candidate images.
  log_event info deployment_started "Recreating only this service's containers with the candidate"
  if ! COREKIT_CANDIDATE_IMAGES="$CANDIDATE_IMAGES" run_hook deploy.sh "$TARGET_VERSION"; then
    write_failure_state compose_up "$backup_manifest"
    die "Candidate deployment failed; stateful recovery requires the guarded rollback plan"
  fi

  # The canary must exercise the candidate, not whatever a compose fallback tag
  # resolves to. It is a second consumer of the images build.sh produced.
  if ! COREKIT_MANAGED_STATE_ROOT="$STATE_ROOT" \
       COREKIT_CANDIDATE_IMAGES="$CANDIDATE_IMAGES" \
       bash "$HOOK_DIR/strict-healthcheck.sh" \
    --expected-workflows "$workflow_count" \
    --expected-credentials "$credential_count" \
    --canary; then
    if have_hook stop.sh; then
      run_hook stop.sh >/dev/null 2>&1 || true
    else
      # Fall back to the components the policy names.
      mapfile -t _components < <(jq -r '.managed_update.components[]? // empty' "$POLICY_FILE")
      (( ${#_components[@]} > 0 )) && docker stop --time 30 "${_components[@]}" >/dev/null 2>&1 || true
    fi
    write_failure_state strict_health "$backup_manifest"
    die "Candidate failed strict health; stopped without automatic database restore because writes are conservatively possible"
  fi

  write_success_state "$current_version" "$previous_n8n_image_id" "$previous_runner_image_id" "$backup_manifest"
  verify_recovery_retention
  log_event info deployment_succeeded "Managed deployment of '$SERVICE' passed readiness, canary, counts, audit, and restore gates"
}

show_status() {
  local current_version runner_version n8n_image_id runner_image_id
  current_version="$(live_version)"
  runner_version="unknown"
  n8n_image_id=""
  runner_image_id=""
  if docker inspect n8n >/dev/null 2>&1; then
    n8n_image_id="$(docker inspect --format '{{.Image}}' n8n)"
  fi
  if docker inspect n8n-runner >/dev/null 2>&1; then
    runner_version="$(docker inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' n8n-runner 2>/dev/null || true)"
    [[ -n "$runner_version" ]] || runner_version="$(docker inspect --format '{{.Config.Image}}' n8n-runner | sed -n 's/.*:\([0-9][0-9.]*\).*/\1/p')"
    runner_image_id="$(docker inspect --format '{{.Image}}' n8n-runner)"
  fi
  local state='null'
  [[ -f "$STATE_FILE" ]] && state="$(cat "$STATE_FILE")"
  jq -n \
    --arg live_n8n_version "$current_version" \
    --arg live_runner_version "$runner_version" \
    --arg n8n_image_id "$n8n_image_id" \
    --arg runner_image_id "$runner_image_id" \
    --argjson state "$state" \
    '{live:{n8n_version:$live_n8n_version,runner_version:$live_runner_version,n8n_image_id:$n8n_image_id,runner_image_id:$runner_image_id},state:$state}'
}

show_rollback_plan() {
  [[ -f "$STATE_FILE" ]] || die "No managed-update state exists"
  jq '{
    service,
    current,
    previous,
    last_result,
    recovery:{
      automatic_database_restore_permitted:false,
      writes_must_be_ruled_out:true,
      backup_manifest:(.current.backup_manifest // .last_result.backup_manifest // .previous.backup_manifest),
      procedure:[
        "Stop only n8n and n8n-runner and preserve their logs.",
        "Verify whether any post-upgrade workflow, credential, execution, user, webhook, or settings writes occurred.",
        "If writes may exist, do not restore: preserve the failed database and escalate.",
        "If writes are conclusively absent, verify checksums.sha256 and repeat an isolated pg_restore drill.",
        "Load previous-images.tar.gz, restore postgres.dump only during an approved maintenance window, then start the recorded previous n8n image and run strict health/count checks."
      ]
    }
  }' "$STATE_FILE"
}

case "$COMMAND" in
  check)
    validate_bundle
    LOCAL_HEAD="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
    REMOTE_HEAD="$(remote_head)"
    jq -n \
      --arg service "$SERVICE" \
      --arg branch "$(git -C "$PROJECT_ROOT" branch --show-current)" \
      --arg expected_branch "$DEPLOYMENT_BRANCH" \
      --arg local_head "$LOCAL_HEAD" \
      --arg remote_head "$REMOTE_HEAD" \
      --arg target_version "$TARGET_VERSION" \
      --arg live_version "$(live_version)" \
      '{service:$service,branch:$branch,expected_branch:$expected_branch,local_head:$local_head,remote_head:$remote_head,target_version:$target_version,live_version:$live_version,mutated:false}'
    ;;
  plan)
    print_plan
    ;;
  apply)
    if [[ "$DRY_RUN" == "true" ]]; then
      print_plan
    else
      apply_update
    fi
    ;;
  status)
    show_status
    ;;
  rollback-plan)
    show_rollback_plan
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    die "Unknown managed-update command: $COMMAND"
    ;;
esac
