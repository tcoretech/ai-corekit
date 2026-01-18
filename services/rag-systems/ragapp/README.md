# 📚 RAGApp - RAG Assistant Builder

### What is RagAPP?

RAGApp is an enterprise-ready platform for building Agentic RAG (Retrieval-Augmented Generation) applications, built on LlamaIndex. It's as simple to configure as OpenAI's custom GPTs but deployable in your own cloud infrastructure using Docker. RAGApp provides a complete solution with Admin UI, Chat UI, and REST API, allowing you to build AI assistants that can intelligently reason over your documents and data.

### Features

- **Agentic RAG with LlamaIndex** - Autonomous agent that can reason about queries, break them down into smaller tasks, choose tools dynamically, and execute multi-step workflows
- **Multiple AI Provider Support** - Works with OpenAI, Google Gemini, and local models via Ollama
- **Admin UI** - Easy web interface for configuring your RAG assistant without code
- **Chat UI & REST API** - Ready-to-use chat interface and API endpoints for integration
- **Document Management** - Upload and process PDFs, Office documents, text files, and more
- **Tool Integration** - Connect to external APIs and knowledge bases
- **Docker-Based Deployment** - Simple container-based setup with docker-compose

### Initial Setup

**First Login to RAGApp:**

1. Navigate to `https://ragapp.yourdomain.com/admin`
2. **Configure AI Provider:**
   - **Option A - OpenAI:** Add your OpenAI API key
   - **Option B - Gemini:** Add your Google AI API key
   - **Option C - Ollama:** Use `http://ollama:11434` (pre-configured)
3. **Upload Documents:**
   - Click "Documents" in Admin UI
   - Upload your PDFs, DOCX, TXT, or other files
   - Documents are automatically processed and indexed
4. **Configure Assistant:**
   - Set system prompt and instructions
   - Choose which tools to enable
   - Configure retrieval settings (top-k, similarity threshold)
5. **Test in Chat UI:**
   - Navigate to `https://ragapp.yourdomain.com`
   - Ask questions about your documents
   - Assistant uses agentic reasoning to find answers

**Pre-configured Integration:**
- **Internal Ollama URL:** `http://ollama:11434` (already set)
- **Qdrant Vector Store:** `http://qdrant:6333` (used for embeddings)

### n8n Integration Setup

**Access RAGApp API from n8n:**

- **Internal URL:** `http://ragapp:8000`
- **API Docs:** `http://ragapp:8000/docs` (OpenAPI/Swagger)
- **No authentication** by default (designed for internal use behind API gateway)

#### Example 1: Simple Document Q&A Workflow

Ask questions about uploaded documents via n8n:

```javascript
// 1. Webhook Trigger - Receive question from external system

// 2. HTTP Request: Query RAGApp
Method: POST
URL: http://ragapp:8000/api/chat
Headers:
  Content-Type: application/json
Body: {
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.question }}"
    }
  ],
  "stream": false
}

// 3. Code Node: Extract answer
const response = $json.choices[0].message.content;
const sources = $json.sources || [];
return {
  answer: response,
  sources: sources.map(s => s.metadata.file_name),
  confidence: $json.confidence_score
};

// 4. Send response back (Slack, Email, etc.)
```

#### Example 2: Document Upload & Processing Pipeline

Automatically upload and process documents:

```javascript
// 1. Email Trigger: Receive PDF attachment

// 2. HTTP Request: Upload document to RAGApp
Method: POST
URL: http://ragapp:8000/api/documents
Headers:
  Content-Type: multipart/form-data
Body:
  - file: {{ $binary.data }}
  - metadata: {
      "source": "email",
      "processed_date": "{{ $now.format('YYYY-MM-DD') }}"
    }

// 3. Wait Node: Give time for processing (30 seconds)

// 4. HTTP Request: Check document status
Method: GET
URL: http://ragapp:8000/api/documents/{{ $json.document_id }}

// 5. Condition Node: If processing complete
If: {{ $json.status === 'completed' }}
Then: Send confirmation email
Else: Log error and retry
```

