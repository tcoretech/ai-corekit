### What is Open Notebook?

Open Notebook is an open-source, privacy-first alternative to Google's NotebookLM that gives you complete control over your research and knowledge management. Unlike NotebookLM which locks you into Google's ecosystem and models, Open Notebook supports 16+ AI providers (OpenAI, Anthropic, Ollama, Google, Groq, Mistral, DeepSeek, xAI, and more), runs entirely on your infrastructure, and processes multi-modal content including PDFs, videos, audio files, web pages, and Office documents. It combines intelligent document processing, AI-powered chat, vector search, and professional podcast generation into a comprehensive research platform - perfect for research automation, content analysis, knowledge base building, and AI-enhanced note-taking.

### Features

- **Multi-Modal Content Processing** - Upload PDFs, videos, audio, web pages, YouTube links, Office docs
- **16+ AI Provider Support** - OpenAI, Anthropic, Ollama, Google, Groq, Mistral, DeepSeek, xAI, OpenRouter, LM Studio
- **Advanced Podcast Generation** - Create 1-4 speaker podcasts with custom profiles and Episode Profiles
- **Context-Aware Chat** - AI conversations powered by your research materials with citations
- **Smart Search** - Full-text and vector search across all content
- **Content Transformations** - Built-in and custom actions for summaries, insights, extractions
- **Multiple Notebooks** - Organize research by project or topic
- **Full REST API** - Complete programmatic access for n8n automation
- **Embedded Database** - SurrealDB included, no external dependencies
- **Privacy-First** - Your data never leaves your server

### Initial Setup

**First Access to Open Notebook:**

1. Navigate to `https://notebook.yourdomain.com`
2. Enter password when prompted (set in `.env` as `OPENNOTEBOOK_PASSWORD`)
3. Configure AI models in Settings → Models:
   - **Language Model:** For chat and content generation (e.g., gpt-4o-mini, claude-3.5-sonnet)
   - **Embedding Model:** For vector search (e.g., text-embedding-3-small, nomic-embed-text)
   - **Text-to-Speech:** For podcast generation (e.g., gpt-4o-mini-tts, eleven_turbo_v2_5)
   - **Speech-to-Text:** For audio transcription (e.g., whisper-1)
4. Create your first notebook
5. Add sources (drag & drop files or paste URLs)

**Using Local Models (Ollama):**

Open Notebook works seamlessly with your Ollama installation:
```bash
# Open Notebook is pre-configured to use Ollama at http://ollama:11434
# Just select Ollama models in Settings:

# Language Model: ollama/qwen2.5:7b-instruct-q4_K_M
# Embedding Model: nomic-embed-text
```

**Using Cloud Models:**

API keys are automatically shared from your `.env` file:
- `OPENAI_API_KEY` - For OpenAI models
- `ANTHROPIC_API_KEY` - For Claude models
- `GROQ_API_KEY` - For Groq models

### n8n Integration Setup

Open Notebook provides a comprehensive REST API for automation.

**Internal URL:** `http://opennotebook:5055`  
**API Documentation:** `http://opennotebook:5055/docs` (Swagger UI)

**Authentication:** Not required for internal Docker network (API port 5055 is not exposed externally)

**Key API Endpoints:**
```javascript
// Notebooks
GET    /api/notebooks           // List all notebooks
POST   /api/notebooks           // Create notebook
GET    /api/notebooks/{id}      // Get notebook details
DELETE /api/notebooks/{id}      // Delete notebook

// Sources (Documents)
GET    /api/sources              // List sources in notebook
POST   /api/sources              // Upload source/document
GET    /api/sources/{id}         // Get source details
DELETE /api/sources/{id}         // Delete source

// Chat
POST   /api/chat                 // Chat with AI about your content
GET    /api/chat/history/{id}    // Get chat history

// Notes
GET    /api/notes                // List notes
POST   /api/notes                // Create note (manual or AI-generated)

// Search
POST   /api/search               // Vector + full-text search

// Podcasts
POST   /api/podcasts             // Generate podcast from sources
GET    /api/podcasts/{id}        // Get podcast status/download
```

### Example Workflows

