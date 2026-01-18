# 💾 Letta - Stateful AI Agent Platform

### What is Letta?

Letta (formerly MemGPT) is an advanced platform for building stateful AI agents with persistent, long-term memory that learn and evolve over time. Unlike traditional LLMs that operate in a stateless paradigm where each interaction exists in isolation, Letta agents maintain continuous memory across sessions, actively forming and updating memories based on accumulated experience. Built by AI researchers from UC Berkeley who created MemGPT, Letta provides an Agent Development Environment for visualizing and managing agent memory, reasoning steps, and tool calls. Agents continue to exist and maintain state even when your application isn't running, with computation happening on the server and all memory, context, and tool connections handled by the Letta server.

### Features

- **Stateful Agents** - Agents with perpetual (infinite) message history that persist across sessions
- **Advanced Memory System** - Self-editing memory blocks (persona, human, archival) that evolve over time
- **Agent Development Environment (ADE)** - No-code UI for building, testing, and debugging agents with full visibility into memory and reasoning
- **Model-Agnostic** - Works with any LLM (OpenAI, Anthropic, Groq, Ollama, local models)
- **Sleep-Time Agents** - Background agents that process and refine memory during downtime
- **Agent File (.af)** - Open file format for serializing and sharing stateful agents
- **Multi-Agent Memory Sharing** - Single memory blocks can be attached to multiple agents
- **Tool Integration** - Built-in support for Composio, LangChain, CrewAI tools, and MCP servers
- **Full API & SDKs** - REST API with native Python and TypeScript SDKs
- **Letta Cloud or Self-Hosted** - Deploy agents in the cloud or run your own server

### Initial Setup

**First Login to Letta:**

1. Navigate to `https://letta.yourdomain.com`
2. **No authentication by default** - The Agent Development Environment (ADE) opens directly
3. If you enabled password protection in `.env`, use your configured credentials
4. You'll see the ADE interface with options to create agents, view memory, and test tools

**Configure LLM Providers:**

1. In the ADE, click **Settings** → **Models**
2. Add your AI model providers:

**For Ollama (local, free):**
```
Provider Type: Ollama
Base URL: http://ollama:11434
Models: Auto-detected (llama3.2, mistral, qwen2.5)
```

**For OpenAI:**
```
Provider Type: OpenAI
API Key: sk-...
Models: gpt-4.1, gpt-4.o-mini, o1-preview
Embedding: text-embedding-3-small
```

**For Anthropic:**
```
Provider Type: Anthropic
API Key: sk-ant-...
Models: claude-4.5-sonnet-20250929
```

**For Groq (fast inference):**
```
Provider Type: Groq
API Key: gsk-...
Models: llama-3.1-70b-versatile, mixtral-8x7b
```

3. **Test connection** - Click "Test" to verify each provider
4. **Set default model** - Choose which model to use by default for new agents

**Create Your First Agent:**

1. Click **Create Agent** in the ADE
2. Configure agent memory blocks:
   - **Persona Block**: "My name is Sam, a helpful AI assistant..."
   - **Human Block**: "The human's name is [User]..."
3. Select your LLM model and embedding model
4. Add tools (optional): web_search, calculator, send_email, etc.
5. Click **Create** - your stateful agent is now running!
6. Send a message to test - agent will remember this conversation forever

**Generate API Key (for n8n/external integration):**

1. **If using Letta Cloud:** Get API key from `https://app.letta.com/settings`
2. **If self-hosted without password:** No API key required, use base URL directly
3. **If self-hosted with password:** Use your configured password as the token
4. Save this key securely for use in n8n workflows

### n8n Integration Setup

**Create Letta Credentials in n8n:**

Letta does not have a native n8n node. Use HTTP Request nodes with the Letta REST API.

1. In n8n, create credentials (only if using authentication):
   - Type: **Header Auth**
   - Name: **Letta API**
   - Header Name: `Authorization`
   - Value: `Bearer YOUR_LETTA_API_KEY` (for Letta Cloud) or just `YOUR_PASSWORD` (for self-hosted with password)

2. For self-hosted without authentication, no credentials needed

**Internal URL:** `http://letta:8283`  
**External URL:** `https://letta.yourdomain.com`
**ADE Web UI:** `https://letta.yourdomain.com` (Agent Development Environment)

### Understanding Letta's Memory System

**Memory Blocks:**