#### Example 3: Agentic Research Workflow

Use RAGApp's agentic capabilities to perform multi-step research across multiple documents:

```javascript
// 1. Schedule Trigger: Daily research task

// 2. HTTP Request: Complex research query
Method: POST
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [
    {
      "role": "user",
      "content": "Analyze all quarterly reports from 2024 and summarize key financial trends. Compare revenue growth across Q1-Q4."
    }
  ],
  "agent_config": {
    "tools": ["document_search", "summarize", "compare"],
    "max_steps": 10,
    "reasoning": true
  }
}

// Agent will:
// - Break down query into sub-tasks
// - Search relevant quarterly reports
// - Extract financial data
// - Compare across quarters
// - Synthesize comprehensive summary

// 3. Code Node: Format research report
const report = {
  title: "Q1-Q4 2024 Financial Analysis",
  summary: $json.choices[0].message.content,
  sources: $json.sources,
  reasoning_steps: $json.agent_steps,
  generated_at: new Date().toISOString()
};

// 4. HTTP Request: Save to Supabase
// 5. Email: Send report to stakeholders
```

#### Example 4: Multi-Source Knowledge Integration

Combine RAGApp with external APIs for comprehensive answers:

```javascript
// 1. Webhook: Receive customer support question

// 2. HTTP Request: Search internal docs (RAGApp)
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [{"role": "user", "content": "{{ $json.question }}"}]
}

// 3. Condition: If RAGApp can't answer fully
If: {{ $json.confidence_score < 0.7 }}

// 4a. HTTP Request: Search web (SearXNG)
URL: http://searxng:8080/search
Query: {{ $json.question }}

// 4b. HTTP Request: Query product database
// Get latest product info

// 5. Code Node: Merge results
const answer = {
  primary_answer: $('RAGApp').first().json.response,
  confidence: $('RAGApp').first().json.confidence_score,
  additional_context: $('SearXNG').first().json.results.slice(0, 3),
  product_info: $('ProductDB').first().json
};

// 6. HTTP Request: Send back to RAGApp for final synthesis
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [
    {
      "role": "system",
      "content": "Synthesize the following information into a comprehensive answer..."
    },
    {
      "role": "user",
      "content": JSON.stringify(answer)
    }
  ]
}

// 7. Send final answer to customer
```

### Advanced Configuration

#### Optimizing RAG Performance

**Chunking Strategy:**
```yaml
# In Admin UI > Settings > Retrieval
chunk_size: 1024  # Smaller for precise retrieval
chunk_overlap: 128  # 10-20% overlap recommended
```

**Retrieval Settings:**
```yaml
top_k: 5  # Number of chunks to retrieve
similarity_threshold: 0.7  # Minimum similarity score (0-1)
rerank: true  # Enable reranking for better results
```

**Embedding Models:**
- **OpenAI:** `text-embedding-3-small` (fast, cost-effective)
- **OpenAI:** `text-embedding-3-large` (best quality)
- **Ollama:** `nomic-embed-text` (local, free)

#### Using Custom System Prompts

Configure your assistant's behavior in Admin UI:

```
You are a financial analyst assistant specialized in quarterly reports.

When answering questions:
1. Always cite specific sections and page numbers from documents
2. Compare data across different time periods when relevant
3. Highlight any significant trends or anomalies
4. If data is missing or unclear, explicitly state this

Format your responses with:
- Executive Summary (2-3 sentences)
- Detailed Analysis (with citations)
- Key Takeaways (bullet points)
```

#### Tool Configuration

Enable additional tools for agentic reasoning:

- **Document Search:** Semantic search across uploaded documents
- **Summarization:** Create summaries of long documents
- **Comparison:** Compare multiple documents or data points
- **External APIs:** Connect to external data sources
- **Code Execution:** Run Python code for data analysis (enterprise feature)

### Troubleshooting

**Documents not being indexed:**

