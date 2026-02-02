#!/bin/bash
# Report for vaultwarden

echo
echo "================================= Vaultwarden ========================="
echo
echo "Host: ${VAULTWARDEN_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  Web Vault: https://${VAULTWARDEN_HOSTNAME:-<hostname_not_set>}"
echo "  Admin Panel: https://${VAULTWARDEN_HOSTNAME:-<hostname_not_set>}/admin"
echo "  Internal API: http://vaultwarden:80"
echo
echo "⚠️  IMPORTANT - Admin Token Required for Admin Panel:"
echo "  Token: ${VAULTWARDEN_ADMIN_TOKEN:-<not_set>}"
echo
echo "First Steps:"
echo "  1. Access Admin Panel with token above"
echo "  2. Configure SMTP settings (using Mailpit)"
echo "  3. Set signup options (disabled by default)"
echo "  4. Create your first user account"
echo "  5. Install browser extension/mobile app"
echo
echo "Client Configuration:"
echo "  Browser Extensions: Set server URL to https://${VAULTWARDEN_HOSTNAME:-<hostname_not_set>}"
echo "  Mobile Apps: Add custom server during setup"
echo "  Desktop Apps: Configure server URL in preferences"
echo
echo "Compatible Clients:"
echo "  - Bitwarden Browser Extensions (all browsers)"
echo "  - Bitwarden Mobile Apps (iOS/Android)"
echo "  - Bitwarden Desktop (Windows/Mac/Linux)"
echo "  - Bitwarden CLI"
echo
echo "Security Features:"
echo "  - Signups disabled by default (enable in admin)"
echo "  - Domain whitelist: ${SIGNUPS_DOMAINS_WHITELIST:-not_set}"
echo "  - 2FA support (TOTP, WebAuthn, Duo, Email)"
echo "  - Emergency access feature"
echo "  - Send feature (secure file/text sharing)"
echo
echo "SMTP Configuration:"
echo "  Currently using: ${MAIL_MODE:-mailpit}"
echo "  Host: ${SMTP_HOST:-mailpit}"
echo "  Port: ${SMTP_PORT:-1025}"
echo
echo "Documentation: https://github.com/dani-garcia/vaultwarden"
