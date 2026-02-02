#!/bin/bash
# Report for stirling-pdf

echo
echo "================================= Stirling-PDF ========================"
echo
echo "Advanced PDF manipulation with 100+ features"
echo
echo "Host: ${STIRLING_HOSTNAME:-<hostname_not_set>}"
echo "  Initial Login: admin / stirling"
echo "  Note: You'll be prompted to change password on first login"
echo
echo "Access:"
echo "  External (HTTPS): https://${STIRLING_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://stirling-pdf:8080"
echo
echo "n8n Integration:"
echo "  Use HTTP Request node with URL: http://stirling-pdf:8080/api/v1"
echo "  API Docs: http://stirling-pdf:8080/api/v1/docs"
echo
echo "Documentation: https://docs.stirlingpdf.com"
echo "GitHub: https://github.com/Stirling-Tools/Stirling-PDF"
