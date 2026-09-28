#!/usr/bin/env bash
# Refuse a committed bundle that could not be deployed reproducibly.
set -Eeuo pipefail

SERVICE_DIR="${COREKIT_SERVICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
fail() { echo "$1" >&2; exit 1; }

info="$("$SERVICE_DIR/managed/version.sh")"
target="$(jq -r '.target_version' <<<"$info")"
runner_version="$(jq -r '.refs.runner_version' <<<"$info")"
n8n_digest="$(jq -r '.refs.n8n_digest' <<<"$info")"
runner_digest="$(jq -r '.refs.runner_digest' <<<"$info")"
git_version="$(jq -r '.refs.n8n_git_version' <<<"$info")"
git_commit="$(jq -r '.refs.n8n_git_commit' <<<"$info")"

[[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Pinned version is invalid"
[[ "$target" == "$runner_version" ]] || fail "Pinned application and runner versions differ"
[[ "$n8n_digest" =~ ^sha256:[0-9a-f]{64}$ ]] || fail "Pinned application digest is invalid"
[[ "$runner_digest" =~ ^sha256:[0-9a-f]{64}$ ]] || fail "Pinned runner digest is invalid"
[[ "$git_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Pinned n8n-git version is invalid"
[[ "$git_commit" =~ ^[0-9a-f]{40}$ ]] || fail "Pinned n8n-git commit is invalid"

jq -e . "$SERVICE_DIR/service.json" "$SERVICE_DIR/task-runners-managed.json" >/dev/null \
  || fail "Managed JSON configuration is invalid"

# A moving tag anywhere in the bundle defeats the point of pinning digests.
if grep -ERn '(^|[[:space:]:])latest([@[:space:]]|$)' \
     "$SERVICE_DIR/Dockerfile" "$SERVICE_DIR/runner/Dockerfile" \
     "$SERVICE_DIR/docker-compose.yml" >/dev/null; then
  fail "Moving 'latest' reference found in the managed bundle"
fi