Letta agents manage memory through editable "memory blocks":

- **Core Memory Blocks:**
  - `human` - Information about the user
  - `persona` - Agent's personality and role
  
- **Archival Memory:**
  - Infinite-size storage for facts and knowledge
  - Searchable with embedding-based retrieval
  
- **Recall Memory:**
  - Conversation history stored as a searchable database
  - Agents can search past interactions

**How It Works:**

1. Agent receives message
2. Checks current memory blocks in context window
3. Can search archival or recall memory if needed
4. Can edit its own memory blocks using tools
5. State automatically saved after each step

### Example Workflows

#### Example 1: Create Stateful Agent via n8n

Create a persistent agent that remembers all past conversations:

```javascript
// n8n Workflow: Create Letta Agent

// 1. HTTP Request Node - Create Agent
Method: POST
URL: http://letta:8283/v1/agents
Authentication: Use Letta credentials (if password protected)
Headers:
  Content-Type: application/json
Body:
{
  "name": "Customer Support Agent",
  "model": "openai/gpt-4.1",
  "embedding": "openai/text-embedding-3-small",
  "memory_blocks": [
    {
      "label": "human",
      "value": "Customer name: New Customer\nAccount tier: Free\nPreferences: Unknown"
    },
    {
      "label": "persona",
      "value": "I am a helpful customer support agent. I remember all past interactions and learn about customer preferences over time. I maintain professional, friendly communication."
    }
  ],
  "tools": ["send_message", "core_memory_append", "core_memory_replace", "archival_memory_insert", "conversation_search"]
}

// Response includes agent.id
// Example: "agent-d9be2c54-1234-5678-9abc-def012345678"

// 2. PostgreSQL Node - Save Agent ID (optional)
Operation: Insert
Table: letta_agents
Data:
  agent_id: {{ $json.id }}
  customer_email: {{ $('Trigger').json.email }}
  created_at: {{ new Date().toISOString() }}

// Agent is now created and will persist indefinitely
```

#### Example 2: Chat with Stateful Agent

Interact with a persistent agent that remembers context across sessions:

```javascript
// n8n Workflow: Chat with Letta Agent

// 1. Webhook Trigger - Receive user message
POST /webhook/letta-chat
Body: { "agent_id": "agent-...", "message": "Hello, do you remember me?" }

// 2. HTTP Request Node - Send Message to Agent
Method: POST
URL: http://letta:8283/v1/agents/{{ $json.agent_id }}/messages
Headers:
  Content-Type: application/json
Body:
{
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.message }}"
    }
  ],
  "stream": false
}

// 3. Code Node - Extract Response
const response = $input.first().json;

// Find assistant message (agent's reply to user)
const assistantMessage = response.messages.find(
  msg => msg.message_type === 'assistant_message'
);

// Find reasoning messages (agent's inner thoughts)
const reasoning = response.messages.filter(
  msg => msg.message_type === 'reasoning_message'
);

// Find tool calls (memory edits, searches)
const toolCalls = response.messages.filter(
  msg => msg.message_type === 'tool_call_message'
);

return {
  json: {
    agent_reply: assistantMessage?.content || "No response",
    agent_thoughts: reasoning.map(r => r.content),
    memory_edits: toolCalls.map(t => ({
      tool: t.tool_call?.name,
      args: t.tool_call?.arguments
    })),
    usage: response.usage
  }
};

// 4. Respond to User Node
Response:
  reply: {{ $json.agent_reply }}
  
// The agent automatically saved all context - next time user chats,
// agent will remember this entire conversation
```

#### Example 3: Agent with Custom Tools

Create an agent with access to external APIs and tools:

```javascript
// n8n Workflow: Letta Agent with Custom Tools

// 1. HTTP Request - Create Agent with Tools
Method: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "Research Assistant",
  "model": "anthropic/claude-4.5-sonnet-20250929",
  "embedding": "openai/text-embedding-3-small",
  "memory_blocks": [
    {
      "label": "human",
      "value": "Researcher working on AI safety"
    },
    {
      "label": "persona",
      "value": "I am a research assistant specialized in AI safety. I can search the web, read papers, and maintain comprehensive notes about research topics."
    }
  ],
  "tools": [
    "send_message",
    "core_memory_replace",
    "archival_memory_insert",
    "archival_memory_search",
    "web_search",
    "read_arxiv_paper",
    "save_research_notes"
  ]
}

// Note: Custom tools (web_search, read_arxiv_paper, save_research_notes)
// must be registered in Letta server first

// 2. User sends: "Find recent papers on Claude 4 and summarize key findings"

// 3. Agent will:
// - Use web_search tool to find papers
// - Use read_arxiv_paper to extract content
// - Save findings to archival_memory_insert
// - Reply with summary using send_message

// 4. Later, user asks: "What did we find about Claude 4?"

// 5. Agent will:
// - Use archival_memory_search to retrieve past findings
// - Provide comprehensive answer based on saved research
// - No need to search web again - it's in agent's memory
```

