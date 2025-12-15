#!/bin/bash
# Report for odoo

echo
echo "================================= Odoo 18 ERP/CRM ====================="
echo
echo "Host: ${ODOO_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access URLs:"
echo "  Main: https://${ODOO_HOSTNAME:-<hostname_not_set>}"
echo "  Internal: http://odoo:8069"
echo
echo "Database Setup (first login):"
echo "  Master Password: ${ODOO_MASTER_PASSWORD:-<check .env file>}"
echo "  Database Name: odoo"
echo "  Admin Email: Use your email"
echo "  Admin Password: Create a strong password"
echo
echo "n8n Integration:"
echo "  Use native Odoo node in n8n"
echo "  Internal URL: http://odoo:8069"
echo "  API Endpoint: /web/session/authenticate"
echo
echo "Resources:"
echo "  RAM Usage: ~2-4GB (2 workers)"
echo "  Disk: ~5-10GB initial"
echo
echo "Documentation: https://www.odoo.com/documentation/18.0/"
