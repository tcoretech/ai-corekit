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
mkdir -p ./config/local/servers

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

# Create README for local servers directory
if [ ! -f "./config/local/servers/README.md" ]; then
    log_info "Creating local servers directory README..."
    cat > ./config/local/servers/README.md << 'EOF'
# Local MCP Server Configurations

Add your MCP server configuration files in this directory. 
Each file (ending in .json) will be loaded and merged into the FastMCP configuration.

You can organize your MCP servers into separate files (e.g., `sqlite.json`, `filesystem.json`).
These files are git-ignored, making them safe for storing configuration that might vary by environment.

## Examples

We've populated this directory with some disabled examples. To use them:
1. Open the JSON file (e.g. `postgres.json`)
2. Change `"enabled": false` to `"enabled": true`
3. Ensure the required environment variables are set in your `.env` file (e.g. `POSTGRES_CONNECTION_STRING`)
EOF
fi

# Bootstrap examples if directory is empty (except for README)
if [ -d "./config/examples" ]; then
    # Create config/local/servers if not exists
    mkdir -p ./config/local/servers
    
    # Check if we should copy
    # We copy current examples even if directory is not empty, but we don't overwrite existing
    # This matches the user's intent to "bootstrap some of the mcp example from the agent-runner"
    
    log_info "Bootstrapping example MCP configurations..."
    for file in ./config/examples/*.json; do
        if [ -f "$file" ]; then
            basename=$(basename "$file")
            target="./config/local/servers/$basename"
            
            if [ ! -f "$target" ]; then
                log_info "Creating example: $basename"
                cp "$file" "$target"
                
                # Special handling for n8n-mcp: Inject token if available
                if [ "$basename" == "n8n.json" ]; then
                    # Try to find n8n-mcp env file in workflow-automation stack
                    N8N_MCP_ENV="../../../workflow-automation/n8n-mcp/.env"
                    if [ -f "$N8N_MCP_ENV" ]; then
                        # Extract token using grep/cut to avoid sourcing the whole file
                        TOKEN=$(grep "^N8N_MCP_TOKEN=" "$N8N_MCP_ENV" | cut -d"'" -f2)
                        
                        # If not found there, maybe it is in global env?
                        if [ -z "$TOKEN" ]; then
                            TOKEN=${N8N_MCP_TOKEN:-}
                        fi
                        
                        if [ -n "$TOKEN" ]; then
                            echo "Injecting N8N_MCP_TOKEN into $target"
                            sed -i "s/PLACEHOLDER_TOKEN/$TOKEN/" "$target"
                        fi
                    fi
                fi
            fi
        fi
    done
fi

# Set proper permissions for data directories
chmod -R 755 ./data

log_success "FastMCP Gateway preparation complete."
