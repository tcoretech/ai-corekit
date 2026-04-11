#!/bin/bash
# OpenClaw startup hook - fix permissions and seed minimal config
# This runs AFTER the container starts

SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

log_info "Fixing OpenClaw volume permissions..."

# Fix ownership and seed minimal config needed for LAN-bound gateway
docker exec -u root openclaw sh -c '
    chown -R node:node /home/node/.openclaw

    # Create minimal config if none exists - just enough to start the gateway
    # The user can then run onboarding interactively to configure everything else
    CONFIG_FILE=/home/node/.openclaw/openclaw.json
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOFCONFIG
{
  "gateway": {
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    }
  }
}
EOFCONFIG
        chown node:node "$CONFIG_FILE"
        echo "Created minimal gateway config"
    fi
' 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "OpenClaw bootstrapped"
else
    log_warning "Could not bootstrap OpenClaw (container may not be ready)"
fi
