#!/bin/bash
# Report for ragapp

echo
echo "================================= RAGApp =============================="
echo
echo "Host: ${RAGAPP_HOSTNAME:-<hostname_not_set>}"
echo "Internal Access (e.g., from n8n): http://ragapp:8000"
echo "User: ${RAGAPP_USERNAME:-<not_set_in_env>}"
echo "Password: ${RAGAPP_PASSWORD:-<not_set_in_env>}"
echo "Admin: https://${RAGAPP_HOSTNAME:-<hostname_not_set>}/admin"
echo "API Docs: https://${RAGAPP_HOSTNAME:-<hostname_not_set>}/docs"
