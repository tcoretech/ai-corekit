#!/bin/bash
# Report for lightrag

echo
echo "================================= LightRAG ==========================="
echo
echo "Host: ${LIGHTRAG_HOSTNAME:-<hostname_not_set>}"
echo
echo "Internal API Auth:"
echo "  Accounts: ${LIGHTRAG_AUTH_ACCOUNTS:-<not_set_in_env>}"
echo "  Token Expiry: ${LIGHTRAG_TOKEN_EXPIRE:-24} hours"
echo
echo "Access:"
echo "  External (HTTPS): https://${LIGHTRAG_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://lightrag:9621"
echo
echo "n8n Integration:"
echo "  Use HTTP Request node with URL: http://lightrag:9621/api/query"
echo "  Query modes: /local, /global, /hybrid, /naive"
echo
echo "Open WebUI Integration:"
echo "  Add as Ollama model type with endpoint: http://lightrag:9621"
echo "  Model name will appear as: lightrag:latest"
echo
echo "Storage Backends:"
echo "  Default: In-memory (NetworkX + nano-vectordb)"
echo "  Optional: PostgreSQL, Neo4j, MongoDB, Redis"
echo
echo "Documentation: https://github.com/HKUDS/LightRAG"
