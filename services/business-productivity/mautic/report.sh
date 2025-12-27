#!/bin/bash
# Report for mautic

echo
echo "================================= MAUTIC =============================="
echo
echo "Marketing Automation Platform"
echo
echo "Access URL: https://${MAUTIC_HOSTNAME:-<hostname_not_set>}"
echo
echo "INSTALLATION WIZARD - Database Setup:"
echo "  Database Driver: MySQL PDO (Recommended)"
echo "  Database Host: mautic_db"
echo "  Database Port: 3306"
echo "  Database Name: mautic"
echo "  Database Username: mautic"
echo "  Database Password: ${MAUTIC_DB_PASSWORD:-<not_set_in_env>}"
echo
echo "Admin Account (after installation):"
echo "  Email: ${MAUTIC_ADMIN_EMAIL:-<not_set_in_env>}"
echo "  Password: ${MAUTIC_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "Email Configuration (for sending):"
echo "  Mailer: SMTP"
echo "  Server: mailpit (for testing)"
echo "  Port: 1025"
echo "  Encryption: None"
echo "  OR use external SMTP (Mailjet, SendGrid, etc.)"
echo
echo "API Access (for n8n):"
echo "  Base URL: https://${MAUTIC_HOSTNAME:-<hostname_not_set>}/api"
echo "  Internal: http://mautic_web/api"
echo "  Enable API: Settings → Configuration → API Settings"
echo "  Create API credentials: Settings → API Credentials"
echo
echo "n8n Integration:"
echo "  1. Add Mautic node in n8n"
echo "  2. Use URL: http://mautic_web"
echo "  3. Create OAuth2 credentials in Mautic"
echo "  4. Configure webhook: http://n8n:5678/webhook/mautic"
echo
echo "Quick Start:"
echo "  1. Open https://${MAUTIC_HOSTNAME:-<hostname_not_set>}"
echo "  2. Complete installation wizard with database info above"
echo "  3. Create your first contact in Contacts → New"
echo "  4. Build your first campaign in Campaigns → New"
echo
echo "Documentation: https://docs.mautic.org"
echo "Community: https://forum.mautic.org"
