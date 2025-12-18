#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["ODOO_DB_PASSWORD"]="password:32"
    ["ODOO_MASTER_PASSWORD"]="password:32"
    ["ODOO_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Set ODOO_USERNAME to PRIMARY_EMAIL if not set
if [[ -z "${SERVICE_ENV_VARS[ODOO_USERNAME]}" ]]; then
    if [[ -n "${SERVICE_ENV_VARS[PRIMARY_EMAIL]}" ]]; then
        SERVICE_ENV_VARS["ODOO_USERNAME"]="${SERVICE_ENV_VARS[PRIMARY_EMAIL]}"
    elif [[ -n "${SERVICE_ENV_VARS[LETSENCRYPT_EMAIL]}" ]]; then
        SERVICE_ENV_VARS["ODOO_USERNAME"]="${SERVICE_ENV_VARS[LETSENCRYPT_EMAIL]}"
    fi
fi

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
