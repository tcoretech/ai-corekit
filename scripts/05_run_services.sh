#!/bin/bash

set -e

# Source the utilities file
source "$(dirname "$0")/utils.sh"

# 1. Check for .env file
if [ ! -f ".env" ]; then
  log_error ".env file not found in project root." >&2
  exit 1
fi

# 2. Check for docker-compose.yml file
if [ ! -f "docker-compose.yml" ]; then
  log_error "docker-compose.yml file not found in project root." >&2
  exit 1
fi

# 3. Check for Caddyfile (optional but recommended for reverse proxy)
if [ ! -f "Caddyfile" ]; then
  log_warning "Caddyfile not found in project root. Reverse proxy might not work as expected." >&2
  exit 1
fi

# 4. Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
  log_error "Docker daemon is not running. Please start Docker and try again." >&2
  exit 1
fi

# 5. Check if start_services.py exists and is executable
if [ ! -f "start_services.py" ]; then
  log_error "start_services.py file not found in project root." >&2
  exit 1
fi

if [ ! -x "start_services.py" ]; then
  log_warning "start_services.py is not executable. Making it executable..."
  chmod +x "start_services.py"
fi

# Create media directories with correct permissions BEFORE Docker starts
log_info "Creating media processing directories..."
mkdir -p media temp
# Use SUDO_USER if available (when run with sudo), otherwise current user
if [ -n "$SUDO_USER" ]; then
  chown -R $SUDO_USER:$SUDO_USER media temp
else
  chown -R $(whoami):$(whoami) media temp
fi
chmod 755 media temp
log_info "Media directories created with correct permissions"

# Setup Postal configuration if needed
if [ -f "./scripts/setup_postal.sh" ]; then
  log_info "Checking for Postal setup..."
  bash ./scripts/setup_postal.sh
fi

# Build services that need local compilation
source .env
if [[ "$COMPOSE_PROFILES" == *"tts-chatterbox"* ]]; then
    log_info "Checking Chatterbox Frontend..."
    # Clone the repository if not exists
    if [ ! -d "./chatterbox-frontend/frontend" ]; then
        log_info "Cloning Chatterbox TTS API repository for frontend..."
        git clone https://github.com/travisvn/chatterbox-tts-api.git ./chatterbox-frontend || {
            log_error "Failed to clone Chatterbox repository"
            log_warning "Chatterbox Frontend will not be available"
        }
    fi

    # Build the frontend if source exists
    if [ -d "./chatterbox-frontend/frontend" ]; then
        log_info "Building Chatterbox Frontend from source..."
        docker compose -p localai build chatterbox-frontend || {
            log_warning "Failed to build Chatterbox Frontend - API will work but no UI"
        }
    fi
fi

log_info "Launching services using start_services.py..."
# Execute start_services.py
./start_services.py

# Explicitly start services with profiles that need building
if [[ "$COMPOSE_PROFILES" == *"tts-chatterbox"* ]]; then
    log_info "Starting Chatterbox services..."
    docker compose -p localai --profile tts-chatterbox up -d
fi

# Start Vexa if selected
if [[ "$COMPOSE_PROFILES" == *"vexa"* ]]; then
    log_info "Starting Vexa services..."

    # Check if vexa directory exists
    if [ ! -d "./vexa" ]; then
        log_error "Vexa directory not found - run setup script first"
        exit 1
    fi

    # Check if docker-compose.yml exists in vexa directory
    if [ ! -f "./vexa/docker-compose.yml" ]; then
        log_error "Vexa docker-compose.yml not found - setup may be incomplete"
        exit 1
    fi

    cd vexa || {
        log_error "Failed to enter vexa directory"
        exit 1
    }

    # Clean any existing containers/volumes
    log_info "Cleaning existing Vexa containers and volumes..."
    sudo docker compose down -v 2>/dev/null || true

    # Build images
    log_info "Building Vexa bot image..."
    sudo -E make build-bot-image || {
        log_warning "Failed to build Vexa bot image"
        cd ..
        exit 1
    }

    log_info "Building Vexa microservices..."
    sudo -E make build || {
        log_warning "Failed to build Vexa services"
        cd ..
        exit 1
    }

    # Start all services
    log_info "Starting all Vexa microservices..."
    sudo -E make up || {
        log_error "Failed to start Vexa services"
        cd ..
        exit 1
    }

    # Wait for Postgres to fully initialize
    log_info "Waiting for Postgres to initialize..."
    sleep 120

    # Run smart database migration/initialization
    # This uses Vexa's own logic to detect DB state (fresh/legacy/alembic-managed)
    log_info "Initializing Vexa database (smart migration)..."
    sudo -E make migrate-or-init || {
        log_error "Vexa database initialization failed"
        log_error "Check logs with: cd vexa && sudo docker compose logs transcription-collector"
        cd ..
        exit 1
    }

    cd .. || exit 1
    log_success "Vexa services started successfully"
else
    log_info "Vexa not selected - skipping"
fi

# Start Airbyte if selected
if [[ "$COMPOSE_PROFILES" == *"airbyte"* ]]; then
    log_info "Starting Airbyte installation..."
    
    # Check if init script exists
    if [ ! -f "./scripts/05a_init_airbyte.sh" ]; then
        log_error "Airbyte init script not found at ./scripts/05a_init_airbyte.sh"
        exit 1
    fi
    
    # Make script executable if not already
    chmod +x ./scripts/05a_init_airbyte.sh
    
    # Run Airbyte initialization
    bash ./scripts/05a_init_airbyte.sh || {
        log_error "Airbyte installation failed"
        log_error "Check the installation log at /tmp/airbyte-install.log"
        exit 1
    }
    
    log_success "Airbyte installation completed successfully"
else
    log_info "Airbyte not selected - skipping"
fi

exit 0
