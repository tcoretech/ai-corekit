### What is Dify?

Dify is an open-source LLMOps (Large Language Model Operations) platform designed to simplify the development, deployment, and management of production-grade AI applications. It bridges the gap between prototyping and production by providing visual workflow builders, RAG pipelines, agent capabilities, and comprehensive monitoring tools. Think of it as "Backend-as-a-Service for AI" - allowing developers to build sophisticated AI applications without complex backend infrastructure.

### Features

- **Visual Workflow Builder** - Drag-and-drop interface (Chatflow & Workflow modes) for building AI applications
- **Multiple Application Types** - Chatbots, text generators, AI agents, and automation workflows
- **Prompt IDE** - Built-in prompt editor with variables, versioning, and A/B testing
- **RAG Engine** - High-quality document processing, embedding, and retrieval with multiple vector databases
- **Agent Capabilities** - Function calling, ReACT reasoning, 50+ built-in tools (Google Search, DALL·E, etc.)
- **Model Management** - Support for 100+ LLM providers (OpenAI, Anthropic, Ollama, Groq, etc.)
- **Backend-as-a-Service API** - Production-ready REST APIs for all applications
- **LLMOps & Observability** - Real-time monitoring, logs, annotations, and performance tracking
- **Multi-Tenancy** - Workspace management for teams and organizations
- **Dataset Management** - Upload, annotate, and manage training/testing datasets
- **Version Control** - Track changes to prompts, workflows, and configurations
- **Human-in-the-Loop** - Annotation workflows for continuous improvement

### Initial Setup

**First Login to Dify:**

1. Navigate to `https://dify.yourdomain.com`
2. **Create workspace owner account** (first user becomes admin)
3. Set strong password (minimum 8 characters)
4. Complete workspace setup:
   - Workspace name: Your organization name
   - Language: English, Chinese, German, etc.
5. Setup complete!

**Configure LLM Providers:**

1. Go to **Settings** → **Model Providers**
2. Add your AI providers:

**For Ollama (local, free):**
```
Provider: Ollama
Base URL: http://ollama:11434
Models: Auto-detected (llama3.2, mistral, qwen, etc.)
```

**For OpenAI:**
```
Provider: OpenAI  
API Key: sk-...
Models: gpt-4o, gpt-4o-mini, gpt-4-turbo
```

**For Anthropic:**
```
Provider: Anthropic
API Key: sk-ant-...
Models: claude-3-5-sonnet-20241022, claude-3-5-haiku-20241022
```

3. **Test connection** - Click "Test" button for each provider
4. Save configuration

**Generate API Key (for n8n integration):**

1. Go to **Settings** → **API Keys**
2. Click **Create API Key**
3. Name: "n8n Integration" or "External Services"
4. Select permissions:
   - `apps.read` - Read app configurations
   - `apps.write` - Create and modify apps
   - `datasets.read` - Access knowledge bases
5. **Copy API key immediately** - you won't see it again!
6. Save securely in password manager

### n8n Integration Setup

**Create Dify Credentials in n8n:**

Dify does not have a native n8n node. Use HTTP Request nodes with Bearer token authentication.

1. In n8n, create credentials:
   - Type: **Header Auth**
   - Name: **Dify API**
   - Name (Header): `Authorization`
   - Value: `Bearer YOUR_DIFY_API_KEY`

2. Test connection:
   ```bash
   # From n8n HTTP Request node
   GET http://dify-api:5001/v1/parameters
   ```

**Internal URL:** `http://dify-api:5001` (API server)  
**External URL:** `https://dify.yourdomain.com/v1`
**Web UI:** `https://dify.yourdomain.com` (for building apps visually)

### Example Workflows

#### Example 1: Customer Support Chatbot with RAG

Build an AI support agent that answers from your documentation. Full workflow example available in project knowledge under [name of workflow example].

#### Example 2: Bulk Content Generation

Use Dify for automated content creation at scale. See project knowledge for complete implementation.

#### Example 3: AI Agent with Tools

Create intelligent agents that use external tools and APIs. Refer to Dify documentation for agent configuration.

### Dify Application Types

**Chatbot (Chatflow):**
- Multi-turn conversations with memory
- Customer service, semantic search
- Uses `chat-messages` API endpoint
- Continuous context preservation

**Text Generator (Completion):**
- Single-turn text generation
- Writing, translation, classification
- Uses `completion-messages` API endpoint
- Form input + results output

**Agent:**
- Autonomous task execution
- Function calling with tools
- ReACT reasoning pattern
- Can use both chat and completion APIs

**Workflow:**
- Visual orchestration platform
- Automation and batch processing
- Complex multi-step logic
- Uses `workflows/run` API endpoint

### Troubleshooting

**Connection refused:**

```bash
# 1. Check Dify services are running
docker ps | grep dify

# You should see:
# - dify-api (port 5001)
# - dify-web (port 3000)
# - dify-worker
# - dify-db (PostgreSQL)
# - dify-redis

# 2. Test API connectivity
curl http://localhost:5001/v1/parameters

# 3. Check Dify logs
docker logs dify-api --tail 50
docker logs dify-worker --tail 50

# 4. Restart if needed
docker compose restart dify-api dify-worker
```

**API authentication fails:**

```bash
# 1. Verify API key format
# Must be: Authorization: Bearer app-xxxxxxxxxxxx

# 2. Test with curl
curl -X POST http://localhost:5001/v1/chat-messages \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"inputs": {}, "query": "test", "response_mode": "blocking", "user": "test"}'
```

**RAG not returning relevant documents:**

```bash
# 1. Check knowledge base processed correctly
# Dify UI → Knowledge → Your KB → Processing Status

# 2. Adjust retrieval settings:
# - Top K: Increase to 5-10
# - Score threshold: Lower to 0.3-0.5
# - Enable reranking for better relevance

# 3. Reindex knowledge base if needed
```

### Resources

- **Official Website:** https://dify.ai/
- **Documentation:** https://docs.dify.ai/
- **GitHub:** https://github.com/langgenius/dify
- **API Reference:** https://docs.dify.ai/api-reference
- **Community:** https://github.com/langgenius/dify/discussions
- **Blog:** https://dify.ai/blog

### Best Practices

**Application Design:**
- Start simple, iterate based on results
- Use Chatflow for conversations, Workflow for automation
- Test with diverse inputs before production
- Implement human-in-the-loop for critical applications

**RAG Optimization:**
- Chunk size: 500-1000 characters
- Use metadata filtering for precision
- Enable reranking for relevance
- Regular knowledge base updates

**Production:**
- Use API keys per environment
- Monitor token usage and costs
- Implement rate limiting
- Log interactions for quality review

**Security:**
- Never expose API keys in frontend
- Regularly rotate API keys
- Implement input validation
- Use Dify's built-in user management
