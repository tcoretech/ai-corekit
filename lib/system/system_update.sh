#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

log_info "Updating system packages..."

if command -v apt-get &> /dev/null; then
    # Check for sudo if not root
    if [ "$EUID" -ne 0 ] && command -v sudo &> /dev/null; then
        sudo apt-get update && sudo apt-get upgrade -y
    elif [ "$EUID" -eq 0 ]; then
        apt-get update && apt-get upgrade -y
    else
        log_warning "Cannot run apt-get without root privileges."
        exit 1
    fi
    log_success "System packages updated successfully."
else
    log_warning "'apt-get' not found. Skipping system package update. This is normal on non-debian systems."
fi
