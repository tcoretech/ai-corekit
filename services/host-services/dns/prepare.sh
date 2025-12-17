#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/scripts/utils.sh"

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

    # Read existing values
    existing_dns_ip=$(grep "^PRIVATE_DNS_TARGET_IP=" "$DNS_ENV_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')
    existing_dns_hosts=$(grep "^PRIVATE_DNS_HOSTS=" "$DNS_ENV_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')
    existing_dns_fwd1=$(grep "^PRIVATE_DNS_FORWARD_1=" "$DNS_ENV_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')
    existing_dns_fwd2=$(grep "^PRIVATE_DNS_FORWARD_2=" "$DNS_ENV_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')
    base_domain_val=$(grep "^PRIVATE_BASE_DOMAIN=" "$DNS_ENV_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')

    default_dns_ip=${existing_dns_ip:-10.255.0.5}
    base_no_tld="${base_domain_val%%.*}"
    default_dns_hosts=${existing_dns_hosts:-"mail.${base_domain_val:-yourdomain.com} ssh.${base_domain_val:-yourdomain.com} ${base_no_tld:-yourdomain}.local"}
    default_fwd1=${existing_dns_fwd1:-1.1.1.1}
    default_fwd2=${existing_dns_fwd2:-1.0.0.1}

    read -p "Bind IP for private DNS [${default_dns_ip}]: " input_dns_ip
    read -p "Hostnames (space-separated) [${default_dns_hosts}]: " input_dns_hosts
    read -p "Forwarder 1 [${default_fwd1}]: " input_dns_fwd1
    read -p "Forwarder 2 [${default_fwd2}]: " input_dns_fwd2

    dns_ip=${input_dns_ip:-$default_dns_ip}
    dns_hosts=${input_dns_hosts:-$default_dns_hosts}
    dns_fwd1=${input_dns_fwd1:-$default_fwd1}
    dns_fwd2=${input_dns_fwd2:-$default_fwd2}

    # Update .env
    # We can use sed or a helper if available. Using sed as in wizard.
    sed -i "s|^PRIVATE_DNS_TARGET_IP=.*|PRIVATE_DNS_TARGET_IP=${dns_ip}|g" "$DNS_ENV_FILE"
    sed -i "s|^PRIVATE_DNS_HOSTS=.*|PRIVATE_DNS_HOSTS=\"${dns_hosts}\"|g" "$DNS_ENV_FILE"
    sed -i "s|^PRIVATE_DNS_FORWARD_1=.*|PRIVATE_DNS_FORWARD_1=${dns_fwd1}|g" "$DNS_ENV_FILE"
    sed -i "s|^PRIVATE_DNS_FORWARD_2=.*|PRIVATE_DNS_FORWARD_2=${dns_fwd2}|g" "$DNS_ENV_FILE"

    echo ""
    log_success "✅ Private DNS settings saved to .env"
    echo "Remember to ensure the bind IP (${dns_ip}) exists on the host."
    echo ""
fi
