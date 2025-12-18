#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["LIGHTRAG_PASSWORD"]="password:32"
    ["LIGHTRAG_TOKEN_SECRET"]="apikey:64"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Generate LIGHTRAG_AUTH_ACCOUNTS if not set
if [[ -z "${SERVICE_ENV_VARS[LIGHTRAG_AUTH_ACCOUNTS]}" ]]; then
    ADMIN_PASS=$(gen_password 16)
    update_env_var "LIGHTRAG_AUTH_ACCOUNTS" "admin:${ADMIN_PASS}" "$SCRIPT_DIR/.env"
    log_success "Generated LIGHTRAG_AUTH_ACCOUNTS"
fi


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
