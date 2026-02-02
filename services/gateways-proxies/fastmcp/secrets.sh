#!/bin/bash
# FastMCP Secrets Generation
# Generates API key for the FastMCP gateway

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/../../../lib/utils/secrets.sh"

load_all_env "$SCRIPT_DIR"

declare -A SECRETS=(
    ["FASTMCP_API_KEY"]="apikey:64"
)

generate_secrets SECRETS
write_service_env "$SCRIPT_DIR"
