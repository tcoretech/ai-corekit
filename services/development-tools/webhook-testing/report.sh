#!/bin/bash
# Report for webhook-testing

echo
echo "================================= WEBHOOK TESTING SUITE ==============="
echo
echo "============ Webhook Tester (Incoming Webhook Debugger) =============="
echo "Host: ${WEBHOOK_TESTER_HOSTNAME:-<hostname_not_set>}"
echo "User: ${WEBHOOK_TESTER_USERNAME:-<not_set_in_env>}"
echo "Password: ${WEBHOOK_TESTER_PASSWORD:-<not_set_in_env>}"
echo "URL: https://${WEBHOOK_TESTER_HOSTNAME:-<hostname_not_set>}"
echo "Internal URL: http://webhook-tester:8080"
echo
echo "============ Hoppscotch (API Testing Platform) ======================"
echo "Host: ${HOPPSCOTCH_HOSTNAME:-<hostname_not_set>}"
echo "URL: https://${HOPPSCOTCH_HOSTNAME:-<hostname_not_set>}"
echo "Admin Dashboard: https://${HOPPSCOTCH_HOSTNAME:-<hostname_not_set>}/admin"
echo "Internal API: http://hoppscotch:3170"
echo
echo "⚠️  First-time setup:"
echo "  1. Visit https://${HOPPSCOTCH_HOSTNAME:-<hostname_not_set>}"
echo "  2. Create your account with email"
echo "  3. Check Mailpit for verification email"
echo "  4. Admin dashboard at /admin (first user = admin)"
echo
echo "Documentation: https://docs.hoppscotch.io"
