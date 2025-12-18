#!/bin/bash
set -e

# Vexa Initialization
# This runs AFTER the container is started.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"

# Initialize Vexa if not already done
# The legacy script called 05a_init_vexa.sh. We should check if that logic can be moved here.
# For now, we'll assume the init logic is complex and might need to be ported or called.

# If there is an init script in the service dir, run it.
if [ -f "$SERVICE_DIR/init.sh" ]; then
    bash "$SERVICE_DIR/init.sh"
fi
