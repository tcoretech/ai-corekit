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
    # Keep Vexa's default bridge network (no patching needed)
    log_info "Using Vexa's default bridge network..."
    log_success "Network configuration kept as default"
    # Patch WHISPER_LIVE_URL to use whisperlive-cpu
    log_info "Patching WHISPER_LIVE_URL for CPU deployment..."
    if grep -q "ws://traefik:8081/ws" docker-compose.yml; then
        sed -i 's|ws://traefik:8081/ws|ws://whisperlive-cpu:9090|g' docker-compose.yml
        log_success "WHISPER_LIVE_URL patched"
    else
        log_info "WHISPER_LIVE_URL already configured"
    fi
    # Fix Playwright version mismatch - use latest stable
    log_info "Fixing Playwright Docker image version to v1.56.0..."
    sed -i 's|mcr.microsoft.com/playwright:v[0-9.]*-jammy|mcr.microsoft.com/playwright:v1.56.0-jammy|g' \
        services/vexa-bot/core/Dockerfile
    log_success "Playwright version set to v1.56.0"

    # Fix transcription-collector SQL type mismatch bug
    # Bug: Code compares Meeting.platform_specific_id (VARCHAR) with native_meeting_id (INTEGER)
    # Fix: Use Meeting.id instead (the internal DB ID that WhisperLive sends)
    log_info "Patching transcription-collector SQL type mismatch..."
    if grep -q "Meeting.platform_specific_id == native_meeting_id" services/transcription-collector/streaming/processors.py 2>/dev/null; then
        sed -i 's|Meeting.platform_specific_id == native_meeting_id|Meeting.id == native_meeting_id|g' \
            services/transcription-collector/streaming/processors.py
        log_success "Transcription-collector SQL fix applied"
    else
        log_info "Transcription-collector SQL fix already applied or not needed"
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
# Docker Network Configuration
DOCKER_NETWORK=vexa_dev_vexa_default
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
