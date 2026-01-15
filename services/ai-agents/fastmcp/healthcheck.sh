#!/bin/bash
# FastMCP Gateway Health Check
# Verifies the gateway is responding correctly

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/../../../lib/utils/logging.sh"
source "$SCRIPT_DIR/.env" 2>/dev/null || true

PORT="${FASTMCP_PORT:-8100}"
MAX_RETRIES=12
RETRY_DELAY=5

log_info "Checking FastMCP Gateway health..."

for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf "http://localhost:${PORT}/health" > /dev/null 2>&1; then
        log_success "FastMCP Gateway is healthy and responding on port ${PORT}"

        # Show server info
        INFO=$(curl -s "http://localhost:${PORT}/info" 2>/dev/null || echo "{}")
        if [ -n "$INFO" ] && [ "$INFO" != "{}" ]; then
            log_info "Server info:"
            echo "$INFO" | python3 -m json.tool 2>/dev/null || echo "$INFO"
        fi

        exit 0
    fi

    if [ $i -lt $MAX_RETRIES ]; then
        log_warning "Attempt $i/$MAX_RETRIES failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    fi
done

log_error "FastMCP Gateway health check failed after $MAX_RETRIES attempts"
exit 1
