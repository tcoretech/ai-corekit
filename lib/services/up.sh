#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"
CONFIG_DIR="$PROJECT_ROOT/config"
GLOBAL_ENV="$CONFIG_DIR/.env.global"

# Helper: Load Environment
load_env() {
    if [ -f "$GLOBAL_ENV" ]; then
        set -a
        source "$GLOBAL_ENV"
        set +a
    fi
    # Also load root .env for backward compatibility or overrides
    if [ -f "$PROJECT_ROOT/.env" ]; then
        set -a
        source "$PROJECT_ROOT/.env"
        set +a
    fi
}

# Helper: Get Services from Stack
get_stack_services() {
    local stack="$1"
    local stack_file="$CONFIG_DIR/stacks/$stack.yaml"
    if [ -f "$stack_file" ]; then
        sed -n '/^services:/,$p' "$stack_file" | grep '^\s*-\s*' | sed 's/^\s*-\s*//'
    else
        log_error "Stack file not found: $stack"
        return 1
    fi
}

# Parse Arguments
SERVICES_TO_START=()
USE_SPECIFIC=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stack)
            shift
            if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
            stack_services=$(get_stack_services "$1")
            if [ $? -eq 0 ]; then
                for s in $stack_services; do SERVICES_TO_START+=("$s"); done
            fi
            USE_SPECIFIC=true
            shift
            ;;
        *)
            SERVICES_TO_START+=("$1")
            USE_SPECIFIC=true
            shift
            ;;
    esac
done

load_env

# Determine services to run
if [ "$USE_SPECIFIC" = true ]; then
    # Use provided list
    # Deduplicate
    sorted_unique_ids=($(echo "${SERVICES_TO_START[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    SERVICES_TO_START=("${sorted_unique_ids[@]}")
else
    # Use configured profiles
    if [ -z "$COMPOSE_PROFILES" ]; then
        log_warning "No services enabled in configuration. Use 'launchkit config' or 'launchkit enable'."
        exit 0
    fi
    IFS=',' read -ra SERVICES_TO_START <<< "$COMPOSE_PROFILES"
fi

if [ ${#SERVICES_TO_START[@]} -eq 0 ]; then
    log_error "No services to start."
    exit 1
fi

log_info "Starting services: ${SERVICES_TO_START[*]}"

# Load project name
PROJECT_NAME="localai" # Default
if [ -f "$CONFIG_DIR/stacks/core.yaml" ]; then
    PROJECT_NAME=$(grep "^project_name:" "$CONFIG_DIR/stacks/core.yaml" | cut -d':' -f2 | tr -d ' "')
fi
export PROJECT_NAME

# 1. Prepare & Build
log_info "Running preparation and build hooks..."
for service in "${SERVICES_TO_START[@]}"; do
    # Find service directory
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -z "$service_dir" ]; then
        log_warning "Service directory not found for: $service"
        continue
    fi
    
    # Secrets Generation
    if [ -f "$service_dir/secrets.sh" ]; then
        log_info "[$service] Checking secrets..."
        bash "$service_dir/secrets.sh"
    fi

    # Prepare Hook
    if [ -f "$service_dir/prepare.sh" ]; then
        log_info "[$service] Running prepare hook..."
        bash "$service_dir/prepare.sh"
    fi
    
    # Build Hook
    if [ -f "$service_dir/build.sh" ]; then
        log_info "[$service] Running build hook..."
        bash "$service_dir/build.sh"
    fi
done

# 2. Construct Docker Compose Command
COMPOSE_FILES=("-f" "$PROJECT_ROOT/docker-compose.yml")

for service in "${SERVICES_TO_START[@]}"; do
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
        COMPOSE_FILES+=("-f" "$service_dir/docker-compose.yml")
    fi
done

# 3. Run Docker Compose Up
log_info "Bringing up services..."
docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FILES[@]}" up -d "${SERVICES_TO_START[@]}"

# 4. Startup Hooks
log_info "Running startup hooks..."
for service in "${SERVICES_TO_START[@]}"; do
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -n "$service_dir" ] && [ -f "$service_dir/startup.sh" ]; then
        log_info "[$service] Running startup hook..."
        bash "$service_dir/startup.sh"
    fi
done

log_success "Services started successfully."
