#!/usr/bin/env bash
# Nothing to build. Confirm the pinned images really are the version claimed,
# then report them, so the driver treats this like any other candidate.
set -Eeuo pipefail
TARGET_VERSION="${1:?target version required}"
SERVICE_DIR="${COREKIT_SERVICE_DIR:?}"
fail() { echo "$1" >&2; exit 1; }

info="$("$SERVICE_DIR/managed/version.sh")"
app_image="$(jq -r '.refs.app_image' <<<"$info")"
runner_image="$(jq -r '.refs.runner_image' <<<"$info")"

actual="$(docker run --rm --network none "$app_image" n8n --version 2>/dev/null | tr -d '\r')"
[[ "$actual" == "$TARGET_VERSION" ]] \
  || fail "Pinned image reports $actual, not the expected $TARGET_VERSION"

label="$(docker image inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' "$runner_image" 2>/dev/null || true)"
[[ -z "$label" || "$label" == "$TARGET_VERSION" ]] \
  || fail "Runner image is built for $label, not $TARGET_VERSION"

jq -cn --arg a "$app_image" --arg r "$runner_image" '{images:{app:$a, runner:$r}}'
