#!/bin/bash

# Ensure data directories exist
mkdir -p ./data/repo

# Ensure config/local exists for any overrides
mkdir -p ./config/local

# Set permissions if needed (usually docker handles this, but good practice)
chmod 755 ./data

# Bootstrap: If the service image doesn't exist, create a dummy one.
# This ensures docker-compose doesn't fail on startup.
# The updater will build the real image and restart the service.
source .env
IMG=${SERVICE_IMAGE_NAME:-example-service:latest}
if ! docker image inspect "$IMG" > /dev/null 2>&1; then
    echo "[Bootstrap] Image $IMG not found. Creating placeholder..."
    
    # Check if we have internet to pull alpine, if not try to use any local image? 
    # CoreKit assumes internet.
    docker pull alpine:latest
    docker tag alpine:latest "$IMG"
    echo "[Bootstrap] Placeholder image created."
fi
