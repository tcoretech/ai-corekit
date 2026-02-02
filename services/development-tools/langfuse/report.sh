#!/bin/bash
# Report for langfuse

echo
echo "================================= Langfuse ============================"
echo
echo "Host: ${LANGFUSE_HOSTNAME:-<hostname_not_set>}"
echo "User: ${LANGFUSE_INIT_USER_EMAIL:-<not_set_in_env>}"
echo "Password: ${LANGFUSE_INIT_USER_PASSWORD:-<not_set_in_env>}"
