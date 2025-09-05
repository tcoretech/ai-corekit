#!/bin/bash
# Setup Postal configuration after installation

# Only run if Postal is selected (MAIL_MODE=postal)
if grep -q 'MAIL_MODE="postal"' .env 2>/dev/null; then
    echo "Setting up Postal configuration..."
    
    # Get passwords and hostname from .env
    POSTAL_DB_PASS=$(grep "POSTAL_DB_ROOT_PASSWORD" .env | cut -d'=' -f2 | tr -d '"')
    RABBITMQ_PASS=$(grep "POSTAL_RABBITMQ_PASSWORD" .env | cut -d'=' -f2 | tr -d '"')
    POSTAL_HOST=$(grep "POSTAL_HOSTNAME" .env | cut -d'=' -f2 | tr -d '"')
    
    # Generate secret key
    SECRET_KEY=$(openssl rand -hex 64)
    
    # Create postal config directory
    mkdir -p postal/config
    
    # Generate postal.yml
    cat > postal/config/postal.yml << EOF
general:
  secret_key: "$SECRET_KEY"

web:
  host: $POSTAL_HOST
  protocol: https

web_server:
  bind_address: 0.0.0.0
  port: 5000

main_db:
  host: postal-mariadb
  username: root
  password: "$POSTAL_DB_PASS"
  database: postal

message_db:
  host: postal-mariadb
  username: root
  password: "$POSTAL_DB_PASS"

rabbitmq:
  host: postal-rabbitmq
  username: postal
  password: "$RABBITMQ_PASS"
  vhost: /postal
EOF
    
    echo "Postal configuration created."
fi