#### Example 1: Automated Research Document Processing
```javascript
// Process uploaded PDFs, generate summaries, and chat with content

// 1. Webhook Trigger
// Receives PDF upload notification
// Input: { "file_path": "/data/shared/research/paper.pdf", "project": "AI Research" }

// 2. HTTP Request - Create Notebook
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "{{ $json.project }} - {{ $now.format('YYYY-MM-DD') }}",
  "description": "Automated research notebook"
}
// Save notebook_id from response

// 3. HTTP Request - Upload PDF to Open Notebook
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "file_path": "{{ $('Webhook').json.file_path }}",
  "transformations": ["summary", "key_points", "entities"]
}
// Open Notebook processes PDF, extracts text, runs transformations

// 4. Wait Node (2 minutes)
// Allow time for processing and transformations

// 5. HTTP Request - Get Source Details
Method: GET
URL: http://opennotebook:5055/api/sources/{{ $('HTTP Request 1').json.source_id }}

// Response includes processed content and transformations:
{
  "id": "source_123",
  "title": "Research Paper Title",
  "content": "Full extracted text...",
  "transformations": {
    "summary": "This paper discusses...",
    "key_points": ["Point 1", "Point 2", ...],
    "entities": ["Entity1", "Entity2", ...]
  },
  "metadata": {
    "pages": 12,
    "word_count": 5432
  }
}

// 6. HTTP Request - Chat to Extract Specific Information
Method: POST
URL: http://opennotebook:5055/api/chat
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "message": "What are the main findings and methodology of this research?",
  "context_level": "full"  // Uses all sources in notebook
}

// 7. Code Node - Format Results
const summary = $('HTTP Request 2').json.transformations.summary;
const keyPoints = $('HTTP Request 2').json.transformations.key_points;
const chatResponse = $('HTTP Request 3').json.message;

return {
  project: $('Webhook').json.project,
  document: $('HTTP Request 2').json.title,
  summary: summary,
  key_findings: keyPoints,
  detailed_analysis: chatResponse,
  notebook_url: `https://notebook.yourdomain.com/notebooks/${$('HTTP Request').json.id}`
};

// 8. Notion/Airtable Node - Store in Database
// Save all extracted information for team access

// 9. Slack/Email Node - Notify Team
Message: |
  📚 New research document processed!
  
  Project: {{ $json.project }}
  Document: {{ $json.document }}
  
  Summary: {{ $json.summary }}
  
  Key Findings:
  {{ $json.key_findings.join('\n- ') }}
  
  View full analysis: {{ $json.notebook_url }}
```

#### Example 2: Podcast Generation from Web Articles
```javascript
// Scrape articles, analyze, and generate multi-speaker podcast

// 1. Schedule Trigger
Cron: 0 8 * * *  // Daily at 8 AM

// 2. HTTP Request - Create Daily News Notebook
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "Daily Tech News - {{ $now.format('YYYY-MM-DD') }}",
  "description": "Automated daily tech news digest"
}

// 3. Set Node - News Sources
[
  "https://techcrunch.com/latest",
  "https://news.ycombinator.com/best",
  "https://arstechnica.com"
]

// 4. Loop Node - Process Each Source
Items: {{ $json }}

// 5. HTTP Request - Add URL to Open Notebook
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "url": "{{ $json.item }}",
  "content_type": "url",
  "transformations": ["summary", "key_points"]
}
// Open Notebook fetches, processes, and extracts content

// 6. Wait Node (5 minutes)
// Allow processing time for all sources

// 7. HTTP Request - Generate Podcast
Method: POST
URL: http://opennotebook:5055/api/podcasts
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "episode_profile": {
    "title": "Daily Tech News Digest",
    "description": "Top tech stories from around the web",
    "length": "15min",
    "tone": "informative and conversational"
  },
  "speakers": [
    {
      "name": "Alex",
      "role": "host",
      "style": "enthusiastic tech journalist",
      "voice": "alloy"  // OpenAI TTS voice
    },
    {
      "name": "Morgan",
      "role": "analyst",
      "style": "critical and insightful",
      "voice": "nova"
    }
  ]
}

// 8. Wait Node (3-5 minutes)
// Podcast generation takes time depending on content length

// 9. Loop Node - Poll for Completion
// Check podcast status every 30 seconds

// 10. HTTP Request - Check Podcast Status
Method: GET
URL: http://opennotebook:5055/api/podcasts/{{ $('HTTP Request 2').json.podcast_id }}

// Response:
{
  "id": "podcast_123",
  "status": "completed",  // or "processing", "failed"
  "audio_url": "/data/podcasts/podcast_123.mp3",
  "transcript": "Full transcript...",
  "duration_seconds": 892
}

// 11. If Node - Check if Completed
Condition: {{ $json.status === 'completed' }}

