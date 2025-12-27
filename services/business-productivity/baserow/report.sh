#!/bin/bash
# Report for baserow

echo
echo "================================= Baserow ============================"
echo
echo "Host: ${BASEROW_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External: https://${BASEROW_HOSTNAME:-<hostname_not_set>}"
echo "  Internal API: http://baserow:80"
echo
echo "Setup:"
echo "  First user to register becomes admin"
echo "  Create workspaces and databases after login"
echo
echo "n8n Integration:"
echo "  External URL: https://${BASEROW_HOSTNAME:-<hostname_not_set>}"
echo "  Internal URL: http://baserow:80 (add Host header: ${BASEROW_HOSTNAME})"
echo "  Or use external URL for simpler setup"
echo "  Authentication: Username/Password or API Token"
echo "  Generate API token in user settings after setup"
echo
echo "Documentation: https://baserow.io/docs"
