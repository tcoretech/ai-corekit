#!/bin/bash
set -e

# Workaround: Ensure LibreTranslate starts properly
# This was moved from the legacy update script
if docker ps -a | grep -q libretranslate; then
    echo "Ensuring LibreTranslate container is running properly..."
    
    # Use the exported PROJECT_NAME from up.sh, default to localai if missing
    PROJECT_NAME="${PROJECT_NAME:-localai}"
    
    # Stop and remove the container to ensure a clean start
    docker compose -p "$PROJECT_NAME" stop libretranslate 2>/dev/null || true
    docker compose -p "$PROJECT_NAME" rm -f libretranslate 2>/dev/null || true
    
    echo "LibreTranslate cleaned up for fresh start."
fi
