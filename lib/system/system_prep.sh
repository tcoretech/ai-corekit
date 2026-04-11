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

# Install essential packages (skip if all already present)
if command -v apt-get &> /dev/null; then
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

    MISSING=()
    for pkg in "${PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            MISSING+=("$pkg")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        log_info "Installing missing packages: ${MISSING[*]}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y "${MISSING[@]}"
        log_success "Essential packages installed successfully."
    else
        log_info "All essential packages already installed, skipping."
    fi
else
    log_warning "'apt-get' not found. Skipping package installation."
fi

log_success "System preparation completed successfully."
log_info "Note: Firewall configuration has been moved to a separate command."
log_info "To configure firewall, run: corekit system --close-ports"