// 12. Move File Node (Bash)
// Copy podcast to shared directory for distribution
Command: cp {{ $json.audio_url }} /data/shared/podcasts/daily-news-{{ $now.format('YYYY-MM-DD') }}.mp3

// 13. RSS Node / Upload to Podcast Platform
// Publish to your podcast feed

// 14. Slack/Discord Node - Notify Team
Message: |
  🎙️ Daily Tech News Podcast Ready!
  
  Duration: {{ Math.floor($json.duration_seconds / 60) }} minutes
  Topics: {{ $json.topics_count }} articles covered
  
  Listen: [Shared Drive Link]
  Transcript: [View in Open Notebook]
```

#### Example 3: Intelligent Knowledge Base Q&A
```javascript
// Build searchable knowledge base with AI-powered Q&A

// 1. Webhook Trigger
// Employee asks question via Slack command or form
// Input: { "question": "What is our refund policy for enterprise customers?", "user": "john@company.com" }

// 2. HTTP Request - Search Knowledge Base
Method: POST
URL: http://opennotebook:5055/api/search
Body: {
  "notebook_id": "company_knowledge_base",  // Your main knowledge notebook
  "query": "{{ $json.question }}",
  "limit": 5,
  "search_type": "hybrid"  // Combines vector and full-text search
}

// Response includes most relevant sources:
{
  "results": [
    {
      "source_id": "doc_42",
      "title": "Enterprise Customer Policy",
      "snippet": "Refund policy for enterprise...",
      "score": 0.89,
      "chunk_id": "chunk_123"
    },
    // ... more results
  ]
}

// 3. HTTP Request - Get Detailed Answer via Chat
Method: POST
URL: http://opennotebook:5055/api/chat
Body: {
  "notebook_id": "company_knowledge_base",
  "message": "{{ $('Webhook').json.question }}",
  "context_sources": {{ $('HTTP Request').json.results.map(r => r.source_id) }},
  "context_level": "selected",  // Use only provided sources
  "system_prompt": "You are a helpful company assistant. Always cite specific policy documents in your answers."
}

// Response:
{
  "message": "According to our Enterprise Customer Policy (Section 3.2)...",
  "sources_used": ["doc_42", "doc_17"],
  "confidence": 0.92
}

// 4. Code Node - Format Response with Sources
const answer = $('HTTP Request 1').json.message;
const sources = $('HTTP Request').json.results;

const formattedResponse = `${answer}\n\n**Sources:**\n${sources.map(s => 
  `• ${s.title} (Relevance: ${Math.round(s.score * 100)}%)`
).join('\n')}`;

return {
  question: $('Webhook').json.question,
  answer: formattedResponse,
  user: $('Webhook').json.user,
  timestamp: new Date().toISOString()
};

// 5. If Node - Low Confidence Check
Condition: {{ $('HTTP Request 1').json.confidence < 0.7 }}

True Branch:
  // 6a. Slack Node - Escalate to Human
  Channel: #knowledge-base-questions
  Message: |
    ⚠️ Question needs human review (Low confidence: {{ $('HTTP Request 1').json.confidence }})
    
    Question: {{ $json.question }}
    User: {{ $json.user }}
    
    AI Answer: {{ $json.answer }}
    
    Please review and provide accurate answer.

False Branch:
  // 6b. Slack/Email Node - Send Answer to User
  To: {{ $json.user }}
  Message: {{ $json.answer }}

// 7. PostgreSQL/Airtable Node - Log Q&A
// Track questions, answers, and confidence for analytics
Table: knowledge_base_queries
Fields:
  question: {{ $json.question }}
  answer: {{ $json.answer }}
  confidence: {{ $('HTTP Request 1').json.confidence }}
  user: {{ $json.user }}
  timestamp: {{ $json.timestamp }}
```

#### Example 4: Multi-Source Research Compilation
```javascript
// Aggregate research from multiple documents into comprehensive report

// 1. Manual Trigger or Schedule
// Research topic defined

// 2. Set Node - Research Topic
{
  "topic": "Impact of AI on Healthcare",
  "subtopics": [
    "Diagnosis and Treatment",
    "Drug Discovery",
    "Patient Care",
    "Administrative Efficiency"
  ]
}

// 3. HTTP Request - Create Research Notebook
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "{{ $json.topic }} Research",
  "description": "Comprehensive research compilation"
}

// 4. Perplexica/Web Search Node
// Gather URLs for relevant articles, papers, reports

