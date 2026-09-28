#!/usr/bin/env bash
# Recreate this service's containers with the candidate images.
#
# Only this service's containers are touched: --no-deps keeps shared
# infrastructure out of the blast radius.
set -Eeuo pipefail

TARGET_VERSION="${1:?target version required}"
SERVICE_DIR="${COREKIT_SERVICE_DIR:?}"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:?}"
IMAGES_JSON="${COREKIT_CANDIDATE_IMAGES:-}"
[[ -n "$IMAGES_JSON" ]] || { echo "No candidate images supplied" >&2; exit 1; }

export N8N_MANAGED_IMAGE="$(jq -r '.images.app' <<<"$IMAGES_JSON")"
export N8N_MANAGED_RUNNER_IMAGE="$(jq -r '.images.runner' <<<"$IMAGES_JSON")"

project_name="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' n8n 2>/dev/null || true)"
[[ -n "$project_name" ]] || project_name=localai

# Drain any workers before replacing the main container.
mapfile -t old_workers < <(docker ps -a --filter label=com.docker.compose.service=n8n-worker --format '{{.Names}}' | sort)
if (( ${#old_workers[@]} > 0 )); then
  docker stop --time 60 "${old_workers[@]}" >/dev/null
fi

docker compose -p "$project_name" --project-directory "$SERVICE_DIR" \
  --env-file "$PROJECT_ROOT/services/data-services/postgres/.env" \
  --env-file "$SERVICE_DIR/.env" -f "$SERVICE_DIR/docker-compose.yml" \
  up -d --no-deps n8n n8n-runner >&2

if (( ${#old_workers[@]} > 0 )); then
  docker rm "${old_workers[@]}" >/dev/null 2>&1 || true
fi
