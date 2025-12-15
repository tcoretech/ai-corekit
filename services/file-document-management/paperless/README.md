# 🤖 Paperless AI Extensions - LLM-Powered OCR & RAG Chat

### What are Paperless AI Extensions?

The Paperless AI Extensions are two complementary tools that supercharge your Paperless-ngx installation with advanced AI capabilities:

- **paperless-gpt** - Superior OCR using Vision LLMs (GPT-4o, Claude, Ollama) for accurate text extraction from poor quality scans
- **paperless-ai** - RAG-powered chat interface for natural language document search and Q&A

Together, they transform Paperless-ngx from a document archive into an intelligent document assistant that can answer questions like "What was my electricity bill last month?" or "Show me all contracts expiring this year."

### ⚠️ CRITICAL Setup Requirements

**This suite requires manual configuration after installation. Follow these steps EXACTLY:**

#### Step 1: Generate API Token with Full Permissions
1. Open Paperless-ngx → Settings → Django Admin Panel
2. Click on "Auth tokens" → "Add"
3. Select your user and save
4. Click the pencil icon to edit the token
5. In the popup under "Permissions" click "Choose all permissions"
6. Save and copy the token

#### Step 2: Configure Environment
1. Add token to `.env` file:
```bash
   nano .env
   # Add/update: PAPERLESS_API_TOKEN=your_token_here
```

2. **CRITICAL: Full restart required for token to load:**
```bash
   docker compose -p localai down
   docker compose -p localai up -d
```
   ⚠️ Simple restart is NOT enough - must use `down` then `up -d`!

#### Step 3: Configure paperless-gpt
- Access: `https://paperless-gpt.yourdomain.com`
- Login with Basic Auth (username/password from .env)
- Should now connect successfully to Paperless

#### Step 4: Configure paperless-ai
1. Access: `https://paperless-ai.yourdomain.com`
2. First visit shows setup wizard
3. Create your own username/password (remember them!)
4. Enter configuration:
   - Paperless URL: `http://paperless-ngx:8000`
   - API Token: (paste the token from Step 1)
   - Ollama URL: `http://ollama:11434` (if using)

#### Step 5: Fix RAG Chat (REQUIRED)
```bash
# This fixes a bug where paperless-ai uses different ENV variable names
docker exec paperless-ai sh -c "echo 'PAPERLESS_URL=http://paperless-ngx:8000' >> /app/data/.env"
docker compose -p localai restart paperless-ai
```

### Known Issues & Workarounds

| Issue | Impact | Workaround |
|-------|---------|-----------|
| **paperless-gpt: Documents need tags** | Can't update documents without at least one tag | Add a default tag like "inbox" to all documents |
| **paperless-ai: Inconsistent ENV names** | RAG chat shows "your-paperless-instance" error | Apply Step 5 fix above |
| **Token not loading after update** | Services show "401 Unauthorized" | Use full restart with `docker compose -p localai down` then `up -d` |

### Features Comparison

| Feature | paperless-gpt | paperless-ai |
|---------|--------------|--------------|
| **LLM-based OCR** | ✅ GPT-4o, MiniCPM-V | ❌ |
| **Searchable PDFs** | ✅ With text layers | ❌ |
| **Auto-Tagging** | ✅ AI-powered | ✅ Rule-based |
| **RAG Chat** | ❌ | ✅ Main feature |
| **Semantic Search** | ❌ | ✅ "Find similar" |
| **Batch Processing** | ✅ Queue system | ❌ |
| **Multi-language** | ✅ Configurable | ✅ Auto-detect |
| **Authentication** | Basic Auth (Caddy) | Own system |

### Configuration Options

**Default (CPU-friendly, using OpenAI):**
```yaml
PAPERLESS_GPT_LLM_PROVIDER=openai
PAPERLESS_GPT_LLM_MODEL=gpt-4o-mini
PAPERLESS_GPT_VISION_MODEL=gpt-4o-mini
```

**Local Processing (using Ollama):**
```yaml
PAPERLESS_GPT_LLM_PROVIDER=ollama
PAPERLESS_GPT_LLM_MODEL=qwen2.5:7b
PAPERLESS_GPT_VISION_MODEL=minicpm-v
```

### Usage Examples

#### paperless-gpt OCR Processing
1. Tag document with `paperless-gpt` for manual processing
2. Tag with `paperless-gpt-ocr-auto` for automatic OCR
3. Access web UI at `/manual` to review and confirm
4. Check status at `/ocr` tab

#### paperless-ai Natural Language Search
- "Show me all invoices from last month"
- "What was my electricity bill in January?"
- "Find contracts expiring this year"
- "Which documents mention GDPR?"

### Troubleshooting

**Token Issues:**
```bash
# Verify token in .env
grep PAPERLESS_API_TOKEN .env

# Check if token loads in container
docker exec paperless-gpt env | grep PAPERLESS_API_TOKEN

# If missing, full restart required:
docker compose -p localai down
docker compose -p localai up -d
```

**RAG Not Working:**
```bash
# Check for "your-paperless-instance" error
docker logs paperless-ai | grep "your-paperless"

# Apply fix:
docker exec paperless-ai sh -c "echo 'PAPERLESS_URL=http://paperless-ngx:8000' >> /app/data/.env"
docker compose -p localai restart paperless-ai
```

**Reset paperless-ai (loses settings):**
```bash
docker compose -p localai stop paperless-ai
docker volume rm localai_paperless-ai-data
docker compose -p localai up -d paperless-ai
```

### Resources
- **RAM:** ~1GB additional for both services
- **Disk:** ~500MB for vector databases
- **API Costs:** ~$0.001 per page with GPT-4o-mini

### Documentation
- **paperless-gpt:** https://github.com/icereed/paperless-gpt
- **paperless-ai:** https://github.com/clusterzx/paperless-ai
- **Installation Guide:** See final report after running `bash scripts/06_final_report.sh`
