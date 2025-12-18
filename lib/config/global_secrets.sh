#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../utils/utils_secrets.sh"

CONFIG_DIR="$PROJECT_ROOT/config"
GLOBAL_ENV="$CONFIG_DIR/global.env"
TEMPLATE_FILE="$CONFIG_DIR/.env.global.example"

# Ensure config dir exists
mkdir -p "$CONFIG_DIR"

# 1. Initialize .env.global
if [[ ! -f "$GLOBAL_ENV" ]]; then
    log_info "Creating .env.global from example..."
    cp "$TEMPLATE_FILE" "$GLOBAL_ENV"
fi

# Load existing global env into SERVICE_ENV_VARS for manipulation
_load_file_to_map "$GLOBAL_ENV"
# Copy ALL_ENV_VARS to SERVICE_ENV_VARS
for key in "${!ALL_ENV_VARS[@]}"; do
    SERVICE_ENV_VARS["$key"]="${ALL_ENV_VARS[$key]}"
done

# 2. Interactive Prompts

# Domain
if [[ -z "${SERVICE_ENV_VARS[DOMAIN]}" ]]; then
    while true; do
        echo ""
        read -p "Enter the primary domain name (e.g., example.com): " DOMAIN_INPUT
        if [[ -n "$DOMAIN_INPUT" ]]; then
            SERVICE_ENV_VARS["DOMAIN"]="$DOMAIN_INPUT"
            break
        fi
    done
fi

# Email
if [[ -z "${SERVICE_ENV_VARS[PRIMARY_EMAIL]}" ]]; then
    while true; do
        echo ""
        read -p "Enter your email address (for SSL & logins): " EMAIL_INPUT
        if [[ -n "$EMAIL_INPUT" ]]; then
            SERVICE_ENV_VARS["PRIMARY_EMAIL"]="$EMAIL_INPUT"
            break
        fi
    done
fi

# OpenAI Key (Optional)
if [[ -z "${SERVICE_ENV_VARS[OPENAI_API_KEY]}" ]]; then
    echo ""
    read -p "Enter OpenAI API Key (Optional, press Enter to skip): " OPENAI_INPUT
    if [[ -n "$OPENAI_INPUT" ]]; then
        SERVICE_ENV_VARS["OPENAI_API_KEY"]="$OPENAI_INPUT"
    fi
fi

# 3. Automatic Generation
declare -A SECRETS=(
    ["JWT_SECRET"]="base64:64"
)
generate_secrets SECRETS

# 4. Defaults & Sync
if [[ -z "${SERVICE_ENV_VARS[TZ]}" ]]; then SERVICE_ENV_VARS[TZ]="UTC"; fi
if [[ -z "${SERVICE_ENV_VARS[PUID]}" ]]; then SERVICE_ENV_VARS[PUID]="1000"; fi
if [[ -z "${SERVICE_ENV_VARS[PGID]}" ]]; then SERVICE_ENV_VARS[PGID]="1000"; fi

# Sync Domain vars
DOMAIN="${SERVICE_ENV_VARS[DOMAIN]}"
if [[ -n "$DOMAIN" ]]; then
    SERVICE_ENV_VARS["BASE_DOMAIN"]="$DOMAIN"
    SERVICE_ENV_VARS["USER_DOMAIN_NAME"]="$DOMAIN"
fi

# Sync Email vars
EMAIL="${SERVICE_ENV_VARS[PRIMARY_EMAIL]}"
if [[ -n "$EMAIL" ]]; then
    SERVICE_ENV_VARS["LETSENCRYPT_EMAIL"]="$EMAIL"
fi

# 5. Write back
write_env_file "$TEMPLATE_FILE" "$GLOBAL_ENV"
log_success "Updated global configuration in config/.env.global"
