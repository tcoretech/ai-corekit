#!/bin/bash
echo "====================================="
echo "📥 CREDENTIALS DOWNLOAD"
echo "====================================="
echo

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." &> /dev/null && pwd )"

CRED_FILE="$PROJECT_ROOT/ai-launchkit-credentials.json"

# File already exists, just serve it
if [ ! -f "$CRED_FILE" ]; then
    echo "Warning: Credential file ($CRED_FILE) not found."
fi

# Get IPv4 address
IP=$(curl -4 -s ifconfig.me)

# Open port
if command -v ufw >/dev/null; then
    sudo ufw allow 8889/tcp >/dev/null 2>&1
fi

echo "👇 Open this link in your browser:"
echo
echo "http://$IP:8889/ai-launchkit-credentials.json"
echo
echo "⏱️  Download within 60 seconds!"

# Start server
cd "$PROJECT_ROOT"
timeout 60 python3 -m http.server 8889 >/dev/null 2>&1

# Cleanup
if command -v ufw >/dev/null; then
    sudo ufw delete allow 8889/tcp >/dev/null 2>&1
fi
# rm -f "$CRED_FILE" # Optional: keep it or delete it. Original script deleted it.
echo
echo "✅ Done!"
