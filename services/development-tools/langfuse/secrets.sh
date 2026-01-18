#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["LANGFUSE_SALT"]="secret:64"
    ["LANGFUSE_NEXTAUTH_SECRET"]="secret:64"
    ["LANGFUSE_ENCRYPTION_KEY"]="hex:64"
    ["LANGFUSE_INIT_USER_PASSWORD"]="password:32"
    ["LANGFUSE_INIT_PROJECT_PUBLIC_KEY"]="langfuse_pk:32"
    ["LANGFUSE_INIT_PROJECT_SECRET_KEY"]="langfuse_sk:32"
    ["MINIO_ROOT_PASSWORD"]="password:32"
    ["CLICKHOUSE_PASSWORD"]="password:32"
    ["LANGFUSE_INIT_ORG_ID"]="random:10"
    ["LANGFUSE_INIT_PROJECT_ID"]="random:10"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# No post-processing needed

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
