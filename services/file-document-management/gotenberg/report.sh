#!/bin/bash
# Report for gotenberg

echo
echo "================================= Gotenberg ============================"
echo
echo "Internal Access (e.g., from n8n): http://gotenberg:3000"
echo "API Documentation: https://gotenberg.dev/docs"
echo
echo "Common API Endpoints:"
echo "  HTML to PDF: POST /forms/chromium/convert/html"
echo "  URL to PDF: POST /forms/chromium/convert/url"
echo "  Markdown to PDF: POST /forms/chromium/convert/markdown"
echo "  Office to PDF: POST /forms/libreoffice/convert"
