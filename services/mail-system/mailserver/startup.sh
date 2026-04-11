#!/bin/bash
# startup.sh - Provision mail accounts after mailserver container is running
# Runs on the HOST after docker compose up

source "$PROJECT_ROOT/lib/utils/logging.sh"

# Wait for mailserver to be ready
log_info "Waiting for mailserver to accept commands..."
for i in $(seq 1 30); do
    if docker exec mailserver setup email list &>/dev/null; then
        break
    fi
    sleep 2
done

# Provision accounts idempotently
# Usage: ensure_account <email> <password_env_var>
ensure_account() {
    local email="$1"
    local password="$2"

    if [[ -z "$password" ]]; then
        log_warning "Skipping $email: no password set"
        return
    fi

    if docker exec mailserver setup email list | grep -q "^\\* $email"; then
        log_info "Account $email already exists"
        docker exec mailserver setup email update "$email" "$password" 2>/dev/null
    else
        log_info "Creating account $email"
        docker exec mailserver setup email add "$email" "$password"
    fi
}

ensure_account "noreply@${BASE_DOMAIN}" "${MAIL_NOREPLY_PASSWORD}"
ensure_account "info@${BASE_DOMAIN}" "${MAIL_INFO_PASSWORD}"

log_success "Mail accounts provisioned"