// 5. Loop Node - Add Each Source to Notebook
Items: {{ $('Perplexica').json.sources }}

// 6. HTTP Request - Add Source to Open Notebook
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "url": "{{ $json.item.url }}",
  "title": "{{ $json.item.title }}",
  "transformations": ["summary", "key_points", "methodology"]
}

// 7. Wait Node (10 minutes)
// Process all sources

// 8. Loop Node - Research Each Subtopic
Items: {{ $('Set Node').json.subtopics }}

// 9. HTTP Request - Chat About Subtopic
Method: POST
URL: http://opennotebook:5055/api/chat
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "message": "Provide a detailed analysis of {{ $json.item }} based on all available sources. Include specific examples, statistics, and cite sources.",
  "context_level": "full"
}

// 10. Aggregate Node - Compile Research
const topic = $('Set Node').json.topic;
const subtopics = $('Loop Node').all().map((item, i) => ({
  title: $('Set Node').json.subtopics[i],
  analysis: item.json.message,
  sources: item.json.sources_used || []
}));

// 11. OpenAI/Claude Node - Generate Executive Summary
Prompt: |
  Based on the following research on "{{ topic }}", create an executive summary:
  
  {{ subtopics.map(s => `\n### ${s.title}\n${s.analysis}`).join('\n') }}

// 12. Docx/PDF Node - Create Report Document
// Format complete research report

// 13. Store in Seafile/Google Drive
// Make accessible to team
```

### API Documentation

**Base URL:** `http://opennotebook:5055`

**Notebook Operations:**
```bash
# Create Notebook
curl -X POST http://opennotebook:5055/api/notebooks \
  -H "Content-Type: application/json" \
  -d '{"name": "My Research", "description": "Project notes"}'

# List Notebooks
curl http://opennotebook:5055/api/notebooks

# Get Notebook Details
curl http://opennotebook:5055/api/notebooks/{notebook_id}

# Delete Notebook
curl -X DELETE http://opennotebook:5055/api/notebooks/{notebook_id}
```

**Source Management:**
```bash
# Upload File
curl -X POST http://opennotebook:5055/api/sources \
  -F "notebook_id=notebook_123" \
  -F "file=@/path/to/document.pdf" \
  -F "transformations=[\"summary\",\"key_points\"]"

# Add URL
curl -X POST http://opennotebook:5055/api/sources \
  -H "Content-Type: application/json" \
  -d '{
    "notebook_id": "notebook_123",
    "url": "https://example.com/article",
    "content_type": "url"
  }'

# List Sources
curl http://opennotebook:5055/api/sources?notebook_id=notebook_123

# Get Source Details
curl http://opennotebook:5055/api/sources/{source_id}
```

**Chat Interface:**
```bash
# Chat with Notebook Content
curl -X POST http://opennotebook:5055/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "notebook_id": "notebook_123",
    "message": "What are the main themes in these documents?",
    "context_level": "full",
    "model": "gpt-4o-mini"
  }'

# Get Chat History
curl http://opennotebook:5055/api/chat/history/{notebook_id}?limit=20
```

**Search:**
```bash
# Vector + Full-Text Search
curl -X POST http://opennotebook:5055/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "notebook_id": "notebook_123",
    "query": "quantum computing applications",
    "limit": 10,
    "search_type": "hybrid"
  }'
```

**Podcast Generation:**
```bash
# Generate Podcast
curl -X POST http://opennotebook:5055/api/podcasts \
  -H "Content-Type: application/json" \
  -d '{
    "notebook_id": "notebook_123",
    "episode_profile": {
      "title": "Weekly Tech Roundup",
      "description": "Discussion of latest tech news",
      "length": "20min"
    },
    "speakers": [
      {
        "name": "Alex",
        "role": "host",
        "voice": "alloy"
      },
      {
        "name": "Sam",
        "role": "expert",
        "voice": "nova"
      }
    ]
  }'

# Check Podcast Status
curl http://opennotebook:5055/api/podcasts/{podcast_id}
```

### Troubleshooting

**Issue 1: Open Notebook Not Accessible**
```bash
# Check if container is running
docker ps | grep opennotebook

# Check logs
docker logs opennotebook --tail 100

# Restart service
docker compose restart opennotebook

# Check if ports are accessible internally
docker exec n8n curl http://opennotebook:8502/
docker exec n8n curl http://opennotebook:5055/docs
```

