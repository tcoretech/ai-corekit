#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

# Parse Arguments
NO_RESET=false
UPDATE_SYSTEM=false

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
        *)
            ;;
    esac
done

log_info "Starting AI LaunchKit update..."

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

log_success "Update complete. Run 'launchkit up' to apply changes and restart services."

