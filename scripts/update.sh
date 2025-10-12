#!/bin/bash
set -e

# Source the utilities file
source "$(dirname "$0")/utils.sh"

# Set the compose command explicitly to use docker compose subcommand

# Navigate to the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Project root directory (one level up from scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
# Path to the apply_update.sh script
APPLY_UPDATE_SCRIPT="$SCRIPT_DIR/apply_update.sh"

# Check if apply update script exists
if [ ! -f "$APPLY_UPDATE_SCRIPT" ]; then
    log_error "Crucial update script $APPLY_UPDATE_SCRIPT not found. Cannot proceed."
    exit 1
fi

log_info "Starting update process..."

# Pull the latest repository changes
log_info "Pulling latest repository changes..."
# Check if git is installed
if ! command -v git &> /dev/null; then
    log_warning "'git' command not found. Skipping repository update."
    log_error "Cannot proceed with update without git. Please install git."
    exit 1
else
    # Change to project root for git pull
    cd "$PROJECT_ROOT" || { log_error "Failed to change directory to $PROJECT_ROOT"; exit 1; }
    git reset --hard HEAD || { log_warning "Failed to reset repository. Continuing update with potentially unreset local changes..."; }
    git pull || { log_warning "Failed to pull latest repository changes. Continuing update with potentially old version of apply_update.sh..."; }
fi

# Update Ubuntu packages before running apply_update
log_info "Updating system packages..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get upgrade -y
    log_info "System packages updated successfully."
else
    log_warning "'apt-get' not found. Skipping system package update. This is normal on non-debian systems."
fi

# Build Cal.com if selected (needed for updates)
# NOTE: This checks EXISTING .env to pre-build Cal.com if it was previously selected
log_info "Checking if Cal.com needs to be built..."
if grep -q "calcom" "$PROJECT_ROOT/.env" 2>/dev/null || [[ "$COMPOSE_PROFILES" == *"calcom"* ]]; then
    if [ -f "$SCRIPT_DIR/build_calcom.sh" ]; then
        log_info "Cal.com detected - preparing build..."
        bash "$SCRIPT_DIR/build_calcom.sh" || { log_error "Cal.com build preparation failed"; exit 1; }
        log_success "Cal.com build preparation complete!"
    else
        log_warning "Cal.com selected but build script not found"
    fi
else
    log_info "Cal.com not selected, skipping build"
fi

# Execute the rest of the update process using the (potentially updated) apply_update.sh
# This includes: 03_generate_secrets.sh --update, 04_wizard.sh, 05_run_services.sh
bash "$APPLY_UPDATE_SCRIPT"

# Workaround: Setup and initialize Vexa if selected
if grep -q "vexa" "$PROJECT_ROOT/.env" 2>/dev/null || [[ "$COMPOSE_PROFILES" == *"vexa"* ]]; then
    log_info "Vexa detected - running setup and initialization..."
    
    # Run setup script if vexa directory doesn't exist
    if [ ! -d "$PROJECT_ROOT/vexa" ]; then
        log_info "Vexa directory not found - running setup script..."
        bash "$SCRIPT_DIR/04a_setup_vexa.sh" || { log_warning "Vexa setup failed - continuing update..."; }
    fi
    
    # Ensure Vexa services are running
    if [ -d "$PROJECT_ROOT/vexa" ]; then
        cd "$PROJECT_ROOT/vexa" || true
        log_info "Building and starting Vexa services..."
        sudo make build 2>/dev/null || log_warning "Vexa build failed"
        sudo docker compose up -d 2>/dev/null || log_warning "Vexa start failed"
        cd "$PROJECT_ROOT" || true
        
        # Initialize Vexa if not already done
        bash "$SCRIPT_DIR/05a_init_vexa.sh" 2>/dev/null || log_info "Vexa already initialized"
    fi
fi

# Workaround: Ensure Supabase DB starts if Supabase was selected
if grep -q "supabase" "$PROJECT_ROOT/.env" 2>/dev/null; then
    log_info "Ensuring Supabase database container is running..."
    cd "$PROJECT_ROOT" || true
    sudo docker compose -p localai -f supabase/docker/docker-compose.yml up -d db 2>/dev/null || true
fi

# Workaround: Ensure LibreTranslate starts properly if selected
if grep -q "libretranslate" "$PROJECT_ROOT/.env" 2>/dev/null || docker ps -a | grep -q libretranslate; then
    log_info "Ensuring LibreTranslate container is running properly..."
    sudo docker compose -p localai stop libretranslate 2>/dev/null || true
    sudo docker compose -p localai rm -f libretranslate 2>/dev/null || true
    sudo docker compose -p localai --profile libretranslate up -d libretranslate 2>/dev/null || true
fi

log_info "Update script finished."
exit 0
