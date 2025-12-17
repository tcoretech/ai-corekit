#!/bin/bash
# Report for opennotebook

echo
echo "======================= Open Notebook =============================="
echo
echo "🧠 AI-Powered Knowledge Management & Research Platform"
echo "Privacy-First Alternative to Google NotebookLM"
echo
echo "Host: ${OPENNOTEBOOK_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${OPENNOTEBOOK_HOSTNAME:-<hostname_not_set>}"
echo "  Internal API: http://opennotebook:5055 (n8n workflows only)"
echo
echo "Authentication:"
echo "  Password: ${OPENNOTEBOOK_PASSWORD:-<not_set_in_env>}"
echo "  Note: Native Open Notebook password - enter on first visit"
echo
echo "n8n Integration (REST API):"
echo "  Base URL: http://opennotebook:5055"
echo "  API Docs: http://opennotebook:5055/docs (Swagger UI)"
echo "  No auth required for internal Docker network"
echo
echo "  Example endpoints:"
echo "    GET  /api/notebooks - List all notebooks"
echo "    POST /api/notebooks - Create notebook"
echo "    POST /api/sources - Upload research content"
echo "    POST /api/chat - Chat with AI about your content"
echo
echo "Data Storage:"
echo "  Notebooks: ./opennotebook/notebook_data"
echo "  Database: ./opennotebook/surreal_data (embedded SurrealDB)"
echo "  Shared: ./shared (for file exchange with other services)"
echo
echo "AI Configuration:"
echo "  Using shared API keys: OPENAI_API_KEY, ANTHROPIC_API_KEY, GROQ_API_KEY"
echo "  Configure models in Settings → Models (Web UI)"
echo "  Supports local models via Ollama: http://ollama:11434"
echo
echo "Documentation: https://www.open-notebook.ai"
echo "GitHub: https://github.com/lfnovo/open-notebook"
