#!/bin/bash
# Report for bolt

echo
echo "================================= Bolt.diy ==========================="
echo
echo "Host: ${BOLT_HOSTNAME:-<hostname_not_set>}"
echo "User: ${BOLT_USERNAME:-<not_set_in_env>}"
echo "Password: ${BOLT_PASSWORD:-<not_set_in_env>}"
echo "URL: https://${BOLT_HOSTNAME:-<hostname_not_set>}"
echo "Internal URL: http://bolt:5173"
echo "Description: AI-powered web development in the browser"
echo "Documentation: https://github.com/stackblitz-labs/bolt.diy"
echo
