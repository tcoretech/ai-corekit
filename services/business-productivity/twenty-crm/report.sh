#!/bin/bash
# Report for twenty-crm

echo
echo "================================= Twenty CRM =========================="
echo
echo "Host: ${TWENTY_CRM_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${TWENTY_CRM_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://twenty-crm:3000"
echo
echo "Setup:"
echo "  1. Visit https://${TWENTY_CRM_HOSTNAME:-<hostname_not_set>}"
echo "  2. Create your first workspace during initial setup"
echo "  3. Configure workspace settings and invite team members"
echo
echo "n8n Integration:"
echo "  GraphQL Endpoint: http://twenty-crm:3000/graphql"
echo "  REST API: http://twenty-crm:3000/rest"
echo "  Note: Generate API key in workspace settings after setup"
echo
echo "Documentation: https://twenty.com/developers"
