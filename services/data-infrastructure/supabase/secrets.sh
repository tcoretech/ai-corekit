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
    ["JWT_SECRET"]="base64:64"
    ["DASHBOARD_PASSWORD"]="password:32"
    ["CLICKHOUSE_PASSWORD"]="password:32"
    ["MINIO_ROOT_PASSWORD"]="password:32"
    ["SECRET_KEY_BASE"]="base64:64"
    ["VAULT_ENC_KEY"]="alphanum:32"
    ["LOGFLARE_PRIVATE_ACCESS_TOKEN"]="fixed:not-in-use"
    ["LOGFLARE_PUBLIC_ACCESS_TOKEN"]="fixed:not-in-use"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
