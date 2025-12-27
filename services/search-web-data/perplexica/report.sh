#!/bin/bash
# Report for perplexica

echo
echo "================================= Perplexica =========================="
echo
echo "Host: ${PERPLEXICA_HOSTNAME:-<hostname_not_set>}"
echo "User: ${PERPLEXICA_USERNAME:-<not_set_in_env>}"
echo "Password: ${PERPLEXICA_PASSWORD:-<not_set_in_env>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${PERPLEXICA_HOSTNAME:-<hostname_not_set>}"
echo "  Internal API: http://perplexica:3000"
echo
echo "n8n Integration:"
echo "  API Endpoint: http://perplexica:3000/api/search"
echo "  Method: POST"
echo "  Body: {\"query\": \"your search\", \"focusMode\": \"webSearch\", \"chatHistory\": []}"
echo
echo "Documentation: https://github.com/ItzCrazyKns/Perplexica"
echo
echo "Note: Configure AI providers (OpenAI, Ollama, etc.) via Web UI after first login"
