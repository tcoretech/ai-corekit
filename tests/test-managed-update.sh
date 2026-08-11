#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_STATE_ROOT="$(mktemp -d /tmp/corekit-managed-state.XXXXXX)"
trap 'rm -rf -- "$TEST_STATE_ROOT"' EXIT

BEFORE_HEAD="$(git -C "$PROJECT_ROOT" rev-parse HEAD)"
BEFORE_STATUS="$(git -C "$PROJECT_ROOT" status --porcelain=v1)"
BEFORE_CONTAINERS="$(docker ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | sort)"

COREKIT_MANAGED_STATE_ROOT="$TEST_STATE_ROOT" "$PROJECT_ROOT/corekit.sh" managed-update check n8n --offline \
  | jq -e '.service == "n8n" and .mutated == false' >/dev/null
COREKIT_MANAGED_STATE_ROOT="$TEST_STATE_ROOT" "$PROJECT_ROOT/corekit.sh" managed-update plan n8n --offline \
  | jq -e '.policy_enabled == true and .gates.backup_required == true' >/dev/null
COREKIT_MANAGED_STATE_ROOT="$TEST_STATE_ROOT" "$PROJECT_ROOT/corekit.sh" managed-update apply n8n --dry-run --offline \
  | jq -e '.target_version != null and .candidate.runner_digest != null' >/dev/null

if COREKIT_MANAGED_STATE_ROOT="$TEST_STATE_ROOT" "$PROJECT_ROOT/corekit.sh" managed-update check postgres --offline >/dev/null 2>&1; then
  echo "non-opted-in service was accepted" >&2
  exit 1
fi

[[ "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" == "$BEFORE_HEAD" ]]
[[ "$(git -C "$PROJECT_ROOT" status --porcelain=v1)" == "$BEFORE_STATUS" ]]
[[ "$(docker ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | sort)" == "$BEFORE_CONTAINERS" ]]

echo "managed updater dry-run tests passed"
