#!/bin/bash
set -e

# Source utilities
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

log_info "Running Vexa startup tasks..."

# Wait for Admin API to be ready
log_info "Waiting for Vexa Admin API to be ready..."
for i in {1..60}; do
    if curl -sf http://localhost:8057/ >/dev/null 2>&1; then
        log_success "Admin API is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "Timeout waiting for Admin API"
        # Don't exit, just warn, maybe it's already initialized or running in a different mode
    fi
    sleep 2
done

# Only proceed if we have the admin token
if [ -z "$VEXA_ADMIN_TOKEN" ]; then
    log_warn "VEXA_ADMIN_TOKEN not set. Skipping user creation."
    exit 0
fi

# Check if we need to create a user
# We use the email from LANGFUSE_INIT_USER_EMAIL or a default
USER_EMAIL="${LANGFUSE_INIT_USER_EMAIL:-admin@example.com}"

log_info "Checking if user $USER_EMAIL exists..."
# This is a simplified check, ideally we'd list users and grep
# But for now, let's try to create and handle error if exists, or just skip if we have an API key already?
# The legacy script created a user every time? No, it just ran.

# Create default user via Admin API
log_info "Creating/Ensuring default Vexa user..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8057/admin/users \
    -H "Content-Type: application/json" \
    -H "X-Admin-API-Key: ${VEXA_ADMIN_TOKEN}" \
    -d "{\"email\":\"${USER_EMAIL}\",\"name\":\"Admin\",\"max_concurrent_bots\":10}")

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id')

if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    # Maybe user already exists?
    log_warn "Failed to create user or user already exists. Response: $USER_RESPONSE"
    # Try to find user ID if possible? 
    # For now, we assume if we can't create, we might not be able to get a token for them easily without listing.
else
    log_success "User created/found with ID: $USER_ID"

    # Check if we have an API key in env
    if [ -z "$VEXA_API_KEY" ]; then
        log_info "Generating new API token for user..."
        TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8057/admin/users/${USER_ID}/tokens" \
            -H "X-Admin-API-Key: ${VEXA_ADMIN_TOKEN}")

        API_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')

        if [ -n "$API_TOKEN" ] && [ "$API_TOKEN" != "null" ]; then
            # Update .env file
            update_env_var "$SCRIPT_DIR/.env" "VEXA_API_KEY" "$API_TOKEN"
            log_success "VEXA_API_KEY generated and saved to .env"
        else
            log_error "Failed to create token. Response: $TOKEN_RESPONSE"
        fi
    else
        log_info "VEXA_API_KEY already set."
    fi
fi

log_success "Vexa startup complete."
