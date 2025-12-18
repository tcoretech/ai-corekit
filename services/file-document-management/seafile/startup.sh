#!/bin/bash
set -e

# Workaround: Fix Seafile HTTPS/CSRF issue
# This runs AFTER the container is started.

echo "Waiting for Seafile to be ready..."
sleep 30

if docker ps | grep -q seafile; then
    echo "Fixing Seafile HTTPS/CSRF configuration..."
    docker exec seafile bash /init-fix.sh 2>/dev/null || echo "Seafile init-fix.sh failed or not found"
    
    # Restart Seafile to apply changes
    # We need to be careful about restarting the container we just started.
    # But if the fix requires it, we must.
    PROJECT_NAME="${PROJECT_NAME:-localai}"
    docker compose -p "$PROJECT_NAME" restart seafile
    echo "Seafile restarted."
fi
