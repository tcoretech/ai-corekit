#!/usr/bin/env bash
# The pinned images must exist locally and agree on version. Nothing is built
# here, so an image that is absent is a hard stop rather than something to fetch.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:?}"
fail() { echo "$1" >&2; exit 1; }

info="$("$SERVICE_DIR/managed/version.sh")"
target="$(jq -r '.target_version' <<<"$info")"
runner_version="$(jq -r '.refs.runner_version' <<<"$info")"
app_image="$(jq -r '.refs.app_image' <<<"$info")"
runner_image="$(jq -r '.refs.runner_image' <<<"$info")"

[[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Pinned version is not a release version: $target"
[[ "$target" == "$runner_version" ]] || fail "Application and runner versions differ: $target vs $runner_version"
[[ "$app_image" != *:latest ]] || fail "Application image uses a moving 'latest' tag"
[[ "$runner_image" != *:latest ]] || fail "Runner image uses a moving 'latest' tag"

docker image inspect "$app_image" >/dev/null 2>&1 \
  || fail "Pinned application image is not present locally: $app_image"
docker image inspect "$runner_image" >/dev/null 2>&1 \
  || fail "Pinned runner image is not present locally: $runner_image"

jq -e . "$SERVICE_DIR/service.json" >/dev/null || fail "service.json is not valid JSON"
