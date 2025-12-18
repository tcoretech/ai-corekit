#!/bin/bash
set -e

# Source the utilities file
source "$(dirname "$0")/../utils/logging.sh"

# Get the directory where the script resides
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
ENV_FILE="$PROJECT_ROOT/config/.env.global"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    log_error "The .env file ('$ENV_FILE') was not found."
    exit 1
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

echo
log_info "Service Access Credentials. Save this information securely!"

# Check for jq
if ! command -v jq &> /dev/null; then
    log_warning "jq is not installed. Output will be limited."
fi

# Iterate over enabled profiles
IFS=',' read -ra PROFILES <<< "$COMPOSE_PROFILES"

for profile in "${PROFILES[@]}"; do
    # Find services with this profile
    # We search for service.json files
    find "$PROJECT_ROOT/services" -name "service.json" | while read service_json; do
        # Check if profile matches
        if [ -f "$service_json" ]; then
            svc_profile=$(jq -r '.profile // empty' "$service_json" 2>/dev/null || true)
            if [ "$svc_profile" == "$profile" ]; then
                svc_name=$(jq -r '.name // "Unknown"' "$service_json")
                svc_desc=$(jq -r '.description // ""' "$service_json")
                svc_port=$(jq -r '.port // ""' "$service_json")
                svc_path=$(dirname "$service_json")
                
                echo "---------------------------------------------------"
                echo "Service: $svc_name"
                echo "Description: $svc_desc"
                
                # Get Host/IP
                # Use a cached IP if possible or just localhost/IP
                # HOST_IP=$(curl -s ifconfig.me || echo "localhost")
                # Avoid external call if possible for speed
                HOST_IP="<your-server-ip>"
                
                if [ -n "$svc_port" ]; then
                    echo "URL: http://$HOST_IP:$svc_port"
                fi
                
                # Try to find credentials in .env
                if [ -f "$svc_path/.env" ]; then
                    echo "Credentials (from .env):"
                    # Naive grep for common credential patterns
                    grep -E "USER|PASS|KEY|TOKEN|SECRET|EMAIL|ADMIN" "$svc_path/.env" | grep -v "^#" | sed 's/^/  /'
                fi
                echo "---------------------------------------------------"
            fi
        fi
    done
done

log_success "Report complete."
