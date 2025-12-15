#!/bin/bash
# Report for mailserver

echo
echo "================================= Docker-Mailserver ==================="
echo
echo "✅ Production mail server ready for all services"
echo
echo "Auto-configured Account:"
echo "  Email: noreply@${BASE_DOMAIN}"
echo "  Password: ${MAIL_NOREPLY_PASSWORD:-<check_env_file>}"
echo
echo "SMTP Settings (automatically configured for all services):"
echo "  Host: mailserver (internal)"
echo "  Port: 587"
echo "  Security: STARTTLS"
echo "  User: noreply@${BASE_DOMAIN}"
if [[ -n "${MAILGUN_SMTP_HOST}" ]]; then
  echo
  echo "Outbound Relay: Mailgun SMTP"
  echo "  Relay Host: ${MAILGUN_SMTP_HOST:-<not_set>}"
  echo "  Relay Port: ${MAILGUN_SMTP_PORT:-587}"
  echo "  Relay User: ${MAILGUN_SMTP_USER:-<not_set>}"
fi
echo
echo "Services using this mail server:"
echo "  ✓ Cal.com - Appointment notifications"
echo "  ✓ Baserow - User invitations"
echo "  ✓ Odoo - All email features"
echo "  ✓ n8n - Email nodes"
echo "  ✓ Supabase - Auth emails"

echo
echo "Mailgun Intake Webhook (mail-ingest service):"
echo "  Hostname: ${MAIL_INGEST_HOSTNAME:-mail-ingest.${BASE_DOMAIN}}"
echo "  Endpoint: https://${MAIL_INGEST_HOSTNAME:-mail-ingest.${BASE_DOMAIN}}/mailgun/incoming"
echo "  Signing Key (Mailgun private API key): ${MAILGUN_WEBHOOK_SIGNING_KEY:-<not_set_in_env>}"
echo "  Route hint: Mailgun → Store and Notify → POST to the endpoint above"
echo "  Internal health: http://mail-ingest:3000/healthz"
echo
echo "⚠️  IMPORTANT: Configure these DNS records:"
echo
echo "1. MX Record:"
echo "   Type: MX"
echo "   Name: ${BASE_DOMAIN}"
echo "   Value: mail.${BASE_DOMAIN}"
echo "   Priority: 10"
echo
echo "2. A Record for mail subdomain:"
echo "   Type: A"
echo "   Name: mail"
echo "   Value: YOUR_SERVER_IP"
echo
echo "3. SPF Record:"
echo "   Type: TXT"
echo "   Name: @"
echo "   Value: \"v=spf1 mx ~all\""
echo
echo "4. DMARC Record:"
echo "   Type: TXT"
echo "   Name: _dmarc"
echo "   Value: \"v=DMARC1; p=none; rua=mailto:postmaster@${BASE_DOMAIN}\""
echo
echo "5. DKIM Record:"
# Check if DKIM was generated during installation
if [ -f "dkim_record.txt" ]; then
  echo "   ✅ DKIM KEY AUTOMATICALLY GENERATED!"
  echo ""
  echo "   Copy this ENTIRE record to your DNS as TXT record:"
  echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cat dkim_record.txt | sed 's/^/   /'
  echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "   DNS Record Name: mail._domainkey.${BASE_DOMAIN}"
  echo "   Type: TXT"
else
  echo "   ⚠️  DKIM not generated automatically"
  echo "   Run manually: docker exec mailserver setup config dkim"
  echo "   Then copy the output to DNS"
fi
echo
echo "Commands:"
echo "  Add user: docker exec -it mailserver setup email add user@${BASE_DOMAIN}"
echo "  List users: docker exec -it mailserver setup email list"
echo "  DKIM setup: docker exec mailserver setup config dkim"
echo "  View logs: docker logs mailserver"
echo
echo "Documentation: https://docker-mailserver.github.io/docker-mailserver/"
