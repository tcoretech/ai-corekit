#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["TWENTY_CRM_DB_PASSWORD"]="password:32"
    ["TWENTY_CRM_APP_SECRET"]="apikey:64"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
