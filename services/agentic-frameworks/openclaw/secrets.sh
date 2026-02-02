#!/bin/bash
# Generate secrets for openclaw

# Source secrets utility
source "$PROJECT_ROOT/lib/utils/secrets.sh"

load_all_env "$(dirname "${BASH_SOURCE[0]}")"

declare -A secrets=(
    ["OPENCLAW_GATEWAY_TOKEN"]="hex:32"
)

generate_secrets secrets

write_service_env "$(dirname "${BASH_SOURCE[0]}")"
