#!/bin/bash
# Report for outline

echo
echo "================================= Outline Wiki ========================"
echo
echo "Host: ${OUTLINE_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  Wiki URL: https://${OUTLINE_HOSTNAME:-<hostname_not_set>}"
echo "  Login URL: https://${OUTLINE_HOSTNAME:-<hostname_not_set>}/auth/login"
echo
echo "🔐 Authentication (Local Dex Identity Provider):"
echo "  Admin Email: ${DEX_ADMIN_EMAIL:-<not_set_in_env>}"
echo "  Admin Password: ${DEX_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "✅ Login Process:"
echo "  1. Visit https://${OUTLINE_HOSTNAME:-<hostname_not_set>}"
echo "  2. Click 'Continue with Login'"
echo "  3. Enter admin credentials above"
echo "  4. First login creates Outline workspace"
echo
echo "MinIO S3 Storage:"
echo "  Admin UI: https://${OUTLINE_S3_ADMIN_HOSTNAME:-<hostname_not_set>}"
echo "  Username: minio"
echo "  Password: ${OUTLINE_MINIO_ROOT_PASSWORD:-<not_set>}"
echo "  Note: Bucket 'outline' auto-created on first start"
echo
echo "n8n Integration:"
echo "  Webhooks: Configure in Outline settings"
echo "  API: Requires API token from user settings"
echo
echo "💡 Tips:"
echo "  - Fully self-hosted, no external dependencies!"
echo "  - GDPR/DSGVO compliant solution"
echo "  - Add more users: Create in Dex config"
echo
echo "Documentation: https://docs.getoutline.com"
