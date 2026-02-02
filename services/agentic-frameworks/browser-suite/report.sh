#!/bin/bash
# Report for browser-suite

echo
echo "==================== Browser Automation Suite ========================"
echo
echo "🌐 Browserless (Chrome Runtime):"
echo "  Internal WebSocket: ws://browserless:3000?token=${BROWSERLESS_TOKEN:-<not_set>}"
echo "  Concurrent Sessions: ${BROWSERLESS_CONCURRENT:-10}"
echo "  Timeout: ${BROWSERLESS_TIMEOUT:-120000}ms"
echo
echo "🤖 Skyvern (Vision AI):"
echo "  Internal API: http://skyvern:8000"
echo "  API Key: ${SKYVERN_API_KEY:-<not_set>}"
if [ "${ENABLE_OLLAMA}" = "true" ]; then
  echo "  Mode: LOCAL (Ollama)"
  echo "  Model: ${OLLAMA_MODEL:-qwen2.5:7b-instruct}"
else
  echo "  Mode: CLOUD (OpenAI)"
  echo "  API Key: ${OPENAI_API_KEY:-<not_set>}"
fi
echo
echo "🧠 Browser-use (LLM Control):"
echo "  Execute: docker exec browser-use python -c 'your_code'"
echo "  Script location: ./shared/*.py"
echo
echo "📦 n8n Community Nodes to install:"
echo "  - n8n-nodes-puppeteer (WebSocket: ws://browserless:3000)"
echo "  - n8n-nodes-browserless"
echo
echo "Example n8n usage:"
echo "  1. Install community nodes in n8n UI"
echo "  2. Use Puppeteer node with browserless WebSocket"
echo "  3. For Skyvern: HTTP Request to http://skyvern:8000/v1/execute"
echo
echo "Documentation:"
echo "  Browserless: https://docs.browserless.io"
echo "  Skyvern: https://docs.skyvern.com"
echo "  Browser-use: https://github.com/browser-use/browser-use"
