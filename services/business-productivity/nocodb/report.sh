#!/bin/bash
# Report for nocodb

echo
echo "================================= NocoDB =============================="
echo
echo "🗄️  Open Source Airtable Alternative"
echo
echo "Host: ${NOCODB_HOSTNAME:-<hostname_not_set>}"
echo "Admin Email: ${USER_EMAIL:-<not_set_in_env>}"
echo "Admin Password: ${NOCODB_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "Access Methods:"
echo "  External (HTTPS): https://${NOCODB_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://nocodb:8080"
echo
echo "n8n Integration:"
echo "  1. Use HTTP Request node with base URL: http://nocodb:8080"
echo "  2. API Token: Generate in NocoDB UI under 'API Tokens'"
echo "  3. Webhooks: Configure in table settings for automation"
echo
echo "Quick Start:"
echo "  1. Login with admin credentials above"
echo "  2. Create your first base (database)"
echo "  3. Import data or create tables"
echo "  4. Share views or collaborate with team"
echo
echo "Documentation: https://docs.nocodb.com"
echo "Community: https://discord.gg/5RgZmkW"
