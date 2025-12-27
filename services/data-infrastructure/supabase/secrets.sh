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
    ["PG_META_CRYPTO_KEY"]="alphanum:32"
    ["LOGFLARE_PRIVATE_ACCESS_TOKEN"]="fixed:not-in-use"
    ["LOGFLARE_PUBLIC_ACCESS_TOKEN"]="fixed:not-in-use"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Generate JWTs if missing
if [[ -z "${SERVICE_ENV_VARS[ANON_KEY]}" ]] || [[ -z "${SERVICE_ENV_VARS[SERVICE_ROLE_KEY]}" ]]; then
    log_info "Generating Supabase JWTs..."
    
    JWT_SECRET="${SERVICE_ENV_VARS[JWT_SECRET]}"
    
    if [[ -n "$JWT_SECRET" ]]; then
        # Python script to sign JWT
        read -r -d '' PY_SCRIPT << EOM
import sys
import json
import base64
import hmac
import hashlib
import time

def base64url_encode(input):
    return base64.urlsafe_b64encode(input).replace(b'=', b'').decode('utf-8')

def sign(payload, secret):
    header = {"alg": "HS256", "typ": "JWT"}
    header_enc = base64url_encode(json.dumps(header).encode('utf-8'))
    payload_enc = base64url_encode(json.dumps(payload).encode('utf-8'))
    msg = f"{header_enc}.{payload_enc}"
    signature = hmac.new(secret.encode('utf-8'), msg.encode('utf-8'), hashlib.sha256).digest()
    sig_enc = base64url_encode(signature)
    return f"{msg}.{sig_enc}"

secret = sys.argv[1]
role = sys.argv[2]

payload = {
    "role": role,
    "iss": "supabase",
    "iat": int(time.time()),
    "exp": int(time.time()) + 315360000 # 10 years
}

print(sign(payload, secret))
EOM
        
        ANON_KEY=$(python3 -c "$PY_SCRIPT" "$JWT_SECRET" "anon")
        SERVICE_ROLE_KEY=$(python3 -c "$PY_SCRIPT" "$JWT_SECRET" "service_role")
        
        SERVICE_ENV_VARS["ANON_KEY"]="$ANON_KEY"
        SERVICE_ENV_VARS["SERVICE_ROLE_KEY"]="$SERVICE_ROLE_KEY"
    else
        log_warning "JWT_SECRET is missing, cannot generate JWTs."
    fi
fi

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
