<div align="center">

# AI CoreKit

**Open-Source AI Development Toolkit**

*Deploy your complete AI stack in minutes, not weeks*

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/tcoretech/ai-corekit?style=social)](https://github.com/tcoretech/ai-corekit)
[![Repository Views](https://komarev.com/ghpvc/?username=tcoretech&repo=ai-corekit&label=Views&color=brightgreen)](https://github.com/tcoretech/ai-corekit)
[![GitHub last commit](https://img.shields.io/github/last-commit/tcoretech/ai-corekit)](https://github.com/tcoretech/ai-corekit/commits/main)
[![Contributors](https://img.shields.io/github/contributors/tcoretech/ai-corekit)](https://github.com/tcoretech/ai-corekit/graphs/contributors)

[Installation](#-quick-start) • [Services](#-whats-included) • [CLI Reference](#-cli-reference) • [Configuration](#-configuration-and-customisation) • [Documentation](#-documentation--support)

</div>

---

## 🎯 What is it?

AI CoreKit is a comprehensive, self-hosted AI development environment that instantly deploys over **78+ pre-configured services**.

Launch any stack or service with a simple one-liner:

```bash
# Start your workflow automation
corekit up n8n

# Deploy a private LLM server
corekit up ollama

# Launch a knowledge base
corekit up supabase
```

### 🚀 Quick Start

```bash
git clone https://github.com/tcoretech/ai-corekit && cd ai-corekit
sudo make install
corekit init
corekit config
corekit up
```

---

<!-- SERVICES_SECTION_START -->
## ✨ What's Included

**80+ self-hosted services** pre-configured and wrapped for easy deployment.

Each service includes its own config, secrets handling and detailed setup instructions. Navigate to each modular service definition below.

### 🔧 Workflow Automation
Orchestrate processes and integrate services

| Service | Name | Description |
| --- | --- | ------ |
| [**n8n**](services/workflow-automation/n8n) | `n8n` | Extendable workflow automation tool for connecting apps, building API integrations, and orchestrating complex business processes. [[↗](https://github.com/n8n-io/n8n)] |
| [**Flowise**](services/workflow-automation/flowise) | `flowise` | Drag-and-drop AI agent builder for creating chatbots, customer support assistants, and complex AI workflows. [[↗](https://github.com/FlowiseAI/Flowise)] |
| [**Webhook Tester + Hoppscotch**](services/workflow-automation/webhook-testing) | `webhook-testing` | Debugging suite combining Webhook Tester and Hoppscotch for inspecting incoming webhooks and testing external service integrations. [[↗](https://github.com/tarampampam/webhook-tester)] |
| [**n8n-MCP**](services/workflow-automation/n8n-mcp) | `n8n-mcp` | Model Context Protocol (MCP) server for n8n, enabling AI assistants like Claude or Cursor to generate and validate n8n workflows. [[↗](https://github.com/czlonkowski/n8n-mcp)] |

### 🎯 Frontends
Front-end interfaces and dashboards

| Service | Name | Description |
| --- | --- | ------ |
| [**Homepage**](services/frontends/homepage) | `homepage` | Modern, customizable dashboard providing a centralized overview and quick access to all hosted services and Docker integrations. [[↗](https://github.com/gethomepage/homepage)] |
| [**Landing Page**](services/frontends/landing-page) | `landing-page` | Static landing page serving as the main entry point and navigation hub for the deployed infrastructure. |
| [**Open WebUI**](services/frontends/open-webui) | `open-webui` | Feature-rich, self-hosted web interface (ChatGPT alternative) for interacting with local Large Language Models. [[↗](https://github.com/open-webui/open-webui)] |

### 📧 Mail System
Email sending, receiving, and management

| Service | Name | Description |
| --- | --- | ------ |
| [**Docker Mailserver**](services/mail-system/mailserver) | `mailserver` | Full-stack mail server (Docker-Mailserver) with Mailgun ingest support for sending and receiving real emails. [[↗](https://github.com/docker-mailserver/docker-mailserver)] |
| [**Mail Ingest**](services/mail-system/mail-ingest) | `mail-ingest` | Webhook forwarder that ingests incoming emails from Mailgun and routes them to the local docker-mailserver. |
| [**Mailpit**](services/mail-system/mailpit) | `mailpit` | Development email capture tool with a web UI for testing and debugging SMTP flows without sending real emails. [[↗](https://github.com/axllent/mailpit)] |
| [**SMTP Relay**](services/mail-system/smtp-relay) | `smtp-relay` | Dedicated SMTP relay service for handling outbound transactional email delivery and forwarding. [[↗](https://github.com/docker-mailserver/docker-mailserver)] |
| [**SnappyMail**](services/mail-system/snappymail) | `snappymail` | Modern, lightweight webmail client interface for Docker-Mailserver. [[↗](https://github.com/the-djmaze/snappymail)] |

### 💼 Business Productivity
Tools for business operations and management

| Service | Name | Description |
| --- | --- | ------ |
| [**Baserow**](services/business-productivity/baserow) | `baserow` | Open-source no-code database and Airtable alternative for database management, project tracking, and building collaborative workflows. [[↗](https://github.com/bram2w/baserow)] |
| [**Cal.com**](services/business-productivity/calcom) | `calcom` | Open-source scheduling platform streamlining meeting bookings, team calendars, and payment integrations. [[↗](https://github.com/calcom/cal.com)] |
| [**EspoCRM**](services/business-productivity/espocrm) | `espocrm` | Full-featured Customer Relationship Management (CRM) system offering email campaigns, workflow automation, advanced reporting, and role-based access. [[↗](https://github.com/espocrm/espocrm)] |
| [**Formbricks**](services/business-productivity/formbricks) | `formbricks` | Privacy-first survey and form builder serving as a GDPR-compliant Typeform alternative for customer feedback, NPS surveys, and market research. [[↗](https://github.com/formbricks/formbricks)] |
| [**Invoice Ninja**](services/business-productivity/invoiceninja) | `invoiceninja` | Professional invoicing platform supporting multi-currency invoices, recurring billing, client portals, and over 40 payment gateways. [[↗](https://github.com/invoiceninja/invoiceninja)] |
| [**Jitsi Meet**](services/business-productivity/jitsi) | `jitsi` | Secure, open-source video conferencing platform supporting screen sharing, team calls, and webinar hosting (Requires UDP port 10000). [[↗](https://github.com/jitsi/jitsi-meet)] |
| [**Kimai**](services/business-productivity/kimai) | `kimai` | Professional, DSGVO-compliant time tracking software featuring team timesheets, invoicing, 2FA security, and API access. [[↗](https://github.com/kimai/kimai)] |
| [**Leantime**](services/business-productivity/leantime) | `leantime` | ADHD-friendly project management suite comparable to Asana or Monday, featuring time tracking, sprint planning, and strategy tools. [[↗](https://github.com/Leantime/leantime)] |
| [**Mautic**](services/business-productivity/mautic) | `mautic` | Open-source marketing automation platform for lead scoring, email campaigns, landing pages, and multi-channel marketing workflows. [[↗](https://github.com/mautic/mautic)] |
| [**Metabase**](services/business-productivity/metabase) | `metabase` | Business intelligence platform enabling no-code dashboards, automated reports, data exploration, and team analytics. [[↗](https://github.com/metabase/metabase)] |
| [**NocoDB**](services/business-productivity/nocodb) | `nocodb` | Open-source Airtable alternative featuring a smart spreadsheet UI for real-time collaboration and automation. [[↗](https://github.com/nocodb/nocodb)] |
| [**Odoo**](services/business-productivity/odoo) | `odoo` | Comprehensive ERP and CRM suite with AI features for sales automation, inventory management, accounting, and lead scoring. [[↗](https://github.com/odoo/odoo)] |
| [**Postiz**](services/business-productivity/postiz) | `postiz` | Open-source social media scheduling and publishing platform with analytics and multi-account support. [[↗](https://github.com/gitroomhq/postiz-app)] |
| [**Twenty CRM**](services/business-productivity/twenty-crm) | `twenty-crm` | Modern, open-source CRM with a Notion-like interface, featuring customer pipelines, GraphQL API, and tools for startups. [[↗](https://github.com/twentyhq/twenty)] |
| [**Vikunja**](services/business-productivity/vikunja) | `vikunja` | Modern task management platform and Todoist alternative offering Kanban boards, Gantt charts, CalDAV sync, and team collaboration. [[↗](https://github.com/go-vikunja/vikunja)] |

### 💻 Development Tools
Coding assistance and development tools

| Service | Name | Description |
| --- | --- | ------ |
| [**Langfuse**](services/development-tools/langfuse) | `langfuse` | AI observability platform including Clickhouse and Minio, specialized for DSGVO compliance, German text processing, and entity recognition. |
| [**bolt.diy**](services/development-tools/bolt) | `bolt` | AI-powered web development tool for rapid prototyping, creating MVPs, and assisting in learning to code. [[↗](https://github.com/stackblitz-labs/bolt.diy)] |
| [**Gitea**](services/development-tools/gitea) | `gitea` | Lightweight, self-hosted DevOps platform and Git service providing source code management, issue tracking, and CI/CD capabilities. [[↗](https://github.com/go-gitea/gitea)] |
| [**OpenUI**](services/development-tools/openui) | `openui` | Experimental AI frontend and UI generator for creating design systems, component libraries, and mockups. [[↗](https://github.com/wandb/openui)] |

### 🤖 Agentic Frameworks
Autonomous agents and frameworks

| Service | Name | Description |
| --- | --- | ------ |
| [**Browser Automation Suite**](services/agentic-frameworks/browser-suite) | `browser-suite` | Comprehensive browser automation suite combining Browserless, Skyvern, and Browser-use for web scraping, form filling, and automated testing. [[↗](https://github.com/browser-use/browser-use)] |
| [**Dify**](services/agentic-frameworks/dify) | `dify` | LLM application development platform designed for building AI agents, chatbots, and automating workflows. [[↗](https://github.com/langgenius/dify)] |
| [**Letta**](services/agentic-frameworks/letta) | `letta` | Agent Server and SDK enabling the creation of persistent AI assistants with advanced memory management capabilities. [[↗](https://github.com/letta-ai/letta)] |
| [**Vexa**](services/agentic-frameworks/vexa) | `vexa` | Real-time meeting transcription API supporting 99 languages, offering live transcription for Google Meet & Teams with speaker identification. [[↗](https://github.com/Vexa-ai/vexa)] |

### 📚 RAG Systems
Retrieval-Augmented Generation systems

| Service | Name | Description |
| --- | --- | ------ |
| [**LightRAG**](services/rag-systems/lightrag) | `lightrag` | Graph-based Retrieval-Augmented Generation (RAG) system specializing in entity extraction and automatic knowledge graph creation. [[↗](https://github.com/HKUDS/LightRAG)] |
| [**RAGApp**](services/rag-systems/ragapp) | `ragapp` | Open-source UI and API for Retrieval-Augmented Generation (RAG), enabling easy creation of knowledge bases and document Q&A tools. [[↗](https://github.com/ragapp/ragapp)] |

### 🎙️ Voice & Multimodal
Speech recognition, synthesis, and multimodal processing

| Service | Name | Description |
| --- | --- | ------ |
| [**LibreTranslate**](services/voice-multimodal/libretranslate) | `libretranslate` | Self-hosted, privacy-focused translation API supporting over 50 languages for text and document translation. [[↗](https://github.com/LibreTranslate/LibreTranslate)] |
| [**LiveKit**](services/voice-multimodal/livekit) | `livekit` | Real-time voice/video WebRTC infrastructure for building AI voice assistants and conversational AI bots. Requires UDP ports 50000-50100. [[↗](https://github.com/livekit/livekit)] |
| [**Scriberr**](services/voice-multimodal/scriberr) | `scriberr` | AI-powered audio transcription tool featuring speaker diarization, ideal for creating meeting transcripts, processing podcasts, and analyzing call recordings. [[↗](https://github.com/rishikanthc/Scriberr)] |
| [**Speech Stack**](services/voice-multimodal/speech) | `speech` | CPU-optimized speech stack combining Whisper ASR and OpenedAI TTS, suitable for building voice assistants, generating audiobooks, and audio notifications. [[↗](https://github.com/matatonic/openedai-speech)] |
| [**TTS Chatterbox**](services/voice-multimodal/tts-chatterbox) | `tts-chatterbox` | State-of-the-art Text-to-Speech system serving as a high-quality alternative to ElevenLabs, providing AI voices with rich emotional expression. [[↗](https://github.com/resemble-ai/chatterbox)] |

### 🔍 Search & Web Data
Search engines and data scraping

| Service | Name | Description |
| --- | --- | ------ |
| [**Crawl4ai**](services/search-web-data/crawl4ai) | `crawl4ai` | AI-optimized web crawler designed for efficient web scraping, data extraction, and site monitoring. [[↗](https://github.com/unclecode/crawl4ai)] |
| [**GPT Researcher**](services/search-web-data/gpt-researcher) | `gpt-researcher` | Autonomous research agent capable of generating comprehensive 2000+ word reports with citations from multiple sources. [[↗](https://github.com/assafelovic/gpt-researcher)] |
| [**Local Deep Research**](services/search-web-data/local-deep-research) | `local-deep-research` | LangChain-based iterative research agent capable of fact-checking and detailed analysis with high accuracy. [[↗](https://github.com/langchain-ai/local-deep-researcher)] |
| [**Open Notebook**](services/search-web-data/opennotebook) | `opennotebook` | AI-powered knowledge management tool (NotebookLM alternative) supporting multi-modal content, podcast generation, and 16+ AI models. [[↗](https://github.com/lfnovo/open-notebook)] |
| [**Perplexica**](services/search-web-data/perplexica) | `perplexica` | Open-source AI search engine and Deep Research tool, serving as a privacy-focused alternative to Perplexity AI. [[↗](https://github.com/ItzCrazyKns/Perplexica)] |
| [**SearXNG**](services/search-web-data/searxng) | `searxng` | Privacy-respecting metasearch engine allowing search queries across multiple sources without tracking, ideal for AI agents. [[↗](https://github.com/searxng/searxng)] |

### 🗄️ Data Services
Databases and data management systems

| Service | Name | Description |
| --- | --- | ------ |
| [**Supabase**](services/data-services/supabase) | `supabase` | Open-source Backend-as-a-Service (BaaS) providing Database, Authentication, Realtime subscriptions, Storage, and Edge Functions. [[↗](https://github.com/supabase/supabase)] |
| [**Airbyte**](services/data-services/airbyte) | `airbyte` | Advanced data integration platform capable of syncing data from over 600 sources (Google Ads, Meta, TikTok, GA4) to data warehouses. Ideal for use with Metabase. [[↗](https://github.com/airbytehq/airbyte)] |
| [**MySQL Database**](services/data-services/mysql) | `mysql` | Shared MySQL database instance powering services like Leantime and Mautic. [[↗](https://hub.docker.com/_/mysql)] |
| [**Neo4j**](services/data-services/neo4j) | `neo4j` | High-performance graph database optimized for knowledge graphs, relationship mapping, and fraud detection. [[↗](https://github.com/neo4j/neo4j)] |
| [**PostgreSQL Database**](services/data-services/postgres) | `postgres` | Shared PostgreSQL database instance serving as the backend for n8n, Flowise, and other data-intensive applications. [[↗](https://hub.docker.com/_/postgres)] |
| [**Qdrant**](services/data-services/qdrant) | `qdrant` | High-performance vector database optimized for semantic search, recommendation engines, and RAG storage. [[↗](https://github.com/qdrant/qdrant)] |
| [**Redis Cache**](services/data-services/redis) | `redis` | Shared Redis instance providing caching and message brokering for services like n8n. [[↗](https://hub.docker.com/_/redis)] |
| [**Weaviate**](services/data-services/weaviate) | `weaviate` | Cloud-native vector database with API key authentication, supporting hybrid search, multi-modal data, and GraphQL APIs. [[↗](https://github.com/weaviate/weaviate)] |

### ⚙️ System Management
Monitoring, logging, and infrastructure tools

| Service | Name | Description |
| --- | --- | ------ |
| [**Kopia**](services/system-management/kopia) | `kopia` | Fast and secure backup solution supporting deduction, encryption, and compression with Cloud and WebDAV storage backends. [[↗](https://github.com/kopia/kopia)] |
| [**Monitoring Suite**](services/system-management/monitoring) | `monitoring` | Comprehensive monitoring stack (Prometheus, Grafana, cAdvisor, Node-Exporter) for system performance tracking, dashboards, and alerting. [[↗](https://github.com/grafana/grafana)] |
| [**Portainer**](services/system-management/portainer) | `portainer` | User-friendly web interface for managing Docker environments, containers, logs, and service deployments. [[↗](https://github.com/portainer/portainer)] |
| [**Uptime Kuma**](services/system-management/uptime-kuma) | `uptime-kuma` | Self-hosted monitoring tool for tracking service uptime in real-time, featuring status pages and multi-protocol notifications. [[↗](https://github.com/louislam/uptime-kuma)] |
| [**Watchtower**](services/system-management/watchtower) | `watchtower` | Utility for automating Docker container base image updates, ensuring services are always running the latest versions. [[↗](https://containrrr.dev/watchtower/)] |

### 🛡️ Security & Compliance
Security auditing and compliance tools

| Service | Name | Description |
| --- | --- | ------ |
| [**AI Security Suite - LLM Guard + Presidio**](services/security-compliance/ai-security) | `ai-security` | Comprehensive AI security suite combining LLM Guard and Presidio for AI safety and GDPR-compliance, preventing prompt injections, filtering toxicity, and removing PII. [[↗](https://github.com/protectai/llm-guard)] |
| [**Vaultwarden**](services/security-compliance/vaultwarden) | `vaultwarden` | Lightweight, self-hosted password manager compatible with Bitwarden clients, enabling secure credential management and team sharing. [[↗](https://github.com/dani-garcia/vaultwarden)] |

### 🐍 Code Runners
Code execution environments

| Service | Name | Description |
| --- | --- | ------ |
| [**Python Runner**](services/code-runners/python-runner) | `python-runner` | Execution environment for running custom Python scripts and workflows, designed to integrate seamlessly with n8n. [[↗](https://github.com/n8n-io/n8n)] |

### 🖥️ Host Services
Core host-level services

| Service | Name | Description |
| --- | --- | ------ |
| [**Private DNS**](services/host-services/private-dns) | `private-dns` | CoreDNS instance providing private DNS resolution for internal services and mail server routing. [[↗](https://github.com/coredns/coredns)] |
| [**SSH Tunnel**](services/host-services/ssh-tunnel) | `ssh-tunnel` | Cloudflare Tunnel configuration enabling secure remote SSH access via Cloudflare Zero Trust. [[↗](https://github.com/cloudflare/cloudflared)] |

### 🌐 Gateways & Proxies
Gateways, proxies and tunnels

| Service | Name | Description |
| --- | --- | ------ |
| [**Caddy Reverse Proxy**](services/gateways-proxies/caddy) | `caddy` | Advanced Reverse Proxy and Web Server providing automatic SSL termination and routing for all hosted services. [[↗](https://caddyserver.com/)] |
| [**Cloudflare Web Tunnel**](services/gateways-proxies/web-tunnel) | `web-tunnel` | Cloudflare Tunnel configuration for securely exposing local web services to the internet without opening public ports. [[↗](https://github.com/cloudflare/cloudflared)] |
| [**FastMCP Gateway**](services/gateways-proxies/fastmcp) | `fastmcp` | A unified MCP (Model Context Protocol) server that proxies and aggregates multiple MCP servers |

### 🏠 Local AI Services
Locally hosted AI models and inference servers

| Service | Name | Description |
| --- | --- | ------ |
| [**Ollama**](services/local-ai/ollama) | `ollama` | Local Large Language Model (LLM) runner enabling the execution of models like Llama, Mistral, and Phi locally with an API-compatible interface. [[↗](https://github.com/ollama/ollama)] |
| [**ComfyUI**](services/local-ai/comfyui) | `comfyui` | Node-based user interface for Stable Diffusion, enabling complex image generation workflows, AI art creation, and photo editing. [[↗](https://github.com/comfyanonymous/ComfyUI)] |
| [**OCR Bundle**](services/local-ai/ocr) | `ocr` | OCR bundle combining Tesseract and EasyOCR to reliably extract text from images and PDF documents. |

### 📁 File & Document Management
Storage, organization, and document processing

| Service | Name | Description |
| --- | --- | ------ |
| [**DocuSeal**](services/file-document-management/docuseal) | `docuseal` | Open-source e-signature platform serving as a DocuSign alternative for document signing and managing contract workflows. [[↗](https://github.com/docusealco/docuseal)] |
| [**Gotenberg**](services/file-document-management/gotenberg) | `gotenberg` | Powerful document conversion API for converting HTML, Markdown, and Office documents to PDF, as well as merging PDF files. [[↗](https://github.com/gotenberg/gotenberg)] |
| [**Outline**](services/file-document-management/outline) | `outline` | Team knowledge base and documentation platform serving as a Notion alternative with a modern, real-time editor. [[↗](https://github.com/outline/outline)] |
| [**Paperless AI Suite**](services/file-document-management/paperless-ai) | `paperless-ai` | Advanced document management suite enhanced with AI, enabling superior OCR, RAG-based Chat, and natural language queries for document Q&A. [[↗](https://github.com/clusterzx/paperless-ai)] |
| [**Paperless**](services/file-document-management/paperless) | `paperless` | Community-supported document management system featuring OCR, AI-powered auto-tagging, full-text search, and GDPR compliance tools. [[↗](https://github.com/paperless-ngx/paperless-ngx)] |
| [**Seafile**](services/file-document-management/seafile) | `seafile` | Enterprise-grade file synchronization and sharing platform (Dropbox/Google Drive alternative) featuring file versioning, WebDAV support, and mobile sync. [[↗](https://github.com/haiwen/seafile)] |
| [**Stirling-PDF**](services/file-document-management/stirling-pdf) | `stirling-pdf` | Comprehensive PDF manipulation tool offering over 100 features including merging, splitting, compressing, OCR, and signing documents. [[↗](https://github.com/Stirling-Tools/Stirling-PDF)] |

### ✨ Custom Services
User-defined custom services

| Service | Name | Description |
| --- | --- | ------ |
| [**Example Service**](services/custom-services/example-service) | `example-service` | Custom Repo Hosting Template |

---

### 🛠️ Creating Custom Services

You can easily add your own services to AI LaunchKit using the custom services directory. This allows you to integrate your own tools or proprietary software while keeping them separate from the core repository.

👉 **[Learn how to add custom services](services/custom-services/README.md)**
<!-- SERVICES_SECTION_END -->

## 💻 CLI Reference

CoreKit includes a powerful CLI tool to manage your AI stack.

```bash
corekit <command> [arguments]
```

### Common Commands

| Command | Usage | Description |
| ------- | ----- | ----------- |
| `up` | `corekit up n8n` | Start a specific service (and its dependencies). |
| `down` | `corekit down` | Stop all running services. |
| `enable` | `corekit enable <service>` | Enable a service permanently in your stack. |
| `logs` | `corekit logs <service>` | View real-time logs for a service. |
| `update` | `corekit update` | Pull latest changes and update images. |

### All Commands

| Command | Description |
| ------- | ----------- |
| `init` | Initialize the system (check requirements, install Docker). |
| `config` | Run the interactive configuration wizard. |
| `enable` | Enable specific services or entire stacks (e.g. `-s core`). |
| `disable` | Disable services or stacks. |
| `up` | Start services. |
| `down` | Stop services (use --prune to stop disabled services). |
| `restart` | Restart services. |
| `stop` | Stop services (without removing). |
| `build` | Build services. |
| `rm` | Remove stopped containers. |
| `logs` | View service logs. |
| `ps` | List running services. |
| `exec` | Execute command in container. |
| `pull` | Pull service images. |
| `update` | Update the system. |
| `credentials` | Manage credentials (download|export). |
| `run` | Run a service-specific command (e.g., corekit run ssh ...). |
| `list` | List all available services. |
| `help` | Show this help message. |

## 🔧 Configuration and Customisation

### Stacks
Stacks are pre-defined groups of services designed to work together.
- **Core Stack**: Essential services like n8n, Postgres, and Caddy.
- **AI Stack**: AI-specific tools like Ollama, Flowise, and Vector DBs.

Enable a stack easily:
```bash
corekit enable -s core
```

Define custom stacks to quickly bring up your own combinations in `config/stacks/custom`

See [Custom Stacks README](config/stacks/custom/README.md) for guidance.

### Configuration
Configuration is handled in two layers:
1.  **Global Config** (`config/.env.global`): Shared settings like Domain and Timezone.
2.  **Service Config** (`services/*/.env`): Service-specific secrets and variables.

Generate or update secrets automatically with:
```bash
corekit config
```

## 🛠️ Extensibility

AI CoreKit is designed to be purely modular.

### Service Structure
Every service is a self-contained unit in `services/<category>/<service-name>/`.
- `docker-compose.yml`: Defines the service.
- `.env.example`: Template for configuration.
- `service.json`: Metadata and dependencies.

### Adding Custom Services
1.  Create a folder: `services/custom-services/my-app`.
2.  Add a `docker-compose.yml`.
3.  Add a `service.json`.
4.  Add other hook scripts as your service requires e.g. `secrets.sh`

See [Adding New Services](docs/ADDING_NEW_SERVICE.md) for a complete guide.

## 📦 Installation & Upgrades

The `corekit` CLI handles all installation prerequisites (Docker, etc.) and updates.

- **Installation:** Follow the [Quick Start](#quick-start) above. `corekit init` will verify system requirements and install Docker if needed.
- **Update:** Run `corekit update` to pull the latest changes and update services.

## 📚 Documentation & Support

### Documentation
- [**Service Catalogue**](docs/SERVICES_CATALOGUE.md): Detailed list of all available services.
- [**Troubleshooting Guide**](docs/TROUBLESHOOTING.md): Solutions for common issues.
- [**Architecture**](docs/ARCHITECTURE.md): Deep dive into the system design.

### Need Help?
- [**GitHub Issues**](https://github.com/tcoretech/ai-corekit/issues): Report bugs or request features.
- [**Community Forum**](https://thinktank.ottomator.ai/c/local-ai/18): Discuss with other users.

---

## 👥 Contributors

Currently maintained by [tcoretech](https://github.com/tcoretech)

**Forked from:**
- [ai-launchkit](https://github.com/freddy-schuetz/ai-launchkit) by [Friedemann Schuetz](https://www.linkedin.com/in/friedemann-schuetz)

**Originally based on:**
- [n8n-installer](https://github.com/kossakovsky/n8n-installer) by kossakovsky
- [self-hosted-ai-starter-kit](https://github.com/n8n-io/self-hosted-ai-starter-kit) by n8n team
- [local-ai-packaged](https://github.com/coleam00/local-ai-packaged) by coleam00

[View all contributors](https://github.com/tcoretech/ai-corekit/graphs/contributors)

---

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Ready to launch your AI projects?**

[⭐ Star this repo](https://github.com/tcoretech/ai-corekit) • [🐛 Report issues](https://github.com/tcoretech/ai-corekit/issues) • [🤝 Contribute](https://github.com/tcoretech/ai-corekit/pulls)

</div>
