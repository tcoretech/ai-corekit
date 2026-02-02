#!/bin/bash
# Prepare openclaw service

SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SERVICE_DIR/repo"

if [ ! -f "$REPO_DIR/Dockerfile" ]; then
    echo "OpenClaw repo not found in $REPO_DIR. Cloning..."
    git clone https://github.com/openclaw/openclaw "$REPO_DIR"
fi

# Create volumes manually if needed? No, docker compose handles it.
# But we might want to ensure permissions if we were mounting host paths.
# The docker-compose uses named volumes, so it's fine.