**Solution:**
- Verify container is running
- Check Docker network connectivity
- Ensure SurrealDB (embedded) initialized properly
- Check for port conflicts

**Issue 2: Password Not Working**
```bash
# Check password in .env
grep OPENNOTEBOOK_PASSWORD ~/ai-launchkit/.env

# Regenerate password
cd ~/ai-launchkit
bash scripts/03_generate_secrets.sh

# Restart Open Notebook
docker compose restart opennotebook
```

**Solution:**
- Password is set via `OPENNOTEBOOK_PASSWORD` environment variable
- Clear browser cache/cookies if password was recently changed
- Use incognito/private browsing to test fresh session

**Issue 3: AI Models Not Working**
```bash
# Check API keys
docker exec opennotebook env | grep -E "OPENAI|ANTHROPIC|GROQ"

# Test Ollama connectivity
docker exec opennotebook curl http://ollama:11434/api/tags

# Check model configuration in UI
# Settings → Models → Verify model selections
```

**Solution:**
- Verify API keys in `.env` file
- For Ollama: Ensure models are downloaded (`docker exec ollama ollama list`)
- Check model names match exactly (case-sensitive)
- Test with different model provider

**Issue 4: File Upload Fails**
```bash
# Check disk space
df -h

# Check Open Notebook storage directory
du -sh ~/ai-launchkit/opennotebook/

# Check file permissions
ls -la ~/ai-launchkit/opennotebook/
chmod -R 755 ~/ai-launchkit/opennotebook/

# Check Docker volume
docker volume inspect ${PROJECT_NAME:-localai}_opennotebook_data
```

**Solution:**
- Ensure sufficient disk space (>5GB recommended)
- Check file size limits (default 100MB via Caddy)
- Verify volume permissions
- For large files: Split into smaller chunks or increase limits

**Issue 5: Podcast Generation Hangs**
```bash
# Check TTS service status
docker logs opennotebook | grep -i "tts\|podcast"

# Verify TTS model configured
# Settings → Models → Text-to-Speech

# Check available TTS providers
curl http://opennotebook:5055/api/models/tts
```

**Solution:**
- Podcast generation requires TTS model (OpenAI, Google, or ElevenLabs)
- Processing time varies: 2-5 minutes for short podcasts, 10-20 minutes for long content
- Monitor logs for specific errors
- Reduce content length if timeouts occur

**Issue 6: Search Returns No Results**
```bash
# Check if sources are indexed
curl http://opennotebook:5055/api/sources?notebook_id=YOUR_ID

# Verify embedding model configured
# Settings → Models → Embedding Model

# Test embedding service
docker logs opennotebook | grep -i "embedding"
```

**Solution:**
- Embedding model required for vector search
- Sources must be fully processed before searchable (check status)
- Use full-text search if embedding not configured
- Re-index sources if needed (delete and re-upload)

**Issue 7: Cannot Access from n8n**
```bash
# Test API connectivity from n8n
docker exec n8n curl http://opennotebook:5055/docs

# Check Docker network
docker network inspect ${PROJECT_NAME:-localai}_default | grep -E "opennotebook|n8n"

# Test specific endpoint
docker exec n8n curl -X POST http://opennotebook:5055/api/notebooks \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}'
```

**Solution:**
- Use internal URL: `http://opennotebook:5055` (not localhost or external domain)
- Verify both containers are running
- Check network configuration
- No authentication required for internal API access

### Configuration Options

**AI Provider Configuration:**

Open Notebook supports 16+ AI providers. Configure in Web UI (Settings → Models) or via environment variables.

