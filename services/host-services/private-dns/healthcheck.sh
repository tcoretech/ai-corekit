#!/bin/bash
source "../../../lib/utils/logging.sh"

log_info "Verifying Private DNS..."
target_ip="${PRIVATE_DNS_TARGET_IP:-10.255.0.5}"
test_domain="mail.${PRIVATE_BASE_DOMAIN:-example.com}"

if command -v dig &> /dev/null; then
    if dig @"$target_ip" "$test_domain" +short +time=2 +tries=1 | grep -q "$target_ip"; then
        log_success "Private DNS is responding correctly."
        exit 0
    else
        log_warning "Private DNS check failed. It might still be starting up."
        exit 1
    fi
else
    log_warning "Cannot verify Private DNS: 'dig' not found on host."
    exit 1
fi
