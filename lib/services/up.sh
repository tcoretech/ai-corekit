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

# Debug
# echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
# echo "DEBUG: PROJECT_ROOT=$PROJECT_ROOT"

source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"
source "$PROJECT_ROOT/lib/utils/stack.sh"
CONFIG_DIR="$PROJECT_ROOT/config"
GLOBAL_ENV="$CONFIG_DIR/.env.global"

# Helper: Load Environment
load_env() {
    # Save PROJECT_ROOT before loading env, as env might overwrite it with empty string
    local SAVED_PROJECT_ROOT="$PROJECT_ROOT"
    
    load_all_envs
    
    # Export all loaded variables
    for key in "${!ALL_ENV_VARS[@]}"; do
        export "$key"="${ALL_ENV_VARS[$key]}"
    done
    
    # Mark environment as loaded to prevent re-scanning in subprocesses
    export COREKIT_ENV_LOADED=true
    
    # Restore PROJECT_ROOT if it was clobbered
    if [ -z "$PROJECT_ROOT" ] && [ -n "$SAVED_PROJECT_ROOT" ]; then
        PROJECT_ROOT="$SAVED_PROJECT_ROOT"
    fi
}


# Parse Arguments
SERVICES_TO_START=()
USE_SPECIFIC=false
STACK_NAME="core"
PROJECT_OVERRIDE=""
FORCE_RECREATE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stack)
            shift
            if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
            STACK_NAME="$1"
            stack_services=$(get_stack_services "$STACK_NAME")
            if [ $? -eq 0 ]; then
                for s in $stack_services; do SERVICES_TO_START+=("$s"); done
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
        --force-recreate)
            FORCE_RECREATE=true
            shift
            ;;
        *)
            SERVICES_TO_START+=("$1")
            USE_SPECIFIC=true
            shift
            ;;
    esac
done

# Suppress orphan warnings
export COMPOSE_IGNORE_ORPHANS=True

