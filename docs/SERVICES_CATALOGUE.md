# AI LaunchKit Services Catalogue

This document provides a complete catalogue of the **78+ self-hosted services** included in AI LaunchKit.

## Table of Contents

- [🔧 Workflow Automation](#🔧-workflow-automation)
- [🎯 User Interfaces](#🎯-user-interfaces)
- [📧 Mail System](#📧-mail-system)
- [📹 Video Conferencing](#📹-video-conferencing)
- [📁 File & Document Management](#📁-file---document-management)
- [💼 Business Productivity](#💼-business-productivity)
- [🎨 AI Content Generation](#🎨-ai-content-generation)
- [💻 AI-Powered Development](#💻-ai-powered-development)
- [🤖 AI Agents](#🤖-ai-agents)
- [📚 RAG Systems](#📚-rag-systems)
- [🎙️ Speech, Language & Text](#🎙️-speech--language---text)
- [🔍 Search & Web Data](#🔍-search---web-data)
- [🧠 Knowledge Graphs](#🧠-knowledge-graphs)
- [🗄️ Data Infrastructure](#🗄️-data-infrastructure)
- [⚙️ System Management](#⚙️-system-management)
- [🧰 AI Support Tools](#🧰-ai-support-tools)
- [🛡️ AI Security & Compliance](#🛡️-ai-security---compliance)
- [🐍 Python](#🐍-python)
- [🖥️ Host Services](#🖥️-host-services)

---

## 🔧 Workflow Automation
Orchestrate processes and integrate services

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**n8n**](../services/workflow-automation/n8n) [↗](https://github.com/n8n-io/n8n) <br> [`n8n`] | Extendable workflow automation tool for connecting apps, building API integrations, and orchestrating complex business processes. | `n8n.<yourdomain>.com` | postgres, redis |
| [**Gitea**](../services/workflow-automation/gitea) [↗](https://github.com/go-gitea/gitea) <br> [`gitea`] | Lightweight, self-hosted DevOps platform and Git service providing source code management, issue tracking, and CI/CD capabilities. | `git.<yourdomain>.com` | - |
| [**Webhook Tester + Hoppscotch**](../services/workflow-automation/webhook-testing) [↗](https://github.com/tarampampam/webhook-tester) <br> [`webhook-testing`] | Debugging suite combining Webhook Tester and Hoppscotch for inspecting incoming webhooks and testing external service integrations. | `webhook-test.<yourdomain>.com` | mailpit |
| [**n8n-MCP**](../services/workflow-automation/n8n-mcp) [↗](https://github.com/czlonkowski/n8n-mcp) <br> [`n8n-mcp`] | Model Context Protocol (MCP) server for n8n, enabling AI assistants like Claude or Cursor to generate and validate n8n workflows. | `n8nmcp.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🎯 User Interfaces
Front-end interfaces and dashboards

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Homepage**](../services/user-interfaces/homepage) [↗](https://github.com/gethomepage/homepage) <br> [`homepage`] | Modern, customizable dashboard providing a centralized overview and quick access to all hosted services and Docker integrations. | `dashboard.<yourdomain>.com` | - |
| [**Landing Page**](../services/user-interfaces/landing-page) <br> [`landing-page`] | Static landing page serving as the main entry point and navigation hub for the deployed infrastructure. | `<yourdomain>.com` | - |
| [**Open WebUI**](../services/user-interfaces/open-webui) [↗](https://github.com/open-webui/open-webui) <br> [`open-webui`] | Feature-rich, self-hosted web interface (ChatGPT alternative) for interacting with local Large Language Models. | `webui.<yourdomain>.com` | - |
| [**Postiz**](../services/user-interfaces/postiz) [↗](https://github.com/gitroomhq/postiz-app) <br> [`postiz`] | Open-source social media scheduling and publishing platform with analytics and multi-account support. | `postiz.<yourdomain>.com` | postgres, redis |

[Back to Top](#table-of-contents)

## 📧 Mail System
Email sending, receiving, and management

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Docker Mailserver**](../services/mail-system/mailserver) [↗](https://github.com/docker-mailserver/docker-mailserver) <br> [`mailserver`] | Full-stack mail server (Docker-Mailserver) with Mailgun ingest support for sending and receiving real emails. | `mail.<yourdomain>.com` | caddy |
| [**Mail Ingest**](../services/mail-system/mail-ingest) <br> [`mail-ingest`] | Webhook forwarder that ingests incoming emails from Mailgun and routes them to the local docker-mailserver. | `mail-ingest.<yourdomain>.com` | mailserver |
| [**Mailpit**](../services/mail-system/mailpit) [↗](https://github.com/axllent/mailpit) <br> [`mailpit`] | Development email capture tool with a web UI for testing and debugging SMTP flows without sending real emails. | `mailpit.<yourdomain>.com` | - |
| [**SMTP Relay**](../services/mail-system/smtp-relay) [↗](https://github.com/docker-mailserver/docker-mailserver) <br> [`smtp-relay`] | Dedicated SMTP relay service for handling outbound transactional email delivery and forwarding. | internal: smtp://mailserver:25 | - |
| [**SnappyMail**](../services/mail-system/snappymail) [↗](https://github.com/the-djmaze/snappymail) <br> [`snappymail`] | Modern, lightweight webmail client interface for Docker-Mailserver. | `webmail.<yourdomain>.com` | mailserver |

[Back to Top](#table-of-contents)

## 📹 Video Conferencing
Real-time video and audio communication

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Jitsi Meet**](../services/video-conferencing/jitsi) [↗](https://github.com/jitsi/jitsi-meet) <br> [`jitsi`] | Secure, open-source video conferencing platform supporting screen sharing, team calls, and webinar hosting (Requires UDP port 10000). | `meet.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 📁 File & Document Management
Storage, organization, and document processing

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Paperless AI Suite**](../services/file-document-management/paperless-ai) [↗](https://github.com/clusterzx/paperless-ai) <br> [`paperless-ai`] | Advanced document management suite enhanced with AI, enabling superior OCR, RAG-based Chat, and natural language queries for document Q&A. | `paperless-ai.<yourdomain>.com` | paperless |
| [**Paperless**](../services/file-document-management/paperless) [↗](https://github.com/paperless-ngx/paperless-ngx) <br> [`paperless`] | Community-supported document management system featuring OCR, AI-powered auto-tagging, full-text search, and GDPR compliance tools. | `docs.<yourdomain>.com` | - |
| [**Seafile**](../services/file-document-management/seafile) [↗](https://github.com/haiwen/seafile) <br> [`seafile`] | Enterprise-grade file synchronization and sharing platform (Dropbox/Google Drive alternative) featuring file versioning, WebDAV support, and mobile sync. | `files.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 💼 Business Productivity
Tools for business operations and management

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Airbyte**](../services/business-productivity/airbyte) [↗](https://github.com/airbytehq/airbyte) <br> [`airbyte`] | Advanced data integration platform capable of syncing data from over 600 sources (Google Ads, Meta, TikTok, GA4) to data warehouses. Ideal for use with Metabase. | `airbyte.<yourdomain>.com` | - |
| [**Baserow**](../services/business-productivity/baserow) [↗](https://github.com/bram2w/baserow) <br> [`baserow`] | Open-source no-code database and Airtable alternative for database management, project tracking, and building collaborative workflows. | `baserow.<yourdomain>.com` | postgres, redis |
| [**Cal.com**](../services/business-productivity/calcom) [↗](https://github.com/calcom/cal.com) <br> [`calcom`] | Open-source scheduling platform streamlining meeting bookings, team calendars, and payment integrations. | `cal.<yourdomain>.com` | postgres, redis |
| [**EspoCRM**](../services/business-productivity/espocrm) [↗](https://github.com/espocrm/espocrm) <br> [`espocrm`] | Full-featured Customer Relationship Management (CRM) system offering email campaigns, workflow automation, advanced reporting, and role-based access. | `espocrm.<yourdomain>.com` | - |
| [**Formbricks**](../services/business-productivity/formbricks) [↗](https://github.com/formbricks/formbricks) <br> [`formbricks`] | Privacy-first survey and form builder serving as a GDPR-compliant Typeform alternative for customer feedback, NPS surveys, and market research. | `forms.<yourdomain>.com` | postgres, redis |
| [**Invoice Ninja**](../services/business-productivity/invoiceninja) [↗](https://github.com/invoiceninja/invoiceninja) <br> [`invoiceninja`] | Professional invoicing platform supporting multi-currency invoices, recurring billing, client portals, and over 40 payment gateways. | `invoices.<yourdomain>.com` | redis |
| [**Kimai**](../services/business-productivity/kimai) [↗](https://github.com/kimai/kimai) <br> [`kimai`] | Professional, DSGVO-compliant time tracking software featuring team timesheets, invoicing, 2FA security, and API access. | `time.<yourdomain>.com` | - |
| [**Leantime**](../services/business-productivity/leantime) [↗](https://github.com/Leantime/leantime) <br> [`leantime`] | ADHD-friendly project management suite comparable to Asana or Monday, featuring time tracking, sprint planning, and strategy tools. | `leantime.<yourdomain>.com` | mysql |
| [**Mautic**](../services/business-productivity/mautic) [↗](https://github.com/mautic/mautic) <br> [`mautic`] | Open-source marketing automation platform for lead scoring, email campaigns, landing pages, and multi-channel marketing workflows. | `mautic.<yourdomain>.com` | - |
| [**Metabase**](../services/business-productivity/metabase) [↗](https://github.com/metabase/metabase) <br> [`metabase`] | Business intelligence platform enabling no-code dashboards, automated reports, data exploration, and team analytics. | `analytics.<yourdomain>.com` | - |
| [**NocoDB**](../services/business-productivity/nocodb) [↗](https://github.com/nocodb/nocodb) <br> [`nocodb`] | Open-source Airtable alternative featuring a smart spreadsheet UI for real-time collaboration and automation. | `nocodb.<yourdomain>.com` | postgres, redis |
| [**Odoo**](../services/business-productivity/odoo) [↗](https://github.com/odoo/odoo) <br> [`odoo`] | Comprehensive ERP and CRM suite with AI features for sales automation, inventory management, accounting, and lead scoring. | `odoo.<yourdomain>.com` | postgres |
| [**Outline**](../services/business-productivity/outline) [↗](https://github.com/outline/outline) <br> [`outline`] | Team knowledge base and documentation platform serving as a Notion alternative with a modern, real-time editor. | `outline.<yourdomain>.com` | - |
| [**Twenty CRM**](../services/business-productivity/twenty-crm) [↗](https://github.com/twentyhq/twenty) <br> [`twenty-crm`] | Modern, open-source CRM with a Notion-like interface, featuring customer pipelines, GraphQL API, and tools for startups. | `twenty.<yourdomain>.com` | - |
| [**Vikunja**](../services/business-productivity/vikunja) [↗](https://github.com/go-vikunja/vikunja) <br> [`vikunja`] | Modern task management platform and Todoist alternative offering Kanban boards, Gantt charts, CalDAV sync, and team collaboration. | `vikunja.<yourdomain>.com` | postgres, redis |

[Back to Top](#table-of-contents)

## 🎨 AI Content Generation
Generate images, text, and other media

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**ComfyUI**](../services/ai-content-generation/comfyui) [↗](https://github.com/comfyanonymous/ComfyUI) <br> [`comfyui`] | Node-based user interface for Stable Diffusion, enabling complex image generation workflows, AI art creation, and photo editing. | `comfyui.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 💻 AI-Powered Development
Coding assistance and development tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**bolt.diy**](../services/ai-powered-development/bolt) [↗](https://github.com/stackblitz-labs/bolt.diy) <br> [`bolt`] | AI-powered web development tool for rapid prototyping, creating MVPs, and assisting in learning to code. | `bolt.<yourdomain>.com` | - |
| [**OpenUI**](../services/ai-powered-development/openui) [↗](https://github.com/wandb/openui) <br> [`openui`] | Experimental AI frontend and UI generator for creating design systems, component libraries, and mockups. | `openui.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🤖 AI Agents
Autonomous agents and assistants

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Langfuse**](../services/ai-agents/langfuse) <br> [`langfuse`] | AI observability platform including Clickhouse and Minio, specialized for DSGVO compliance, German text processing, and entity recognition. | internal: http://langfuse-web:3000 | - |
| [**Browser Automation Suite**](../services/ai-agents/browser-suite) [↗](https://github.com/browser-use/browser-use) <br> [`browser-suite`] | Comprehensive browser automation suite combining Browserless, Skyvern, and Browser-use for web scraping, form filling, and automated testing. | internal: http://browserless:3000 | - |
| [**Dify**](../services/ai-agents/dify) [↗](https://github.com/langgenius/dify) <br> [`dify`] | LLM application development platform designed for building AI agents, chatbots, and automating workflows. | `dify.<yourdomain>.com` | - |
| [**Flowise**](../services/ai-agents/flowise) [↗](https://github.com/FlowiseAI/Flowise) <br> [`flowise`] | Drag-and-drop AI agent builder for creating chatbots, customer support assistants, and complex AI workflows. | `flowise.<yourdomain>.com` | - |
| [**Letta**](../services/ai-agents/letta) [↗](https://github.com/letta-ai/letta) <br> [`letta`] | Agent Server and SDK enabling the creation of persistent AI assistants with advanced memory management capabilities. | `letta.<yourdomain>.com` | - |
| [**LiveKit**](../services/ai-agents/livekit) [↗](https://github.com/livekit/livekit) <br> [`livekit`] | Real-time voice/video WebRTC infrastructure for building AI voice assistants and conversational AI bots. Requires UDP ports 50000-50100. | `livekit.<yourdomain>.com` | redis |
| [**Vexa**](../services/ai-agents/vexa) [↗](https://github.com/Vexa-ai/vexa) <br> [`vexa`] | Real-time meeting transcription API supporting 99 languages, offering live transcription for Google Meet & Teams with speaker identification. | internal: http://api-gateway:8000 | - |

[Back to Top](#table-of-contents)

## 📚 RAG Systems
Retrieval-Augmented Generation systems

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Qdrant**](../services/rag-systems/qdrant) [↗](https://github.com/qdrant/qdrant) <br> [`qdrant`] | High-performance vector database optimized for semantic search, recommendation engines, and RAG storage. | `qdrant.<yourdomain>.com` | - |
| [**RAGApp**](../services/rag-systems/ragapp) [↗](https://github.com/ragapp/ragapp) <br> [`ragapp`] | Open-source UI and API for Retrieval-Augmented Generation (RAG), enabling easy creation of knowledge bases and document Q&A tools. | `ragapp.<yourdomain>.com` | - |
| [**Weaviate**](../services/rag-systems/weaviate) [↗](https://github.com/weaviate/weaviate) <br> [`weaviate`] | Cloud-native vector database with API key authentication, supporting hybrid search, multi-modal data, and GraphQL APIs. | `weaviate.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🎙️ Speech, Language & Text
Speech recognition and text processing

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**LibreTranslate**](../services/speech-language-text/libretranslate) [↗](https://github.com/LibreTranslate/LibreTranslate) <br> [`libretranslate`] | Self-hosted, privacy-focused translation API supporting over 50 languages for text and document translation. | `translate.<yourdomain>.com` | - |
| [**OCR Bundle**](../services/speech-language-text/ocr) <br> [`ocr`] | OCR bundle combining Tesseract and EasyOCR to reliably extract text from images and PDF documents. | internal: http://tesseract-ocr:8884 | - |
| [**Scriberr**](../services/speech-language-text/scriberr) [↗](https://github.com/rishikanthc/Scriberr) <br> [`scriberr`] | AI-powered audio transcription tool featuring speaker diarization, ideal for creating meeting transcripts, processing podcasts, and analyzing call recordings. | `scriberr.<yourdomain>.com` | - |
| [**Speech Stack**](../services/speech-language-text/speech) [↗](https://github.com/matatonic/openedai-speech) <br> [`speech`] | CPU-optimized speech stack combining Whisper ASR and OpenedAI TTS, suitable for building voice assistants, generating audiobooks, and audio notifications. | internal: http://openedai-speech:8000 | - |
| [**TTS Chatterbox**](../services/speech-language-text/tts-chatterbox) [↗](https://github.com/resemble-ai/chatterbox) <br> [`tts-chatterbox`] | State-of-the-art Text-to-Speech system serving as a high-quality alternative to ElevenLabs, providing AI voices with rich emotional expression. | `chatterbox.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🔍 Search & Web Data
Search engines and data scraping

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Crawl4ai**](../services/search-web-data/crawl4ai) [↗](https://github.com/unclecode/crawl4ai) <br> [`crawl4ai`] | AI-optimized web crawler designed for efficient web scraping, data extraction, and site monitoring. | Internal | - |
| [**GPT Researcher**](../services/search-web-data/gpt-researcher) [↗](https://github.com/assafelovic/gpt-researcher) <br> [`gpt-researcher`] | Autonomous research agent capable of generating comprehensive 2000+ word reports with citations from multiple sources. | `research.<yourdomain>.com` | searxng |
| [**Local Deep Research**](../services/search-web-data/local-deep-research) [↗](https://github.com/langchain-ai/local-deep-researcher) <br> [`local-deep-research`] | LangChain-based iterative research agent capable of fact-checking and detailed analysis with high accuracy. | internal: http://local-deep-research:2024 | searxng |
| [**Open Notebook**](../services/search-web-data/opennotebook) [↗](https://github.com/lfnovo/open-notebook) <br> [`opennotebook`] | AI-powered knowledge management tool (NotebookLM alternative) supporting multi-modal content, podcast generation, and 16+ AI models. | `notebook.<yourdomain>.com` | - |
| [**Perplexica**](../services/search-web-data/perplexica) [↗](https://github.com/ItzCrazyKns/Perplexica) <br> [`perplexica`] | Open-source AI search engine and Deep Research tool, serving as a privacy-focused alternative to Perplexity AI. | `perplexica.<yourdomain>.com` | searxng |
| [**SearXNG**](../services/search-web-data/searxng) [↗](https://github.com/searxng/searxng) <br> [`searxng`] | Privacy-respecting metasearch engine allowing search queries across multiple sources without tracking, ideal for AI agents. | `searxng.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🧠 Knowledge Graphs
Structure and query complex data relationships

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**LightRAG**](../services/knowledge-graphs/lightrag) [↗](https://github.com/HKUDS/LightRAG) <br> [`lightrag`] | Graph-based Retrieval-Augmented Generation (RAG) system specializing in entity extraction and automatic knowledge graph creation. | `lightrag.<yourdomain>.com` | - |
| [**Neo4j**](../services/knowledge-graphs/neo4j) [↗](https://github.com/neo4j/neo4j) <br> [`neo4j`] | High-performance graph database optimized for knowledge graphs, relationship mapping, and fraud detection. | `neo4j.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🗄️ Data Infrastructure
Databases and data management systems

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Supabase**](../services/data-infrastructure/supabase) [↗](https://github.com/supabase/supabase) <br> [`supabase`] | Open-source Backend-as-a-Service (BaaS) providing Database, Authentication, Realtime subscriptions, Storage, and Edge Functions. | `supabase.<yourdomain>.com` | - |
| [**MySQL Database**](../services/data-infrastructure/mysql) [↗](https://hub.docker.com/_/mysql) <br> [`mysql`] | Shared MySQL database instance powering services like Leantime and Mautic. | internal: tcp://mysql:3306 | - |
| [**PostgreSQL Database**](../services/data-infrastructure/postgres) [↗](https://hub.docker.com/_/postgres) <br> [`postgres`] | Shared PostgreSQL database instance serving as the backend for n8n, Flowise, and other data-intensive applications. | internal: tcp://postgres:5432 | - |
| [**Redis Cache**](../services/data-infrastructure/redis) [↗](https://hub.docker.com/_/redis) <br> [`redis`] | Shared Redis instance providing caching and message brokering for services like n8n. | internal: tcp://redis:6379 | - |

[Back to Top](#table-of-contents)

## ⚙️ System Management
Monitoring, logging, and infrastructure tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Caddy Reverse Proxy**](../services/system-management/caddy) [↗](https://caddyserver.com/) <br> [`caddy`] | Advanced Reverse Proxy and Web Server providing automatic SSL termination and routing for all hosted services. | internal: http://caddy:80 | - |
| [**Cloudflare Web Tunnel**](../services/system-management/web-tunnel) [↗](https://github.com/cloudflare/cloudflared) <br> [`web-tunnel`] | Cloudflare Tunnel configuration for securely exposing local web services to the internet without opening public ports. | N/A | - |
| [**Kopia**](../services/system-management/kopia) [↗](https://github.com/kopia/kopia) <br> [`kopia`] | Fast and secure backup solution supporting deduction, encryption, and compression with Cloud and WebDAV storage backends. | `backup.<yourdomain>.com` | postgres, redis |
| [**Monitoring Suite**](../services/system-management/monitoring) [↗](https://github.com/grafana/grafana) <br> [`monitoring`] | Comprehensive monitoring stack (Prometheus, Grafana, cAdvisor, Node-Exporter) for system performance tracking, dashboards, and alerting. | `grafana.<yourdomain>.com` | - |
| [**Portainer**](../services/system-management/portainer) [↗](https://github.com/portainer/portainer) <br> [`portainer`] | User-friendly web interface for managing Docker environments, containers, logs, and service deployments. | `portainer.<yourdomain>.com` | - |
| [**Uptime Kuma**](../services/system-management/uptime-kuma) [↗](https://github.com/louislam/uptime-kuma) <br> [`uptime-kuma`] | Self-hosted monitoring tool for tracking service uptime in real-time, featuring status pages and multi-protocol notifications. | `status.<yourdomain>.com` | - |
| [**Vaultwarden**](../services/system-management/vaultwarden) [↗](https://github.com/dani-garcia/vaultwarden) <br> [`vaultwarden`] | Lightweight, self-hosted password manager compatible with Bitwarden clients, enabling secure credential management and team sharing. | `vault.<yourdomain>.com` | - |
| [**Watchtower**](../services/system-management/watchtower) [↗](https://containrrr.dev/watchtower/) <br> [`watchtower`] | Utility for automating Docker container base image updates, ensuring services are always running the latest versions. | Internal | - |

[Back to Top](#table-of-contents)

## 🧰 AI Support Tools
Utilities and supporting services for AI

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**DocuSeal**](../services/ai-support-tools/docuseal) [↗](https://github.com/docusealco/docuseal) <br> [`docuseal`] | Open-source e-signature platform serving as a DocuSign alternative for document signing and managing contract workflows. | `sign.<yourdomain>.com` | - |
| [**Gotenberg**](../services/ai-support-tools/gotenberg) [↗](https://github.com/gotenberg/gotenberg) <br> [`gotenberg`] | Powerful document conversion API for converting HTML, Markdown, and Office documents to PDF, as well as merging PDF files. | internal: http://gotenberg:3000 | - |
| [**Ollama**](../services/ai-support-tools/ollama) [↗](https://github.com/ollama/ollama) <br> [`ollama`] | Local Large Language Model (LLM) runner enabling the execution of models like Llama, Mistral, and Phi locally with an API-compatible interface. | `ollama.<yourdomain>.com` | - |
| [**Stirling-PDF**](../services/ai-support-tools/stirling-pdf) [↗](https://github.com/Stirling-Tools/Stirling-PDF) <br> [`stirling-pdf`] | Comprehensive PDF manipulation tool offering over 100 features including merging, splitting, compressing, OCR, and signing documents. | `pdf.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

## 🛡️ AI Security & Compliance
Security auditing and compliance tools

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**AI Security Suite - LLM Guard + Presidio**](../services/ai-security-compliance/ai-security) [↗](https://github.com/protectai/llm-guard) <br> [`ai-security`] | Comprehensive AI security suite combining LLM Guard and Presidio for AI safety and GDPR-compliance, preventing prompt injections, filtering toxicity, and removing PII. | internal: http://llm-guard:8000 | - |

[Back to Top](#table-of-contents)

## 🐍 Python
Python environments and script runners

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Python Runner**](../services/python/python-runner) [↗](https://github.com/n8n-io/n8n) <br> [`python-runner`] | Execution environment for running custom Python scripts and workflows, designed to integrate seamlessly with n8n. | Internal | - |

[Back to Top](#table-of-contents)

## 🖥️ Host Services
Core host-level services

| Service | Description | Interface | Dependencies |
|---------|-------------|-----------|--------------|
| [**Private DNS**](../services/host-services/private-dns) [↗](https://github.com/coredns/coredns) <br> [`private-dns`] | CoreDNS instance providing private DNS resolution for internal services and mail server routing. | N/A | - |
| [**SSH Tunnel**](../services/host-services/ssh-tunnel) [↗](https://github.com/cloudflare/cloudflared) <br> [`ssh-tunnel`] | Cloudflare Tunnel configuration enabling secure remote SSH access via Cloudflare Zero Trust. | `ssh.<yourdomain>.com` | - |

[Back to Top](#table-of-contents)

