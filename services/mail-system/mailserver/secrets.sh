#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["SMTP_PASS"]="password:16"
    ["MAIL_NOREPLY_PASSWORD"]="password:32"
    ["MAIL_INFO_PASSWORD"]="password:32"
    ["MAIL_INGEST_SMTP_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS

# generate_secrets only fills the in-memory map; nothing writes it back to .env.
# The mail-ingest login must persist (mail-ingest's compose reads it), so write
# it here if .env does not have it yet.
if ! grep -q "^MAIL_INGEST_SMTP_PASSWORD=." "$SCRIPT_DIR/.env" 2>/dev/null; then
    update_env_var "$SCRIPT_DIR/.env" "MAIL_INGEST_SMTP_PASSWORD" "${SERVICE_ENV_VARS[MAIL_INGEST_SMTP_PASSWORD]}"
fi
