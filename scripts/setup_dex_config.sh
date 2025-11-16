
#!/bin/bash

set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    log_error ".env file not found!"
    exit 1
fi

# Check if Dex template exists
if [ ! -f "$PROJECT_ROOT/dex/config-template.yaml" ]; then
    log_error "Dex config template not found!"
    exit 1
fi

log_info "Generating Dex configuration..."

# Copy template to actual config
cp "$PROJECT_ROOT/dex/config-template.yaml" "$PROJECT_ROOT/dex/config.yaml"

# Replace placeholders
sed -i "s|DEX_HOSTNAME_PLACEHOLDER|${DEX_HOSTNAME}|g" "$PROJECT_ROOT/dex/config.yaml"
sed -i "s|OUTLINE_HOSTNAME_PLACEHOLDER|${OUTLINE_HOSTNAME}|g" "$PROJECT_ROOT/dex/config.yaml"
sed -i "s|OUTLINE_OIDC_CLIENT_SECRET_PLACEHOLDER|${OUTLINE_OIDC_CLIENT_SECRET}|g" "$PROJECT_ROOT/dex/config.yaml"
sed -i "s|ADMIN_EMAIL_PLACEHOLDER|${DEX_ADMIN_EMAIL}|g" "$PROJECT_ROOT/dex/config.yaml"
sed -i "s|ADMIN_PASSWORD_HASH_PLACEHOLDER|${DEX_ADMIN_PASSWORD_HASH}|g" "$PROJECT_ROOT/dex/config.yaml"

log_success "Dex configuration generated successfully!"
log_info "Admin login: ${DEX_ADMIN_EMAIL} / ${DEX_ADMIN_PASSWORD}"
