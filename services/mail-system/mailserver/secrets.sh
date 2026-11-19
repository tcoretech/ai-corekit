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

# mail-ingest verifies the mailserver certificate before it logs in. Nothing
# renews that certificate since Caddy left the stack, so while it is expired
# pin its fingerprint instead; once it is valid again, clear the pin so
# mail-ingest goes back to normal CA and hostname checks. Leave the value
# alone if the mailserver is not running to ask.
if docker exec mailserver true 2>/dev/null; then
    cert_fp=""
    if ! docker exec mailserver sh -c 'openssl x509 -in "$SSL_CERT_PATH" -noout -checkend 0' >/dev/null 2>&1; then
        cert_fp="$(docker exec mailserver sh -c 'openssl x509 -in "$SSL_CERT_PATH" -outform DER | sha256sum' | cut -d' ' -f1)"
        log_warning "Mailserver certificate has expired; pinning it for mail-ingest"
    fi
    update_env_var "$SCRIPT_DIR/.env" "MAIL_INGEST_TLS_FINGERPRINT" "$cert_fp"
fi
