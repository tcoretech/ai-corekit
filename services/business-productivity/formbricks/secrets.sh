#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../scripts/utils_secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["FORMBRICKS_NEXTAUTH_SECRET"]="apikey:32"
    ["FORMBRICKS_ENCRYPTION_KEY"]="apikey:32"
    ["FORMBRICKS_CRON_SECRET"]="apikey:32"
    ["FORMBRICKS_DB_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
