#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

# ============================================================================
# Firewall Configuration Script
# ============================================================================
# This script configures UFW (Uncomplicated Firewall) to secure the system.
# 
# WARNING: This will close most ports and could lock you out if not careful!
# SSH port (22) will be preserved by default to maintain access.
# ============================================================================

# Check for sudo if not root
if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
    log_error "This script requires root privileges or sudo. Please run with sudo or as root."
    exit 1
fi

SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
fi

# Check if UFW is available
if ! command -v ufw &> /dev/null; then
    log_error "UFW (Uncomplicated Firewall) is not installed."
    log_info "To install UFW on Ubuntu/Debian, run: sudo apt-get install ufw"
    exit 1
fi

# Display warning
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  WARNING: FIREWALL CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script will configure the firewall to close most ports."
echo ""
echo "📋 What will happen:"
echo "   1. Enable UFW firewall"
echo "   2. Set default policy to DENY incoming connections"
echo "   3. Allow SSH (port 22) to prevent lockout"
echo "   4. Allow HTTP (port 80) and HTTPS (port 443)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - If you're using a non-standard SSH port, you MUST cancel and"
echo "     manually configure UFW before running this script!"
echo "   - Make sure you have physical/console access to the server in case"
echo "     of issues"
echo "   - This will block all other ports unless specifically allowed"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get current SSH port
SSH_PORT=22
if command -v ss &> /dev/null; then
    # Try to detect SSH port from active connections
    DETECTED_SSH_PORT=$(ss -tlnp | grep sshd | grep -oP ':\K[0-9]+' | head -1)
    if [ -n "$DETECTED_SSH_PORT" ] && [ "$DETECTED_SSH_PORT" != "22" ]; then
        SSH_PORT=$DETECTED_SSH_PORT
        log_warning "Detected SSH running on non-standard port: $SSH_PORT"
        echo "   We will allow this port to prevent lockout."
        echo ""
    fi
fi

# First confirmation
read -p "Do you understand the risks and want to continue? (type 'yes' to continue): " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    log_info "Firewall configuration cancelled."
    exit 0
fi

# Check if UFW is already enabled
UFW_STATUS=$($SUDO_CMD ufw status | grep -i "Status:" | awk '{print $2}')
if [[ "$UFW_STATUS" == "active" ]]; then
    log_warning "UFW is already active. This will modify existing rules."
    echo ""
    echo "Current UFW status:"
    $SUDO_CMD ufw status numbered
    echo ""
    read -p "Do you want to continue and modify existing rules? (type 'yes' to continue): " -r
    echo
    if [[ ! $REPLY == "yes" ]]; then
        log_info "Firewall configuration cancelled."
        exit 0
    fi
fi

# Second confirmation with countdown
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  FINAL CONFIRMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This is your last chance to cancel before firewall rules are applied."
echo ""
read -p "Type 'CONFIGURE FIREWALL' to proceed: " -r
echo
if [[ ! $REPLY == "CONFIGURE FIREWALL" ]]; then
    log_info "Firewall configuration cancelled."
    exit 0
fi

log_info "Starting firewall configuration..."

# Set default policies
log_info "Setting default policies (deny incoming, allow outgoing)..."
$SUDO_CMD ufw default deny incoming
$SUDO_CMD ufw default allow outgoing

# Allow SSH - CRITICAL to prevent lockout
log_info "Allowing SSH on port $SSH_PORT (to prevent lockout)..."
$SUDO_CMD ufw allow $SSH_PORT/tcp comment 'SSH access'

# Allow HTTP and HTTPS for web services
log_info "Allowing HTTP (80) and HTTPS (443)..."
$SUDO_CMD ufw allow 80/tcp comment 'HTTP'
$SUDO_CMD ufw allow 443/tcp comment 'HTTPS'

# Enable UFW
log_info "Enabling UFW..."
echo "y" | $SUDO_CMD ufw enable

# Show status
echo ""
log_success "Firewall configured successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Current Firewall Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SUDO_CMD ufw status verbose
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Tips:"
echo "   - To allow additional ports: sudo ufw allow <port>/tcp"
echo "   - To remove a rule: sudo ufw delete allow <port>/tcp"
echo "   - To check status: sudo ufw status"
echo "   - To disable firewall: sudo ufw disable"
echo ""
echo "📖 Service-specific firewall rules can be found in each service's README"
echo ""
log_success "✅ Done!"
