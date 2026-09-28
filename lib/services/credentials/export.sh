#!/bin/bash

# ============================================================================
# Export & Download Credentials Script
# ============================================================================
# This script exports all service credentials from the final report
# to a hostname-based text file and optionally provides a download link.
#
# Usage: 
#   sudo bash ./lib/maintenance/export_credentials.sh           # Export only
#   sudo bash ./lib/maintenance/export_credentials.sh -d        # Export + Download
#   sudo bash ./lib/maintenance/export_credentials.sh --download # Export + Download
#
# Note: Requires sudo access because .env file is owned by root
# File is automatically deleted after successful download
# ============================================================================

set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

AUTO_DOWNLOAD=false
if [[ "$1" == "-d" ]] || [[ "$1" == "--download" ]]; then
    AUTO_DOWNLOAD=true
fi

# ============================================================================
# Directory Setup
# ============================================================================

# ============================================================================
# Check .env file access
# ============================================================================

ENV_FILE="$PROJECT_ROOT/config/.env.global"

# Check if .env exists and is readable
if [ ! -r "$ENV_FILE" ]; then
    log_error "Cannot read .env file: $ENV_FILE"
    echo
    echo "This script requires access to the .env file which is owned by root."
    echo
    echo "Please run with sudo:"
    echo "  sudo corekit credentials export"
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
OUTPUT_DIR="$PROJECT_ROOT/config/local"
mkdir -p "$OUTPUT_DIR"
# The export is a plaintext copy of every credential on the host. Keep the
# directory and the file readable only by the account that created them.
chmod 700 "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/credentials.${BASE_DOMAIN}.txt"
# Create the file with the right mode before anything is written to it, so the
# contents are never briefly world-readable under a permissive umask.
install -m 600 /dev/null "$OUTPUT_FILE"

# ============================================================================
# Header
# ============================================================================

echo
log_info "============================================"
log_info "   AI CoreKit Credentials Export"
log_info "============================================"
echo

# ============================================================================
# Check if final report script exists
# ============================================================================

FINAL_REPORT_SCRIPT="$PROJECT_ROOT/lib/services/final_report.sh"

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
    chown "$SUDO_USER:$SUDO_USER" "$OUTPUT_DIR"
    log_info "File ownership adjusted to: $SUDO_USER"
fi

# Re-assert the mode in case anything above replaced the file rather than
# writing through the handle we created.
chmod 600 "$OUTPUT_FILE"
chmod 700 "$OUTPUT_DIR"

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
echo "➡️  Import this file into your password manager, then delete it."
echo "   It is a plaintext copy of every credential on this host, and nothing"
echo "   rotates or expires it. Leaving it on disk is the risk it creates."
echo "   Delete it with:  shred -u $OUTPUT_FILE"
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
# Next Steps
# ============================================================================

echo
echo "💾 Credentials file saved to: $OUTPUT_FILE"
echo
echo "To download this file securely (encrypted zip):"
echo "   corekit credentials download"
echo
echo "Import it into your password manager, then delete it:"
echo "   shred -u $OUTPUT_FILE"
echo

exit 0
