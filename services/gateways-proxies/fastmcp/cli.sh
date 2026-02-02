#!/bin/bash
#
# FastMCP Gateway CLI
# Usage: corekit run fastmcp <command> [args]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
EXAMPLES_DIR="$CONFIG_DIR/examples"
LOCAL_SERVERS_DIR="$CONFIG_DIR/local/servers"

# Source logging utilities if available
if [ -f "$SCRIPT_DIR/../../lib/utils/logging.sh" ]; then
    source "$SCRIPT_DIR/../../lib/utils/logging.sh"
else
    # Fallback logging
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_warning() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Ensure local servers directory exists
mkdir -p "$LOCAL_SERVERS_DIR"

# Get server status (enabled/disabled) from a JSON file
get_server_status() {
    local file="$1"
    local name="$2"
    if [ -f "$file" ]; then
        jq -r --arg name "$name" '.[$name].enabled // false' "$file" 2>/dev/null || echo "false"
    else
        echo "false"
    fi
}

# Get server description from a JSON file
get_server_description() {
    local file="$1"
    local name="$2"
    if [ -f "$file" ]; then
        jq -r --arg name "$name" '.[$name].description // "No description"' "$file" 2>/dev/null || echo "No description"
    else
        echo "No description"
    fi
}

# List all available servers
cmd_list() {
    echo "FastMCP Gateway - Available Servers"
    echo "===================================="
    echo ""

    # Collect all servers from local/servers/*.json
    echo "Local Servers (config/local/servers/):"
    echo "--------------------------------------"
    local found_local=false
    for file in "$LOCAL_SERVERS_DIR"/*.json; do
        [ -f "$file" ] || continue
        [ "$(basename "$file")" = "README.md" ] && continue

        # Get server name (first key in the JSON)
        local name=$(jq -r 'keys[0]' "$file" 2>/dev/null)
        [ -z "$name" ] || [ "$name" = "null" ] && continue

        local enabled=$(get_server_status "$file" "$name")
        local desc=$(get_server_description "$file" "$name")

        if [ "$enabled" = "true" ]; then
            printf "  ✓ %-20s %s\n" "$name" "$desc"
        else
            printf "  ○ %-20s %s\n" "$name" "$desc"
        fi
        found_local=true
    done

    if [ "$found_local" = "false" ]; then
        echo "  (none configured)"
    fi

    echo ""
    echo "Available Examples (config/examples/):"
    echo "--------------------------------------"
    for file in "$EXAMPLES_DIR"/*.json; do
        [ -f "$file" ] || continue

        local name=$(jq -r 'keys[0]' "$file" 2>/dev/null)
        [ -z "$name" ] || [ "$name" = "null" ] && continue

        local desc=$(get_server_description "$file" "$name")

        # Check if already in local
        if [ -f "$LOCAL_SERVERS_DIR/$(basename "$file")" ]; then
            printf "  · %-20s %s (already in local)\n" "$name" "$desc"
        else
            printf "  + %-20s %s\n" "$name" "$desc"
        fi
    done

    echo ""
    echo "Legend: ✓ enabled, ○ disabled, + available to enable, · in local"
}

# Find file containing a server by name
find_server_file() {
    local name="$1"
    local search_dir="$2"

    for file in "$search_dir"/*.json; do
        [ -f "$file" ] || continue
        local sname=$(jq -r 'keys[0]' "$file" 2>/dev/null)
        if [ "$sname" = "$name" ]; then
            echo "$file"
            return 0
        fi
    done
    return 1
}

# Check for required environment variables and prompt to set them
check_required_env_vars() {
    local config_file="$1"
    local name="$2"
    local env_file="$SCRIPT_DIR/.env"
    local missing_vars=()

    # Source existing env file
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file" 2>/dev/null || true
        set +a
    fi

    # Extract env vars from config
    local env_vars=$(jq -r --arg name "$name" '.[$name].env // {} | keys[]' "$config_file" 2>/dev/null)

    for var in $env_vars; do
        # Extract the source var name from ${VAR} or ${VAR:-default} syntax
        local source_var=$(jq -r --arg name "$name" --arg var "$var" '.[$name].env[$var]' "$config_file" 2>/dev/null)
        # Parse ${VAR_NAME} or ${VAR_NAME:-default}
        local actual_var=$(echo "$source_var" | sed -n 's/.*\${\([^}:-]*\).*/\1/p')

        if [ -n "$actual_var" ]; then
            # Check if the variable is set and non-empty
            local current_value="${!actual_var:-}"
            if [ -z "$current_value" ]; then
                missing_vars+=("$actual_var")
            fi
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo ""
        log_warning "This server requires the following environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""

        # Check if we're in an interactive terminal
        if [ -t 0 ]; then
            echo "Would you like to set them now? [y/N] "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                for var in "${missing_vars[@]}"; do
                    echo -n "Enter value for $var: "
                    read -r value
                    if [ -n "$value" ]; then
                        # Add or update the variable in .env file
                        if grep -q "^${var}=" "$env_file" 2>/dev/null; then
                            # Update existing
                            sed -i "s|^${var}=.*|${var}='${value}'|" "$env_file"
                        else
                            # Append new
                            echo "${var}='${value}'" >> "$env_file"
                        fi
                        log_success "Set $var in $env_file"
                    fi
                done
            else
                echo ""
                echo "You can set these later in: $env_file"
                echo "Then restart the gateway: corekit restart fastmcp"
            fi
        else
            echo "Set these in: $env_file"
            echo "Then restart: corekit restart fastmcp"
        fi
        return 1
    fi
    return 0
}

