#!/bin/bash
# Report for calcom

echo
echo "================================= Cal.com ============================="
echo
echo "Host: ${CALCOM_HOSTNAME:-cal.${BASE_DOMAIN}}"
echo
echo "Access URL: https://${CALCOM_HOSTNAME:-cal.${BASE_DOMAIN}}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "First Steps:"
echo "  1. Open the URL above in your browser"
echo "  2. First user to register becomes admin"
echo "  3. Configure your availability in Settings"
echo "  4. Create event types (15min, 30min, 60min meetings)"
echo "  5. Share your booking link: https://${CALCOM_HOSTNAME}/USERNAME"
echo
echo "Email Configuration:"
echo "  Using: ${MAIL_MODE:-mailpit} (${SMTP_HOST}:${SMTP_PORT})"
echo "  Bookings will be captured in Mailpit"
echo
echo "📚 Documentation:"
echo "  Setup Guide: ~/ai-corekit/docs/CALCOM_SETUP.md"
echo "  - Google Calendar integration instructions"
echo "  - Zoom, Stripe, MS365 integrations"
echo "  - Troubleshooting guide"
echo "  Online: https://github.com/tcoretech/ai-corekit/blob/main/docs/CALCOM_SETUP.md"  
echo
echo "n8n Integration:"
echo "  Base URL: http://calcom:3000/api/v2"
echo "  Auth: Generate API key in Settings → Developer → API Keys"
echo "  Docs: https://api.cal.com/v2/docs"
echo
echo "Documentation: https://cal.com/docs"
