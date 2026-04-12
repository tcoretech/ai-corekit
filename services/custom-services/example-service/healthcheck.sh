#!/bin/bash
source .env
PORT="${SERVICE_PORT:-80}"
curl -sf "http://example-service:${PORT}/" > /dev/null && echo "OK" || exit 1