# Enable a server
cmd_enable() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "Server name required. Usage: corekit run fastmcp enable <server-name>"
        echo ""
        echo "Available servers:"
        for file in "$EXAMPLES_DIR"/*.json "$LOCAL_SERVERS_DIR"/*.json; do
            [ -f "$file" ] || continue
            local sname=$(jq -r 'keys[0]' "$file" 2>/dev/null)
            [ -z "$sname" ] || [ "$sname" = "null" ] && continue
            echo "  - $sname"
        done
        exit 1
    fi

    # Search for server by name in files
    local local_file=$(find_server_file "$name" "$LOCAL_SERVERS_DIR")
    local example_file=$(find_server_file "$name" "$EXAMPLES_DIR")
    local dest_file="$LOCAL_SERVERS_DIR/${name}.json"

    # Check if server exists in local
    if [ -n "$local_file" ]; then
        # Update enabled to true
        local tmp=$(mktemp)
        jq --arg name "$name" '.[$name].enabled = true' "$local_file" > "$tmp" && mv "$tmp" "$local_file"
        log_success "Enabled server: $name"
        dest_file="$local_file"
    elif [ -n "$example_file" ]; then
        # Copy from examples and enable
        local tmp=$(mktemp)
        jq --arg name "$name" '.[$name].enabled = true' "$example_file" > "$tmp" && mv "$tmp" "$dest_file"
        log_success "Copied from examples and enabled: $name"
    else
        log_error "Server '$name' not found in examples or local servers."
        echo ""
        echo "Available servers:"
        for file in "$EXAMPLES_DIR"/*.json; do
            [ -f "$file" ] || continue
            local sname=$(jq -r 'keys[0]' "$file" 2>/dev/null)
            [ -z "$sname" ] || [ "$sname" = "null" ] && continue
            echo "  - $sname"
        done
        exit 1
    fi

    # Check for required env vars and offer to set them
    check_required_env_vars "$dest_file" "$name" || true

    echo ""
    echo "Restart the gateway to apply changes:"
    echo "  corekit restart fastmcp"
}

# Disable a server
cmd_disable() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "Server name required. Usage: corekit run fastmcp disable <server-name>"
        exit 1
    fi

    # Search for server by name in local files
    local local_file=$(find_server_file "$name" "$LOCAL_SERVERS_DIR")

    if [ -z "$local_file" ]; then
        log_error "Server '$name' not found in local servers."
        exit 1
    fi

    # Update enabled to false
    local tmp=$(mktemp)
    jq --arg name "$name" '.[$name].enabled = false' "$local_file" > "$tmp" && mv "$tmp" "$local_file"
    log_success "Disabled server: $name"

    echo ""
    echo "Restart the gateway to apply changes:"
    echo "  corekit restart fastmcp"
}

# Show gateway status
cmd_status() {
    local port="${FASTMCP_PORT:-8100}"

    echo "FastMCP Gateway Status"
    echo "======================"
    echo ""

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^fastmcp$"; then
        echo "Container: running"
    else
        echo "Container: stopped"
        return 1
    fi

    # Check health endpoint
    local health=$(curl -s "http://localhost:${port}/health" 2>/dev/null)
    if [ -n "$health" ]; then
        echo "Health: $(echo "$health" | jq -r '.status // "unknown"')"
        echo "Tools: $(echo "$health" | jq -r '.tools_count // "unknown"')"
    else
        echo "Health: unreachable"
    fi

    # Show info
    local info=$(curl -s "http://localhost:${port}/info" 2>/dev/null)
    if [ -n "$info" ]; then
        echo ""
        echo "Enabled Features:"
        echo "$info" | jq -r '.features | to_entries[] | select(.value == true) | "  ✓ \(.key)"'
    fi
}

# Show help
cmd_help() {
    echo "FastMCP Gateway CLI"
    echo ""
    echo "Usage: corekit run fastmcp <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list              List all available and configured servers"
    echo "  enable <name>     Enable an MCP server"
    echo "  disable <name>    Disable an MCP server"
    echo "  status            Show gateway status"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  corekit run fastmcp list"
    echo "  corekit run fastmcp enable context7"
    echo "  corekit run fastmcp disable postgres"
    echo "  corekit run fastmcp status"
}

# Main dispatch
case "${1:-help}" in
    list|ls)
        cmd_list
        ;;
    enable)
        shift
        cmd_enable "$@"
        ;;
    disable)
        shift
        cmd_disable "$@"
        ;;
    status)
        cmd_status
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
