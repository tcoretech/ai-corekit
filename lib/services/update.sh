#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

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
    
    # Load all secrets/envs from services
    load_all_envs
    
    # Export all loaded variables
    for key in "${!ALL_ENV_VARS[@]}"; do
        export "$key"="${ALL_ENV_VARS[$key]}"
    done
}

# Parse Arguments
NO_RESET=false
UPDATE_SYSTEM=false
FORCE=false
UPDATE_CONTAINERS=true

for arg in "$@"; do
    case $arg in
        --no-reset)
            NO_RESET=true
            shift
            ;;
        --system)
            UPDATE_SYSTEM=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-containers)
            UPDATE_CONTAINERS=false
            shift
            ;;
        *)
            ;;
    esac
done

log_info "Starting AI CoreKit update..."

# 1. Self Update (Git)
if [ "$NO_RESET" = true ]; then
    log_info "Pulling latest repository changes (--no-reset mode: preserving local changes)..."
else
    log_info "Pulling latest repository changes..."
fi

if ! command -v git &> /dev/null; then
    log_warning "'git' command not found. Skipping repository update."
else
    cd "$PROJECT_ROOT"
    
    if [ "$NO_RESET" = false ]; then
        # Check for local changes
        if [ -n "$(git status --porcelain)" ]; then
            log_warning "Local changes detected in the repository."
            git status --short
            
            if [[ -t 0 ]]; then
                echo ""
                read -p "⚠️  WARNING: Update will DISCARD all local changes. Proceed? [y/N]: " CONFIRM
                if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                    log_info "Update aborted. Use 'corekit update --no-reset' to pull changes without resetting."
                    exit 0
                fi
            else
                log_info "Non-interactive terminal detected. Proceeding with reset..."
            fi
        fi
        git reset --hard HEAD || log_warning "Failed to reset repository."
    fi
    
    git pull || log_warning "Failed to pull latest changes."
fi

# 2. System Update (Optional)
if [ "$UPDATE_SYSTEM" = true ]; then
    if [ -f "$PROJECT_ROOT/lib/system/system_update.sh" ]; then
        bash "$PROJECT_ROOT/lib/system/system_update.sh"
    else
        log_error "System update script not found."
    fi
fi

# 3. Container Update
if [ "$UPDATE_CONTAINERS" = true ]; then
    log_info "Updating containers..."
    load_env
    
    # Prune disabled services
    log_info "Pruning disabled services..."
    bash "$PROJECT_ROOT/lib/services/down.sh" --prune
    
    # Get enabled services
    IFS=',' read -ra ENABLED_SERVICES <<< "${COMPOSE_PROFILES:-}"
    
    # Get critical services
    IFS=',' read -ra CRITICAL_LIST <<< "${CRITICAL_SERVICES:-}"
    
    for service in "${ENABLED_SERVICES[@]}"; do
        if [ -z "$service" ]; then continue; fi
        
        is_critical=false
        for critical in "${CRITICAL_LIST[@]}"; do
            if [ "$critical" == "$service" ]; then
                is_critical=true
                break
            fi
        done
        
        if [ "$is_critical" = true ] && [ "$FORCE" = false ]; then
            log_warning "Skipping CRITICAL service '$service'. Use --force to update it."
            continue
        fi
        
        log_info "Updating service: $service"
        
        # Find service directory
        service_dir=$(find_service_path "$service")
        
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
             log_info "Pulling images for $service..."
             # We use service directory as project directory to ensure relative paths work correctly
             docker compose -f "$service_dir/docker-compose.yml" --project-directory "$service_dir" pull
             
             log_info "Recreating containers for $service..."
             # Call up.sh to handle startup logic (networks, etc)
             bash "$PROJECT_ROOT/lib/services/up.sh" "$service"
        else
            log_warning "Service directory or compose file not found for $service"
        fi
    done
fi

log_success "Update complete."

