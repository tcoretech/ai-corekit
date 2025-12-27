#!/bin/bash
# Report for seafile

echo
echo "================================= Seafile ============================"
echo
echo "Host: ${SEAFILE_HOSTNAME:-<hostname_not_set>}"
echo "Admin Email: ${SEAFILE_ADMIN_EMAIL}"
echo "Admin Password: ${SEAFILE_ADMIN_PASSWORD:-<not_set>}"
echo
echo "Access: https://${SEAFILE_HOSTNAME:-<hostname_not_set>}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "n8n Integration:"
echo "  Install community node: n8n-nodes-seafile"
echo "  Internal URL: http://seafile:80"
echo "  API Docs: https://manual.seafile.com/develop/web_api_v2.1/"
echo
echo "Desktop/Mobile Apps:"
echo "  Download: https://www.seafile.com/en/download/"
echo
echo "Documentation: https://manual.seafile.com/"
