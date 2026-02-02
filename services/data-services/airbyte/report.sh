#!/bin/bash
# Report for airbyte

echo
echo "================================= Airbyte =============================="
echo
echo "Web UI Access:"
echo "  URL:      https://${AIRBYTE_HOSTNAME}"
echo
echo "First Login:"
echo "  - Enter your email address (will be your username)"
echo "  - Password: ${AIRBYTE_PASSWORD}"
echo
echo "Destination Database (for synced data):"
echo "  Host:     airbyte_destination_db (or ${SERVER_IP} for external access)"
echo "  Port:     5433"
echo "  Database: marketing_data"
echo "  User:     airbyte"
echo "  Password: ${AIRBYTE_DESTINATION_DB_PASSWORD}"
echo
echo "Setup Steps:"
echo "  1. Log into Airbyte UI at URL above"
echo "  2. First login: Enter your email + password (above)"
echo "  3. Add your data sources (Google Ads, Meta, TikTok, etc.)"
echo "  4. Create destination: PostgreSQL"
echo "     - Host: airbyte_destination_db (or ${SERVER_IP})"
echo "     - Port: 5433"
echo "     - Database: marketing_data"
echo "     - Username: airbyte"
echo "     - Password: ${AIRBYTE_DESTINATION_DB_PASSWORD}"
echo "  5. Create connections (source → destination)"
echo
echo "Metabase Integration:"
echo "  Connect Metabase to the destination database above"
echo "  to create dashboards on your synced marketing data."
echo
echo "n8n Integration:"
echo "  Trigger syncs via: http://localhost:8001/api/v1/"
echo