```bash
# 1. Check RAGApp logs
docker logs ragapp --tail 50

# 2. Verify Qdrant is running
docker ps | grep qdrant
curl http://localhost:6333/health

# 3. Check document format
# Supported: PDF, DOCX, TXT, MD, HTML, CSV
# Unsupported or corrupted files will be skipped

# 4. Check available disk space
df -h
# Documents and indexes require storage

# 5. Re-upload document
# Delete and re-upload if processing failed
```

**Low quality answers:**

```bash
# 1. Check similarity threshold
# Lower threshold if no results found (try 0.5-0.6)

# 2. Increase top_k value
# Try retrieving more chunks (10-15 instead of 5)

# 3. Verify embedding model
# In Admin UI: Settings > Models > Embedding Model
# Ensure model is loaded and working

# 4. Test embeddings directly
curl -X POST http://ragapp:8000/api/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "test query"}'
# Should return embedding vector

# 5. Review document quality
# Ensure documents have clear structure
# Remove low-quality scanned PDFs
# Use OCR for image-based documents
```

**API connection issues:**

```bash
# 1. Verify RAGApp is accessible from n8n
docker exec n8n curl http://ragapp:8000/health
# Should return: {"status": "healthy"}

# 2. Check API endpoint
# Admin UI: Settings > API > Base URL
# Should be: http://ragapp:8000

# 3. Test API directly
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello"}
    ]
  }'

# 4. Check Docker network
docker network inspect ai-corekit_default
# Verify ragapp and n8n are on same network

# 5. Restart RAGApp if needed
docker compose restart ragapp
```

**Ollama model not found:**

```bash
# 1. Verify Ollama is running
docker ps | grep ollama

# 2. Check which models are available
docker exec ollama ollama list

# 3. Pull required model
docker exec ollama ollama pull llama3.2

# 4. Update RAGApp configuration
# Admin UI > Settings > Models > LLM Model
# Select: ollama/llama3.2

# 5. Test connection
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.2", "prompt": "test"}'
```

### Best Practices

**Document Preparation:**
- Clean and structure documents before upload
- Use consistent formatting (headers, sections)
- Include metadata in filenames (date, author, version)
- Remove unnecessary pages (cover, blank pages)
- For scanned documents, use OCR first

**Prompt Engineering:**
- Be specific about what information you need
- Reference document types or sections when possible
- Ask follow-up questions to refine answers
- Use examples in your system prompt

**Performance Optimization:**
- Start with fewer documents and scale up
- Monitor embedding costs (if using OpenAI)
- Use local Ollama for development/testing
- Cache frequent queries where possible
- Batch process documents during off-hours

**Security:**
- Deploy behind API gateway for authentication
- Use environment variables for API keys
- Enable HTTPS in production
- Implement rate limiting
- Audit document access logs

### Integration with Other AI CoreKit Services

**RAGApp + Qdrant:**
- Qdrant is pre-configured as vector store
- All embeddings stored in `http://qdrant:6333`
- Use Qdrant UI to browse collections and inspect vectors

**RAGApp + Flowise:**
- Use Flowise for complex multi-agent workflows
- RAGApp handles document Q&A
- Flowise orchestrates the overall agent logic
- Example: Research agent that queries RAGApp → summarizes → decides next action

**RAGApp + Open WebUI:**
- Build custom OpenAI-compatible API wrapper around RAGApp
- Users can access RAGApp knowledge through familiar ChatGPT interface
- Combine both UIs: RAGApp for document-focused work, Open WebUI for general chat

**RAGApp + n8n:**
- Automate document ingestion pipelines
- Schedule regular queries and reports
- Integrate with business workflows (email, Slack, CRM)
- Build self-service knowledge portals

### Resources

- **Official Website:** https://www.ragapp.dev/
- **Documentation:** https://docs.ragapp.dev/
- **GitHub:** https://github.com/ragapp/ragapp
- **LlamaIndex Docs:** https://docs.llamaindex.ai/
- **API Reference:** `http://ragapp.yourdomain.com/docs` (OpenAPI)
- **Community:** LlamaIndex Discord
