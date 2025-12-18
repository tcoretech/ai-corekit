#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# 1. Global Configuration
log_info "Initializing global configuration..."
bash "$PROJECT_ROOT/lib/config/global_secrets.sh"

# Load current globals (now that they are generated)
load_all_env "$PROJECT_ROOT/config"

# 2. Service Secrets Generation
log_info "Generating secrets for all services..."

# Find all secrets.sh files
find "$PROJECT_ROOT/services" -name "secrets.sh" | sort | while read -r secret_script; do
    service_name=$(basename "$(dirname "$secret_script")")
    log_info "Processing $service_name..."
    
    # Run the script
    if ! bash "$secret_script"; then
        log_error "Failed to generate secrets for $service_name"
    fi
done

log_success "Global configuration and service secrets generation complete."
