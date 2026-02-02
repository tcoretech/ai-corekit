#!/bin/bash
# Source the healthcheck utility library
source "$PROJECT_ROOT/lib/utils/healthcheck.sh"
source .env

# Extract service name
SERVICE_NAME=$(grep '"name":' service.json | cut -d '"' -f 4)
INTERNAL_PORT="${SERVICE_PORT:-3000}"

# Verify service health using the updater sidecar
check_internal_service_http "$SERVICE_NAME" "$INTERNAL_PORT" "${SERVICE_NAME}-updater"
