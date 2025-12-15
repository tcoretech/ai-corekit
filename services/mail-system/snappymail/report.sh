#!/bin/bash
# Report for snappymail

  echo
  echo "================================= SnappyMail Webmail =================="
  echo
  echo "✅ Modern webmail interface ready"
  echo
  echo "Access:"
  echo "  URL: https://${SNAPPYMAIL_HOSTNAME:-webmail.${BASE_DOMAIN}}"
  echo "  Admin Panel: https://${SNAPPYMAIL_HOSTNAME:-webmail.${BASE_DOMAIN}}/?admin"
  echo
  echo "⚠️  IMPORTANT - Get Admin Password:"
  echo "  The admin password is auto-generated on first start."
  echo "  Run this command to see it:"
  echo "  docker exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt"
  echo
  echo "First Time Setup:"
  echo "  1. Get admin password with command above"
  echo "  2. Login to admin panel: /?admin"
  echo "  3. Username: admin"
  echo "  4. Go to Domains → Add Domain"
  echo "  5. Add domain: ${BASE_DOMAIN}"
  echo "  6. IMAP Server: mailserver"
  echo "  7. IMAP Port: 143"
  echo "  8. SMTP Server: mailserver"
  echo "  9. SMTP Port: 587"
  echo "  10. Use STARTTLS for both"
  echo
  echo "Users can then login with:"
  echo "  Email: their-email@${BASE_DOMAIN}"
  echo "  Password: their Docker-Mailserver password"
  echo
  echo "Documentation: https://github.com/the-djmaze/snappymail/wiki"
# Auto-configure domain if setup script exists
  if [ -f "$SCRIPT_DIR/setup_snappymail.sh" ]; then
    log_info "Checking SnappyMail domain configuration..."
    bash $SCRIPT_DIR/setup_snappymail.sh
  fi
