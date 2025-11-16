#!/bin/bash

set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    log_error ".env file not found!"
    exit 1
fi

log_info "Generating Homepage services configuration..."

# Start services.yaml with simple structure
cat > "$PROJECT_ROOT/homepage_config/services.yaml" << 'EOF'
- Services:
EOF

# Function to add service if running
add_service() {
    local container_name=$1
    local display_name=$2
    local hostname_var=$3
    local description=$4
    
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        hostname_value=$(eval echo \$${hostname_var})
        if [ -n "$hostname_value" ]; then
            cat >> "$PROJECT_ROOT/homepage_config/services.yaml" << EOF
    - ${display_name}:
        href: https://${hostname_value}
        description: ${description}
EOF
            log_success "Added ${display_name}"
        fi
    fi
}

# Add all services (check if container is running)
add_service "n8n" "n8n" "N8N_HOSTNAME" "Workflow Automation"
add_service "flowise" "Flowise" "FLOWISE_HOSTNAME" "AI Agent Builder"
add_service "bolt" "Bolt.diy" "BOLT_HOSTNAME" "AI Web Development"
add_service "open-webui" "Open WebUI" "WEBUI_HOSTNAME" "Chat Interface"
add_service "dify" "Dify" "DIFY_HOSTNAME" "AI Apps Platform"
add_service "gitea" "Gitea" "GITEA_HOSTNAME" "Git Server"
add_service "portainer" "Portainer" "PORTAINER_HOSTNAME" "Docker Management"
add_service "outline" "Outline" "OUTLINE_HOSTNAME" "Team Wiki"
add_service "docuseal" "DocuSeal" "DOCUSEAL_HOSTNAME" "E-Signatures"
add_service "paperless-ngx" "Paperless" "PAPERLESS_HOSTNAME" "Document Management"
add_service "seafile" "Seafile" "SEAFILE_HOSTNAME" "File Sync & Share"
add_service "calcom" "Cal.com" "CALCOM_HOSTNAME" "Scheduling"
add_service "twenty-crm" "Twenty CRM" "TWENTY_CRM_HOSTNAME" "Customer Management"
add_service "espocrm" "EspoCRM" "ESPOCRM_HOSTNAME" "CRM Suite"
add_service "odoo" "Odoo" "ODOO_HOSTNAME" "ERP System"
add_service "vikunja" "Vikunja" "VIKUNJA_HOSTNAME" "Task Management"
add_service "leantime" "Leantime" "LEANTIME_HOSTNAME" "Project Management"
add_service "kimai" "Kimai" "KIMAI_HOSTNAME" "Time Tracking"
add_service "invoiceninja" "Invoice Ninja" "INVOICENINJA_HOSTNAME" "Invoicing"
add_service "baserow" "Baserow" "BASEROW_HOSTNAME" "Database"
add_service "nocodb" "NocoDB" "NOCODB_HOSTNAME" "Smart Spreadsheet"
add_service "formbricks" "Formbricks" "FORMBRICKS_HOSTNAME" "Surveys"
add_service "metabase" "Metabase" "METABASE_HOSTNAME" "Analytics"
add_service "jitsi-web" "Jitsi Meet" "JITSI_HOSTNAME" "Video Conferencing"
add_service "postiz" "Postiz" "POSTIZ_HOSTNAME" "Social Media"
add_service "mautic_web" "Mautic" "MAUTIC_HOSTNAME" "Marketing Automation"
add_service "ragapp" "RAGApp" "RAGAPP_HOSTNAME" "RAG Builder"
add_service "perplexica" "Perplexica" "PERPLEXICA_HOSTNAME" "AI Search"
add_service "gpt-researcher" "GPT Researcher" "GPTR_HOSTNAME" "Research Agent"
add_service "letta" "Letta" "LETTA_HOSTNAME" "AI Agents"
add_service "comfyui" "ComfyUI" "COMFYUI_HOSTNAME" "Image Generation"
add_service "grafana" "Grafana" "GRAFANA_HOSTNAME" "Metrics Dashboard"
add_service "prometheus" "Prometheus" "PROMETHEUS_HOSTNAME" "Monitoring"
add_service "uptime-kuma" "Uptime Kuma" "UPTIME_KUMA_HOSTNAME" "Status Monitoring"
add_service "vaultwarden" "Vaultwarden" "VAULTWARDEN_HOSTNAME" "Password Manager"
add_service "kopia" "Kopia" "KOPIA_HOSTNAME" "Backup Solution"
add_service "supabase-studio" "Supabase" "SUPABASE_HOSTNAME" "Backend as Service"
add_service "mailpit" "Mailpit" "MAILPIT_HOSTNAME" "Mail Catcher"
add_service "searxng" "SearXNG" "SEARXNG_HOSTNAME" "Private Search"
add_service "airbyte-webapp" "Airbyte" "AIRBYTE_HOSTNAME" "Data Integration"

# Create simple widgets.yaml
cat > "$PROJECT_ROOT/homepage_config/widgets.yaml" << 'EOF'
- resources:
    cpu: true
    memory: true
    disk: /

- search:
    provider: searxng
    focus: false
    target: _blank
EOF

# Fix permissions for Homepage (needs user 1000)
log_info "Setting correct permissions for Homepage..."
sudo chown -R 1000:1000 "$PROJECT_ROOT/homepage_config/"
sudo mkdir -p "$PROJECT_ROOT/homepage_config/logs"
sudo chown 1000:1000 "$PROJECT_ROOT/homepage_config/logs"

log_success "Homepage configuration generated successfully!"

# Restart Homepage if it's running
if docker ps | grep -q homepage; then
    docker compose -p localai restart homepage
    log_success "Homepage restarted with new configuration"
fi