# Auto-detect stack if using specific services and default stack
if [ "$USE_SPECIFIC" = true ] && [ "$STACK_NAME" = "core" ] && [ ${#SERVICES_TO_START[@]} -gt 0 ]; then
    # Check the first service
    first_service="${SERVICES_TO_START[0]}"
    detected_stack=$(find_stack_for_service "$first_service")
    if [ -n "$detected_stack" ] && [ "$detected_stack" != "core" ]; then
        log_info "Auto-detected stack '$detected_stack' for service '$first_service'. Switching context."
        STACK_NAME="$detected_stack"
    fi
fi

# Helper: Resolve Dependencies
resolve_dependencies() {
    local service="$1"
    local service_dir=$(find_service_path "$service")
    
    if [ -n "$service_dir" ] && [ -f "$service_dir/service.json" ]; then
        # Use python3 to parse JSON if available (closest to jq without jq)
        if command -v python3 &>/dev/null; then
            python3 -c "import json; f=open('$service_dir/service.json'); d=json.load(f).get('depends_on', []); print(' '.join(d))" 2>/dev/null
        else
            # Fallback: legacy grep parsing (flaky)
            # Extract depends_on array using grep/sed/tr since we don't have jq guaranteed
            # This is a simple parser and assumes standard formatting
            local deps=$(grep -A 10 '"depends_on":' "$service_dir/service.json" | grep '"' | grep -v "depends_on" | tr -d ' ",' | tr '\n' ' ')
            echo "$deps"
        fi
    fi
}

# Determine services to run
if [ "$USE_SPECIFIC" = true ]; then
    # Resolve dependencies recursively
    # Simple iterative approach to resolve dependencies
    # Max depth 5 to prevent infinite loops
    for i in {1..5}; do
        NEW_SERVICES=()
        for s in "${SERVICES_TO_START[@]}"; do
            deps=$(resolve_dependencies "$s")
            # Add dependencies BEFORE the service
            for d in $deps; do
                NEW_SERVICES+=("$d")
            done
            NEW_SERVICES+=("$s")
        done
        SERVICES_TO_START=("${NEW_SERVICES[@]}")
    done

    # Deduplicate preserving order (keep first occurrence)
    # This ensures dependencies (added before) stay before the services that need them
    UNIQUE_SERVICES=()
    declare -A SEEN_SERVICES
    for s in "${SERVICES_TO_START[@]}"; do
        if [ -z "${SEEN_SERVICES[$s]}" ]; then
            UNIQUE_SERVICES+=("$s")
            SEEN_SERVICES[$s]=1
        fi
    done
    SERVICES_TO_START=("${UNIQUE_SERVICES[@]}")

    # Validate services exist before enabling
    for s in "${SERVICES_TO_START[@]}"; do
        # Use find to locate service directory
        service_dir=$(find_service_path "$s")
        if [ -z "$service_dir" ]; then
            log_error "Service '$s' not found. Please check the service name."
            exit 1
        fi
    done

    load_env

    # Update profiles
    log_info "Updating enabled profiles..."
    for s in "${SERVICES_TO_START[@]}"; do
        enable_service_profile "$s"
    done
    
    # Reload COMPOSE_PROFILES to ensure docker compose sees the changes
    if [ -f "$GLOBAL_ENV" ]; then
        export COMPOSE_PROFILES=$(grep "^COMPOSE_PROFILES=" "$GLOBAL_ENV" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
else
    load_env

    # Use configured profiles
    if [ -z "$COMPOSE_PROFILES" ]; then
        log_warning "No services a in configuration. Use 'corekit config' or 'corekit enable'."
        exit 0
    fi
    IFS=',' read -ra SERVICES_TO_START <<< "$COMPOSE_PROFILES"
    
    # Prune disabled services
    log_info "Pruning disabled services..."
    bash "$PROJECT_ROOT/lib/services/down.sh" --prune
fi

if [ ${#SERVICES_TO_START[@]} -eq 0 ]; then
    log_error "No services to start."
    exit 1
fi

log_info "Starting services: ${SERVICES_TO_START[*]}"

# Load project name
if [ -n "$PROJECT_OVERRIDE" ]; then
    PROJECT_NAME="$PROJECT_OVERRIDE"
else
    PROJECT_NAME=$(get_stack_project_name "$STACK_NAME")
fi
export PROJECT_NAME

# 1. Prepare & Build
log_info "Running preparation and build hooks..."
for service in "${SERVICES_TO_START[@]}"; do
    # Find service directory
    # Look for services/<category>/<service>
    # Use find with explicit path to avoid empty PROJECT_ROOT issues
    if [ -z "$PROJECT_ROOT" ]; then
        log_error "PROJECT_ROOT is not defined."
        exit 1
    fi
    
    service_dir=$(find_service_path "$service")
    
    if [ -z "$service_dir" ]; then
        log_warning "Service directory not found for: $service"
        continue
    fi
    
    # Load Service Environment
    if [ -f "$service_dir/.env" ]; then
        log_info "[$service] Loading environment variables..."
        set -a
        source "$service_dir/.env"
        set +a
    fi
    
    # Secrets Generation
    if [ -f "$service_dir/secrets.sh" ]; then
        log_info "[$service] Checking secrets..."
        (cd "$service_dir" && bash "secrets.sh")
        
        # Re-load environment to pick up generated secrets
        if [ -f "$service_dir/.env" ]; then
            log_info "[$service] Reloading environment variables..."
            set -a
            source "$service_dir/.env"
            set +a
        fi
    fi

    # Prepare Hook
    if [ -f "$service_dir/prepare.sh" ]; then
        log_info "[$service] Running prepare hook..."
        (cd "$service_dir" && bash "prepare.sh")
    fi
    
    # Build Hook
    if [ -f "$service_dir/build.sh" ]; then
        log_info "[$service] Running build hook..."
        (cd "$service_dir" && bash "build.sh")
    fi
done

# 2. Run Docker Compose Up
log_info "Bringing up services..."

FAILED_SERVICES=()
set +e # Disable exit on error to capture failures

for service in "${SERVICES_TO_START[@]}"; do
    service_dir=$(find_service_path "$service")
    if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
        log_info "[$service] Starting..."
        # Run docker compose with project directory set to service directory
        # This allows relative paths in docker-compose.yml to work correctly
        COMPOSE_ARGS="-d"
        if [ "$FORCE_RECREATE" = true ]; then
            COMPOSE_ARGS="$COMPOSE_ARGS --force-recreate"
        fi
        
        if ! docker compose -p "$PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" up $COMPOSE_ARGS; then
            log_error "[$service] Failed to start."
            FAILED_SERVICES+=("$service")
        fi
    fi
done

set -e # Re-enable exit on error

# 3. Startup Hooks
log_info "Running startup hooks..."
for service in "${SERVICES_TO_START[@]}"; do
    # Skip if failed
    if [[ " ${FAILED_SERVICES[*]} " =~ " ${service} " ]]; then
        log_warning "[$service] Skipping startup hook due to start failure."
        continue
    fi

    service_dir=$(find_service_path "$service")
    if [ -n "$service_dir" ] && [ -f "$service_dir/startup.sh" ]; then
        log_info "[$service] Running startup hook..."
        if ! (cd "$service_dir" && bash "startup.sh"); then
             log_warning "[$service] Startup hook failed."
        fi
    fi

    # Healthcheck Hook
    if [ -n "$service_dir" ] && [ -f "$service_dir/healthcheck.sh" ]; then
        log_info "[$service] Running healthcheck..."
        if ! (cd "$service_dir" && bash "healthcheck.sh"); then
             log_warning "[$service] Healthcheck failed."
        fi
    fi
done

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    log_error "Services started with errors. Failed: ${FAILED_SERVICES[*]}"
    exit 1
else
    log_success "Services started successfully."
fi
