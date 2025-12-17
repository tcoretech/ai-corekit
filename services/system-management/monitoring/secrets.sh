#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../scripts/utils_secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["GRAFANA_ADMIN_PASSWORD"]="password:32"
    ["PROMETHEUS_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Hash password for Caddy
if [[ -n "${SERVICE_ENV_VARS[PROMETHEUS_PASSWORD]}" ]]; then
    HASH=$(generate_caddy_hash "${SERVICE_ENV_VARS[PROMETHEUS_PASSWORD]}")
    if [[ -n "$HASH" ]]; then
        SERVICE_ENV_VARS["PROMETHEUS_PASSWORD_HASH"]="$HASH"
    fi
fi

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
