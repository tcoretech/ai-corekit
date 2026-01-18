#!/bin/bash
# Report for paperless-ai

echo
echo "==================== Paperless AI Extensions ========================"
echo
echo "⚠️  CRITICAL SETUP REQUIRED - FOLLOW THESE STEPS CAREFULLY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📝 STEP 1: Create API Token in Paperless-ngx (REQUIRED)"
echo "────────────────────────────────────────────────────────────────"
echo "  1. Open Paperless-ngx: https://${PAPERLESS_HOSTNAME}"
echo "  2. Login with: ${PAPERLESS_ADMIN_EMAIL} / ${PAPERLESS_ADMIN_PASSWORD}"
echo "  3. Go to Settings → Open Django Admin Panel"
echo "  4. Click on 'Auth tokens' → 'Add'"
echo "  5. Select your user and save"
echo "  6. Click the pencil icon to edit the token"
echo "  7. In the popup under 'Permissions' click 'Choose all permissions'"
echo "  8. Save and copy the token"
echo
echo "📝 STEP 2: Configure paperless-gpt"
echo "────────────────────────────────────────────────────────────────"
echo "  1. Add token to .env:"
echo "     nano .env"
echo "     Find: PAPERLESS_API_TOKEN="
echo "     Paste your token after ="
echo
echo "  2. Restart paperless-gpt:"
echo "     corekit restart paperless-gpt"
echo
echo "  3. Access: https://${PAPERLESS_GPT_HOSTNAME}"
echo "     Login: ${PAPERLESS_GPT_USERNAME} / ${PAPERLESS_GPT_PASSWORD}"
echo
echo "  ⚠️  KNOWN BUG: Documents need at least ONE tag for updates to work!"
echo "     Workaround: Add a tag like 'inbox' to all documents"
echo
echo "📝 STEP 3: Configure paperless-ai"
echo "────────────────────────────────────────────────────────────────"
echo "  1. Access: https://${PAPERLESS_AI_HOSTNAME}"
echo "  2. On first visit: Create your own username/password"
echo "  3. Enter configuration:"
echo "     - Paperless URL: http://paperless-ngx:8000"
echo "     - API Token: (paste the token from Step 1)"
echo "     - Ollama URL: http://ollama:11434"
echo
echo "📝 STEP 4: Fix RAG Chat (REQUIRED for paperless-ai)"
echo "────────────────────────────────────────────────────────────────"
echo "  Run this command to fix RAG indexing:"
echo
echo "  docker exec paperless-ai sh -c \"echo 'PAPERLESS_URL=http://paperless-ngx:8000' >> /app/data/.env\""
echo "  corekit restart paperless-ai"
echo
echo "  This fixes a bug where paperless-ai uses inconsistent ENV variables"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ After completing these steps:"
echo "  - paperless-gpt: Superior OCR at /manual and /ocr tabs"
echo "  - paperless-ai: RAG chat and semantic search working"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
