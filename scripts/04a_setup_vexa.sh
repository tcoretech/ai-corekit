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

    # Patch bot-manager to use DOCKER_NETWORK env variable
    log_info "Patching bot-manager to use AI LaunchKit's network..."
    if ! grep -q "DOCKER_NETWORK" docker-compose.yml; then
        # Add DOCKER_NETWORK environment variable to bot-manager service
        sed -i '/bot-manager:/,/^  [a-z]/ {
            /environment:/a\      - DOCKER_NETWORK=localai_default
        }' docker-compose.yml

        log_success "bot-manager network variable configured"
    else
        log_info "bot-manager already configured for network"
    fi

    # Patch PostgreSQL to use md5 authentication (fixes scram-sha-256 issue)
    log_info "Patching PostgreSQL authentication method..."
    if ! grep -q "POSTGRES_HOST_AUTH_METHOD" docker-compose.yml; then
        sed -i '/postgres:/,/^  [a-z]/ {
            /environment:/a\      - POSTGRES_HOST_AUTH_METHOD=md5
        }' docker-compose.yml

        log_success "PostgreSQL authentication method configured"
    else
        log_info "PostgreSQL authentication already configured"
    fi

    # Create pg_hba.conf with md5 authentication
    log_info "Creating pg_hba.conf for md5 authentication..."
    if [ ! -f "pg_hba.conf" ]; then
        cat > pg_hba.conf << 'EOF'
# PostgreSQL Client Authentication Configuration File
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
host    all             all             all                     md5
EOF
        chmod 600 pg_hba.conf
        log_success "pg_hba.conf created"
    else
        log_info "pg_hba.conf already exists"
    fi

    # Ensure pg_hba.conf is mounted in docker-compose.yml
    log_info "Configuring PostgreSQL to mount pg_hba.conf..."
    if ! grep -q "pg_hba.conf:/var/lib/postgresql/data/pg_hba.conf" docker-compose.yml; then
        # Insert mount BEFORE postgres-data line in postgres volumes section
        sed -i '/^  postgres:/,/^  [a-z]/ {
            /- postgres-data:\/var\/lib\/postgresql\/data/i\      - ./pg_hba.conf:/var/lib/postgresql/data/pg_hba.conf
        }' docker-compose.yml
        log_success "pg_hba.conf mount configured"
    else
        log_info "pg_hba.conf mount already configured"
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
DOCKER_NETWORK=localai_default

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
