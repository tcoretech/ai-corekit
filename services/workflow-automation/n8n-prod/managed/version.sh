#!/usr/bin/env bash
# This service does not build an image. It adopts one already built and verified
# for the authoring instance, pinned in this service's .env. "Updating" it means
# re-pinning to a newer image and recreating the containers.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

[[ -f "$SERVICE_DIR/.env" ]] || { echo "No .env for this service" >&2; exit 1; }
# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a

app_image="${N8N_PROD_IMAGE:-}"
runner_image="${N8N_PROD_RUNNER_IMAGE:-}"
[[ -n "$app_image" && -n "$runner_image" ]] || { echo "N8N_PROD_IMAGE and N8N_PROD_RUNNER_IMAGE must be set in .env" >&2; exit 1; }

# corekit/n8n:<version>-git<commit> -> <version>
tag="${app_image##*:}"
target_version="${tag%%-*}"
runner_tag="${runner_image##*:}"
runner_version="${runner_tag%%-*}"

live_version="unknown"
if docker inspect n8n-prod >/dev/null 2>&1 \
   && [[ "$(docker inspect --format '{{.State.Running}}' n8n-prod)" == "true" ]]; then
  live_version="$(docker exec n8n-prod n8n --version 2>/dev/null | tr -d '\r' || echo unknown)"
fi

identity="$(printf '%s|%s' "$app_image" "$runner_image" | sha256sum | awk '{print $1}')"

jq -cn --arg t "$target_version" --arg l "$live_version" --arg i "$identity" \
       --arg app "$app_image" --arg runner "$runner_image" --arg rv "$runner_version" \
  '{target_version:$t, live_version:$l, identity:$i,
    refs:{app_image:$app, runner_image:$runner, runner_version:$rv}}'
