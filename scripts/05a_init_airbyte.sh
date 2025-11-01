#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

echo ""
echo "============================================"
echo "🔄 Airbyte Installation via abctl"
echo "============================================"
echo ""

# Check if Airbyte profile is active
if ! grep -q "airbyte" <<< "${COMPOSE_PROFILES:-}"; then
    echo "ℹ️  Airbyte profile not active. Skipping installation."
    exit 0
fi

# Step 1: Check if abctl is already installed
echo "📦 Checking for abctl..."
if command -v abctl &> /dev/null; then
    ABCTL_VERSION=$(abctl version 2>/dev/null || echo "unknown")
    echo "✓ abctl is already installed (version: $ABCTL_VERSION)"
else
    echo "📥 Installing abctl..."
    
    if curl -LsfS https://get.airbyte.com | bash -; then
        echo "✓ abctl installed successfully"
        
        if ! command -v abctl &> /dev/null; then
            export PATH="$HOME/.airbyte/bin:$PATH"
            echo "✓ Added abctl to PATH"
        fi
    else
        echo "❌ Failed to install abctl"
        exit 1
    fi
fi

# Step 2: Install Airbyte (with built-in PostgreSQL)
echo ""
echo "🚀 Installing Airbyte..."
echo "⏱️  This may take 15-30 minutes depending on your internet connection."
echo ""

if abctl local install --port 8001 2>&1 | tee /tmp/airbyte-install.log; then
    echo ""
    echo "✓ Airbyte installation completed"
else
    echo ""
    echo "❌ Airbyte installation failed. Check log: /tmp/airbyte-install.log"
    exit 1
fi

# Step 3: Set custom password
echo ""
echo "🔐 Configuring authentication..."
sleep 5

if abctl local credentials --password "${AIRBYTE_PASSWORD}" &>/dev/null; then
    echo "✓ Custom password configured"
else
    echo "⚠️  Warning: Could not set custom password"
fi

# Step 4: Wait for Airbyte to be ready
echo ""
echo "🔍 Waiting for Airbyte to be ready..."

MAX_WAIT=120
COUNTER=0

while [ $COUNTER -lt $MAX_WAIT ]; do
    if curl -sf http://localhost:8001/api/v1/health &>/dev/null; then
        echo "✓ Airbyte is healthy and responding"
        break
    fi
    
    if [ $COUNTER -eq 0 ]; then
        echo -n "   Waiting"
    else
        echo -n "."
    fi
    
    sleep 5
    COUNTER=$((COUNTER + 5))
done
echo ""

if [ $COUNTER -ge $MAX_WAIT ]; then
    echo "⚠️  Warning: Could not verify Airbyte health"
    echo "   Airbyte might still be starting up"
else
    echo "✓ Airbyte is fully operational"
fi

# Success summary
echo ""
echo "============================================"
echo "✅ Airbyte Installation Complete!"
echo "============================================"
echo ""
echo "Access Information:"
echo "  URL:      https://${AIRBYTE_HOSTNAME}"
echo "  Username: admin"
echo "  Password: ${AIRBYTE_PASSWORD}"
echo ""
echo "Destination Database (for synced data):"
echo "  Host:     airbyte_destination_db"
echo "  Port:     5432"
echo "  Database: marketing_data"
echo "  User:     airbyte"
echo "  Password: ${AIRBYTE_DESTINATION_DB_PASSWORD}"
echo ""
echo "Next Steps:"
echo "  1. Access Airbyte at: https://${AIRBYTE_HOSTNAME}"
echo "  2. Add sources (Google Ads, Meta, etc.)"
echo "  3. Create destination: PostgreSQL (use above credentials)"
echo "  4. Connect Metabase to marketing_data database"
echo ""
echo "Integration (n8n):"
echo "  API: http://localhost:8001/api/v1/"
echo ""
echo "============================================"
echo ""
