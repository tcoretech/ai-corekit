#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["OUTLINE_SECRET_KEY"]="hex:32"
    ["OUTLINE_UTILS_SECRET"]="hex:32"
    ["OUTLINE_MINIO_ROOT_PASSWORD"]="password:32"
    ["OUTLINE_OIDC_CLIENT_SECRET"]="apikey:32"
    ["DEX_ADMIN_PASSWORD"]="password:20"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Generate Dex Admin Password Hash if needed
if [[ -n "${SERVICE_ENV_VARS[DEX_ADMIN_PASSWORD]}" && -z "${SERVICE_ENV_VARS[DEX_ADMIN_PASSWORD_HASH]}" ]]; then
    log_info "Generating bcrypt hash for Dex Admin Password..."
    if command -v python3 &> /dev/null; then
        # Ensure bcrypt is installed or use a standard library method if possible? 
        # Python standard library doesn't have bcrypt. 
        # We might need to rely on the user having it or use a docker container.
        # The legacy script assumed python3 with bcrypt or just failed.
        # Let's try to use python3 if available, otherwise warn.
        
        # Check if bcrypt module is available
        if python3 -c "import bcrypt" &> /dev/null; then
            DEX_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw('${SERVICE_ENV_VARS[DEX_ADMIN_PASSWORD]}'.encode(), bcrypt.gensalt()).decode())")
            if [[ -n "$DEX_HASH" ]]; then
                update_env_var "$SCRIPT_DIR/.env" "DEX_ADMIN_PASSWORD_HASH" "$DEX_HASH"
                log_success "Generated DEX_ADMIN_PASSWORD_HASH"
            fi
        else
            log_warning "Python bcrypt module not found. Cannot generate DEX_ADMIN_PASSWORD_HASH."
            log_info "Install it with: pip3 install bcrypt"
        fi
    else
        log_warning "Python3 not found. Cannot generate DEX_ADMIN_PASSWORD_HASH."
    fi
fi

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
