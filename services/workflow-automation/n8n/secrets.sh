#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["N8N_ENCRYPTION_KEY"]="secret:64"
    ["N8N_USER_MANAGEMENT_JWT_SECRET"]="secret:64"
    ["N8N_RUNNERS_AUTH_TOKEN"]="secret:64"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed for n8n

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
