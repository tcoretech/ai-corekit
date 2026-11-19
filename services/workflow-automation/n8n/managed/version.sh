#!/usr/bin/env bash
# Report the committed and live versions of this service, plus an identity that
# changes whenever the committed build would change.
#
# The versions and digests are read from the Dockerfiles, which are the only
# place a version is declared for this service.
set -Eeuo pipefail

SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

n8n_ref="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/n8n:/ {print $2; exit}' "$SERVICE_DIR/Dockerfile")"
runner_ref="$(awk '$1 == "FROM" && $2 ~ /^n8nio\/runners:/ {print $2; exit}' "$SERVICE_DIR/runner/Dockerfile")"

target_version="${n8n_ref#*:}"; target_version="${target_version%%@*}"
target_digest="${n8n_ref##*@}"
runner_version="${runner_ref#*:}"; runner_version="${runner_version%%@*}"
runner_digest="${runner_ref##*@}"
git_version="$(awk -F= '$1 == "ARG N8N_GIT_VERSION" {print $2}' "$SERVICE_DIR/Dockerfile")"
git_commit="$(awk -F= '$1 == "ARG N8N_GIT_COMMIT" {print $2}' "$SERVICE_DIR/Dockerfile")"

live_version="unknown"
if docker inspect n8n >/dev/null 2>&1 \
   && [[ "$(docker inspect --format '{{.State.Running}}' n8n)" == "true" ]]; then
  live_version="$(docker exec n8n n8n --version 2>/dev/null | tr -d '\r' || echo unknown)"
fi

# Identity covers everything that would change the built image.
identity="$(printf '%s|%s|%s|%s' "$n8n_ref" "$runner_ref" "$git_version" "$git_commit" \
            | sha256sum | awk '{print $1}')"

jq -cn \
  --arg target "$target_version" --arg live "$live_version" --arg identity "$identity" \
  --arg n8n_digest "$target_digest" --arg runner_version "$runner_version" \
  --arg runner_digest "$runner_digest" --arg git_version "$git_version" --arg git_commit "$git_commit" \
  '{target_version:$target, live_version:$live, identity:$identity,
    refs:{n8n_digest:$n8n_digest, runner_version:$runner_version,
          runner_digest:$runner_digest, n8n_git_version:$git_version,
          n8n_git_commit:$git_commit}}'