#### Example 4: Multi-Agent with Shared Memory

Create multiple agents sharing the same memory block:

```javascript
// n8n Workflow: Multi-Agent System

// 1. HTTP Request - Create Shared Memory Block
Method: POST
URL: http://letta:8283/v1/blocks
Body:
{
  "label": "project_knowledge",
  "value": "Project: AI CoreKit\nStatus: Active\nTeam members: Alice, Bob\nKey decisions: ..."
}

// Response: { "id": "block-shared-123" }

// 2. HTTP Request - Create Agent 1 (Developer)
Method: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "Developer Agent",
  "model": "openai/gpt-4.1",
  "memory_blocks": [
    { "label": "persona", "value": "I am a developer agent focused on code implementation." },
    { "id": "block-shared-123" }  // Reference shared block
  ],
  "tools": ["send_message", "core_memory_replace", "run_code", "git_commit"]
}

// 3. HTTP Request - Create Agent 2 (Product Manager)
Method: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "PM Agent",
  "model": "openai/gpt-4.1",
  "memory_blocks": [
    { "label": "persona", "value": "I am a product manager agent focused on requirements and planning." },
    { "id": "block-shared-123" }  // Same shared block
  ],
  "tools": ["send_message", "core_memory_replace", "create_task", "update_roadmap"]
}

// Now both agents share the "project_knowledge" memory block
// When one agent updates it, the other agent sees the changes
// Perfect for coordinated multi-agent workflows
```

#### Example 5: Export and Import Agents (.af files)

Checkpoint agents and move them between servers:

```javascript
// n8n Workflow: Backup and Restore Agents

// 1. HTTP Request - Export Agent to .af file
Method: GET
URL: http://letta:8283/v1/agents/{{ $json.agent_id }}/export
Response Format: File

// Save the .af file to storage (Google Drive, S3, etc.)

// 2. Later: Import Agent from .af file
Method: POST
URL: http://letta:8283/v1/agents/import
Headers:
  Content-Type: multipart/form-data
Body:
  file: {{ $binary.data }}

// Agent is restored with complete state:
// - All memory blocks
// - Full conversation history
// - Tool configurations
// - Exact same personality

// Use cases:
// - Backup critical agents
// - Move agents between Letta Cloud and self-hosted
// - Version control for agent development
// - Share agents with team members
```

### Troubleshooting

**Issue 1: Letta Server Won't Start**

```bash
# Check Letta container logs
docker logs letta --tail 100

# Common errors:
# 1. "Could not connect to PostgreSQL"
# Solution: Ensure PostgreSQL is running
docker ps | grep postgres

# 2. "Invalid model configuration"
# Solution: Check .env file has valid model endpoints
grep LETTA_ .env

# 3. Port 8283 already in use
# Solution: Change port in docker-compose.yml or kill process using port
sudo lsof -i :8283
docker compose restart letta
```

**Issue 2: Agent Not Remembering Past Conversations**

```bash
# Check if agent has proper memory blocks
curl http://letta:8283/v1/agents/{agent_id} | jq '.memory_blocks'

# Verify PostgreSQL persistence is enabled
docker exec letta env | grep DATABASE_URL

# Check if agent state is being saved
curl http://letta:8283/v1/agents/{agent_id}/messages | jq '.messages | length'
# Should show all past messages

# If memory is lost: Agent was likely recreated instead of reused
# Always save agent_id and reuse the same agent for persistent memory
```

**Issue 3: API Returns 401 Unauthorized**

```bash
# For self-hosted with password:
# Verify password is correct
grep LETTA_SERVER_PASS .env

# Test authentication
curl -H "Authorization: Bearer YOUR_PASSWORD" \
  http://letta:8283/v1/agents

# For Letta Cloud:
# Verify API key is valid
curl -H "Authorization: Bearer LETTA_API_KEY" \
  https://api.letta.com/v1/agents
```

