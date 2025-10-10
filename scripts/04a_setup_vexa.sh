#!/bin/bash

set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ENV_FILE="$PROJECT_ROOT/.env"

# Check if vexa is in COMPOSE_PROFILES
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [[ "$COMPOSE_PROFILES" == *"vexa"* ]]; then
    log_info "Vexa selected - Setting up Vexa repository..."
    
    cd "$PROJECT_ROOT"
    
    # Clone Vexa repository if it doesn't exist
    if [ ! -d "vexa" ]; then
        log_info "Cloning Vexa repository..."
        git clone https://github.com/Vexa-ai/vexa.git vexa || {
            log_error "Failed to clone Vexa repository"
            exit 1
        }
        
        cd vexa
        log_info "Initializing git submodules..."
        git submodule update --init --recursive || {
            log_error "Failed to initialize submodules"
            exit 1
        }
    else
        log_info "Vexa repository already exists"
        cd vexa
    fi
    
    # Patch docker-compose.yml to use AI LaunchKit's network
    log_info "Configuring Vexa to use AI LaunchKit's Docker network..."
    
    if ! grep -q "external: true" docker-compose.yml; then
        # Backup original
        cp docker-compose.yml docker-compose.yml.backup
        
        # Replace network configuration
        sed -i '/^networks:/,/^[^ ]/ {
            /^networks:/a\
  vexa_default:\
    name: localai_default\
    external: true
            /^  vexa_default:/d
            /^    driver: bridge/d
        }' docker-compose.yml
        
        log_success "Vexa network configuration updated"
    else
        log_info "Vexa network already configured"
    fi
    
    # Create .env file for Vexa from AI LaunchKit variables
    log_info "Creating Vexa .env file..."
    
    cat > .env << EOF
# Vexa Configuration (managed by AI LaunchKit)
ADMIN_API_TOKEN=${VEXA_ADMIN_TOKEN}
LANGUAGE_DETECTION_SEGMENTS=10
VAD_FILTER_THRESHOLD=0.5
WHISPER_MODEL_SIZE=${VEXA_WHISPER_MODEL:-base}
DEVICE_TYPE=${VEXA_WHISPER_DEVICE:-cpu}
BOT_IMAGE_NAME=vexa-bot:dev

# Exposed Host Ports (internal only, not exposed externally)
API_GATEWAY_HOST_PORT=8056
ADMIN_API_HOST_PORT=8057
TRAEFIK_WEB_HOST_PORT=9090
TRAEFIK_DASHBOARD_HOST_PORT=8085
TRANSCRIPTION_COLLECTOR_HOST_PORT=8123
POSTGRES_HOST_PORT=5438

# WhisperLive Configuration
WL_MAX_CLIENTS=10
CONSUL_ENABLE=true
CONSUL_HTTP_ADDR=http://consul:8500
EOF
    
    log_success "Vexa .env file created"
    
    cd "$PROJECT_ROOT"
    log_info "Vexa setup completed successfully"
else
    log_info "Vexa not selected - skipping setup"
fi

exit 0
