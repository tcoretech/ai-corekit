#!/bin/bash
set -euo pipefail

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

echo "📦 Checking for abctl..."
if command -v abctl &> /dev/null; then
    ABCTL_VERSION=$(abctl version 2>/dev/null || echo "unknown")
    echo "✓ abctl is already installed (version: $ABCTL_VERSION)"
else
    echo "📥 Installing abctl..."
    if curl -LsfS https://get.airbyte.com | bash -; then
        echo "✓ abctl installed successfully"
    else
        echo "❌ Failed to install abctl"
        exit 1
    fi
fi
