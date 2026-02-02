#!/bin/bash
# Report for docuseal

echo
echo "================================= DocuSeal E-Signatures =============="
echo
echo "Host: ${DOCUSEAL_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${DOCUSEAL_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://docuseal:3000"
echo
echo "Initial Setup:"
echo "  1. Visit https://${DOCUSEAL_HOSTNAME:-<hostname_not_set>}"
echo "  2. Complete setup wizard"
echo "  3. Create admin account"
echo "  4. Configure SMTP for notifications (optional)"
echo
echo "n8n Integration:"
echo "  API Base: http://docuseal:3000/api"
echo "  Webhooks: Configure in DocuSeal settings"
echo
echo "Documentation: https://docs.docuseal.co"
