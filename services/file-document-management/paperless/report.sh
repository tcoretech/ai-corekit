#!/bin/bash
# Report for paperless

echo
echo "========================== Paperless-ngx ============================"
echo
echo "Host: ${PAPERLESS_HOSTNAME:-<hostname_not_set>}"
echo "Admin User: ${PAPERLESS_ADMIN_EMAIL}"
echo "Admin Password: ${PAPERLESS_ADMIN_PASSWORD:-<not_set>}"
echo
echo "Access: https://${PAPERLESS_HOSTNAME:-<hostname_not_set>}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Integration:"
echo "  - Consume folder: ./shared (accessible from Seafile)"
echo "  - API URL: http://paperless:8000/api/"
echo "  - API Token: Generate in user settings"
echo
echo "Mobile Apps:"
echo "  - iOS: 'Paperless Mobile'"
echo "  - Android: 'Paperless Mobile'"
echo
echo "Documentation: https://docs.paperless-ngx.com/"
echo "Community: https://github.com/paperless-ngx/paperless-ngx/discussions"
