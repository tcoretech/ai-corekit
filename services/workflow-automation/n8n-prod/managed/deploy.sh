#!/usr/bin/env bash
# Recreate this service's containers. --no-deps keeps its database out of the
# restart: the application is replaced, the data is not touched.
set -Eeuo pipefail
SERVICE_DIR="${COREKIT_SERVICE_DIR:?}"
IMAGES_JSON="${COREKIT_CANDIDATE_IMAGES:?No candidate images supplied}"

# shellcheck disable=SC1091
set -a; . "$SERVICE_DIR/.env"; set +a
export N8N_PROD_IMAGE="$(jq -r '.images.app' <<<"$IMAGES_JSON")"
export N8N_PROD_RUNNER_IMAGE="$(jq -r '.images.runner' <<<"$IMAGES_JSON")"

project_name="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' n8n-prod 2>/dev/null || true)"
[[ -n "$project_name" ]] || project_name="n8n-prod"

COMPOSE_PROFILES=n8n-prod docker compose -p "$project_name" \
  --project-directory "$SERVICE_DIR" -f "$SERVICE_DIR/docker-compose.yml" \
  up -d --no-deps n8n-prod n8n-prod-runner >&2
