#!/bin/bash
set -e

# Source utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# Global Configuration only — service secrets are generated lazily by `corekit up <service>`
log_info "Initializing global configuration..."
bash "$PROJECT_ROOT/lib/config/global_secrets.sh"

log_success "Global configuration complete. Service secrets will be generated on first use."
