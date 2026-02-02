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
PRUNE_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE_STOP=true
            shift
            ;;
        --prune)
            PRUNE_MODE=true
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

# Prune Mode Logic
if [ "$PRUNE_MODE" = true ]; then
    log_info "Checking for disabled services to prune..."
    load_env
    
    # Get enabled services
    IFS=',' read -ra ENABLED_SERVICES_ARRAY <<< "${COMPOSE_PROFILES:-}"
    # Create associative array for fast lookup
    declare -A ENABLED_MAP
    for s in "${ENABLED_SERVICES_ARRAY[@]}"; do
        ENABLED_MAP["$s"]=1
    done
    
    # Determine project name for checking status
    CHECK_PROJECT_NAME="localai"
    if [ -n "$PROJECT_OVERRIDE" ]; then
        CHECK_PROJECT_NAME="$PROJECT_OVERRIDE"
    else
        CHECK_PROJECT_NAME=$(get_stack_project_name "$STACK_NAME")
    fi

    # 1. Build Map: Docker Service Name -> Corekit Service Name
    declare -A DOCKER_TO_COREKIT
    
    # Find all docker-compose.yml files
    # We use a loop to handle paths with spaces safely, though unlikely here
    while IFS= read -r file; do
        # Extract corekit service name from path
        # Path: .../services/<category>/<service_name>/docker-compose.yml
        corekit_svc=$(basename "$(dirname "$file")")
        
        # Extract docker service names from file
        # Look for lines starting with 2 spaces and a name followed by colon
        docker_svcs=$(grep "^  [a-zA-Z0-9_-]\+:" "$file" | sed 's/^  //;s/://')
        
        for d_svc in $docker_svcs; do
            DOCKER_TO_COREKIT["$d_svc"]="$corekit_svc"
        done
    done < <(find "$PROJECT_ROOT/services" -mindepth 3 -maxdepth 3 -name "docker-compose.yml")

    # 2. Get Running Docker Services
    RUNNING_DOCKER_SVCS=$(docker ps --filter "label=com.docker.compose.project=$CHECK_PROJECT_NAME" --format "{{.Label \"com.docker.compose.service\"}}" | sort -u)
    
    # 3. Check against Enabled Services
    declare -A SERVICES_TO_STOP_MAP
    
    for d_svc in $RUNNING_DOCKER_SVCS; do
        lk_svc="${DOCKER_TO_COREKIT[$d_svc]}"
        
        if [ -n "$lk_svc" ]; then
            # Check if enabled
            if [ -z "${ENABLED_MAP[$lk_svc]}" ]; then
                if [ -z "${SERVICES_TO_STOP_MAP[$lk_svc]}" ]; then
                    log_info "[$lk_svc] Found running service '$d_svc' but '$lk_svc' is disabled. Scheduling for stop."
                    SERVICES_TO_STOP+=("$lk_svc")
                    SERVICES_TO_STOP_MAP["$lk_svc"]=1
                    USE_SPECIFIC=true
                fi
            fi
        fi
    done
fi

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
    if [ "$PRUNE_MODE" = true ]; then
        log_info "No disabled services found running."
        exit 0
    fi
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
#     service_dir=$(find_service_path "$service")
#     if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
#         COMPOSE_FILES+=("-f" "$service_dir/docker-compose.yml")
#     fi
# done

# Load project name
PROJECT_NAME="localai"
if [ -n "$PROJECT_OVERRIDE" ]; then
    PROJECT_NAME="$PROJECT_OVERRIDE"
else
    # If stopping specific services, try to detect the correct project name for each service
    # This is tricky because we are iterating over services, but PROJECT_NAME is global for the loop if we don't change it.
    # However, the loop below uses PROJECT_NAME.
    
    # If we are using the default stack (core), PROJECT_NAME is localai.
    # But ssh-tunnel is in host-ssh stack, which has project_name: host-ssh.
    
    # If the user didn't specify a stack, we default to core/localai.
    # This is why ssh-tunnel (running in host-ssh project) is not found when we try to stop it with project localai.
    
    # We should probably detect the stack for each service if we are in specific mode and no stack was explicitly provided?
    # Or just rely on the user to provide the stack?
    # Better: Auto-detect stack if not provided.
    
    if [ "$STACK_NAME" = "core" ]; then
         # We are using default stack.
         # We will let the loop handle project name detection if possible, or just use the detected stack's project.
         # But the loop uses $PROJECT_NAME.
         
         # Let's just set it to localai for now, and override it inside the loop if we can detect a different stack.
         PROJECT_NAME=$(get_stack_project_name "$STACK_NAME")
    else
         PROJECT_NAME=$(get_stack_project_name "$STACK_NAME")
    fi
fi

# Run Docker Compose Stop/Down
# If specific services, use 'stop' or 'rm -s -v'? 'down' removes network if no services left.
# 'docker compose down' usually takes down the whole project if no services specified.
# If services specified, it stops and removes them.

if [ "$USE_SPECIFIC" = true ]; then
    log_info "Stopping specific services..."
    for service in "${SERVICES_TO_STOP[@]}"; do
        # Auto-detect project name for this service if we are using default stack and no override
        CURRENT_PROJECT_NAME="$PROJECT_NAME"
        if [ -z "$PROJECT_OVERRIDE" ] && [ "$STACK_NAME" = "core" ]; then
            detected_stack=$(find_stack_for_service "$service")
            if [ -n "$detected_stack" ]; then
                detected_project=$(get_stack_project_name "$detected_stack")
                if [ -n "$detected_project" ]; then
                    CURRENT_PROJECT_NAME="$detected_project"
                    log_info "[$service] Auto-detected project: $CURRENT_PROJECT_NAME (from stack: $detected_stack)"
                fi
            fi
        fi

        log_info "Looking for service: $service in $PROJECT_ROOT/services"
        service_dir=$(find_service_path "$service")
        log_info "Found service dir: $service_dir"
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
             # Force enable all profiles to ensure the service is actually stopped/removed
             COMPOSE_PROFILES="*" docker compose -p "$CURRENT_PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down
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
        service_dir=$(find_service_path "$service")
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
             # Force enable all profiles to ensure the service is actually stopped/removed
             COMPOSE_PROFILES="*" docker compose -p "$PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" down
        fi
    done
fi

# Cleanup Hooks (Optional)
for service in "${SERVICES_TO_STOP[@]}"; do
    service_dir=$(find_service_path "$service")
    if [ -n "$service_dir" ] && [ -f "$service_dir/cleanup.sh" ]; then
        log_info "[$service] Running cleanup hook..."
        (cd "$service_dir" && bash "cleanup.sh")
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
