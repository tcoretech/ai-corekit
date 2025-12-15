#!/bin/bash
# Report for invoiceninja

echo
echo "================================= Invoice Ninja ========================"
echo
echo "🌐 Access URL: https://${INVOICENINJA_HOSTNAME:-<hostname_not_set>}/login"
echo
echo "⚠️  APP_KEY Status:"
if [[ -n "${INVOICENINJA_APP_KEY}" ]]; then
  echo "  ✅ APP_KEY is configured"
else
  echo "  ❌ APP_KEY MISSING! Generate with:"
  echo "     docker run --rm invoiceninja/invoiceninja:5 php artisan key:generate --show"
  echo "     Then add to .env as INVOICENINJA_APP_KEY"
fi
echo
echo "👤 Initial Admin Account:"
echo "  Email: ${INVOICENINJA_ADMIN_EMAIL:-<not_set_in_env>}"
echo "  Password: ${INVOICENINJA_ADMIN_PASSWORD:-<not_set_in_env>}"
echo "  Note: Delete IN_USER_EMAIL and IN_PASSWORD from .env after first login!"
echo
echo "🔌 API Endpoints:"
echo "  External: https://${INVOICENINJA_HOSTNAME:-<hostname_not_set>}/api/v1"
echo "  Internal (n8n): http://invoiceninja:8000/api/v1"
echo
echo "🔗 n8n Integration:"
echo "  Native node available! Search for 'Invoice Ninja' in n8n"
echo "  API Token: Settings → Account Management → API Tokens"
echo
echo "📚 Documentation: https://invoiceninja.github.io/"
echo "🎥 Videos: https://www.youtube.com/channel/UCXjmYgQdCTpvHZSQ0x6VFRA"
