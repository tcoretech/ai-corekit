#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/utils_secrets.sh"

# 1. Global Configuration
log_info "Initializing global configuration..."
bash "$SCRIPT_DIR/global_secrets.sh"

# Load current globals (now that they are generated)
load_all_env "$SCRIPT_DIR"

# 2. Service Secrets Generation
log_info "Generating secrets for all services..."

# Find all secrets.sh files
find "$SCRIPT_DIR/../services" -name "secrets.sh" | sort | while read -r secret_script; do
    service_name=$(basename "$(dirname "$secret_script")")
    log_info "Processing $service_name..."
    
    # Run the script
    if ! bash "$secret_script"; then
        log_error "Failed to generate secrets for $service_name"
    fi
done

# 3. Aggregate to root .env for Docker Compose compatibility
log_info "Aggregating secrets to root .env..."
ROOT_ENV="$SCRIPT_DIR/../.env"

# Preserve COMPOSE_PROFILES if it exists
CURRENT_PROFILES=""
if [[ -f "$ROOT_ENV" ]]; then
    CURRENT_PROFILES=$(grep "^COMPOSE_PROFILES=" "$ROOT_ENV" || echo "")
fi

# Start with global env
cp "$GLOBAL_ENV" "$ROOT_ENV"

# Restore COMPOSE_PROFILES
if [[ -n "$CURRENT_PROFILES" ]]; then
    echo "" >> "$ROOT_ENV"
    echo "# Preserved Profiles" >> "$ROOT_ENV"
    echo "$CURRENT_PROFILES" >> "$ROOT_ENV"
fi

# Append all service envs
find "$SCRIPT_DIR/../services" -name ".env" | sort | while read -r service_env; do
    # Skip if it's the global env (though it shouldn't be in services/)
    echo "" >> "$ROOT_ENV"
    echo "### From $(basename "$(dirname "$service_env")") ###" >> "$ROOT_ENV"
    # Filter out comments and empty lines to keep it clean? Or just cat.
    # Just cat is safer to preserve structure, but we might want to avoid overwriting globals if they are redefined?
    # Docker compose uses the LAST definition.
    # So if service defines VAR, it overrides global. This is correct inheritance.
    cat "$service_env" >> "$ROOT_ENV"
done

log_success "Global configuration and service secrets generation complete."