**Supported Providers:**
- OpenAI (`OPENAI_API_KEY`)
- Anthropic (`ANTHROPIC_API_KEY`)
- Groq (`GROQ_API_KEY`)
- Google Gemini
- Ollama (http://ollama:11434)
- Mistral
- DeepSeek
- xAI
- OpenRouter
- LM Studio
- Azure OpenAI
- Vertex AI
- Perplexity
- ElevenLabs (TTS)
- Voyage (Embeddings)

**Storage Configuration:**
```bash
# Data directories (relative to ~/ai-launchkit)
./opennotebook/notebook_data/  # Notebooks and content
./opennotebook/surreal_data/   # Embedded SurrealDB
./shared/                      # Shared with other services
```

**Password Protection:**
```bash
# In .env file
OPENNOTEBOOK_PASSWORD=your_secure_password

# Leave empty for local-only deployments (no password required)
OPENNOTEBOOK_PASSWORD=
```

**Model Defaults (recommended):**
```
Language: gpt-4o-mini (OpenAI) or claude-3.5-sonnet (Anthropic)
Embedding: text-embedding-3-small (OpenAI) or nomic-embed-text (Ollama)
TTS: gpt-4o-mini-tts (OpenAI) or eleven_turbo_v2_5 (ElevenLabs)
STT: whisper-1 (OpenAI) or groq/whisper-large-v3 (Groq)
```

### Resources

- **GitHub:** https://github.com/lfnovo/open-notebook
- **Documentation:** https://www.open-notebook.ai
- **Web Interface:** `https://notebook.yourdomain.com`
- **API Endpoint:** `http://opennotebook:5055`
- **API Docs (Swagger):** `http://opennotebook:5055/docs`
- **Discord Community:** https://discord.gg/open-notebook
- **NotebookLM Comparison:** https://www.open-notebook.ai/comparison

### Best Practices

**For Research Workflows:**
- Create separate notebooks for each project/topic
- Use content transformations (summaries, key points) on upload
- Tag and organize sources systematically
- Use vector search for semantic queries, full-text for exact matches
- Export important findings to external knowledge base (Notion, Obsidian)

**For Podcast Creation:**
- Start with 2 speakers (host + guest), expand to 3-4 for panel discussions
- Define clear speaker roles and personalities for consistency
- Episode Profiles dramatically improve output quality
- Test with shorter content first (5-10 min) before longer episodes
- Use high-quality TTS models (OpenAI, ElevenLabs) for production podcasts

**For Knowledge Management:**
- Build one "master" notebook per domain (e.g., Company Knowledge Base)
- Regular content review and cleanup (archive old/irrelevant sources)
- Use chat history to build FAQs from common questions
- Combine with vector database (Qdrant) for cross-notebook search
- Set up automated workflows for new document intake

**For n8n Integration:**
- Use internal API URL (`http://opennotebook:5055`) for all requests
- No authentication needed for internal network
- Implement retry logic for long-running operations (podcast generation)
- Cache common queries in Redis or PostgreSQL
- Use webhooks to trigger workflows on new content

**Performance Tips:**
- Use smaller LLM models for faster responses (gpt-4o-mini vs gpt-4)
- Limit source size for notebooks (<100 sources for optimal performance)
- Use content transformations strategically (not on every upload)
- Store processed content in external database for complex analytics
- Monitor disk usage (embeddings can grow large with many sources)

**Privacy Considerations:**
- With Ollama: Completely local processing, no external API calls
- API keys stored locally, never transmitted to Open Notebook servers
- Native password protection for public deployments
- All data stored in `./opennotebook/` directory (easy backup/migration)
- For maximum privacy: Use Ollama for all models (LLM, embedding, TTS)

### When to Use Open Notebook

**✅ Perfect For:**
- Research project management and knowledge compilation
- Multi-modal content analysis (PDFs + videos + audio)
- Building searchable knowledge bases with AI Q&A
- Podcast generation from written content
- Academic research with citations and source tracking
- Content research and summarization at scale
- Team knowledge sharing and documentation
- NotebookLM alternative with more flexibility
- Private AI-powered note-taking

**❌ Not Ideal For:**
- Real-time collaboration (no simultaneous editing)
- Simple note-taking without AI features (use Notion instead)
- When you need Google's specific Gemini models
- Video/audio editing (Open Notebook extracts content, doesn't edit)
- When bandwidth is extremely limited (large uploads required)

**Open Notebook vs NotebookLM:**
- ✅ 16+ AI providers vs Google models only
- ✅ Self-hosted (complete data control)
- ✅ 1-4 podcast speakers vs 2 only
- ✅ Full REST API for automation
- ✅ No vendor lock-in
- ❌ Requires self-hosting setup
- ❌ No Google Workspace integration

**Open Notebook vs Obsidian:**
- ✅ AI-powered chat and analysis
- ✅ Multi-modal content support
- ✅ Automatic content transformations
- ✅ Podcast generation
- ❌ Not markdown-native
- ❌ Fewer community plugins
- ❌ Web-based interface (not desktop app)

**Open Notebook vs RAGapp:**
- ✅ Better UI/UX for end users
- ✅ Podcast generation feature
- ✅ Multi-notebook organization
- ✅ More AI provider support
- ❌ RAGapp more developer-focused
- ❌ RAGapp better for pure RAG implementations
