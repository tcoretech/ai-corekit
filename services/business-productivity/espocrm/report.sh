#!/bin/bash
# Report for espocrm

echo
echo "================================= EspoCRM ============================="
echo
echo "Host: ${ESPOCRM_HOSTNAME:-<hostname_not_set>}"
echo
echo "Initial Admin Account:"
echo "  Username: ${ESPOCRM_ADMIN_USERNAME:-admin}"
echo "  Password: ${ESPOCRM_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${ESPOCRM_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://espocrm:80"
echo
echo "Setup:"
echo "  1. Visit https://${ESPOCRM_HOSTNAME:-<hostname_not_set>}"
echo "  2. Login with admin credentials above"
echo "  3. Configure additional users at Administration > Users"
echo "  4. Set up email integration for campaigns"
echo
echo "n8n Integration:"
echo "  API Endpoint: http://espocrm:80/api/v1/"
echo "  Authentication: API Key (generate in user preferences)"
echo "  Webhooks: Administration > Webhooks (for real-time events)"
echo
echo "Documentation: https://docs.espocrm.com/"