**Issue 4: Agent Responses are Slow**

```bash
# Check which LLM model is being used
# Faster models: gpt-4.o-mini, claude-haiku, llama-3.1-8b (via Groq)
# Slower models: o1-preview, gpt-4, claude-opus

# Check if using local Ollama
docker exec letta curl http://ollama:11434/api/tags

# For faster inference: Use Groq with Llama models
# In ADE: Settings → Models → Add Groq provider

# Monitor token usage
docker logs letta | grep "tokens"
# High token counts = slower responses
```

**Issue 5: Memory Blocks Not Updating**

```bash
# Verify agent has the correct tools enabled
curl http://letta:8283/v1/agents/{agent_id} | jq '.tools'

# Should include: core_memory_append, core_memory_replace

# Check if agent is actually using the tools
curl http://letta:8283/v1/agents/{agent_id}/messages | jq '.messages[] | select(.message_type=="tool_call_message")'

# If no tool calls: Agent may need better prompting or different model
# Try using a more capable model (gpt-4.1, claude-4.5-sonnet)
```

**Issue 6: Can't Access Agent Development Environment**

```bash
# Check if Letta is running
docker ps | grep letta

# Test ADE endpoint
curl http://localhost:8283/
# Should return HTML

# Check Caddy proxy configuration
docker exec caddy cat /etc/caddy/Caddyfile | grep letta

# Restart both services
docker compose restart letta caddy
```

### Resources

- **Official Website:** https://www.letta.com
- **Documentation:** https://docs.letta.com
- **GitHub Repository:** https://github.com/letta-ai/letta
- **Agent Development Environment (ADE):** https://docs.letta.com/ade
- **API Reference:** https://docs.letta.com/api-reference
- **Python SDK:** https://github.com/letta-ai/letta-python
- **TypeScript SDK:** https://github.com/letta-ai/letta-node
- **Agent File Format (.af):** https://github.com/letta-ai/agent-file
- **Letta Cloud (Hosted):** https://app.letta.com
- **Quickstart Tutorial:** https://docs.letta.com/quickstart
- **Memory System Guide:** https://docs.letta.com/guides/agents/memory
- **Tool Integration:** https://docs.letta.com/guides/agents/tools
- **Discord Community:** https://discord.gg/letta-ai
- **Blog (Stateful Agents):** https://www.letta.com/blog/stateful-agents
- **Research Paper (MemGPT):** https://arxiv.org/abs/2310.08560

### Key Concepts

**Stateful vs Stateless:**
- Traditional LLMs: Stateless, forget after session ends
- Letta Agents: Stateful, permanent memory across all sessions

**Memory Hierarchy:**
- Core Memory: Always in context window (persona, human blocks)
- Archival Memory: Infinite storage, searchable with embeddings
- Recall Memory: All past conversations, searchable database

**Agent Persistence:**
- Agents exist permanently on Letta server
- All state automatically saved to PostgreSQL
- Agents continue to exist even when your app isn't running

**Tool-Based Memory Management:**
- Agents control their own memory via tools
- core_memory_append: Add to memory blocks
- core_memory_replace: Update memory blocks
- archival_memory_insert: Save to long-term storage
- conversation_search: Search past messages

**Model Context Protocol (MCP) Support:**
- Connect to MCP servers for pre-built tools
- Use standardized tool libraries
- Seamless integration with MCP ecosystem

```

### Memory Management Best Practices

**Core Memory:**
- Keep concise (2000-4000 chars per block)
- Use structured format (Name: X\nRole: Y)
- Update regularly as agent learns
- Use `core_memory_replace` for corrections

**Archival Memory:**
- Store facts that don't fit in core memory
- Use for knowledge base articles
- Include metadata for better search
- Regular cleanup of outdated information

**Recall Memory:**
- Automatically stores all conversations
- Use `conversation_search` to find past interactions
- Helpful for returning customers
- No manual management needed

### Troubleshooting

**Agent not persisting memory:**

```bash
# 1. Check agent was created successfully
curl http://letta:8283/v1/agents/{agent_id}

# 2. Verify memory blocks exist
curl http://letta:8283/v1/agents/{agent_id}/memory

