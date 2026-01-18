<div align="center">

# AI CoreKit

**Open-Source AI Development Toolkit**

*Deploy your complete AI stack in minutes, not weeks*

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/tcoretech/ai-corekit?style=social)](https://github.com/tcoretech/ai-corekit)
[![Repository Views](https://komarev.com/ghpvc/?username=tcoretech&repo=ai-corekit&label=Views&color=brightgreen)](https://github.com/tcoretech/ai-corekit)
[![GitHub last commit](https://img.shields.io/github/last-commit/tcoretech/ai-corekit)](https://github.com/tcoretech/ai-corekit/commits/main)
[![Contributors](https://img.shields.io/github/contributors/tcoretech/ai-corekit)](https://github.com/tcoretech/ai-corekit/graphs/contributors)

[Installation](#quick-start) • [Services](#whats-included) • [CLI Reference](#cli-reference) • [Configuration](#configuration-and-customisation) • [Documentation](#documentation--support)

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
corekit up ragflow
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

> **78+ self-hosted services** organized into categories.
> Each service includes its own README with detailed setup instructions, n8n integration examples, and troubleshooting guides.

### 🔧 Workflow Automation
Orchestrate processes and integrate services

| Service | Name | Description |
| --- | --- | ------ |
| [**n8n**](services/workflow-automation/n8n) [↗](https://github.com/n8n-io/n8n) | `n8n` | Extendable workflow automation tool for connecting apps, building API integrations, and orchestrating complex business processes. |
| [**Gitea**](services/workflow-automation/gitea) [↗](https://github.com/go-gitea/gitea) | `gitea` | Lightweight, self-hosted DevOps platform and Git service providing source code management, issue tracking, and CI/CD capabilities. |
| [**Webhook Tester + Hoppscotch**](services/workflow-automation/webhook-testing) [↗](https://github.com/tarampampam/webhook-tester) | `webhook-testing` | Debugging suite combining Webhook Tester and Hoppscotch for inspecting incoming webhooks and testing external service integrations. |
| [**n8n-MCP**](services/workflow-automation/n8n-mcp) [↗](https://github.com/czlonkowski/n8n-mcp) | `n8n-mcp` | Model Context Protocol (MCP) server for n8n, enabling AI assistants like Claude or Cursor to generate and validate n8n workflows. |

### 🎯 User Interfaces
Front-end interfaces and dashboards

| Service | Name | Description |
| --- | --- | ------ |
| [**Homepage**](services/user-interfaces/homepage) [↗](https://github.com/gethomepage/homepage) | `homepage` | Modern, customizable dashboard providing a centralized overview and quick access to all hosted services and Docker integrations. |
| [**Landing Page**](services/user-interfaces/landing-page) | `landing-page` | Static landing page serving as the main entry point and navigation hub for the deployed infrastructure. |
| [**Open WebUI**](services/user-interfaces/open-webui) [↗](https://github.com/open-webui/open-webui) | `open-webui` | Feature-rich, self-hosted web interface (ChatGPT alternative) for interacting with local Large Language Models. |
| [**Postiz**](services/user-interfaces/postiz) [↗](https://github.com/gitroomhq/postiz-app) | `postiz` | Open-source social media scheduling and publishing platform with analytics and multi-account support. |

### 📧 Mail System
Email sending, receiving, and management

| Service | Name | Description |
| --- | --- | ------ |
| [**Docker Mailserver**](services/mail-system/mailserver) [↗](https://github.com/docker-mailserver/docker-mailserver) | `mailserver` | Full-stack mail server (Docker-Mailserver) with Mailgun ingest support for sending and receiving real emails. |
| [**Mail Ingest**](services/mail-system/mail-ingest) | `mail-ingest` | Webhook forwarder that ingests incoming emails from Mailgun and routes them to the local docker-mailserver. |
| [**Mailpit**](services/mail-system/mailpit) [↗](https://github.com/axllent/mailpit) | `mailpit` | Development email capture tool with a web UI for testing and debugging SMTP flows without sending real emails. |
| [**SMTP Relay**](services/mail-system/smtp-relay) [↗](https://github.com/docker-mailserver/docker-mailserver) | `smtp-relay` | Dedicated SMTP relay service for handling outbound transactional email delivery and forwarding. |
| [**SnappyMail**](services/mail-system/snappymail) [↗](https://github.com/the-djmaze/snappymail) | `snappymail` | Modern, lightweight webmail client interface for Docker-Mailserver. |

### 📹 Video Conferencing
Real-time video and audio communication

| Service | Name | Description |
| --- | --- | ------ |
| [**Jitsi Meet**](services/video-conferencing/jitsi) [↗](https://github.com/jitsi/jitsi-meet) | `jitsi` | Secure, open-source video conferencing platform supporting screen sharing, team calls, and webinar hosting (Requires UDP port 10000). |

### 📁 File & Document Management
Storage, organization, and document processing

| Service | Name | Description |
| --- | --- | ------ |
| [**Paperless AI Suite**](services/file-document-management/paperless-ai) [↗](https://github.com/clusterzx/paperless-ai) | `paperless-ai` | Advanced document management suite enhanced with AI, enabling superior OCR, RAG-based Chat, and natural language queries for document Q&A. |
| [**Paperless**](services/file-document-management/paperless) [↗](https://github.com/paperless-ngx/paperless-ngx) | `paperless` | Community-supported document management system featuring OCR, AI-powered auto-tagging, full-text search, and GDPR compliance tools. |
| [**Seafile**](services/file-document-management/seafile) [↗](https://github.com/haiwen/seafile) | `seafile` | Enterprise-grade file synchronization and sharing platform (Dropbox/Google Drive alternative) featuring file versioning, WebDAV support, and mobile sync. |

### 💼 Business Productivity
Tools for business operations and management

| Service | Name | Description |
| --- | --- | ------ |
| [**Airbyte**](services/business-productivity/airbyte) [↗](https://github.com/airbytehq/airbyte) | `airbyte` | Advanced data integration platform capable of syncing data from over 600 sources (Google Ads, Meta, TikTok, GA4) to data warehouses. Ideal for use with Metabase. |
| [**Baserow**](services/business-productivity/baserow) [↗](https://github.com/bram2w/baserow) | `baserow` | Open-source no-code database and Airtable alternative for database management, project tracking, and building collaborative workflows. |
| [**Cal.com**](services/business-productivity/calcom) [↗](https://github.com/calcom/cal.com) | `calcom` | Open-source scheduling platform streamlining meeting bookings, team calendars, and payment integrations. |
| [**EspoCRM**](services/business-productivity/espocrm) [↗](https://github.com/espocrm/espocrm) | `espocrm` | Full-featured Customer Relationship Management (CRM) system offering email campaigns, workflow automation, advanced reporting, and role-based access. |
| [**Formbricks**](services/business-productivity/formbricks) [↗](https://github.com/formbricks/formbricks) | `formbricks` | Privacy-first survey and form builder serving as a GDPR-compliant Typeform alternative for customer feedback, NPS surveys, and market research. |
| [**Invoice Ninja**](services/business-productivity/invoiceninja) [↗](https://github.com/invoiceninja/invoiceninja) | `invoiceninja` | Professional invoicing platform supporting multi-currency invoices, recurring billing, client portals, and over 40 payment gateways. |
| [**Kimai**](services/business-productivity/kimai) [↗](https://github.com/kimai/kimai) | `kimai` | Professional, DSGVO-compliant time tracking software featuring team timesheets, invoicing, 2FA security, and API access. |
| [**Leantime**](services/business-productivity/leantime) [↗](https://github.com/Leantime/leantime) | `leantime` | ADHD-friendly project management suite comparable to Asana or Monday, featuring time tracking, sprint planning, and strategy tools. |
| [**Mautic**](services/business-productivity/mautic) [↗](https://github.com/mautic/mautic) | `mautic` | Open-source marketing automation platform for lead scoring, email campaigns, landing pages, and multi-channel marketing workflows. |
| [**Metabase**](services/business-productivity/metabase) [↗](https://github.com/metabase/metabase) | `metabase` | Business intelligence platform enabling no-code dashboards, automated reports, data exploration, and team analytics. |
| [**NocoDB**](services/business-productivity/nocodb) [↗](https://github.com/nocodb/nocodb) | `nocodb` | Open-source Airtable alternative featuring a smart spreadsheet UI for real-time collaboration and automation. |
| [**Odoo**](services/business-productivity/odoo) [↗](https://github.com/odoo/odoo) | `odoo` | Comprehensive ERP and CRM suite with AI features for sales automation, inventory management, accounting, and lead scoring. |
| [**Outline**](services/business-productivity/outline) [↗](https://github.com/outline/outline) | `outline` | Team knowledge base and documentation platform serving as a Notion alternative with a modern, real-time editor. |
| [**Twenty CRM**](services/business-productivity/twenty-crm) [↗](https://github.com/twentyhq/twenty) | `twenty-crm` | Modern, open-source CRM with a Notion-like interface, featuring customer pipelines, GraphQL API, and tools for startups. |
| [**Vikunja**](services/business-productivity/vikunja) [↗](https://github.com/go-vikunja/vikunja) | `vikunja` | Modern task management platform and Todoist alternative offering Kanban boards, Gantt charts, CalDAV sync, and team collaboration. |

### 🎨 AI Content Generation
Generate images, text, and other media

| Service | Name | Description |
| --- | --- | ------ |
| [**ComfyUI**](services/ai-content-generation/comfyui) [↗](https://github.com/comfyanonymous/ComfyUI) | `comfyui` | Node-based user interface for Stable Diffusion, enabling complex image generation workflows, AI art creation, and photo editing. |

### 💻 AI-Powered Development
Coding assistance and development tools

| Service | Name | Description |
| --- | --- | ------ |
| [**bolt.diy**](services/ai-powered-development/bolt) [↗](https://github.com/stackblitz-labs/bolt.diy) | `bolt` | AI-powered web development tool for rapid prototyping, creating MVPs, and assisting in learning to code. |
| [**OpenUI**](services/ai-powered-development/openui) [↗](https://github.com/wandb/openui) | `openui` | Experimental AI frontend and UI generator for creating design systems, component libraries, and mockups. |

### 🤖 AI Agents
Autonomous agents and assistants

| Service | Name | Description |
| --- | --- | ------ |
| [**Langfuse**](services/ai-agents/langfuse) | `langfuse` | AI observability platform including Clickhouse and Minio, specialized for DSGVO compliance, German text processing, and entity recognition. |
| [**Browser Automation Suite**](services/ai-agents/browser-suite) [↗](https://github.com/browser-use/browser-use) | `browser-suite` | Comprehensive browser automation suite combining Browserless, Skyvern, and Browser-use for web scraping, form filling, and automated testing. |
| [**Dify**](services/ai-agents/dify) [↗](https://github.com/langgenius/dify) | `dify` | LLM application development platform designed for building AI agents, chatbots, and automating workflows. |
| [**Flowise**](services/ai-agents/flowise) [↗](https://github.com/FlowiseAI/Flowise) | `flowise` | Drag-and-drop AI agent builder for creating chatbots, customer support assistants, and complex AI workflows. |
| [**Letta**](services/ai-agents/letta) [↗](https://github.com/letta-ai/letta) | `letta` | Agent Server and SDK enabling the creation of persistent AI assistants with advanced memory management capabilities. |
| [**LiveKit**](services/ai-agents/livekit) [↗](https://github.com/livekit/livekit) | `livekit` | Real-time voice/video WebRTC infrastructure for building AI voice assistants and conversational AI bots. Requires UDP ports 50000-50100. |
| [**Vexa**](services/ai-agents/vexa) [↗](https://github.com/Vexa-ai/vexa) | `vexa` | Real-time meeting transcription API supporting 99 languages, offering live transcription for Google Meet & Teams with speaker identification. |

### 📚 RAG Systems
Retrieval-Augmented Generation systems

| Service | Name | Description |
| --- | --- | ------ |
| [**Qdrant**](services/rag-systems/qdrant) [↗](https://github.com/qdrant/qdrant) | `qdrant` | High-performance vector database optimized for semantic search, recommendation engines, and RAG storage. |
| [**RAGApp**](services/rag-systems/ragapp) [↗](https://github.com/ragapp/ragapp) | `ragapp` | Open-source UI and API for Retrieval-Augmented Generation (RAG), enabling easy creation of knowledge bases and document Q&A tools. |
| [**Weaviate**](services/rag-systems/weaviate) [↗](https://github.com/weaviate/weaviate) | `weaviate` | Cloud-native vector database with API key authentication, supporting hybrid search, multi-modal data, and GraphQL APIs. |

### 🎙️ Speech, Language & Text
Speech recognition and text processing

| Service | Name | Description |
| --- | --- | ------ |
| [**LibreTranslate**](services/speech-language-text/libretranslate) [↗](https://github.com/LibreTranslate/LibreTranslate) | `libretranslate` | Self-hosted, privacy-focused translation API supporting over 50 languages for text and document translation. |
| [**OCR Bundle**](services/speech-language-text/ocr) | `ocr` | OCR bundle combining Tesseract and EasyOCR to reliably extract text from images and PDF documents. |
| [**Scriberr**](services/speech-language-text/scriberr) [↗](https://github.com/rishikanthc/Scriberr) | `scriberr` | AI-powered audio transcription tool featuring speaker diarization, ideal for creating meeting transcripts, processing podcasts, and analyzing call recordings. |
| [**Speech Stack**](services/speech-language-text/speech) [↗](https://github.com/matatonic/openedai-speech) | `speech` | CPU-optimized speech stack combining Whisper ASR and OpenedAI TTS, suitable for building voice assistants, generating audiobooks, and audio notifications. |
| [**TTS Chatterbox**](services/speech-language-text/tts-chatterbox) [↗](https://github.com/resemble-ai/chatterbox) | `tts-chatterbox` | State-of-the-art Text-to-Speech system serving as a high-quality alternative to ElevenLabs, providing AI voices with rich emotional expression. |

### 🔍 Search & Web Data
Search engines and data scraping

| Service | Name | Description |
| --- | --- | ------ |
| [**Crawl4ai**](services/search-web-data/crawl4ai) [↗](https://github.com/unclecode/crawl4ai) | `crawl4ai` | AI-optimized web crawler designed for efficient web scraping, data extraction, and site monitoring. |
| [**GPT Researcher**](services/search-web-data/gpt-researcher) [↗](https://github.com/assafelovic/gpt-researcher) | `gpt-researcher` | Autonomous research agent capable of generating comprehensive 2000+ word reports with citations from multiple sources. |
| [**Local Deep Research**](services/search-web-data/local-deep-research) [↗](https://github.com/langchain-ai/local-deep-researcher) | `local-deep-research` | LangChain-based iterative research agent capable of fact-checking and detailed analysis with high accuracy. |
| [**Open Notebook**](services/search-web-data/opennotebook) [↗](https://github.com/lfnovo/open-notebook) | `opennotebook` | AI-powered knowledge management tool (NotebookLM alternative) supporting multi-modal content, podcast generation, and 16+ AI models. |
| [**Perplexica**](services/search-web-data/perplexica) [↗](https://github.com/ItzCrazyKns/Perplexica) | `perplexica` | Open-source AI search engine and Deep Research tool, serving as a privacy-focused alternative to Perplexity AI. |
| [**SearXNG**](services/search-web-data/searxng) [↗](https://github.com/searxng/searxng) | `searxng` | Privacy-respecting metasearch engine allowing search queries across multiple sources without tracking, ideal for AI agents. |

### 🧠 Knowledge Graphs
Structure and query complex data relationships

| Service | Name | Description |
| --- | --- | ------ |
| [**LightRAG**](services/knowledge-graphs/lightrag) [↗](https://github.com/HKUDS/LightRAG) | `lightrag` | Graph-based Retrieval-Augmented Generation (RAG) system specializing in entity extraction and automatic knowledge graph creation. |
| [**Neo4j**](services/knowledge-graphs/neo4j) [↗](https://github.com/neo4j/neo4j) | `neo4j` | High-performance graph database optimized for knowledge graphs, relationship mapping, and fraud detection. |

### 🗄️ Data Infrastructure
Databases and data management systems

| Service | Name | Description |
| --- | --- | ------ |
| [**Supabase**](services/data-infrastructure/supabase) [↗](https://github.com/supabase/supabase) | `supabase` | Open-source Backend-as-a-Service (BaaS) providing Database, Authentication, Realtime subscriptions, Storage, and Edge Functions. |
| [**MySQL Database**](services/data-infrastructure/mysql) [↗](https://hub.docker.com/_/mysql) | `mysql` | Shared MySQL database instance powering services like Leantime and Mautic. |
| [**PostgreSQL Database**](services/data-infrastructure/postgres) [↗](https://hub.docker.com/_/postgres) | `postgres` | Shared PostgreSQL database instance serving as the backend for n8n, Flowise, and other data-intensive applications. |
| [**Redis Cache**](services/data-infrastructure/redis) [↗](https://hub.docker.com/_/redis) | `redis` | Shared Redis instance providing caching and message brokering for services like n8n. |

### ⚙️ System Management
Monitoring, logging, and infrastructure tools

| Service | Name | Description |
| --- | --- | ------ |
| [**Caddy Reverse Proxy**](services/system-management/caddy) [↗](https://caddyserver.com/) | `caddy` | Advanced Reverse Proxy and Web Server providing automatic SSL termination and routing for all hosted services. |
| [**Cloudflare Web Tunnel**](services/system-management/web-tunnel) [↗](https://github.com/cloudflare/cloudflared) | `web-tunnel` | Cloudflare Tunnel configuration for securely exposing local web services to the internet without opening public ports. |
| [**Kopia**](services/system-management/kopia) [↗](https://github.com/kopia/kopia) | `kopia` | Fast and secure backup solution supporting deduction, encryption, and compression with Cloud and WebDAV storage backends. |
| [**Monitoring Suite**](services/system-management/monitoring) [↗](https://github.com/grafana/grafana) | `monitoring` | Comprehensive monitoring stack (Prometheus, Grafana, cAdvisor, Node-Exporter) for system performance tracking, dashboards, and alerting. |
| [**Portainer**](services/system-management/portainer) [↗](https://github.com/portainer/portainer) | `portainer` | User-friendly web interface for managing Docker environments, containers, logs, and service deployments. |
| [**Uptime Kuma**](services/system-management/uptime-kuma) [↗](https://github.com/louislam/uptime-kuma) | `uptime-kuma` | Self-hosted monitoring tool for tracking service uptime in real-time, featuring status pages and multi-protocol notifications. |
| [**Vaultwarden**](services/system-management/vaultwarden) [↗](https://github.com/dani-garcia/vaultwarden) | `vaultwarden` | Lightweight, self-hosted password manager compatible with Bitwarden clients, enabling secure credential management and team sharing. |
| [**Watchtower**](services/system-management/watchtower) [↗](https://containrrr.dev/watchtower/) | `watchtower` | Utility for automating Docker container base image updates, ensuring services are always running the latest versions. |

### 🧰 AI Support Tools
Utilities and supporting services for AI

| Service | Name | Description |
| --- | --- | ------ |
| [**DocuSeal**](services/ai-support-tools/docuseal) [↗](https://github.com/docusealco/docuseal) | `docuseal` | Open-source e-signature platform serving as a DocuSign alternative for document signing and managing contract workflows. |
| [**Gotenberg**](services/ai-support-tools/gotenberg) [↗](https://github.com/gotenberg/gotenberg) | `gotenberg` | Powerful document conversion API for converting HTML, Markdown, and Office documents to PDF, as well as merging PDF files. |
| [**Ollama**](services/ai-support-tools/ollama) [↗](https://github.com/ollama/ollama) | `ollama` | Local Large Language Model (LLM) runner enabling the execution of models like Llama, Mistral, and Phi locally with an API-compatible interface. |
| [**Stirling-PDF**](services/ai-support-tools/stirling-pdf) [↗](https://github.com/Stirling-Tools/Stirling-PDF) | `stirling-pdf` | Comprehensive PDF manipulation tool offering over 100 features including merging, splitting, compressing, OCR, and signing documents. |

### 🛡️ AI Security & Compliance
Security auditing and compliance tools

| Service | Name | Description |
| --- | --- | ------ |
| [**AI Security Suite - LLM Guard + Presidio**](services/ai-security-compliance/ai-security) [↗](https://github.com/protectai/llm-guard) | `ai-security` | Comprehensive AI security suite combining LLM Guard and Presidio for AI safety and GDPR-compliance, preventing prompt injections, filtering toxicity, and removing PII. |

### 🐍 Python
Python environments and script runners

| Service | Name | Description |
| --- | --- | ------ |
| [**Python Runner**](services/python/python-runner) [↗](https://github.com/n8n-io/n8n) | `python-runner` | Execution environment for running custom Python scripts and workflows, designed to integrate seamlessly with n8n. |

### 🖥️ Host Services
Core host-level services

| Service | Name | Description |
| --- | --- | ------ |
| [**Private DNS**](services/host-services/private-dns) [↗](https://github.com/coredns/coredns) | `private-dns` | CoreDNS instance providing private DNS resolution for internal services and mail server routing. |
| [**SSH Tunnel**](services/host-services/ssh-tunnel) [↗](https://github.com/cloudflare/cloudflared) | `ssh-tunnel` | Cloudflare Tunnel configuration enabling secure remote SSH access via Cloudflare Zero Trust. |

---

> 📖 **For detailed documentation**, see each service's README in `services/<category>/<service>/README.md`
<!-- SERVICES_SECTION_END -->

## ⌨️ CLI Reference

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

## ⚙️ Configuration and Customisation

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
1.  Create a folder: `services/custom/my-app`.
2.  Add a `docker-compose.yml`.
3.  Add a `service.json`.

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
