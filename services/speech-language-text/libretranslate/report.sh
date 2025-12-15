#!/bin/bash
# Report for libretranslate

echo
echo "================================= LibreTranslate ==========================="
echo
echo "Host: ${LIBRETRANSLATE_HOSTNAME:-<hostname_not_set>}"
echo "User: ${LIBRETRANSLATE_USERNAME:-<not_set_in_env>}"
echo "Password: ${LIBRETRANSLATE_PASSWORD:-<not_set_in_env>}"
echo "API (external via Caddy): https://${LIBRETRANSLATE_HOSTNAME:-<hostname_not_set>}"
echo "API (internal): http://libretranslate:5000"
echo ""
echo "API Endpoints:"
echo "  - Translate: POST /translate"
echo "  - Detect Language: POST /detect"
echo "  - Available Languages: GET /languages"
echo ""
echo "Example n8n usage:"
echo "  URL: http://libretranslate:5000/translate"
echo "  Method: POST"
echo "  Body: {\"q\":\"Hello\",\"source\":\"en\",\"target\":\"de\"}"
echo ""
echo "Docs: https://github.com/LibreTranslate/LibreTranslate"
