#!/bin/bash

# ============================================================================
# Secure Credentials Download
# ============================================================================
# This script securely packages credentials into an encrypted zip file
# and serves it temporarily for download.
# ============================================================================

set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

# Configuration
CONFIG_DIR="$PROJECT_ROOT/config/local"
EXPORT_SCRIPT="$PROJECT_ROOT/lib/services/credentials/export.sh"
ENV_FILE="$PROJECT_ROOT/config/.env.global"

# Get hostname from .env
BASE_DOMAIN=$(grep "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
if [ -z "$BASE_DOMAIN" ]; then
    BASE_DOMAIN=$(hostname)
fi

CRED_FILE="$CONFIG_DIR/credentials.${BASE_DOMAIN}.txt"
ZIP_FILE="$CONFIG_DIR/credentials.zip"
DOWNLOAD_PORT=8890

# ============================================================================
# Ensure Credentials Exist
# ============================================================================

if [ ! -f "$CRED_FILE" ]; then
    log_info "Credentials file not found. Generating..."
    bash "$EXPORT_SCRIPT"
fi

if [ ! -f "$CRED_FILE" ]; then
    log_error "Failed to generate credentials file."
    exit 1
fi

# ============================================================================
# Create Encrypted Zip
# ============================================================================

echo
log_info "============================================"
log_info "   Secure Credentials Download"
log_info "============================================"
echo
echo "We will create a password-protected zip file for your credentials."
echo "You will need this password to unzip the file after downloading."
echo

# Prompt for password
while true; do
    read -s -p "Enter password for zip file: " ZIP_PASS
    echo
    read -s -p "Confirm password: " ZIP_PASS_CONFIRM
    echo
    
    if [ -z "$ZIP_PASS" ]; then
        log_error "Password cannot be empty."
        continue
    fi
    
    if [ "$ZIP_PASS" == "$ZIP_PASS_CONFIRM" ]; then
        break
    else
        log_error "Passwords do not match. Please try again."
    fi
done

echo
log_info "Creating encrypted zip file..."

# Create zip with password
# -j: junk paths (don't include directory structure)
# -e: encrypt
# -P: password
cd "$CONFIG_DIR"
zip -j -e -P "$ZIP_PASS" "$ZIP_FILE" "$(basename "$CRED_FILE")" >/dev/null

if [ ! -f "$ZIP_FILE" ]; then
    log_error "Failed to create zip file."
    exit 1
fi

# ============================================================================
# Serve File
# ============================================================================

# Get server IPv4 address
IP=$(curl -4 -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

# Open firewall port temporarily
if command -v ufw >/dev/null; then
    log_info "Opening firewall port $DOWNLOAD_PORT..."
    sudo ufw allow $DOWNLOAD_PORT/tcp >/dev/null 2>&1 || true
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 DOWNLOAD READY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "👇 Open this link in your browser:"
echo
echo "   http://$IP:$DOWNLOAD_PORT/credentials.zip"
echo
echo "⏱️  Link expires in 60 seconds!"
echo
echo "💡 The zip file is encrypted with the password you just set."
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🌐 Starting temporary download server..."
echo "   (Server will auto-stop after 60 seconds)"
echo

cd "$CONFIG_DIR"
timeout 60 python3 -m http.server $DOWNLOAD_PORT >/dev/null 2>&1 || true

# ============================================================================
# Cleanup
# ============================================================================

echo
echo "🧹 Cleaning up..."

# Close firewall port
if command -v ufw >/dev/null; then
    sudo ufw delete allow $DOWNLOAD_PORT/tcp >/dev/null 2>&1 || true
fi

# Delete the zip file
rm -f "$ZIP_FILE"

# Ask to delete the original text file
echo
read -p "Do you want to delete the unencrypted credentials text file? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    rm -f "$CRED_FILE"
    log_success "Unencrypted credentials file deleted."
else
    log_info "Unencrypted credentials file kept at: $CRED_FILE"
fi

echo
log_success "✅ Done!"
