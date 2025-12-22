#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# Only run if interactive
if [[ -t 0 ]]; then
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🔎 PRIVATE DNS (CoreDNS) CONFIGURATION"
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""

    DNS_ENV_FILE="$SCRIPT_DIR/.env"
    
    # Ensure .env exists
    if [[ ! -f "$DNS_ENV_FILE" ]]; then
        cp "$SCRIPT_DIR/.env.example" "$DNS_ENV_FILE"
    fi

    # Load Local Env
    if [ -f "$DNS_ENV_FILE" ]; then
        set -a
        source "$DNS_ENV_FILE"
        set +a
    fi

    existing_dns_ip=${PRIVATE_DNS_TARGET_IP}
    existing_dns_hosts=${PRIVATE_DNS_HOSTS}
    existing_dns_fwd1=${PRIVATE_DNS_FORWARD_1}
    existing_dns_fwd2=${PRIVATE_DNS_FORWARD_2}

    default_dns_ip=${existing_dns_ip:-10.255.0.5}
    default_dns_hosts=${existing_dns_hosts:-"mail.yourdomain.com ssh.yourdomain.com yourdomain.local"}
    default_fwd1=${existing_dns_fwd1:-1.1.1.1}
    default_fwd2=${existing_dns_fwd2:-1.0.0.1}

    # Check if configuration already exists and is valid
    if [[ -n "$existing_dns_ip" ]] && [[ -n "$existing_dns_hosts" ]]; then
        log_info "Configuration found in .env. Skipping interactive prompt."
        dns_ip=$existing_dns_ip
        dns_hosts=$existing_dns_hosts
        dns_fwd1=$existing_dns_fwd1
        dns_fwd2=$existing_dns_fwd2
    else
        read -p "Bind IP for private DNS [${default_dns_ip}]: " input_dns_ip
        read -p "Hostnames (space-separated) [${default_dns_hosts}]: " input_dns_hosts
        read -p "Forwarder 1 [${default_fwd1}]: " input_dns_fwd1
        read -p "Forwarder 2 [${default_fwd2}]: " input_dns_fwd2

        dns_ip=${input_dns_ip:-$default_dns_ip}
        dns_hosts=${input_dns_hosts:-$default_dns_hosts}
        dns_fwd1=${input_dns_fwd1:-$default_fwd1}
        dns_fwd2=${input_dns_fwd2:-$default_fwd2}
        
        # Update .env
        update_env_var "$DNS_ENV_FILE" "PRIVATE_DNS_TARGET_IP" "${dns_ip}"
        update_env_var "$DNS_ENV_FILE" "PRIVATE_DNS_HOSTS" "${dns_hosts}"
        update_env_var "$DNS_ENV_FILE" "PRIVATE_DNS_FORWARD_1" "${dns_fwd1}"
        update_env_var "$DNS_ENV_FILE" "PRIVATE_DNS_FORWARD_2" "${dns_fwd2}"

        echo ""
        log_success "✅ Private DNS settings saved to .env"
        echo "Remember to ensure the bind IP (${dns_ip}) exists on the host."
        echo ""
    fi
fi

# Generate Corefile from template
COREFILE_TEMPLATE="$SCRIPT_DIR/config/Corefile.template"
COREFILE_OUTPUT="$SCRIPT_DIR/config/local/Corefile"

if [ -f "$COREFILE_TEMPLATE" ]; then
    log_info "Generating Corefile from template..."
    
    # Ensure output directory exists
    mkdir -p "$(dirname "$COREFILE_OUTPUT")"
    
    # Read values from .env (re-read to ensure we have latest)
    # We need to export them for envsubst if we use it, or manual substitution
    if [ -f "$DNS_ENV_FILE" ]; then
        set -a
        source "$DNS_ENV_FILE"
        set +a
    fi
    
    # Manual substitution to avoid dependency on envsubst and handle defaults
    # Read template
    content=$(cat "$COREFILE_TEMPLATE")
    
    # Replace variables
    # Note: We use | as delimiter for sed to avoid issues with / in paths/IPs
    content=${content//\$\{PRIVATE_DNS_TARGET_IP\}/${PRIVATE_DNS_TARGET_IP}}
    content=${content//\$\{PRIVATE_DNS_HOSTS\}/${PRIVATE_DNS_HOSTS}}
    content=${content//\$\{PRIVATE_DNS_FORWARD_1\}/${PRIVATE_DNS_FORWARD_1}}
    content=${content//\$\{PRIVATE_DNS_FORWARD_2\}/${PRIVATE_DNS_FORWARD_2}}
    
    # Write output
    echo "$content" > "$COREFILE_OUTPUT"
    log_success "✅ Corefile generated at config/local/Corefile"
fi
