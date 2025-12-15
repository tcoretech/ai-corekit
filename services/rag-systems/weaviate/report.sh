#!/bin/bash
# Report for weaviate

echo
echo "================================= Weaviate ============================"
echo
echo "Host: ${WEAVIATE_HOSTNAME:-<hostname_not_set>}"
echo "Admin User (for Weaviate RBAC): ${WEAVIATE_USERNAME:-<not_set_in_env>}"
echo "Weaviate API Key: ${WEAVIATE_API_KEY:-<not_set_in_env>}"
