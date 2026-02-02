#!/bin/bash

# Service Removal Script
# Usage: rm.sh [service_names...]

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/stack.sh"

# Helper: Load Environment
load_env() {
    if [ -f "$CONFIG_DIR/.env.global" ]; then
        set -a
        source "$CONFIG_DIR/.env.global"
        set +a
    fi
    if [ -f "$PROJECT_ROOT/.env" ]; then
        set -a
        source "$PROJECT_ROOT/.env"
        set +a
    fi
}

# Parse arguments
SERVICES_TO_REMOVE=()
TARGET_PROJECT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stack)
            shift
            if [ -n "$1" ]; then
                STACK_NAME="$1"
                # Get services from stack
                stack_services=$(get_stack_services "$STACK_NAME")
                TARGET_PROJECT=$(get_stack_project_name "$STACK_NAME")
                for s in $stack_services; do
                    SERVICES_TO_REMOVE+=("$s")
                done
                shift
            fi
            ;;
        *)
            SERVICES_TO_REMOVE+=("$1")
            shift
            ;;
    esac
done

if [ ${#SERVICES_TO_REMOVE[@]} -eq 0 ]; then
    log_error "No services specified to remove."
    exit 1
fi

load_env

log_info "Removing services: ${SERVICES_TO_REMOVE[*]}"

for service in "${SERVICES_TO_REMOVE[@]}"; do
    # Find service directory
    # Try to find exact match first
    service_dir=$(find_service_path "$service")
    
    # If not found, try to find by service name in docker-compose.yml
    if [ -z "$service_dir" ]; then
        # This is expensive, but necessary if the directory name doesn't match the service name
        service_dir=$(grep -r "services:" "$PROJECT_ROOT/services" | grep "/docker-compose.yml" | while read file; do
            dir=$(dirname "$file")
            if grep -q "^\s*$service:" "$file"; then
                echo "$dir"
                break
            fi
        done | head -n 1)
    fi

    if [ -z "$service_dir" ]; then
        log_warning "Service directory not found for: $service"
        continue
    fi
    
    if [ -f "$service_dir/docker-compose.yml" ]; then
        log_info "[$service] Removing containers, volumes, and images..."
        
        # Determine project name (try to find what project it might be running under, or just use service name if we can't find it)
        # Ideally we should know the project name, but for removal, we might need to be aggressive.
        # If we use the service directory as project directory, docker compose usually defaults project name to directory name.
        # But we usually set project name explicitly in up.sh.
        
        # Strategy:
        # 1. Try to stop/remove using the standard project name logic if possible?
        # No, 'corekit rm' implies we want to nuke it.
        # We will use 'docker compose down' with the service's compose file.
        # We need to know the project name it was started with.
        # If we don't know, we might miss it.
        
        # However, 'corekit up' uses stack project names.
        # If we don't know the stack, we might have trouble finding the running containers.
        
        # Let's try to find running containers for this service to guess the project name.
        # We search for containers with the label com.docker.compose.service matching the service name
        # OR matching the service name defined in the compose file (which might be different from the corekit service name)
        
        # Get the internal docker service name from the compose file
        # Assuming it's the first service defined or we can grep it?
        # Actually, we can just try to down using the file.
        
        # But to find running containers, we need the service name.
        # If we are removing 'cloudflared', but the service in compose is 'cloudflared', it matches.
        # If we are removing 'web-tunnel', but the service in compose is 'cloudflared', we need to search for 'cloudflared'.
        
        # Extract service names from compose file
        compose_services=$(grep "^  [a-zA-Z0-9_-]\+:" "$service_dir/docker-compose.yml" | sed 's/^  //;s/://')
        
        for compose_service in $compose_services; do
            project_names=$(docker ps --filter "label=com.docker.compose.service=$compose_service" --format "{{.Label \"com.docker.compose.project\"}}" | sort -u)
            
            if [ -n "$TARGET_PROJECT" ]; then
                log_info "[$service] Attempting removal from target project '$TARGET_PROJECT'..."
                # Enable all profiles to ensure services are found
                COMPOSE_PROFILES="*" docker compose -p "$TARGET_PROJECT" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down -v --rmi all
            fi

            if [ -n "$project_names" ]; then
                for proj in $project_names; do
                    log_info "[$service] Found running in project: $proj"
                    COMPOSE_PROFILES="*" docker compose -p "$proj" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down -v --rmi all
                done
            fi
        done
        
        # Fallback if no running containers found
        if [ -z "$project_names" ] && [ -z "$TARGET_PROJECT" ]; then
            # If not running, we can't easily know the project name to remove orphaned containers.
            # We will try to remove from all known projects defined in stacks.
            
            log_info "[$service] No running containers found. Attempting removal from all known stack projects..."

            # Get all known projects
            all_projects=$(get_all_stack_projects)
            
            for proj in $all_projects; do
                log_info "[$service] Attempting removal from project '$proj'..."
                COMPOSE_PROFILES="*" docker compose -p "$proj" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down -v --rmi all
            done
        fi
        
        log_success "[$service] Removed."
    else
        log_warning "[$service] No docker-compose.yml found."
    fi
done

# Disable profiles after removal
log_info "Updating enabled profiles..."
for s in "${SERVICES_TO_REMOVE[@]}"; do
    disable_service_profile "$s"
done
