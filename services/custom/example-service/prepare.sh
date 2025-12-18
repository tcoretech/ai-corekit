#!/bin/bash
# prepare.sh
# Runs BEFORE docker compose up.
# Use this for host preparation: creating directories, setting permissions, generating config files.

set -e

# Example: Create data directories
# mkdir -p data/db
# mkdir -p config/local

# Example: Set permissions
# chown -R 1000:1000 data/

echo "Preparation complete for example-service."
