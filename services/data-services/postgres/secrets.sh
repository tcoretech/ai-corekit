#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["POSTGRES_PASSWORD"]="password:32"
    ["POSTGRES_NON_ROOT_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS

# Write .env
write_service_env "$SCRIPT_DIR"