# 3. Check agent has memory tools enabled
# Agent needs: core_memory_append, core_memory_replace

# 4. View agent's full state
# In ADE: Open agent → View Memory tab

# 5. Check database persistence
docker logs letta | grep "checkpoint"
```

**Connection refused:**

```bash
# 1. Check Letta server is running
docker ps | grep letta

# Should show: letta container on port 8283

# 2. Test API endpoint
curl http://localhost:8283/v1/health
# Should return: {"status": "ok"}

# 3. Check logs
docker logs letta --tail 50

# 4. Verify internal DNS in n8n
docker exec n8n ping letta

# 5. Restart if needed
docker compose restart letta
```

**Agent responses are slow:**

```bash
# 1. Check which model is being used
# Larger models (gpt-4o) are slower than smaller (gpt-4o-mini)

# 2. Switch to faster model
# Update agent's model via ADE or API:
curl -X PATCH http://letta:8283/v1/agents/{agent_id} \
  -d '{"llm_config": {"model": "openai/gpt-4o-mini"}}'

# 3. Use local Ollama for fastest responses
# Model: ollama/llama3.2

# 4. Check if agent is searching too much memory
# Reduce archival memory size or optimize searches

# 5. Monitor resource usage
docker stats letta
```

**Memory blocks not updating:**

```bash
# 1. Verify agent has correct tools
curl http://letta:8283/v1/agents/{agent_id}/tools

# Should include:
# - core_memory_append
# - core_memory_replace

# 2. Check agent's system prompt
# Must instruct agent to use memory tools

# 3. View agent's reasoning
# In ADE: Check "inner monologue" to see if agent tried to edit memory

# 4. Test memory edit directly
curl -X POST http://letta:8283/v1/agents/{agent_id}/memory/core \
  -d '{"human": "Updated information..."}'

# 5. Check memory block limits
# If block is full (hit limit), edits may fail
```

**Agent forgetting across sessions:**

```bash
# This should NOT happen with Letta - that's the whole point!

# If it does:
# 1. Verify you're using the same agent_id
echo "Agent ID: {agent_id}"

# 2. Check agent still exists
curl http://letta:8283/v1/agents/{agent_id}

# 3. View agent's memory after restart
curl http://letta:8283/v1/agents/{agent_id}/memory

# 4. Check database persistence
# Letta uses PostgreSQL by default
docker exec letta-db psql -U letta -d letta -c "SELECT id, name FROM agents;"

# 5. Verify Docker volumes are persisted
docker volume ls | grep letta
```

### Resources

- **Official Website:** https://www.letta.com/
- **Documentation:** https://docs.letta.com/
- **GitHub:** https://github.com/letta-ai/letta
- **Python SDK:** https://github.com/letta-ai/letta-python
- **TypeScript SDK:** https://github.com/letta-ai/letta-typescript
- **Agent File Format:** https://github.com/letta-ai/agent-file
- **Discord Community:** https://discord.gg/letta
- **Blog:** https://www.letta.com/blog
- **Research Paper (MemGPT):** https://arxiv.org/abs/2310.08560

### Key Differences from Other Frameworks

**Letta vs. LangChain:**
- LangChain: Stateless library, requires external state management
- Letta: Stateful service, handles memory automatically

**Letta vs. AutoGPT:**
- AutoGPT: Task-focused, limited memory
- Letta: Session-persistent, evolving memory

**Letta vs. OpenAI Assistants:**
- OpenAI: Vendor lock-in, closed system
- Letta: Model-agnostic, full transparency, self-hostable

**Letta vs. Traditional Chatbots:**
- Traditional: Forget after context window fills
- Letta: Remember indefinitely, self-edit memory

### Advanced Features

**Sleep-Time Compute:**
- Agents can "think" while idle
- Refine memories during downtime
- Precompute responses for common queries
- Multi-model setups (cheap model for reflection, expensive for responses)

**Agent Templates:**
- Create reusable agent configurations
- Apply templates to spawn new agents quickly
- Version and upgrade agent designs
- Rollback to previous versions

**Tool Rules:**
- Constrain agent behavior explicitly
- Define which tools can be used when
- Create deterministic or autonomous agents
- Balance reliability and flexibility

**Model Context Protocol (MCP) Support:**
- Connect to MCP servers for pre-built tools
- Use standardized tool libraries
- Seamless integration with MCP ecosystem
