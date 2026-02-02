#!/bin/bash
set -e

# Check if Dex template exists
if [ ! -f "./config/dex/config-template.yaml" ]; then
    echo "Dex config template not found at ./config/dex/config-template.yaml"
    exit 1
fi

echo "Generating Dex configuration..."

# Ensure local config directory exists
mkdir -p ./config/local/dex

# Copy template to actual config
cp "./config/dex/config-template.yaml" "./config/local/dex/config.yaml"

# Replace placeholders
sed -i "s|DEX_HOSTNAME_PLACEHOLDER|${DEX_HOSTNAME}|g" "./config/local/dex/config.yaml"
sed -i "s|OUTLINE_HOSTNAME_PLACEHOLDER|${OUTLINE_HOSTNAME}|g" "./config/local/dex/config.yaml"
sed -i "s|OUTLINE_OIDC_CLIENT_SECRET_PLACEHOLDER|${OUTLINE_OIDC_CLIENT_SECRET}|g" "./config/local/dex/config.yaml"
sed -i "s|ADMIN_EMAIL_PLACEHOLDER|${DEX_ADMIN_EMAIL}|g" "./config/local/dex/config.yaml"
sed -i "s|ADMIN_PASSWORD_HASH_PLACEHOLDER|${DEX_ADMIN_PASSWORD_HASH}|g" "./config/local/dex/config.yaml"

echo "Dex configuration generated successfully!"
