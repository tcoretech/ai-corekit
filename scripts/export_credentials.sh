#!/bin/bash

# ============================================================================
# Export & Download Credentials Script
# ============================================================================
# This script exports all service credentials from the final report
# to a hostname-based text file and optionally provides a download link.
#
# Usage: 
#   sudo bash ./scripts/export_credentials.sh           # Export only
#   sudo bash ./scripts/export_credentials.sh -d        # Export + Download
#   sudo bash ./scripts/export_credentials.sh --download # Export + Download
#
# Note: Requires sudo access because .env file is owned by root
# File is automatically deleted after successful download
# ============================================================================

set -e

# Parse command line arguments
AUTO_DOWNLOAD=false
if [[ "$1" == "-d" ]] || [[ "$1" == "--download" ]]; then
    AUTO_DOWNLOAD=true
fi

# ============================================================================
# Directory Setup
# ============================================================================

# Get script and project directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Source utilities
source "$SCRIPT_DIR/utils.sh"

# ============================================================================
# Check .env file access
# ============================================================================

ENV_FILE="$PROJECT_ROOT/.env"

# Check if .env exists and is readable
if [ ! -r "$ENV_FILE" ]; then
    log_error "Cannot read .env file: $ENV_FILE"
    echo
    echo "This script requires access to the .env file which is owned by root."
    echo
    echo "Please run with sudo:"
    echo "  sudo bash ./scripts/export_credentials.sh"
    echo
    exit 1
fi

# ============================================================================
# File Paths
# ============================================================================

# Get hostname from .env
BASE_DOMAIN=$(grep "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")

# Fallback to system hostname if BASE_DOMAIN not set
if [ -z "$BASE_DOMAIN" ]; then
    BASE_DOMAIN=$(hostname)
fi

# Create filename with hostname (gets overwritten each time)
OUTPUT_FILE="$PROJECT_ROOT/credentials.${BASE_DOMAIN}.txt"

# ============================================================================
# Header
# ============================================================================

echo
log_info "============================================"
log_info "   AI LaunchKit Credentials Export"
log_info "============================================"
echo

# ============================================================================
# Check if final report script exists
# ============================================================================

FINAL_REPORT_SCRIPT="$SCRIPT_DIR/06_final_report.sh"

if [ ! -f "$FINAL_REPORT_SCRIPT" ]; then
    log_error "Final report script not found: $FINAL_REPORT_SCRIPT"
    exit 1
fi

# ============================================================================
# Export Credentials
# ============================================================================

log_info "Exporting credentials to: credentials.${BASE_DOMAIN}.txt"
echo

# Run the final report script and clean output for plain text file
bash "$FINAL_REPORT_SCRIPT" 2>&1 | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    sed 's/[─━═]/=/g; s/[│┃║]/|/g; s/[┌┏╭╔╒╓]/+/g; s/[┐┓╮╗╕╖]/+/g; s/[└┗╰╚╘╙]/+/g; s/[┘┛╯╝╛╜]/+/g; s/[├┝╞╟╠]/+/g; s/[┤┥╡╢╣]/+/g; s/[┬┯╤╥╦]/+/g; s/[┴┷╧╨╩]/+/g; s/[┼┿╪╫╬]/+/g' \
    > "$OUTPUT_FILE"

# If running as sudo, adjust ownership to the actual user
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$OUTPUT_FILE"
    log_info "File ownership adjusted to: $SUDO_USER"
fi

# ============================================================================
# Success Message
# ============================================================================

echo
log_success "✅ Credentials exported successfully!"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 FILE CREATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Credentials file:"
echo "  📄 $OUTPUT_FILE"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 SECURITY REMINDER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "⚠️  This file contains sensitive credentials:"
echo "   • Passwords, API keys, and tokens"
echo "   • Store securely (password manager recommended)"
echo "   • File is excluded from Git (.gitignore)"
echo "   • Will be auto-deleted after download (if you choose to download)"
echo
echo "To view credentials:"
echo "   cat $OUTPUT_FILE"
echo
echo "To view specific service (example):"
echo "   grep -A 10 'n8n' $OUTPUT_FILE"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# ============================================================================
# Download Option
# ============================================================================

OFFER_DOWNLOAD=false

# Auto-download if flag was provided
if [ "$AUTO_DOWNLOAD" = true ]; then
    OFFER_DOWNLOAD=true
else
    # Ask user if they want to download
    echo
    read -p "📥 Do you want to download the credentials file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        OFFER_DOWNLOAD=true
    fi
fi

# ============================================================================
# Provide Download Link
# ============================================================================

if [ "$OFFER_DOWNLOAD" = true ]; then
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 DOWNLOAD CREDENTIALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # Port for temporary HTTP server
    DOWNLOAD_PORT=8890
    DOWNLOAD_FILENAME="credentials.${BASE_DOMAIN}.txt"
    
    # Get server IPv4 address
    echo "🔍 Detecting server IP address..."
    IP=$(curl -4 -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    # Open firewall port temporarily
    echo "🔓 Opening firewall port $DOWNLOAD_PORT..."
    sudo ufw allow $DOWNLOAD_PORT/tcp >/dev/null 2>&1 || true
    
    echo
    echo "👇 Open this link in your browser:"
    echo
    echo "   http://$IP:$DOWNLOAD_PORT/$DOWNLOAD_FILENAME"
    echo
    echo "⏱️  Link expires in 60 seconds!"
    echo
    echo "💡 Tip: Right-click → 'Save Link As' to download"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "🌐 Starting temporary download server..."
    echo "   (Server will auto-stop after 60 seconds)"
    echo
    
    cd "$PROJECT_ROOT"
    timeout 60 python3 -m http.server $DOWNLOAD_PORT >/dev/null 2>&1 || true
    
    echo
    echo "🧹 Cleaning up..."
    
    # Close firewall port
    sudo ufw delete allow $DOWNLOAD_PORT/tcp >/dev/null 2>&1 || true
    
    # Delete the credentials file after download
    rm -f "$OUTPUT_FILE"
    
    echo
    echo "✅ Download link expired."
    echo "🗑️  Credentials file deleted for security."
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo
    echo "💾 Credentials file saved. Remember to delete it after use:"
    echo "   rm $OUTPUT_FILE"
fi

echo

exit 0
