#!/bin/bash
# startup.sh
# Runs AFTER docker compose up.
# Use this for application bootstrapping: migrations, creating admin users, seeding data.

set -e

# Example: Wait for service to be ready
# ./scripts/wait-for-it.sh localhost:8080

# Example: Run a setup command inside the container
# docker compose exec -T app ./setup_script.sh

echo "Startup tasks complete for example-service."
