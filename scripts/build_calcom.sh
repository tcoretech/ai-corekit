#!/bin/bash
set -e

echo "========================================="
echo "Building Cal.com Docker image..."
echo "This will take 10-15 minutes on first build..."
echo "========================================="

# Clone repository if not exists
if [ ! -d "./calcom-docker" ]; then
    echo "Cloning Cal.com Docker repository..."
    git clone https://github.com/calcom/docker calcom-docker
fi

cd calcom-docker

# Update submodule (Cal.com source)
echo "Updating Cal.com source code..."
git pull
git submodule update --init

# Copy our .env values to build environment
if [ -f "../.env" ]; then
    echo "Using configuration from parent .env..."
    
    # Extract necessary variables
    DOMAIN=$(grep "^DOMAIN=" ../.env | cut -d '=' -f2 | tr -d '"')
    POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" ../.env | cut -d '=' -f2 | tr -d '"')
    
    # Create .env for Cal.com build
    cat > .env << EOF
# Database (using AI LaunchKit's PostgreSQL)
DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/calcom
DATABASE_DIRECT_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/calcom

# URLs
NEXT_PUBLIC_WEBAPP_URL=https://cal.${DOMAIN}
NEXT_PUBLIC_API_V2_URL=https://cal.${DOMAIN}/api/v2
NEXT_PUBLIC_WEBSITE_URL=https://cal.${DOMAIN}
NEXTAUTH_URL=https://cal.${DOMAIN}
CAL_URL=https://cal.${DOMAIN}

# Security (will be generated if not exists)
NEXTAUTH_SECRET=$(openssl rand -base64 32)
CALENDSO_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Email (using AI LaunchKit's mail system)
EMAIL_FROM=${EMAIL_FROM:-noreply@${DOMAIN}}
EMAIL_SERVER_HOST=${SMTP_HOST:-mailpit}
EMAIL_SERVER_PORT=${SMTP_PORT:-1025}
EMAIL_SERVER_USER=${SMTP_USER:-}
EMAIL_SERVER_PASSWORD=${SMTP_PASSWORD:-}
SEND_FEEDBACK_EMAIL=false

# Features
NEXT_PUBLIC_DISABLE_SIGNUP=false
TELEMETRY_DISABLED=1
EOF
fi

echo "========================================="
echo "Cal.com build preparation complete!"
echo "Image will be built when you run docker compose"
echo "========================================="
