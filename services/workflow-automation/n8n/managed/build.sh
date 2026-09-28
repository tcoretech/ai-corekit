#!/usr/bin/env bash
# Build the candidate images and verify they are what the bundle asked for.
#
# Built before anything live is stopped, so a build failure never costs
# availability. Tags carry the version and the commit that produced them, so a
# candidate is never confused with the image currently running.
set -Eeuo pipefail

TARGET_VERSION="${1:?target version required}"
SERVICE_DIR="${COREKIT_SERVICE_DIR:?}"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:?}"
fail() { echo "$1" >&2; exit 1; }

info="$("$SERVICE_DIR/managed/version.sh")"
git_version="$(jq -r '.refs.n8n_git_version' <<<"$info")"
git_commit="$(jq -r '.refs.n8n_git_commit' <<<"$info")"

short_commit="$(git -C "$PROJECT_ROOT" rev-parse --short=12 HEAD)"
image="corekit/n8n:${TARGET_VERSION}-git${short_commit}"
runner_image="corekit/n8n-runners:${TARGET_VERSION}-git${short_commit}"

docker build --pull=false --tag "$image" "$SERVICE_DIR" >&2
docker build --pull=false --tag "$runner_image" "$SERVICE_DIR/runner" >&2

# Verify the image is the version claimed, rather than trusting the build.
[[ "$(docker run --rm --network none "$image" n8n --version | tr -d '\r')" == "$TARGET_VERSION" ]] \
  || fail "Candidate version verification failed"
[[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.n8n-git.version"}}' "$image")" == "$git_version" ]] \
  || fail "Candidate n8n-git version verification failed"
[[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.n8n-git.commit"}}' "$image")" == "$git_commit" ]] \
  || fail "Candidate n8n-git commit verification failed"
[[ "$(docker image inspect --format '{{index .Config.Labels "io.corekit.runner-for-n8n-version"}}' "$runner_image")" == "$TARGET_VERSION" ]] \
  || fail "Candidate runner version verification failed"
[[ "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$runner_image")" == "$TARGET_VERSION" ]] \
  || fail "Candidate upstream runner version verification failed"

jq -cn --arg i "$image" --arg r "$runner_image" '{images:{app:$i, runner:$r}}'
