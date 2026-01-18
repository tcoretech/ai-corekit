# AI LaunchKit Services Catalogue

This document provides a complete catalogue of the **80+ self-hosted services** included in AI LaunchKit.

## Table of Contents

- [🔧 Workflow Automation](#-workflow-automation)
- [🎯 Frontends](#-frontends)
- [📧 Mail System](#-mail-system)
- [💼 Business Productivity](#-business-productivity)
- [💻 Development Tools](#-development-tools)
- [🤖 Agentic Frameworks](#-agentic-frameworks)
- [📚 RAG Systems](#-rag-systems)
- [🎙️ Voice & Multimodal](#%EF%B8%8F-voice--multimodal)
- [🔍 Search & Web Data](#-search--web-data)
- [🗄️ Data Services](#%EF%B8%8F-data-services)
- [⚙️ System Management](#%EF%B8%8F-system-management)
- [🛡️ Security & Compliance](#%EF%B8%8F-security--compliance)
- [🐍 Code Runners](#-code-runners)
- [🖥️ Host Services](#%EF%B8%8F-host-services)
- [🌐 Gateways & Proxies](#-gateways--proxies)
- [🏠 Local AI Services](#-local-ai-services)
- [📁 File & Document Management](#-file--document-management)
- [✨ Custom Services](#-custom-services)

---

## 🔧 Workflow Automation
Orchestrate processes and integrate services

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**n8n**](../services/workflow-automation/n8n) <br> [`n8n`] | Extendable workflow automation tool for connecting apps, building API integrations, and orchestrating complex business processes. [[↗](https://github.com/n8n-io/n8n)] | `n8n.<yourdomain>.com` | postgres, redis |
| [**Flowise**](../services/workflow-automation/flowise) <br> [`flowise`] | Drag-and-drop AI agent builder for creating chatbots, customer support assistants, and complex AI workflows. [[↗](https://github.com/FlowiseAI/Flowise)] | `flowise.<yourdomain>.com` | - |
| [**Webhook Tester + Hoppscotch**](../services/workflow-automation/webhook-testing) <br> [`webhook-testing`] | Debugging suite combining Webhook Tester and Hoppscotch for inspecting incoming webhooks and testing external service integrations. [[↗](https://github.com/tarampampam/webhook-tester)] | `webhook-test.<yourdomain>.com` | mailpit |
| [**n8n-MCP**](../services/workflow-automation/n8n-mcp) <br> [`n8n-mcp`] | Model Context Protocol (MCP) server for n8n, enabling AI assistants like Claude or Cursor to generate and validate n8n workflows. [[↗](https://github.com/czlonkowski/n8n-mcp)] | `n8nmcp.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🎯 Frontends
Front-end interfaces and dashboards

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Homepage**](../services/frontends/homepage) <br> [`homepage`] | Modern, customizable dashboard providing a centralized overview and quick access to all hosted services and Docker integrations. [[↗](https://github.com/gethomepage/homepage)] | `dashboard.<yourdomain>.com` | - |
| [**Landing Page**](../services/frontends/landing-page) <br> [`landing-page`] | Static landing page serving as the main entry point and navigation hub for the deployed infrastructure. | `<yourdomain>.com` | - |
| [**Open WebUI**](../services/frontends/open-webui) <br> [`open-webui`] | Feature-rich, self-hosted web interface (ChatGPT alternative) for interacting with local Large Language Models. [[↗](https://github.com/open-webui/open-webui)] | `webui.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 📧 Mail System
Email sending, receiving, and management

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Docker Mailserver**](../services/mail-system/mailserver) <br> [`mailserver`] | Full-stack mail server (Docker-Mailserver) with Mailgun ingest support for sending and receiving real emails. [[↗](https://github.com/docker-mailserver/docker-mailserver)] | `mail.<yourdomain>.com` | caddy |
| [**Mail Ingest**](../services/mail-system/mail-ingest) <br> [`mail-ingest`] | Webhook forwarder that ingests incoming emails from Mailgun and routes them to the local docker-mailserver. | `mail-ingest.<yourdomain>.com` | mailserver |
| [**Mailpit**](../services/mail-system/mailpit) <br> [`mailpit`] | Development email capture tool with a web UI for testing and debugging SMTP flows without sending real emails. [[↗](https://github.com/axllent/mailpit)] | `mailpit.<yourdomain>.com` | - |
| [**SMTP Relay**](../services/mail-system/smtp-relay) <br> [`smtp-relay`] | Dedicated SMTP relay service for handling outbound transactional email delivery and forwarding. [[↗](https://github.com/docker-mailserver/docker-mailserver)] | internal: smtp://mailserver:25 | - |
| [**SnappyMail**](../services/mail-system/snappymail) <br> [`snappymail`] | Modern, lightweight webmail client interface for Docker-Mailserver. [[↗](https://github.com/the-djmaze/snappymail)] | `webmail.<yourdomain>.com` | mailserver |

[Back to Top](#table-of-contents)

## 💼 Business Productivity
Tools for business operations and management

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Baserow**](../services/business-productivity/baserow) <br> [`baserow`] | Open-source no-code database and Airtable alternative for database management, project tracking, and building collaborative workflows. [[↗](https://github.com/bram2w/baserow)] | `baserow.<yourdomain>.com` | postgres, redis |
| [**Cal.com**](../services/business-productivity/calcom) <br> [`calcom`] | Open-source scheduling platform streamlining meeting bookings, team calendars, and payment integrations. [[↗](https://github.com/calcom/cal.com)] | `cal.<yourdomain>.com` | postgres, redis |
| [**EspoCRM**](../services/business-productivity/espocrm) <br> [`espocrm`] | Full-featured Customer Relationship Management (CRM) system offering email campaigns, workflow automation, advanced reporting, and role-based access. [[↗](https://github.com/espocrm/espocrm)] | `espocrm.<yourdomain>.com` | - |
| [**Formbricks**](../services/business-productivity/formbricks) <br> [`formbricks`] | Privacy-first survey and form builder serving as a GDPR-compliant Typeform alternative for customer feedback, NPS surveys, and market research. [[↗](https://github.com/formbricks/formbricks)] | `forms.<yourdomain>.com` | postgres, redis |
| [**Invoice Ninja**](../services/business-productivity/invoiceninja) <br> [`invoiceninja`] | Professional invoicing platform supporting multi-currency invoices, recurring billing, client portals, and over 40 payment gateways. [[↗](https://github.com/invoiceninja/invoiceninja)] | `invoices.<yourdomain>.com` | redis |
| [**Jitsi Meet**](../services/business-productivity/jitsi) <br> [`jitsi`] | Secure, open-source video conferencing platform supporting screen sharing, team calls, and webinar hosting (Requires UDP port 10000). [[↗](https://github.com/jitsi/jitsi-meet)] | `meet.<yourdomain>.com` | - |
| [**Kimai**](../services/business-productivity/kimai) <br> [`kimai`] | Professional, DSGVO-compliant time tracking software featuring team timesheets, invoicing, 2FA security, and API access. [[↗](https://github.com/kimai/kimai)] | `time.<yourdomain>.com` | - |
| [**Leantime**](../services/business-productivity/leantime) <br> [`leantime`] | ADHD-friendly project management suite comparable to Asana or Monday, featuring time tracking, sprint planning, and strategy tools. [[↗](https://github.com/Leantime/leantime)] | `leantime.<yourdomain>.com` | mysql |
| [**Mautic**](../services/business-productivity/mautic) <br> [`mautic`] | Open-source marketing automation platform for lead scoring, email campaigns, landing pages, and multi-channel marketing workflows. [[↗](https://github.com/mautic/mautic)] | `mautic.<yourdomain>.com` | - |
| [**Metabase**](../services/business-productivity/metabase) <br> [`metabase`] | Business intelligence platform enabling no-code dashboards, automated reports, data exploration, and team analytics. [[↗](https://github.com/metabase/metabase)] | `analytics.<yourdomain>.com` | - |
| [**NocoDB**](../services/business-productivity/nocodb) <br> [`nocodb`] | Open-source Airtable alternative featuring a smart spreadsheet UI for real-time collaboration and automation. [[↗](https://github.com/nocodb/nocodb)] | `nocodb.<yourdomain>.com` | postgres, redis |
| [**Odoo**](../services/business-productivity/odoo) <br> [`odoo`] | Comprehensive ERP and CRM suite with AI features for sales automation, inventory management, accounting, and lead scoring. [[↗](https://github.com/odoo/odoo)] | `odoo.<yourdomain>.com` | postgres |
| [**Postiz**](../services/business-productivity/postiz) <br> [`postiz`] | Open-source social media scheduling and publishing platform with analytics and multi-account support. [[↗](https://github.com/gitroomhq/postiz-app)] | `postiz.<yourdomain>.com` | postgres, redis |
| [**Twenty CRM**](../services/business-productivity/twenty-crm) <br> [`twenty-crm`] | Modern, open-source CRM with a Notion-like interface, featuring customer pipelines, GraphQL API, and tools for startups. [[↗](https://github.com/twentyhq/twenty)] | `twenty.<yourdomain>.com` | - |
| [**Vikunja**](../services/business-productivity/vikunja) <br> [`vikunja`] | Modern task management platform and Todoist alternative offering Kanban boards, Gantt charts, CalDAV sync, and team collaboration. [[↗](https://github.com/go-vikunja/vikunja)] | `vikunja.<yourdomain>.com` | postgres, redis |

[Back to Top](#table-of-contents)

## 💻 Development Tools
Coding assistance and development tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Langfuse**](../services/development-tools/langfuse) <br> [`langfuse`] | AI observability platform including Clickhouse and Minio, specialized for DSGVO compliance, German text processing, and entity recognition. | internal: http://langfuse-web:3000 | - |
| [**bolt.diy**](../services/development-tools/bolt) <br> [`bolt`] | AI-powered web development tool for rapid prototyping, creating MVPs, and assisting in learning to code. [[↗](https://github.com/stackblitz-labs/bolt.diy)] | `bolt.<yourdomain>.com` | - |
| [**Gitea**](../services/development-tools/gitea) <br> [`gitea`] | Lightweight, self-hosted DevOps platform and Git service providing source code management, issue tracking, and CI/CD capabilities. [[↗](https://github.com/go-gitea/gitea)] | `git.<yourdomain>.com` | - |
| [**OpenUI**](../services/development-tools/openui) <br> [`openui`] | Experimental AI frontend and UI generator for creating design systems, component libraries, and mockups. [[↗](https://github.com/wandb/openui)] | `openui.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🤖 Agentic Frameworks
Autonomous agents and frameworks

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Browser Automation Suite**](../services/agentic-frameworks/browser-suite) <br> [`browser-suite`] | Comprehensive browser automation suite combining Browserless, Skyvern, and Browser-use for web scraping, form filling, and automated testing. [[↗](https://github.com/browser-use/browser-use)] | internal: http://browserless:3000 | - |
| [**Dify**](../services/agentic-frameworks/dify) <br> [`dify`] | LLM application development platform designed for building AI agents, chatbots, and automating workflows. [[↗](https://github.com/langgenius/dify)] | `dify.<yourdomain>.com` | - |
| [**Letta**](../services/agentic-frameworks/letta) <br> [`letta`] | Agent Server and SDK enabling the creation of persistent AI assistants with advanced memory management capabilities. [[↗](https://github.com/letta-ai/letta)] | `letta.<yourdomain>.com` | - |
| [**Vexa**](../services/agentic-frameworks/vexa) <br> [`vexa`] | Real-time meeting transcription API supporting 99 languages, offering live transcription for Google Meet & Teams with speaker identification. [[↗](https://github.com/Vexa-ai/vexa)] | internal: http://api-gateway:8000 | - |

[Back to Top](#table-of-contents)

## 📚 RAG Systems
Retrieval-Augmented Generation systems

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**LightRAG**](../services/rag-systems/lightrag) <br> [`lightrag`] | Graph-based Retrieval-Augmented Generation (RAG) system specializing in entity extraction and automatic knowledge graph creation. [[↗](https://github.com/HKUDS/LightRAG)] | `lightrag.<yourdomain>.com` | - |
| [**RAGApp**](../services/rag-systems/ragapp) <br> [`ragapp`] | Open-source UI and API for Retrieval-Augmented Generation (RAG), enabling easy creation of knowledge bases and document Q&A tools. [[↗](https://github.com/ragapp/ragapp)] | `ragapp.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🎙️ Voice & Multimodal
Speech recognition, synthesis, and multimodal processing

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**LibreTranslate**](../services/voice-multimodal/libretranslate) <br> [`libretranslate`] | Self-hosted, privacy-focused translation API supporting over 50 languages for text and document translation. [[↗](https://github.com/LibreTranslate/LibreTranslate)] | `translate.<yourdomain>.com` | - |
| [**LiveKit**](../services/voice-multimodal/livekit) <br> [`livekit`] | Real-time voice/video WebRTC infrastructure for building AI voice assistants and conversational AI bots. Requires UDP ports 50000-50100. [[↗](https://github.com/livekit/livekit)] | `livekit.<yourdomain>.com` | redis |
| [**Scriberr**](../services/voice-multimodal/scriberr) <br> [`scriberr`] | AI-powered audio transcription tool featuring speaker diarization, ideal for creating meeting transcripts, processing podcasts, and analyzing call recordings. [[↗](https://github.com/rishikanthc/Scriberr)] | `scriberr.<yourdomain>.com` | - |
| [**Speech Stack**](../services/voice-multimodal/speech) <br> [`speech`] | CPU-optimized speech stack combining Whisper ASR and OpenedAI TTS, suitable for building voice assistants, generating audiobooks, and audio notifications. [[↗](https://github.com/matatonic/openedai-speech)] | internal: http://openedai-speech:8000 | - |
| [**TTS Chatterbox**](../services/voice-multimodal/tts-chatterbox) <br> [`tts-chatterbox`] | State-of-the-art Text-to-Speech system serving as a high-quality alternative to ElevenLabs, providing AI voices with rich emotional expression. [[↗](https://github.com/resemble-ai/chatterbox)] | `chatterbox.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🔍 Search & Web Data
Search engines and data scraping

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Crawl4ai**](../services/search-web-data/crawl4ai) <br> [`crawl4ai`] | AI-optimized web crawler designed for efficient web scraping, data extraction, and site monitoring. [[↗](https://github.com/unclecode/crawl4ai)] | Internal | - |
| [**GPT Researcher**](../services/search-web-data/gpt-researcher) <br> [`gpt-researcher`] | Autonomous research agent capable of generating comprehensive 2000+ word reports with citations from multiple sources. [[↗](https://github.com/assafelovic/gpt-researcher)] | `research.<yourdomain>.com` | searxng |
| [**Local Deep Research**](../services/search-web-data/local-deep-research) <br> [`local-deep-research`] | LangChain-based iterative research agent capable of fact-checking and detailed analysis with high accuracy. [[↗](https://github.com/langchain-ai/local-deep-researcher)] | internal: http://local-deep-research:2024 | searxng |
| [**Open Notebook**](../services/search-web-data/opennotebook) <br> [`opennotebook`] | AI-powered knowledge management tool (NotebookLM alternative) supporting multi-modal content, podcast generation, and 16+ AI models. [[↗](https://github.com/lfnovo/open-notebook)] | `notebook.<yourdomain>.com` | - |
| [**Perplexica**](../services/search-web-data/perplexica) <br> [`perplexica`] | Open-source AI search engine and Deep Research tool, serving as a privacy-focused alternative to Perplexity AI. [[↗](https://github.com/ItzCrazyKns/Perplexica)] | `perplexica.<yourdomain>.com` | searxng |
| [**SearXNG**](../services/search-web-data/searxng) <br> [`searxng`] | Privacy-respecting metasearch engine allowing search queries across multiple sources without tracking, ideal for AI agents. [[↗](https://github.com/searxng/searxng)] | `searxng.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🗄️ Data Services
Databases and data management systems

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Supabase**](../services/data-services/supabase) <br> [`supabase`] | Open-source Backend-as-a-Service (BaaS) providing Database, Authentication, Realtime subscriptions, Storage, and Edge Functions. [[↗](https://github.com/supabase/supabase)] | `supabase.<yourdomain>.com` | - |
| [**Airbyte**](../services/data-services/airbyte) <br> [`airbyte`] | Advanced data integration platform capable of syncing data from over 600 sources (Google Ads, Meta, TikTok, GA4) to data warehouses. Ideal for use with Metabase. [[↗](https://github.com/airbytehq/airbyte)] | `airbyte.<yourdomain>.com` | - |
| [**MySQL Database**](../services/data-services/mysql) <br> [`mysql`] | Shared MySQL database instance powering services like Leantime and Mautic. [[↗](https://hub.docker.com/_/mysql)] | internal: tcp://mysql:3306 | - |
| [**Neo4j**](../services/data-services/neo4j) <br> [`neo4j`] | High-performance graph database optimized for knowledge graphs, relationship mapping, and fraud detection. [[↗](https://github.com/neo4j/neo4j)] | `neo4j.<yourdomain>.com` | - |
| [**PostgreSQL Database**](../services/data-services/postgres) <br> [`postgres`] | Shared PostgreSQL database instance serving as the backend for n8n, Flowise, and other data-intensive applications. [[↗](https://hub.docker.com/_/postgres)] | internal: tcp://postgres:5432 | - |
| [**Qdrant**](../services/data-services/qdrant) <br> [`qdrant`] | High-performance vector database optimized for semantic search, recommendation engines, and RAG storage. [[↗](https://github.com/qdrant/qdrant)] | `qdrant.<yourdomain>.com` | - |
| [**Redis Cache**](../services/data-services/redis) <br> [`redis`] | Shared Redis instance providing caching and message brokering for services like n8n. [[↗](https://hub.docker.com/_/redis)] | internal: tcp://redis:6379 | - |
| [**Weaviate**](../services/data-services/weaviate) <br> [`weaviate`] | Cloud-native vector database with API key authentication, supporting hybrid search, multi-modal data, and GraphQL APIs. [[↗](https://github.com/weaviate/weaviate)] | `weaviate.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## ⚙️ System Management
Monitoring, logging, and infrastructure tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Kopia**](../services/system-management/kopia) <br> [`kopia`] | Fast and secure backup solution supporting deduction, encryption, and compression with Cloud and WebDAV storage backends. [[↗](https://github.com/kopia/kopia)] | `backup.<yourdomain>.com` | postgres, redis |
| [**Monitoring Suite**](../services/system-management/monitoring) <br> [`monitoring`] | Comprehensive monitoring stack (Prometheus, Grafana, cAdvisor, Node-Exporter) for system performance tracking, dashboards, and alerting. [[↗](https://github.com/grafana/grafana)] | `grafana.<yourdomain>.com` | - |
| [**Portainer**](../services/system-management/portainer) <br> [`portainer`] | User-friendly web interface for managing Docker environments, containers, logs, and service deployments. [[↗](https://github.com/portainer/portainer)] | `portainer.<yourdomain>.com` | - |
| [**Uptime Kuma**](../services/system-management/uptime-kuma) <br> [`uptime-kuma`] | Self-hosted monitoring tool for tracking service uptime in real-time, featuring status pages and multi-protocol notifications. [[↗](https://github.com/louislam/uptime-kuma)] | `status.<yourdomain>.com` | - |
| [**Watchtower**](../services/system-management/watchtower) <br> [`watchtower`] | Utility for automating Docker container base image updates, ensuring services are always running the latest versions. [[↗](https://containrrr.dev/watchtower/)] | Internal | - |

[Back to Top](#table-of-contents)

## 🛡️ Security & Compliance
Security auditing and compliance tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**AI Security Suite - LLM Guard + Presidio**](../services/security-compliance/ai-security) <br> [`ai-security`] | Comprehensive AI security suite combining LLM Guard and Presidio for AI safety and GDPR-compliance, preventing prompt injections, filtering toxicity, and removing PII. [[↗](https://github.com/protectai/llm-guard)] | internal: http://llm-guard:8000 | - |
| [**Vaultwarden**](../services/security-compliance/vaultwarden) <br> [`vaultwarden`] | Lightweight, self-hosted password manager compatible with Bitwarden clients, enabling secure credential management and team sharing. [[↗](https://github.com/dani-garcia/vaultwarden)] | `vault.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🐍 Code Runners
Code execution environments

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Python Runner**](../services/code-runners/python-runner) <br> [`python-runner`] | Execution environment for running custom Python scripts and workflows, designed to integrate seamlessly with n8n. [[↗](https://github.com/n8n-io/n8n)] | Internal | - |

[Back to Top](#table-of-contents)

## 🖥️ Host Services
Core host-level services

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Private DNS**](../services/host-services/private-dns) <br> [`private-dns`] | CoreDNS instance providing private DNS resolution for internal services and mail server routing. [[↗](https://github.com/coredns/coredns)] | N/A | - |
| [**SSH Tunnel**](../services/host-services/ssh-tunnel) <br> [`ssh-tunnel`] | Cloudflare Tunnel configuration enabling secure remote SSH access via Cloudflare Zero Trust. [[↗](https://github.com/cloudflare/cloudflared)] | `ssh.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🌐 Gateways & Proxies
Gateways, proxies and tunnels

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Caddy Reverse Proxy**](../services/gateways-proxies/caddy) <br> [`caddy`] | Advanced Reverse Proxy and Web Server providing automatic SSL termination and routing for all hosted services. [[↗](https://caddyserver.com/)] | internal: http://caddy:80 | - |
| [**Cloudflare Web Tunnel**](../services/gateways-proxies/web-tunnel) <br> [`web-tunnel`] | Cloudflare Tunnel configuration for securely exposing local web services to the internet without opening public ports. [[↗](https://github.com/cloudflare/cloudflared)] | N/A | - |
| [**FastMCP Gateway**](../services/gateways-proxies/fastmcp) <br> [`fastmcp`] | A unified MCP (Model Context Protocol) server that proxies and aggregates multiple MCP servers | Internal | - |

[Back to Top](#table-of-contents)

## 🏠 Local AI Services
Locally hosted AI models and inference servers

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Ollama**](../services/local-ai/ollama) <br> [`ollama`] | Local Large Language Model (LLM) runner enabling the execution of models like Llama, Mistral, and Phi locally with an API-compatible interface. [[↗](https://github.com/ollama/ollama)] | `ollama.<yourdomain>.com` | - |
| [**ComfyUI**](../services/local-ai/comfyui) <br> [`comfyui`] | Node-based user interface for Stable Diffusion, enabling complex image generation workflows, AI art creation, and photo editing. [[↗](https://github.com/comfyanonymous/ComfyUI)] | `comfyui.<yourdomain>.com` | - |
| [**OCR Bundle**](../services/local-ai/ocr) <br> [`ocr`] | OCR bundle combining Tesseract and EasyOCR to reliably extract text from images and PDF documents. | internal: http://tesseract-ocr:8884 | - |

[Back to Top](#table-of-contents)

## 📁 File & Document Management
Storage, organization, and document processing

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**DocuSeal**](../services/file-document-management/docuseal) <br> [`docuseal`] | Open-source e-signature platform serving as a DocuSign alternative for document signing and managing contract workflows. [[↗](https://github.com/docusealco/docuseal)] | `sign.<yourdomain>.com` | - |
| [**Gotenberg**](../services/file-document-management/gotenberg) <br> [`gotenberg`] | Powerful document conversion API for converting HTML, Markdown, and Office documents to PDF, as well as merging PDF files. [[↗](https://github.com/gotenberg/gotenberg)] | internal: http://gotenberg:3000 | - |
| [**Outline**](../services/file-document-management/outline) <br> [`outline`] | Team knowledge base and documentation platform serving as a Notion alternative with a modern, real-time editor. [[↗](https://github.com/outline/outline)] | `outline.<yourdomain>.com` | - |
| [**Paperless AI Suite**](../services/file-document-management/paperless-ai) <br> [`paperless-ai`] | Advanced document management suite enhanced with AI, enabling superior OCR, RAG-based Chat, and natural language queries for document Q&A. [[↗](https://github.com/clusterzx/paperless-ai)] | `paperless-ai.<yourdomain>.com` | paperless |
| [**Paperless**](../services/file-document-management/paperless) <br> [`paperless`] | Community-supported document management system featuring OCR, AI-powered auto-tagging, full-text search, and GDPR compliance tools. [[↗](https://github.com/paperless-ngx/paperless-ngx)] | `docs.<yourdomain>.com` | - |
| [**Seafile**](../services/file-document-management/seafile) <br> [`seafile`] | Enterprise-grade file synchronization and sharing platform (Dropbox/Google Drive alternative) featuring file versioning, WebDAV support, and mobile sync. [[↗](https://github.com/haiwen/seafile)] | `files.<yourdomain>.com` | - |
| [**Stirling-PDF**](../services/file-document-management/stirling-pdf) <br> [`stirling-pdf`] | Comprehensive PDF manipulation tool offering over 100 features including merging, splitting, compressing, OCR, and signing documents. [[↗](https://github.com/Stirling-Tools/Stirling-PDF)] | `pdf.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## ✨ Custom Services
User-defined custom services

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Example Service**](../services/custom-services/example-service) <br> [`example-service`] | Example Service (Custom Repo Hosting Template) | Internal | - |

[Back to Top](#table-of-contents)

