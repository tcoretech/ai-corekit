#!/bin/bash
set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ENV_FILE="$PROJECT_ROOT/.env"

# Check if vexa is in COMPOSE_PROFILES
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [[ "$COMPOSE_PROFILES" == *"vexa"* ]]; then
    log_info "Initializing Vexa with default user and API token..."

    cd "$PROJECT_ROOT/vexa"

    # Wait for Admin API to be ready
    log_info "Waiting for Vexa Admin API to be ready..."
    for i in {1..60}; do
        if curl -sf http://localhost:8057/ >/dev/null 2>&1; then
            log_success "Admin API is ready"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "Timeout waiting for Admin API"
            exit 1
        fi
        sleep 2
    done

    # Create default user via Admin API
    log_info "Creating default Vexa user..."
    USER_RESPONSE=$(curl -s -X POST http://localhost:8057/admin/users \
        -H "Content-Type: application/json" \
        -H "X-Admin-API-Key: ${VEXA_ADMIN_TOKEN}" \
        -d "{\"email\":\"${LANGFUSE_INIT_USER_EMAIL}\",\"name\":\"Admin\",\"max_concurrent_bots\":10}")

    USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id')

    if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
        log_error "Failed to create user. Response: $USER_RESPONSE"
        exit 1
    fi

    log_success "User created with ID: $USER_ID"

    # Check if API token already exists in .env
    EXISTING_TOKEN=$(grep "^VEXA_API_KEY=" "$ENV_FILE" 2>/dev/null | cut -d= -f2 | tr -d '"' | head -1 || echo "")

    if [ -n "$EXISTING_TOKEN" ] && [ "$EXISTING_TOKEN" != "null" ] && [ "$EXISTING_TOKEN" != "<not_set_in_env>" ]; then
        log_info "Existing API token found - keeping it to maintain workflow compatibility"
        API_TOKEN="$EXISTING_TOKEN"
    else
        # Create API token via Admin API
        log_info "Generating new API token for user..."
        TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8057/admin/users/${USER_ID}/tokens" \
            -H "X-Admin-API-Key: ${VEXA_ADMIN_TOKEN}")

        API_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')

        if [ -z "$API_TOKEN" ] || [ "$API_TOKEN" = "null" ]; then
            log_error "Failed to create token. Response: $TOKEN_RESPONSE"
            exit 1
        fi

        # Save token to .env for final report
        if ! grep -q "VEXA_API_KEY=" "$ENV_FILE"; then
            echo "VEXA_API_KEY=${API_TOKEN}" >> "$ENV_FILE"
        else
            sed -i "s/VEXA_API_KEY=.*/VEXA_API_KEY=${API_TOKEN}/" "$ENV_FILE"
        fi

        log_success "API token created and saved"
    fi

    log_success "Vexa initialization complete"

    cd "$PROJECT_ROOT"
else
    log_info "Vexa not selected - skipping initialization"
fi

exit 0
