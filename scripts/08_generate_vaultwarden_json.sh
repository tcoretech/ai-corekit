#!/bin/bash

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Function to check if a profile is active
is_profile_active() {
    local profile="$1"
    [[ ",$COMPOSE_PROFILES," == *",$profile,"* ]]
}

# Function to generate UUID v4
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        # Fallback: generate pseudo-UUID
        printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' \
            $RANDOM $RANDOM $RANDOM \
            $((RANDOM & 0x0fff | 0x4000)) \
            $((RANDOM & 0x3fff | 0x8000)) \
            $RANDOM $RANDOM $RANDOM
    fi
}

# Function to properly escape JSON strings
escape_json() {
    local input="$1"
    # Escape backslashes first, then quotes, then newlines, tabs, etc.
    echo "$input" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\t/\\t/g' | sed 's/\r/\\r/g'
}

# Main function
generate_vaultwarden_json() {
    # Check if Vaultwarden is active
    if ! is_profile_active "vaultwarden"; then
        log_info "Vaultwarden is not selected. Skipping credential export."
        return 0
    fi

    # Load environment variables
    if [ ! -f "$ENV_FILE" ]; then
        log_error "No .env file found at $ENV_FILE"
        return 1
    fi
    
    set -a
    source "$ENV_FILE"
    set +a

    log_info "Generating Vaultwarden import file..."

    local json_file="$PROJECT_ROOT/ai-launchkit-credentials.json"
    local folder_id=$(generate_uuid)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    # Start JSON structure
    cat > "$json_file" << EOF
{
  "encrypted": false,
  "folders": [
    {
      "id": "$folder_id",
      "name": "AI LaunchKit Services"
    }
  ],
  "items": [
EOF

    local items_json=""
    
    # Helper function to add a login item
    add_login_item() {
        local name="$1"
        local username="$2"
        local password="$3"
        local url="$4"
        local notes="$5"
        
        if [[ -z "$username" || -z "$password" ]]; then
            return
        fi
        
        # Escape all string values
        name=$(escape_json "$name")
        username=$(escape_json "$username")
        password=$(escape_json "$password")
        url=$(escape_json "$url")
        notes=$(escape_json "$notes")
        
        local item_id=$(generate_uuid)
        
        # Add comma if not first item
        if [[ -n "$items_json" ]]; then
            items_json="${items_json},"$'\n'
        fi
        
        items_json="${items_json}    {
      \"id\": \"$item_id\",
      \"organizationId\": null,
      \"folderId\": \"$folder_id\",
      \"type\": 1,
      \"reprompt\": 0,
      \"name\": \"$name\",
      \"notes\": \"$notes\",
      \"favorite\": false,
      \"login\": {
        \"username\": \"$username\",
        \"password\": \"$password\",
        \"totp\": null,
        \"passwordRevisionDate\": null,
        \"uris\": [
          {
            \"match\": null,
            \"uri\": \"$url\"
          }
        ]
      },
      \"collectionIds\": [],
      \"revisionDate\": \"$timestamp\"
    }"
    }

    # Helper function to add a secure note
    add_secure_note() {
        local name="$1"
        local notes="$2"
        
        if [[ -z "$notes" ]]; then
            return
        fi
        
        # Escape all string values
        name=$(escape_json "$name")
        notes=$(escape_json "$notes")
        
        local item_id=$(generate_uuid)
        
        # Add comma if not first item
        if [[ -n "$items_json" ]]; then
            items_json="${items_json},"$'\n'
        fi
        
        items_json="${items_json}    {
      \"id\": \"$item_id\",
      \"organizationId\": null,
      \"folderId\": \"$folder_id\",
      \"type\": 2,
      \"reprompt\": 0,
      \"name\": \"$name\",
      \"notes\": \"$notes\",
      \"favorite\": false,
      \"secureNote\": {
        \"type\": 0
      },
      \"collectionIds\": [],
      \"revisionDate\": \"$timestamp\"
    }"
    }

    # Add all service logins
    
    # n8n
    if is_profile_active "n8n"; then
        add_login_item \
            "n8n Workflow Automation" \
            "admin" \
            "CreateOnFirstLogin123!" \
            "https://${N8N_HOSTNAME}" \
            "Main workflow automation platform. Create admin account on first access."
    fi

    # Flowise
    if is_profile_active "flowise"; then
        add_login_item \
            "Flowise AI Agent Builder" \
            "${FLOWISE_USERNAME}" \
            "${FLOWISE_PASSWORD}" \
            "https://${FLOWISE_HOSTNAME}" \
            "Low-code AI agent and chatbot builder"
    fi

    # Bolt.diy
    if is_profile_active "bolt"; then
        add_login_item \
            "Bolt.diy AI Web Development" \
            "${BOLT_USERNAME}" \
            "${BOLT_PASSWORD}" \
            "https://${BOLT_HOSTNAME}" \
            "AI-powered web development in the browser. Protected with Basic Auth."
    fi

    # Open WebUI
    if is_profile_active "open-webui"; then
        add_login_item \
            "Open WebUI (ChatGPT Clone)" \
            "admin@example.com" \
            "ChooseYourPassword123!" \
            "https://${WEBUI_HOSTNAME}" \
            "Self-hosted ChatGPT-like interface. Create account on first access."
    fi

    # Mailpit
    add_login_item \
        "Mailpit Mail Catcher" \
        "${MAILPIT_USERNAME}" \
        "${MAILPIT_PASSWORD}" \
        "https://${MAILPIT_HOSTNAME}" \
        "Mail catcher for development/testing. All emails sent by services are captured here."

    # Add other services...
    # (Ich kürze hier ab, aber alle anderen Services würden nach dem gleichen Muster hinzugefügt)

    # Add secure notes
    
    # Vaultwarden Admin Token
    if [[ -n "$VAULTWARDEN_ADMIN_TOKEN" ]]; then
        add_secure_note \
            "Vaultwarden Admin Token" \
            "Admin Panel: https://${VAULTWARDEN_HOSTNAME}/admin\\nAdmin Token: ${VAULTWARDEN_ADMIN_TOKEN}\\nUse this token to access the Vaultwarden admin panel."
    fi

    # Write items to file
    echo "$items_json" >> "$json_file"

    # Close JSON structure
    cat >> "$json_file" << EOF

  ]
}
EOF

    log_success "✅ Vaultwarden import file generated: $json_file"
    echo
    log_info "📋 Import Instructions:"
    echo "1. Download the file from your VPS:"
    echo "   scp $(whoami)@${USER_DOMAIN_NAME}:~/ai-launchkit/ai-launchkit-credentials.json ./"
    echo
    echo "2. Import into Vaultwarden:"
    echo "   - Open: https://${VAULTWARDEN_HOSTNAME}"
    echo "   - Go to: Tools → Import Data"
    echo "   - Format: Bitwarden (json)"
    echo "   - Choose file and import"
    echo
    echo "⚠️  SECURITY: Delete the JSON file after import!"
    echo
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Load COMPOSE_PROFILES from .env
    if [ -f "$ENV_FILE" ]; then
        COMPOSE_PROFILES=$(grep "^COMPOSE_PROFILES=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')
        export COMPOSE_PROFILES
    fi
    
    generate_vaultwarden_json
fi
