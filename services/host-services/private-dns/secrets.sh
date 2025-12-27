#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"

# No secrets to generate, but we use this to ensure .env is created from .env.example
# and variable substitution happens (e.g. ${BASE_DOMAIN})

# Write .env
write_service_env "$SCRIPT_DIR"
