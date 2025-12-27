#!/bin/bash
set -euo pipefail

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Ensure abctl is in path if installed in user home
export PATH="$HOME/.airbyte/bin:$PATH"

if ! command -v abctl &> /dev/null; then
    echo "❌ abctl not found. Please run prepare.sh first."
    exit 1
fi

echo "🚀 Installing Airbyte..."
echo "⏱️  This may take 15-30 minutes depending on your internet connection."

if abctl local install --port 8001 2>&1 | tee /tmp/airbyte-install.log; then
    echo "✓ Airbyte installation completed"
else
    echo "❌ Airbyte installation failed. Check log: /tmp/airbyte-install.log"
    exit 1
fi

# Set custom password
echo "🔐 Configuring authentication..."
sleep 5

if abctl local credentials --password "${AIRBYTE_PASSWORD}" &>/dev/null; then
    echo "✓ Custom password configured"
else
    echo "⚠️  Warning: Could not set custom password"
fi

# Wait for Airbyte to be ready
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
