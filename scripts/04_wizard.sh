#!/bin/bash
# Service Selection Wizard

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
source "$SCRIPT_DIR/utils.sh"

# Check whiptail
if ! command -v whiptail &> /dev/null; then
    log_error "'whiptail' is not installed. Please install it (apt install whiptail)."
    exit 1
fi

# Load current profiles
CURRENT_PROFILES_VALUE=""
if [ -f "$ENV_FILE" ]; then
    LINE_CONTENT=$(grep "^COMPOSE_PROFILES=" "$ENV_FILE" || echo "")
    if [ -n "$LINE_CONTENT" ]; then
        CURRENT_PROFILES_VALUE=$(echo "$LINE_CONTENT" | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    fi
fi
current_profiles_for_matching=",$CURRENT_PROFILES_VALUE,"

# Service Definitions
base_services_data=(
    "n8n" "n8n, n8n-worker, n8n-import (Workflow Automation)"
    "n8n-mcp" "n8n-MCP (AI workflow generation for Claude/Cursor)"
    "webhook-testing" "Webhook Tester + Hoppscotch (API & Webhook Testing/Debugging Suite)"
    "gitea" "Gitea (Self-hosted Git service for n8n revisions- GitHub alternative)"
    "homepage" "Homepage (Dashboard for all services)"
    "dify" "Dify (AI Application Development Platform with LLMOps)"
    "flowise" "Flowise (AI Agent Builder)"
    "bolt" "bolt.diy (AI Web Development)"
    "openui" "OpenUI (AI Frontend/UI Generator - EXPERIMENTAL, best with Claude/GPT-4)"
    "monitoring" "Monitoring Suite (Prometheus, Grafana, cAdvisor, Node-Exporter)"
    "uptime-kuma" "Uptime Kuma (Uptime Monitoring & Status Pages)"
    "portainer" "Portainer (Docker management UI)"
    "cloudflare-tunnel" "Cloudflare Tunnel (Zero-Trust Secure Access for Web Services)"
    "cloudflare-ssh-tunnel" "Cloudflare SSH Tunnel (Secure SSH via Cloudflare tunnel)"
    "postiz" "Postiz (Social publishing platform)"
    "odoo" "Odoo 18 (Open Source ERP/CRM with AI features)"
    "twenty-crm" "Twenty CRM (Modern Notion-like customer management)"
    "espocrm" "EspoCRM (Full-featured CRM with workflows & automation)"
    "mautic" "Mautic 6.0 - Marketing Automation Platform (Email, Leads, Campaigns)"
    "baserow" "Baserow (Airtable Alternative)"
    "nocodb" "NocoDB (Open-source Airtable alternative, smart spreadsheet UI)"
    "outline" "Outline (Wiki/Documentation - Notion alternative)"
    "seafile" "Seafile (File sync & share like Dropbox/Google Drive/OneDrive)"
    "paperless" "Paperless-ngx (Document management with OCR & AI tagging)"
    "paperless-ai" "Paperless AI Suite (GPT+AI - Superior OCR & RAG Chat for documents)"
    "vikunja" "Vikunja (Modern Task Management - Todoist/TickTick alternative)"
    "leantime" "Leantime - Full project management suite (Asana/Monday alternative)"
    "calcom" "Cal.com (Open Source Scheduling Platform)"
    "kimai" "Kimai (Professional Time Tracking - DSGVO-compliant, 2FA, invoicing)"
    "invoiceninja" "Invoice Ninja - Professional invoicing platform"
    "formbricks" "Formbricks - Privacy-first surveys & forms (Typeform alternative)"
    "metabase" "Metabase - Business intelligence (No-code dashboards, groups, ETL-ready)"
    "airbyte" "Airbyte (Data Integration - Sync from 600+ sources like Google Ads, Meta, TikTok)"
    "jitsi" "Jitsi Meet (Video conferencing - REQUIRES UDP 10000!)"
    "livekit" "LiveKit (Real-time voice & video - WebRTC, REQUIRES UDP 50000-50100!)"
    "vaultwarden" "Vaultwarden (Self-hosted Bitwarden-compatible password manager)"
    "ai-security" "AI Security Suite - LLM Guard + Presidio (AI safety & GDPR-compliant PII)"
    "kopia" "Kopia (Fast and secure backup with Cloud and WebDAV storage)"
    "mailserver" "Docker-Mailserver (+ Mailgun ingest webhook for inbound mail)"
    "mail-ingest" "Mailgun ingest forwarder (webhook -> Docker-Mailserver SMTP)"
    "private-dns" "Private DNS (CoreDNS for mail/ssh hostnames over WARP/private net)"
    "snappymail" "SnappyMail (Modern webmail client for Docker-Mailserver)"
    "langfuse" "Langfuse Suite (AI Observability - includes Clickhouse, Minio)"
    "qdrant" "Qdrant (Vector Database)"
    "supabase" "Supabase (Backend as a Service)"
    "weaviate" "Weaviate (Vector Database with API Key Auth)"
    "lightrag" "LightRAG (Graph-based RAG with entity extraction)"
    "neo4j" "Neo4j (Graph Database)"
    "letta" "Letta (Agent Server & SDK)"
    "gotenberg" "Gotenberg (Document Conversion API)"
    "stirling-pdf" "Stirling-PDF (100+ PDF Tools: Merge, Split, OCR, Sign)"
    "docuseal" "DocuSeal (E-Signatures platform - DocuSign alternative)"
    "crawl4ai" "Crawl4ai (Web Crawler for AI)"
    "ragapp" "RAGApp (Open-source RAG UI + API)"
    "open-webui" "Open WebUI (ChatGPT-like Interface)"
    "searxng" "SearXNG (Private Metasearch Engine)"
    "perplexica" "Perplexica (Open-source Deep Resarch/Perplexity AI alternative)"
    "gpt-researcher" "GPT Researcher (Autonomous research agent - 2000+ word reports with citations)"
    "local-deep-research" "Local Deep Research (LangChain's iterative research - ~95% accuracy)"
    "opennotebook" "Open Notebook (AI Knowledge Management - NotebookLM alternative, 16+ models)"
    "python-runner" "Python Runner (Run your custom Python code from ./python-runner)"
    "ollama" "Ollama (Local LLM Runner - select hardware in next step)"
    "comfyui" "ComfyUI (Node-based Stable Diffusion UI)"
    "speech" "Speech Stack (Whisper ASR + OpenedAI TTS - CPU optimized)"
    "tts-chatterbox" "TTS Chatterbox (State-of-the-art TTS - ElevenLabs alternative)"
    "scriberr" "Scriberr (AI audio transcription with speaker diarization)"
    "vexa" "Vexa (Live meeting transcription - Google Meet & Teams)"
    "ocr" "OCR Bundle (Tesseract + EasyOCR - Extract text from images/PDFs)"
    "libretranslate" "LibreTranslate (Self-hosted translation API - 50+ languages)"
    "browser-suite" "Browser Automation Suite (Browserless + Skyvern + Browser-use)"
)

services=()
idx=0
while [ $idx -lt ${#base_services_data[@]} ]; do
    tag="${base_services_data[idx]}"
    description="${base_services_data[idx+1]}"
    status="OFF"
    
    if [ -n "$CURRENT_PROFILES_VALUE" ] && [ "$CURRENT_PROFILES_VALUE" != '""' ]; then
        if [[ "$tag" == "ollama" ]]; then
            if [[ "$current_profiles_for_matching" == *",cpu,"* || \
                  "$current_profiles_for_matching" == *",gpu-nvidia,"* || \
                  "$current_profiles_for_matching" == *",gpu-amd,"* ]]; then
                status="ON"
            fi
        elif [[ "$current_profiles_for_matching" == *",$tag,"* ]]; then
            status="ON"
        fi
    else
        case "$tag" in
            "n8n"|"flowise"|"monitoring") status="ON" ;;
            *) status="OFF" ;;
        esac
    fi
    services+=("$tag" "$description" "$status")
    idx=$((idx + 2))
done

# Display Checklist
num_services=$(( ${#services[@]} / 3 ))
list_height=$num_services
if [ $list_height -gt 20 ]; then list_height=20; fi
window_height=$(( list_height + 8 ))

CHOICES=$(whiptail --title "Service Selection Wizard" --checklist \
  "Choose the services you want to deploy." $window_height 110 $list_height \
  "${services[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    log_info "Cancelled."
    exit 0
fi

# Process Choices
selected_profiles=()
ollama_selected=0

if [ -n "$CHOICES" ]; then
    eval "temp_choices=($CHOICES)"
    for choice in "${temp_choices[@]}"; do
        if [ "$choice" == "ollama" ]; then
            ollama_selected=1
        else
            selected_profiles+=("$choice")
        fi
    done
fi

# Ollama Hardware Selection
if [ $ollama_selected -eq 1 ]; then
    default_ollama="cpu"
    if [[ "$current_profiles_for_matching" == *",gpu-nvidia,"* ]]; then default_ollama="gpu-nvidia"; fi
    if [[ "$current_profiles_for_matching" == *",gpu-amd,"* ]]; then default_ollama="gpu-amd"; fi
    
    ollama_hardware_options=(
        "cpu" "CPU" "OFF"
        "gpu-nvidia" "NVIDIA GPU" "OFF"
        "gpu-amd" "AMD GPU" "OFF"
    )
    # Set default ON
    for i in "${!ollama_hardware_options[@]}"; do
        if [[ "${ollama_hardware_options[$i]}" == "$default_ollama" ]]; then
            ollama_hardware_options[$((i+2))]="ON"
        fi
    done

    CHOSEN_OLLAMA=$(whiptail --title "Ollama Hardware" --radiolist \
      "Choose hardware profile:" 15 60 3 "${ollama_hardware_options[@]}" 3>&1 1>&2 2>&3)
      
    if [ $? -eq 0 ] && [ -n "$CHOSEN_OLLAMA" ]; then
        selected_profiles+=("$CHOSEN_OLLAMA")
    fi
fi

# Update .env
NEW_PROFILES=$(IFS=,; echo "${selected_profiles[*]}")
if [ ! -f "$ENV_FILE" ]; then touch "$ENV_FILE"; fi

if grep -q "^COMPOSE_PROFILES=" "$ENV_FILE"; then
    sed -i "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=\"$NEW_PROFILES\"|g" "$ENV_FILE"
else
    echo "COMPOSE_PROFILES=\"$NEW_PROFILES\"" >> "$ENV_FILE"
fi

log_success "Updated COMPOSE_PROFILES: $NEW_PROFILES"

# Run Secrets Generation
echo ""
log_info "Running secrets generation..."
bash "$SCRIPT_DIR/03_generate_secrets.sh"

# Run Private DNS Setup if selected
if [[ " ${selected_profiles[@]} " =~ " private-dns " ]]; then
    bash "$PROJECT_ROOT/services/host-services/dns/prepare.sh"
fi

log_success "Wizard complete. Run 'docker compose up -d' to start services."
