#!/bin/bash
# FastMCP Preparation Script
# Creates required directories and sets up configuration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

source "$SCRIPT_DIR/../../../lib/utils/logging.sh"

log_info "Preparing FastMCP Gateway service..."

# Create data directories
mkdir -p ./data/workspace
mkdir -p ./data/memory
mkdir -p ./config/local

# Create local servers config if it doesn't exist
if [ ! -f "./config/local/servers.json" ]; then
    log_info "Creating local servers configuration template..."
    cat > ./config/local/servers.json << 'EOF'
{
  "servers": {
    "_comment": "Add your custom MCP server configurations here",
    "_comment2": "This file is git-ignored and takes precedence over config/servers.json"
  }
}
EOF
fi

# Set proper permissions for data directories
chmod -R 755 ./data

log_success "FastMCP Gateway preparation complete."
