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
SERVICES_TO_STOP=()
USE_SPECIFIC=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stack)
            shift
            if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
            stack_services=$(get_stack_services "$1")
            if [ $? -eq 0 ]; then
                for s in $stack_services; do SERVICES_TO_STOP+=("$s"); done
            fi
            USE_SPECIFIC=true
            shift
            ;;
        *)
            SERVICES_TO_STOP+=("$1")
            USE_SPECIFIC=true
            shift
            ;;
    esac
done

load_env

# Determine services to stop
if [ "$USE_SPECIFIC" = true ]; then
    # Use provided list
    sorted_unique_ids=($(echo "${SERVICES_TO_STOP[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    SERVICES_TO_STOP=("${sorted_unique_ids[@]}")
else
    # Use configured profiles (stop everything enabled)
    if [ -z "$COMPOSE_PROFILES" ]; then
        log_warning "No services enabled in configuration."
        exit 0
    fi
    IFS=',' read -ra SERVICES_TO_STOP <<< "$COMPOSE_PROFILES"
fi

if [ ${#SERVICES_TO_STOP[@]} -eq 0 ]; then
    log_error "No services to stop."
    exit 1
fi

log_info "Stopping services: ${SERVICES_TO_STOP[*]}"

# Construct Docker Compose Command
COMPOSE_FILES=("-f" "$PROJECT_ROOT/docker-compose.yml")

for service in "${SERVICES_TO_STOP[@]}"; do
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
        COMPOSE_FILES+=("-f" "$service_dir/docker-compose.yml")
    fi
done

# Load project name
PROJECT_NAME="localai"
if [ -f "$CONFIG_DIR/stacks/core.yaml" ]; then
    PROJECT_NAME=$(grep "^project_name:" "$CONFIG_DIR/stacks/core.yaml" | cut -d':' -f2 | tr -d ' "')
fi

# Run Docker Compose Stop/Down
# If specific services, use 'stop' or 'rm -s -v'? 'down' removes network if no services left.
# 'docker compose down' usually takes down the whole project if no services specified.
# If services specified, it stops and removes them.

if [ "$USE_SPECIFIC" = true ]; then
    log_info "Stopping specific services..."
    docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FILES[@]}" stop "${SERVICES_TO_STOP[@]}"
    # Optional: remove containers
    # docker compose ... rm -f "${SERVICES_TO_STOP[@]}"
else
    log_info "Stopping all enabled services..."
    docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FILES[@]}" down
fi

# Cleanup Hooks (Optional)
for service in "${SERVICES_TO_STOP[@]}"; do
    service_dir=$(find "$PROJECT_ROOT/services" -name "$service" -type d | head -n 1)
    if [ -n "$service_dir" ] && [ -f "$service_dir/cleanup.sh" ]; then
        log_info "[$service] Running cleanup hook..."
        bash "$service_dir/cleanup.sh"
    fi
done

log_success "Services stopped."
