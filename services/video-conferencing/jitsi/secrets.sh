#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Assuming standard depth: services/<category>/<service>/secrets.sh
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

# Load current environment
load_all_env "$SCRIPT_DIR"


####### Define secrets to generate #########

declare -A SECRETS=(
    ["JICOFO_COMPONENT_SECRET"]="password:32"
    ["JICOFO_AUTH_PASSWORD"]="password:32"
    ["JVB_AUTH_PASSWORD"]="password:32"
)

############################################


# Generate secrets
generate_secrets SECRETS


########## Post-processing #################

# Auto-detect Docker Host Address for JVB (Jitsi)
if [[ -z "${SERVICE_ENV_VARS[JVB_DOCKER_HOST_ADDRESS]}" ]]; then
    # Try to detect public IP
    PUBLIC_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "")
    if [[ -n "$PUBLIC_IP" ]]; then
        SERVICE_ENV_VARS["JVB_DOCKER_HOST_ADDRESS"]="$PUBLIC_IP"
    fi
fi

# Jitsi Hostname logic
if [[ -z "${SERVICE_ENV_VARS[JITSI_HOSTNAME]}" && -n "${SERVICE_ENV_VARS[DOMAIN]}" ]]; then
     SERVICE_ENV_VARS["JITSI_HOSTNAME"]="meet.${SERVICE_ENV_VARS[DOMAIN]}"
fi

if [[ -n "${SERVICE_ENV_VARS[JITSI_HOSTNAME]}" ]]; then
    SERVICE_ENV_VARS["PUBLIC_URL"]="https://${SERVICE_ENV_VARS[JITSI_HOSTNAME]}"
    SERVICE_ENV_VARS["ENABLE_XMPP_WEBSOCKET"]="true"
    SERVICE_ENV_VARS["XMPP_DOMAIN"]="meet.jitsi"
    SERVICE_ENV_VARS["XMPP_SERVER"]="jitsi-prosody"
fi

############################################

# Write .env
write_service_env "$SCRIPT_DIR"
