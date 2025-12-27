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
    local SAVED_PROJECT_ROOT="$PROJECT_ROOT"
    load_all_envs
    for key in "${!ALL_ENV_VARS[@]}"; do
        export "$key"="${ALL_ENV_VARS[$key]}"
    done
    export LAUNCHKIT_ENV_LOADED=true
    if [ -z "$PROJECT_ROOT" ] && [ -n "$SAVED_PROJECT_ROOT" ]; then
        PROJECT_ROOT="$SAVED_PROJECT_ROOT"
    fi
}

# Parse Arguments
SERVICES_TO_BUILD=()
USE_SPECIFIC=false
STACK_NAME="core"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stack)
            shift
            if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
            STACK_NAME="$1"
            stack_services=$(get_stack_services "$STACK_NAME")
            if [ $? -eq 0 ]; then
                for s in $stack_services; do SERVICES_TO_BUILD+=("$s"); done
            fi
            USE_SPECIFIC=true
            shift
            ;;
        *)
            SERVICES_TO_BUILD+=("$1")
            USE_SPECIFIC=true
            shift
            ;;
    esac
done

# If no services specified, show usage
if [ ${#SERVICES_TO_BUILD[@]} -eq 0 ]; then
    log_error "No services specified. Usage: launchkit build <service>... or launchkit build -s <stack>"
    exit 1
fi

load_env

log_info "Building services: ${SERVICES_TO_BUILD[*]}"

for service in "${SERVICES_TO_BUILD[@]}"; do
    log_info "Building service: $service"
    
    # Find service directory
    service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service" -type d | head -n 1)
    
    if [ -z "$service_dir" ]; then
        log_warning "Service directory not found for: $service"
        continue
    fi
    
    # Switch context
    pushd "$service_dir" > /dev/null
    
    # Load service env
    if [ -f ".env" ]; then
        set -a
        source ".env"
        set +a
    fi
    
    # Run prepare hook (often needed for build context)
    if [ -f "prepare.sh" ]; then
        log_info "[$service] Running prepare hook..."
        bash "prepare.sh"
    fi
    
    # Run build hook or docker compose build
    if [ -f "build.sh" ]; then
        log_info "[$service] Running custom build script..."
        bash "build.sh"
    else
        log_info "[$service] Running docker compose build..."
        docker compose build
    fi
    
    popd > /dev/null
    log_success "[$service] Build complete."
done
