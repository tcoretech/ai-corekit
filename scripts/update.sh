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

# Setup Dex for Outline if selected
log_info "Checking if Outline needs Dex configuration..."
if grep -q "outline" "$PROJECT_ROOT/.env" 2>/dev/null || [[ "$COMPOSE_PROFILES" == *"outline"* ]]; then
    if [ -f "$SCRIPT_DIR/setup_dex_config.sh" ]; then
        log_info "Outline detected - generating Dex configuration..."
        bash "$SCRIPT_DIR/setup_dex_config.sh" || { log_warning "Dex configuration failed - continuing update..."; }
        log_success "Dex configuration complete!"
    else
        log_warning "Outline selected but Dex setup script not found"
    fi
else
    log_info "Outline not selected, skipping Dex setup"
fi

# Execute the rest of the update process using the (potentially updated) apply_update.sh
# This includes: 03_generate_secrets.sh --update, 04_wizard.sh, 05_run_services.sh
bash "$APPLY_UPDATE_SCRIPT"

# Generate Homepage configuration if Homepage is running
if docker ps | grep -q homepage; then
    log_info "Updating Homepage dashboard configuration..."
    if [ -f "$SCRIPT_DIR/generate_homepage_config.sh" ]; then
        bash "$SCRIPT_DIR/generate_homepage_config.sh" || log_warning "Homepage config generation failed - continuing..."
    fi
fi

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

# Workaround: Fix Seafile HTTPS/CSRF issue if selected
if grep -q "seafile" "$PROJECT_ROOT/.env" 2>/dev/null || sudo docker ps | grep -q seafile; then
    log_info "Fixing Seafile HTTPS/CSRF configuration..."
    
    # Waitng until Seafile is ready
    sleep 30
    
    # Executing Init script
    sudo docker exec seafile bash /init-fix.sh 2>/dev/null || true
    
    # Restart Seafile
    sudo docker compose -p localai restart seafile 2>/dev/null || true
    
    log_success "Seafile HTTPS/CSRF configuration fixed"
fi

# ============================================================================
# Export Options
# ============================================================================

# Load environment variables from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Function to check if a profile is active (from 06_final_report.sh)
is_profile_active() {
    local profile_to_check="$1"
    if [ -z "$COMPOSE_PROFILES" ]; then
        return 1
    fi
    if [[ ",$COMPOSE_PROFILES," == *",$profile_to_check,"* ]]; then
        return 0
    else
        return 1
    fi
}

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "📋 CREDENTIALS EXPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if Vaultwarden is installed/active
VAULTWARDEN_AVAILABLE=false
if is_profile_active "vaultwarden"; then
    VAULTWARDEN_AVAILABLE=true
fi

# ============================================================================
# If Vaultwarden is NOT available: Simple prompt
# ============================================================================

if [ "$VAULTWARDEN_AVAILABLE" = false ]; then
    echo "All credentials were displayed above."
    echo
    read -p "📥 Do you want to export credentials to file for download? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/export_credentials.sh" -d
    else
        echo
        echo "You can export credentials later anytime with:"
        echo "  sudo bash ./scripts/export_credentials.sh"
        echo
    fi

# ============================================================================
# If Vaultwarden IS available: Full menu
# ============================================================================

else
    echo "Available exports:"
    echo
    echo "  1) Vaultwarden JSON (password manager import)"
    echo "  2) All Credentials TXT (readable text file)"
    echo "  3) Both (recommended)"
    echo "  4) Skip exports"
    echo
    
    read -p "Select option (1-4): " -n 1 -r EXPORT_CHOICE
    echo
    echo
    
    case $EXPORT_CHOICE in
        1)
            log_info "Generating Vaultwarden JSON export..."
            bash "$SCRIPT_DIR/08_generate_vaultwarden_json.sh" -d
            ;;
        2)
            log_info "Generating Credentials TXT export..."
            bash "$SCRIPT_DIR/export_credentials.sh" -d
            ;;
        3)
            log_info "Step 1/2: Generating Vaultwarden JSON export..."
            bash "$SCRIPT_DIR/08_generate_vaultwarden_json.sh" -d
            echo
            log_info "Step 2/2: Generating Credentials TXT export..."
            echo "⏱️  Starting in 5 seconds..."
            sleep 5
            bash "$SCRIPT_DIR/export_credentials.sh" -d
            ;;
        4)
            echo
            log_info "Exports skipped. You can run them later:"
            echo "  • Vaultwarden: sudo bash ./scripts/08_generate_vaultwarden_json.sh"
            echo "  • Credentials: sudo bash ./scripts/export_credentials.sh"
            echo
            ;;
        *)
            echo
            log_warning "Invalid selection. Skipping exports."
            echo
            log_info "You can run exports later:"
            echo "  • Vaultwarden: sudo bash ./scripts/08_generate_vaultwarden_json.sh"
            echo "  • Credentials: sudo bash ./scripts/export_credentials.sh"
            echo
            ;;
    esac
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_info "Update script finished."
exit 0
