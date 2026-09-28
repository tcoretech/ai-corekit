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

# Compose selects nothing unless the profile is named, and WEBHOOK_URL is built
# from N8N_HOSTNAME, which lives in the global config rather than this service's
# .env. Both must be in the environment before compose runs.
export COMPOSE_PROFILES=n8n
if [[ -f "$PROJECT_ROOT/config/.env.global" ]]; then
  hostname_value="$(sed -n 's/^N8N_HOSTNAME=//p' "$PROJECT_ROOT/config/.env.global" | tail -n 1)"
  hostname_value="${hostname_value%$'\r'}"
  hostname_value="${hostname_value#\"}"; hostname_value="${hostname_value%\"}"
  hostname_value="${hostname_value#\'}"; hostname_value="${hostname_value%\'}"
  [[ -n "$hostname_value" ]] && export N8N_HOSTNAME="$hostname_value"
fi

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
