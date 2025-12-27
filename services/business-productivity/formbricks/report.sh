#!/bin/bash
# Report for formbricks

echo
echo "================================= Formbricks Surveys ==================="
echo
echo "🌐 Access URL: https://${FORMBRICKS_HOSTNAME:-<hostname_not_set>}"
echo
echo "🔐 Setup Instructions:"
echo "  1. Open the URL above"
echo "  2. Click 'Sign up' to create the first admin account"
echo "  3. First user automatically becomes organization owner"
echo
echo "🔌 Integration Endpoints:"
echo "  Webhook URL: https://${FORMBRICKS_HOSTNAME:-<hostname_not_set>}/api/v1/webhooks"
echo "  API Base: https://${FORMBRICKS_HOSTNAME:-<hostname_not_set>}/api/v1"
echo "  Internal (n8n): http://formbricks:3000/api/v1"
echo
echo "📝 Survey Types:"
echo "  ✓ Link Surveys - Share via URL"
echo "  ✓ Web Surveys - Embed on websites"  
echo "  ✓ In-App Surveys - Target specific users"
echo "  ✓ Email Surveys - Send via campaigns"
echo
echo "🔗 n8n Integration:"
echo "  Native Node: Install @formbricks/n8n-nodes-formbricks"
echo "  Webhook Trigger: Use 'On Response Completed' webhook"
echo "  API Key: Settings → API Keys (after login)"
echo
echo "📚 Documentation: https://formbricks.com/docs"
echo "💬 Discord: https://formbricks.com/discord"
