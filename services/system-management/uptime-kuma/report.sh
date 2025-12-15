#!/bin/bash
# Report for uptime-kuma

echo
echo "================================= Uptime Kuma ========================="
echo
echo "Host: ${UPTIME_KUMA_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${UPTIME_KUMA_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://uptime-kuma:3001"
echo
echo "First Steps:"
echo "  1. Visit https://${UPTIME_KUMA_HOSTNAME:-<hostname_not_set>}"
echo "  2. Create your first admin account (first user = admin)"
echo "  3. Optional: Enable 2FA for extra security"
echo "  4. Create your first monitor"
echo "  5. Set up notification channels (Discord, Telegram, Email, etc.)"
echo
echo "Public Status Pages:"
echo "  Create public status pages for your customers"
echo "  Share uptime information transparently"
echo "  Configure in Settings → Status Pages"
echo
echo "n8n Integration:"
echo "  Use HTTP Request node with URL: http://uptime-kuma:3001"
echo "  Webhooks: Configure in monitor settings"
echo "  API: Generate API token in Settings → API Keys"
echo
echo "Documentation: https://github.com/louislam/uptime-kuma/wiki"
