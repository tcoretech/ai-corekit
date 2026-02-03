#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

log_info "Running system preparation..."

# Check for sudo if not root
if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
    log_warning "This script requires root privileges or sudo. Please run with sudo or as root."
    exit 1
fi

SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
fi

# Update package lists
log_info "Updating package lists..."
if command -v apt-get &> /dev/null; then
    $SUDO_CMD apt-get update -y
else
    log_warning "'apt-get' not found. Skipping package update. This is normal on non-Debian systems."
fi

# Install essential packages
log_info "Installing essential packages..."
if command -v apt-get &> /dev/null; then
    # Install common utilities needed for the system
    PACKAGES=(
        curl
        wget
        git
        unzip
        zip
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        apt-transport-https
    )
    
    $SUDO_CMD apt-get install -y "${PACKAGES[@]}"
    log_success "Essential packages installed successfully."
else
    log_warning "'apt-get' not found. Skipping package installation."
fi

log_success "System preparation completed successfully."
log_info "Note: Firewall configuration has been moved to a separate command."
log_info "To configure firewall, run: corekit system --close-ports"