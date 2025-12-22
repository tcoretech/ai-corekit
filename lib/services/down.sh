#!/bin/bash
set -e

# Source utilities
# Resolve real path if symlinked
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"
source "$PROJECT_ROOT/lib/utils/stack.sh"
CONFIG_DIR="$PROJECT_ROOT/config"
GLOBAL_ENV="$CONFIG_DIR/.env.global"

# Helper: Load Environment
load_env() {
    # Save PROJECT_ROOT before loading env, as env might overwrite it with empty string
    local SAVED_PROJECT_ROOT="$PROJECT_ROOT"
    
    # Pass SERVICES_TO_STOP to load_all_envs for optimization
    load_all_envs "${SERVICES_TO_STOP[@]}"
    
    # Export all loaded variables
    for key in "${!ALL_ENV_VARS[@]}"; do
        export "$key"="${ALL_ENV_VARS[$key]}"
    done
    
    # Restore PROJECT_ROOT if it was clobbered
    if [ -z "$PROJECT_ROOT" ] && [ -n "$SAVED_PROJECT_ROOT" ]; then
        PROJECT_ROOT="$SAVED_PROJECT_ROOT"
    fi
}


# Parse Arguments
SERVICES_TO_STOP=()
USE_SPECIFIC=false
STACK_NAME="core"
PROJECT_OVERRIDE=""
FORCE_STOP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE_STOP=true
            shift
            ;;
        -s|--stack)
            shift
            if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
            STACK_NAME="$1"
            stack_services=$(get_stack_services "$STACK_NAME")
            if [ $? -eq 0 ]; then
                for s in $stack_services; do SERVICES_TO_STOP+=("$s"); done
            fi
            USE_SPECIFIC=true
            shift
            ;;
        -p|--project)
            shift
            if [ -z "$1" ]; then log_error "Project name required"; exit 1; fi
            PROJECT_OVERRIDE="$1"
            shift
            ;;
        *)
            SERVICES_TO_STOP+=("$1")
            USE_SPECIFIC=true
            shift
            ;;
    esac
done

# Determine services to stop
if [ "$USE_SPECIFIC" = true ]; then
    # Use provided list
    sorted_unique_ids=($(echo "${SERVICES_TO_STOP[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    SERVICES_TO_STOP=("${sorted_unique_ids[@]}")
    
    # Note: We do NOT disable profiles yet, because docker compose needs the profile enabled to stop the service if it uses profiles.
else
    # Use configured profiles (stop everything enabled)
    if [ -z "$COMPOSE_PROFILES" ]; then
        # Try to load envs first to see if COMPOSE_PROFILES is set there
        load_env
        if [ -z "$COMPOSE_PROFILES" ]; then
             log_warning "No services enabled in configuration."
             exit 0
        fi
    fi
    IFS=',' read -ra SERVICES_TO_STOP <<< "$COMPOSE_PROFILES"
fi

# Load envs AFTER determining services (optimized)
load_env

if [ ${#SERVICES_TO_STOP[@]} -eq 0 ]; then
    log_error "No services to stop."
    exit 1
fi

# Check for Critical Services
if [ -n "$CRITICAL_SERVICES" ]; then
    IFS=',' read -ra CRITICAL_LIST <<< "$CRITICAL_SERVICES"
    for critical in "${CRITICAL_LIST[@]}"; do
        for stop_svc in "${SERVICES_TO_STOP[@]}"; do
            if [ "$critical" == "$stop_svc" ]; then
                if [ "$FORCE_STOP" != true ]; then
                    log_error "Service '$stop_svc' is marked as CRITICAL. Use --force to stop it."
                    exit 1
                else
                    log_warning "Stopping CRITICAL service '$stop_svc' (Force enabled)."
                fi
            fi
        done
    done
fi

log_info "Stopping services: ${SERVICES_TO_STOP[*]}"

# Construct Docker Compose Command
# COMPOSE_FILES=()

# for service in "${SERVICES_TO_STOP[@]}"; do
#     service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service" -type d | head -n 1)
#     if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
#         COMPOSE_FILES+=("-f" "$service_dir/docker-compose.yml")
#     fi
# done

# Load project name
PROJECT_NAME="localai"
if [ -n "$PROJECT_OVERRIDE" ]; then
    PROJECT_NAME="$PROJECT_OVERRIDE"
else
    PROJECT_NAME=$(get_stack_project_name "$STACK_NAME")
fi

# Run Docker Compose Stop/Down
# If specific services, use 'stop' or 'rm -s -v'? 'down' removes network if no services left.
# 'docker compose down' usually takes down the whole project if no services specified.
# If services specified, it stops and removes them.

if [ "$USE_SPECIFIC" = true ]; then
    log_info "Stopping specific services..."
    for service in "${SERVICES_TO_STOP[@]}"; do
        log_info "Looking for service: $service in $PROJECT_ROOT/services"
        service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service" -type d | head -n 1)
        log_info "Found service dir: $service_dir"
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
             docker compose -p "$PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down
        else
             log_error "Service directory or docker-compose.yml not found for $service"
        fi
    done
else
    log_info "Stopping all enabled services..."
    # For down, we might want to iterate too if we want to be consistent, 
    # but 'down' on the project might work if we pass all files?
    # But we changed the project directory context.
    # So we should probably iterate to be safe and consistent with 'up'.
    
    for service in "${SERVICES_TO_STOP[@]}"; do
        service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service" -type d | head -n 1)
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
             docker compose -p "$PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down
        fi
    done
fi

# Cleanup Hooks (Optional)
for service in "${SERVICES_TO_STOP[@]}"; do
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -n "$service_dir" ] && [ -f "$service_dir/cleanup.sh" ]; then
        log_info "[$service] Running cleanup hook..."
        bash "$service_dir/cleanup.sh"
    fi
done

# Disable profiles after stopping
if [ "$USE_SPECIFIC" = true ]; then
    log_info "Updating enabled profiles..."
    for s in "${SERVICES_TO_STOP[@]}"; do
        disable_service_profile "$s"
    done
fi

log_success "Services stopped."
