#!/bin/bash
# Report for qdrant

echo
echo "================================= Qdrant =============================="
echo
echo "Host: https://${QDRANT_HOSTNAME:-<hostname_not_set>}"
echo "API Key: ${QDRANT_API_KEY:-<not_set_in_env>}"
echo "Internal REST API Access (e.g., from backend): http://qdrant:6333"
