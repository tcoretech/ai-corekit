# 🔧 n8n - Workflow Automation Platform

### What is n8n?

n8n is a powerful, extendable workflow automation platform that lets you connect anything to everything via its open, fair-code model. It's the heart of AI LaunchKit, orchestrating all integrations between the 50+ services.

### Features

- **400+ Integrations:** Pre-built nodes for popular services
- **Visual Workflow Editor:** Drag-and-drop interface for building automations
- **Custom Code Execution:** JavaScript/Python nodes for complex logic
- **Self-Hosted:** Full data control, no external dependencies
- **Active Community:** 300+ pre-built workflow templates included
- **Advanced Scheduling:** Cron expressions, intervals, webhook triggers
- **Error Handling:** Built-in retry logic, error workflows, monitoring

### Initial Setup

**First Login to n8n:**

1. Navigate to `https://n8n.yourdomain.com`
2. **First visitor becomes owner** - Create your admin account
3. Set strong password (minimum 8 characters)
4. Setup complete!

**Generate API Key (for external integrations):**

1. Click your profile (bottom left)
2. Settings → API
3. Create new API Key
4. Save securely - used for n8n-MCP and external automations

### n8n Integration Setup

n8n integrates with itself and other AI LaunchKit services:

#### Connect to Internal Services

**All services are pre-configured with internal URLs:**

```javascript
// PostgreSQL (internal database)
Host: postgres
Port: 5432
Database: n8n
User: n8n
Password: [from .env file]

// Redis (queue management)
Host: redis
Port: 6379

// Ollama (local LLMs)
Base URL: http://ollama:11434

// Mailpit (email testing)
SMTP Host: mailpit
SMTP Port: 1025
```

#### API Access from External Tools

```bash
# n8n API endpoint (external)
https://n8n.yourdomain.com/api/v1

# Authentication header
Authorization: Bearer YOUR_API_KEY

# Example: List all workflows
curl -X GET https://n8n.yourdomain.com/api/v1/workflows \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Example Workflows

#### Example 1: AI Email Processing Pipeline

Complete workflow for intelligent email handling:

```javascript
// 1. Email (IMAP) Trigger Node
Host: mailserver (or mailpit for testing)
Port: 993
TLS: Enabled
Check for new emails every: 1 minute

// 2. Code Node - Extract Email Data
const email = {
  from: $json.from.value[0].address,
  subject: $json.subject,
  body: $json.textPlain || $json.html,
  date: $json.date,
  attachments: $json.attachments ? $json.attachments.length : 0
};

// Classify email priority
const urgent = /urgent|asap|important/i.test(email.subject);
email.priority = urgent ? 'high' : 'normal';

return { json: email };

// 3. OpenAI Node - Analyze Email Content
Operation: Message a Model
Model: gpt-4o-mini
Messages:
  System: "You are an email classification assistant. Categorize emails into: Support, Sales, General, Spam"
  User: "Subject: {{$json.subject}}\n\nBody: {{$json.body}}"

// 4. Switch Node - Route by Category
Mode: Rules
Rules:
  - category equals "Support" → Route to support workflow
  - category equals "Sales" → Route to CRM
  - category equals "Spam" → Delete
  - default → Archive

// 5a. Support Route: Create Ticket
// HTTP Request to ticketing system
Method: POST
URL: http://baserow:8000/api/database/rows/table/tickets/
Body: {
  "title": "{{$('Extract Email').json.subject}}",
  "description": "{{$('Extract Email').json.body}}",
  "customer_email": "{{$('Extract Email').json.from}}",
  "priority": "{{$('Extract Email').json.priority}}",
  "status": "New"
}

// 6. Send Email Node - Auto-Reply
To: {{$('Extract Email').json.from}}
Subject: Re: {{$('Extract Email').json.subject}}
Message: |
  Thank you for contacting us!
  
  Your ticket #{{$json.id}} has been created.
  Our team will respond within 24 hours.
  
  Best regards,
  Support Team
```

#### Example 2: Multi-Service Data Sync

Sync data across multiple services automatically:

```javascript
// 1. Schedule Trigger Node
Trigger Interval: Every 15 minutes
Cron Expression: */15 * * * *

// 2. HTTP Request - Get New Customers from Supabase
Method: GET
URL: http://supabase-kong:8000/rest/v1/customers
Headers:
  apikey: {{$env.SUPABASE_ANON_KEY}}
  Authorization: Bearer {{$env.SUPABASE_ANON_KEY}}
Query Parameters:
  select: *
  created_at: gte.{{$now.minus(15, 'minutes').toISO()}}

// 3. Loop Over Items Node
// Process each new customer

// 4. Branch 1: Create in CRM (Twenty)
HTTP Request Node
Method: POST
URL: http://twenty:3000/graphql
Body (GraphQL):
mutation {
  createPerson(data: {
    firstName: "{{$json.first_name}}"
    lastName: "{{$json.last_name}}"
    email: "{{$json.email}}"
    phone: "{{$json.phone}}"
    companyId: "{{$json.company_id}}"
  }) {
    id
  }
}

// 5. Branch 2: Add to Mailing List (Mautic)
HTTP Request Node  
Method: POST
URL: http://mautic_web/api/contacts/new
Body: {
  "email": "{{$json.email}}",
  "firstname": "{{$json.first_name}}",
  "lastname": "{{$json.last_name}}",
  "tags": ["new-customer", "supabase-sync"]
}

// 6. Branch 3: Create Project (Leantime)
HTTP Request Node
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.projects.addProject",
  "params": {
    "values": {
      "name": "Onboarding - {{$json.company_name}}",
      "clientId": 1,
      "state": 0
    }
  },
  "id": 1
}

// 7. Slack Notification
Channel: #new-customers
Message: |
  🎉 New Customer Added!
  
  Name: {{$json.first_name}} {{$json.last_name}}
  Email: {{$json.email}}
  Company: {{$json.company_name}}
  
  Actions completed:
  ✅ Added to CRM
  ✅ Added to mailing list
  ✅ Onboarding project created
```

#### Example 3: AI Content Generation Pipeline

Generate and publish content automatically:

```javascript
// 1. Schedule Trigger
Trigger: Weekly on Monday at 10 AM

// 2. Code Node - Define Content Topics
const topics = [
  "AI automation trends",
  "Self-hosted tools benefits",
  "Workflow optimization tips",
  "Data privacy best practices"
];

// Random topic selection
const randomTopic = topics[Math.floor(Math.random() * topics.length)];

return {
  json: {
    topic: randomTopic,
    date: new Date().toISOString()
  }
};

// 3. OpenAI Node - Generate Blog Post
Operation: Message a Model
Model: gpt-4o
Messages:
  System: "You are a technical content writer specializing in AI and automation."
  User: |
    Write a comprehensive blog post about: {{$json.topic}}
    
    Requirements:
    - 800-1000 words
    - Include practical examples
    - SEO-optimized with relevant keywords
    - Engaging tone for technical audience
    - Include 3-5 actionable takeaways

// 4. OpenAI Node - Generate Social Media Posts
Operation: Message a Model
Model: gpt-4o-mini
Messages:
  User: |
    Create social media posts for this blog:
    {{$('Generate Blog Post').json.choices[0].message.content}}
    
    Create:
    1. LinkedIn post (max 1300 characters)
    2. Twitter thread (3-5 tweets)
    3. Instagram caption (max 2200 characters)

// 5. HTTP Request - Publish to WordPress/Ghost
Method: POST
URL: http://wordpress:80/wp-json/wp/v2/posts
Headers:
  Authorization: Basic {{$env.WORDPRESS_AUTH}}
Body: {
  "title": "{{$json.topic}}",
  "content": "{{$('Generate Blog Post').json.content}}",
  "status": "draft",
  "categories": [1]
}

// 6. Postiz Node - Schedule Social Posts
// Use native Postiz node or HTTP requests
// Schedule LinkedIn, Twitter, Instagram posts

// 7. Slack Notification
Channel: #content-team
Message: |
  📝 New Blog Post Generated!
  
  Topic: {{$('Define Topics').json.topic}}
  Status: Draft (ready for review)
  WordPress: {{$('Publish').json.link}}
  
  Social posts scheduled ✅
```

### ⚠️ BREAKING CHANGES - Migration Required

**If you have existing Python Code Nodes**, they need to be updated:

**OLD (Pyodide - no longer works):**
```python
# Dot notation
name = item.json.customer.name
for item in items:  # items variable
```

**NEW (Native Python - required):**
```python
# Bracket notation
name = item["json"]["customer"]["name"]
for item in _items:  # _items variable (underscore!)
```

**Why this change?**
- n8n switched from Pyodide (WebAssembly) to native Python
- Native Python is 10-20x faster and supports all Python packages
- Pyodide accepted non-standard syntax that native Python doesn't

**Migration Steps:**
1. Open each Python Code Node in your workflows
2. Replace `item.json` with `item["json"]`
3. Replace `items` with `_items`
4. Test the workflow
5. See full migration guide below

---

### Troubleshooting

**Workflows not executing:**

```bash
# 1. Check n8n container status
docker ps | grep n8n

# 2. Check n8n logs
docker logs n8n --tail 100

# 3. Check worker processes
docker logs n8n-worker --tail 100

# 4. Verify Redis connection
docker exec n8n nc -zv redis 6379

# 5. Check PostgreSQL connection
docker exec n8n nc -zv postgres 5432
```

**"Service not reachable" errors:**

```bash
# 1. Verify internal service is running
docker ps | grep [service-name]

# 2. Test internal DNS resolution
docker exec n8n ping [service-name]

# 3. Check Docker network
docker network inspect ai-launchkit_default

# 4. Verify port is correct
docker port [service-name]

# 5. Check service logs
docker logs [service-name] --tail 50
```

**Memory/Performance issues:**

```bash
# 1. Check resource usage
docker stats n8n --no-stream

# 2. Check worker count
grep N8N_WORKER_COUNT .env

# 3. Increase memory limit (if needed)
# Edit docker-compose.yml:
# mem_limit: 2g

# 4. Optimize workflows
# - Use pagination for large datasets
# - Add Wait nodes between bulk operations
# - Split complex workflows into smaller ones

# 5. Clear execution data
docker exec n8n n8n clear:executions --all
```

**Credential authentication failures:**

```bash
# 1. Check credential configuration
# In n8n: Credentials → Test Connection

# 2. Verify environment variables
docker exec n8n printenv | grep [SERVICE]

# 3. Check internal URLs
# Use service name, not localhost
# ✅ http://mailserver:587
# ❌ http://localhost:587

# 4. Recreate credential
# Delete and recreate in n8n UI

# 5. Restart n8n
docker compose restart n8n
```

**Webhook not receiving data:**

```bash
# 1. Test webhook URL
curl -X POST https://n8n.yourdomain.com/webhook-test/your-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# 2. Check Caddy logs
docker logs caddy | grep webhook

# 3. Verify webhook is active
# n8n → Workflow → Webhook node → Check "Listening"

# 4. Check firewall
sudo ufw status | grep 443

# 5. Test from external service
# Verify webhook URL is accessible from internet
```

### Resources

- **Official Documentation:** https://docs.n8n.io/
- **Community Forum:** https://community.n8n.io/
- **Workflow Templates:** https://n8n.io/workflows
- **API Documentation:** https://docs.n8n.io/api/
- **YouTube Tutorials:** https://www.youtube.com/@n8n-io
- **GitHub:** https://github.com/n8n-io/n8n

### Best Practices

**Workflow Organization:**
- Use descriptive workflow names
- Add notes to complex nodes
- Group related nodes with sticky notes
- Use consistent naming for credentials
- Version control: Export workflows as JSON

**Performance Optimization:**
- Use batch processing for large datasets
- Add Wait nodes between API calls
- Implement error handling with Try/Catch nodes
- Use pagination for API requests
- Monitor execution times

**Security:**
- Never hardcode credentials in workflows
- Use environment variables for sensitive data
- Implement webhook authentication
- Regularly rotate API keys
- Review workflow permissions

**Maintenance:**
- Regularly check error executions
- Monitor workflow execution times
- Update community nodes
- Backup workflows weekly
- Document complex logic in notes


### What is n8n-MCP?

n8n-MCP enables AI assistants like Claude Desktop and Cursor to generate complete n8n workflows through natural language. It provides access to documentation for 525+ n8n nodes, allowing AI tools to understand node properties, authentication requirements, and configuration options.

n8n-MCP implements the Model Context Protocol (MCP) standard, making it compatible with any MCP-enabled AI tool.

### Features

- **Complete node documentation** - Properties, authentication, and examples for 525+ nodes
- **Workflow generation** - Create complex automations from natural language prompts
- **Validation** - Ensures correct node configuration before deployment
- **99% coverage** - Supports nearly all n8n node properties and settings
- **MCP standard** - Works with any MCP-compatible AI tool (Claude, Cursor, etc.)

### Initial Setup

**Access n8n-MCP:**
- **External URL:** `https://n8nmcp.yourdomain.com`
- **Internal URL:** `http://n8nmcp:3000`
- **Token:** Found in `.env` file as `N8N_MCP_TOKEN`

**No web interface** - n8n-MCP is a backend service accessed through AI tools.

### Setup with Claude Desktop

**1. Locate Claude Desktop Config File:**

**macOS/Linux:**
```bash
~/.config/claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**2. Configure Claude Desktop:**

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["@czlonkowski/n8n-mcp-client"],
      "env": {
        "N8N_MCP_URL": "https://n8nmcp.yourdomain.com",
        "N8N_MCP_TOKEN": "your-token-from-env-file",
        "N8N_API_URL": "https://n8n.yourdomain.com",
        "N8N_API_KEY": "your-n8n-api-key"
      }
    }
  }
}
```

**3. Restart Claude Desktop**

### Setup with Cursor IDE

**Create `.cursor/mcp_config.json` in your project:**

```json
{
  "servers": {
    "n8n-mcp": {
      "url": "https://n8nmcp.yourdomain.com",
      "token": "your-token-from-env-file"
    }
  }
}
```

### Example Prompts for Claude/Cursor

#### Basic Automation

```
"Create an n8n workflow that monitors a Gmail inbox for invoices, 
extracts data using AI, and saves to Google Sheets"
```

**Claude will:**
1. Use n8n-MCP to look up node documentation
2. Generate complete workflow JSON
3. Configure all node properties correctly
4. Include authentication requirements
5. Provide deployment instructions

#### Complex Integration

```
"Build a workflow that:
1. Triggers on new Stripe payment
2. Creates invoice in QuickBooks
3. Sends receipt via SendGrid
4. Updates customer in Airtable
5. Posts to Slack channel"
```

**Result:** Complete workflow with all nodes configured, including:
- Webhook trigger
- API credentials
- Data transformations
- Error handling
- Notification logic

#### AI Pipeline

```
"Design a content pipeline that takes YouTube videos, 
transcribes with Whisper, summarizes with GPT-4, 
and posts to WordPress with SEO optimization"
```

**Claude generates:**
- YouTube data extraction
- Whisper transcription node
- OpenAI summarization
- WordPress API integration
- SEO metadata generation

### Available MCP Commands

n8n-MCP provides these commands to AI assistants:

**`list_nodes`** - Get all available n8n nodes
```json
Response: {
  "nodes": ["HTTP Request", "Code", "IF", "Gmail", "Slack", ...]
}
```

**`get_node_docs`** - Full documentation for specific node
```json
Request: { "node": "HTTP Request" }
Response: {
  "properties": [...],
  "authentication": [...],
  "examples": [...]
}
```

**`validate_workflow`** - Check workflow configuration
```json
Request: { "workflow": {...} }
Response: {
  "valid": true,
  "errors": []
}
```

**`suggest_nodes`** - Get node recommendations for task
```json
Request: { "task": "send email with attachment" }
Response: {
  "nodes": ["Gmail", "Send Email", "IMAP"],
  "reasoning": "..."
}
```

### n8n Integration

**HTTP Request to n8n-MCP from n8n workflow:**

```javascript
// HTTP Request Node Configuration
Method: POST
URL: https://n8nmcp.yourdomain.com/generate
Authentication: Header Auth
  Header: Authorization
  Value: Bearer {{$env.N8N_MCP_TOKEN}}
  
Body (JSON):
{
  "prompt": "Create workflow to sync Notion database with Google Calendar",
  "target_n8n": "https://n8n.yourdomain.com",
  "auto_import": true
}

// Response:
{
  "workflow": {...},
  "import_url": "https://n8n.yourdomain.com/workflows/import",
  "validation": { "valid": true }
}
```

### Example: AI-Generated Workflow

**Prompt to Claude:**
```
"Create an n8n workflow that:
1. Watches a folder in Google Drive
2. When a new PDF is added, extract text with OCR
3. Summarize the content with OpenAI
4. Create a task in Vikunja with the summary
5. Send notification to Slack"
```

**Claude with n8n-MCP generates:**

```javascript
// 1. Google Drive Trigger Node
Trigger: On File Created
Folder: "/Invoices"
File Type: PDF

// 2. HTTP Request Node - OCR Service
Method: POST
URL: http://tesseract:8000/ocr
Body: 
  file: {{$binary.data}}
  language: eng

// 3. OpenAI Node - Summarization
Operation: Message a Model
Model: gpt-4o-mini
System Message: "Summarize this invoice in 2-3 sentences"
User Message: {{$json.text}}

// 4. HTTP Request Node - Vikunja API
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Headers:
  Authorization: Bearer {{$credentials.vikunjaToken}}
Body:
{
  "title": "Invoice: {{$('Google Drive').json.name}}",
  "description": "{{$json.summary}}",
  "project_id": 1
}

// 5. Slack Node
Operation: Send Message
Channel: #finance
Message: |
  New invoice processed:
  File: {{$('Google Drive').json.name}}
  Summary: {{$('OpenAI').json.summary}}
  Task: {{$('Vikunja').json.link}}
```

### Tips for Best Results

**Be Specific:**
```
❌ "Create a workflow to process emails"
✅ "Create a workflow that reads unread Gmail emails, 
   extracts attachments, uploads to Google Drive, 
   and marks email as read"
```

**Include Tool Names:**
```
❌ "Send data to my CRM"
✅ "Send data to Odoo CRM via HTTP Request node"
```

**Provide Sample Data:**
```
"Process customer data like:
{
  'name': 'John Doe',
  'email': 'john@example.com',
  'company': 'Acme Corp'
}"
```

**Iterate Through Conversation:**
```
1. "Create workflow to process invoices"
2. [Claude generates initial workflow]
3. "Add error handling and retry logic"
4. [Claude enhances workflow]
5. "Add notification to Microsoft Teams instead of Slack"
6. [Claude updates notification node]
```

### Workflow Version Control

**Export Workflows as JSON:**

```bash
# After AI generates workflow, export it
curl -X GET https://n8n.yourdomain.com/api/v1/workflows/123 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  > workflow-v1.json

# Commit to Git
git add workflow-v1.json
git commit -m "Add AI-generated invoice processing workflow"
```

### Troubleshooting

**Connection refused:**
```bash
# Check n8n-MCP is running
docker ps | grep n8nmcp

# Check token in .env
grep N8N_MCP_TOKEN .env

# Test connection
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://n8nmcp.yourdomain.com/health
```

**Invalid workflow generated:**
```bash
# Use validation endpoint
curl -X POST https://n8nmcp.yourdomain.com/validate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"workflow": {...}}'

# Check n8n-MCP logs
docker logs n8nmcp --tail 100
```

**Missing node documentation:**
```bash
# Update n8n-MCP to latest version
docker compose pull n8nmcp
docker compose up -d n8nmcp

# Rebuild node cache
docker exec n8nmcp npm run rebuild-cache
```

**Timeout errors:**
```bash
# Increase timeout in MCP client config
{
  "mcpServers": {
    "n8n-mcp": {
      ...
      "timeout": 60000
    }
  }
}
```

### Resources

- **Documentation:** https://github.com/czlonkowski/n8n-mcp
- **MCP Protocol:** https://modelcontextprotocol.io
- **n8n API Reference:** https://docs.n8n.io/api/
- **Community Examples:** https://n8n.io/workflows (filter by "AI-generated")

### Best Practices

**Prompt Engineering:**
- Start with high-level description
- Add details incrementally
- Test each addition
- Use real data examples
- Specify error handling requirements

**Security:**
- Never include credentials in prompts
- Use n8n credential system
- Validate AI-generated workflows before production
- Review generated code for security issues

**Maintenance:**
- Export workflows to Git after generation
- Document prompt used to generate workflow
- Test generated workflows thoroughly
- Keep n8n-MCP updated for latest node support

**Performance:**
- Break complex workflows into smaller ones
- Use webhook triggers instead of polling where possible
- Implement rate limiting for external APIs
- Monitor workflow execution times


### What is Flowise?

Flowise is an open-source visual AI agent builder that allows you to create sophisticated AI applications using a drag-and-drop interface. Built on top of LangChain, it enables developers and non-developers alike to build chatbots, conversational agents, RAG systems, and multi-agent workflows without writing extensive code. Think of it as "Figma for AI backend applications."

### Features

- **Visual Workflow Builder** - Drag-and-drop interface for building AI agents and LLM flows
- **Multi-Agent Systems** - Create teams of specialized AI agents with supervisor coordination
- **RAG Support** - Connect to documents, databases, and knowledge bases for context-aware responses
- **Tool Calling** - Agents can use external tools, APIs, and functions dynamically
- **Memory Management** - Conversational memory and context retention across sessions
- **Multiple LLM Support** - Works with OpenAI, Anthropic, Ollama, Groq, and 50+ other providers
- **Pre-built Templates** - Start from ready-made templates for common use cases
- **Assistant Mode** - Beginner-friendly way to create AI agents with file upload RAG
- **AgentFlow V2** - Advanced sequential workflows with loops, conditions, and human-in-the-loop
- **Streaming Support** - Real-time response streaming for better UX
- **Embed Anywhere** - Generate embeddable chat widgets for websites

### Initial Setup

**First Login to Flowise:**

1. Navigate to `https://flowise.yourdomain.com`
2. **First user becomes admin** - Create your account
3. Set strong password
4. Setup complete!

**Quick Start:**

1. Click **Add New** → Select **Assistant** (easiest) or **Chatflow** (flexible)
2. Choose a template or start from scratch
3. Add nodes by dragging from left sidebar
4. Connect nodes to create your flow
5. Configure each node (LLM, prompts, tools, etc.)
6. Click **Save** then **Deploy**
7. Test in the chat interface

### Three Ways to Build in Flowise

**1. Assistant (Beginner-Friendly)**
- Simple interface for creating AI assistants
- Upload files for automatic RAG
- Follow instructions and use tools
- Best for: Simple chatbots, document Q&A

**2. Chatflow (Flexible)**
- Full control over LLM chains
- Advanced techniques: Graph RAG, Reranker, Retriever
- Best for: Custom workflows, complex logic

**3. AgentFlow (Most Powerful)**
- Multi-agent systems with supervisor orchestration
- Sequential workflows with branching
- Loops and conditions
- Human-in-the-loop capabilities
- Best for: Complex automation, enterprise workflows

### Building Your First Agent

**Simple Chatbot with RAG:**

1. **Create New Assistant:**
   - Click **Add New** → **Assistant**
   - Name it: "Document Q&A Bot"

2. **Configure Settings:**
   - **Model**: Select `gpt-4o` (or `llama3.2` via Ollama)
   - **Instructions**: 
     ```
     You are a helpful assistant that answers questions based on uploaded documents.
     If you don't know the answer, say so - don't make up information.
     ```

3. **Upload Documents:**
   - Click **Upload Files**
   - Add PDFs, DOCX, TXT files
   - Flowise automatically creates vector embeddings

4. **Test:**
   - Click **Chat** icon
   - Ask: "What are the main points in the uploaded document?"
   - Agent retrieves relevant chunks and answers

5. **Deploy:**
   - Click **Deploy**
   - Get API endpoint and embed code

### Multi-Agent Systems

**Supervisor + Workers Pattern:**

Flowise supports hierarchical multi-agent systems where a Supervisor agent coordinates multiple Worker agents:

```
User Request
    ↓
Supervisor Agent (coordinates tasks)
    ↓
    ├─→ Worker 1: Research Agent (searches web)
    ├─→ Worker 2: Analyst Agent (analyzes data)
    └─→ Worker 3: Writer Agent (creates reports)
    ↓
Supervisor aggregates results
    ↓
Final Response
```

**Creating a Multi-Agent System:**

1. **Create Workers First:**
   - Research Agent: Add Google Search Tool
   - Analyst Agent: Add Code Interpreter Tool
   - Writer Agent: Specialized prompt for writing

2. **Create Supervisor:**
   - Add **Supervisor Agent** node
   - Connect all Worker nodes
   - Configure delegation logic

3. **Example - Lead Research System:**
   - **Worker 1 (Lead Researcher)**: Uses Google Search to find company info
   - **Worker 2 (Email Writer)**: Creates personalized outreach emails
   - **Supervisor**: Coordinates research → email generation workflow

### n8n Integration

**Call Flowise Agents from n8n:**

Flowise exposes a REST API that n8n can call using HTTP Request nodes.

**Get Flowise API Details:**

1. In Flowise, open your deployed Chatflow/Agentflow
2. Click **API** tab
3. Copy:
   - **Endpoint URL**: `https://flowise.yourdomain.com/api/v1/prediction/{FLOW_ID}`
   - **API Key**: Generate in Settings → API Keys

**n8n HTTP Request Configuration:**

```javascript
// HTTP Request Node
Method: POST
URL: https://flowise.yourdomain.com/api/v1/prediction/{{FLOW_ID}}
Authentication: Header Auth
  Header Name: Authorization
  Header Value: Bearer {{YOUR_FLOWISE_API_KEY}}

Body (JSON):
{
  "question": "{{$json.user_query}}",
  "overrideConfig": {
    // Optional: Override chatflow parameters
  }
}

// Response structure:
{
  "text": "AI agent response...",
  "chatId": "uuid-here",
  "messageId": "uuid-here"
}
```

### Example Workflows

#### Example 1: Customer Support Automation

**n8n → Flowise Integration:**

```javascript
// 1. Webhook Trigger - Receive support ticket
// Input: { "email": "customer@example.com", "issue": "Can't login" }

// 2. HTTP Request - Query Flowise Support Agent
Method: POST
URL: https://flowise.yourdomain.com/api/v1/prediction/support-agent-id
Headers:
  Authorization: Bearer {{$env.FLOWISE_API_KEY}}
Body: {
  "question": "Customer issue: {{$json.issue}}. Provide troubleshooting steps.",
  "overrideConfig": {
    "sessionId": "{{$json.email}}" // Maintain conversation context
  }
}

// 3. Code Node - Parse Flowise response
const solution = $json.text;
return {
  customer: $('Webhook').item.json.email,
  issue: $('Webhook').item.json.issue,
  ai_solution: solution,
  resolved: solution.includes("resolved") || solution.includes("fixed")
};

// 4. IF Node - Check if auto-resolved
If: {{$json.resolved}} === true

// 5a. Send Email - Auto-resolved
To: {{$json.customer}}
Subject: Issue Resolved
Body: {{$json.ai_solution}}

// 5b. Create Ticket - Needs human review
// → Baserow/Airtable Node
```

#### Example 2: Multi-Agent Research Pipeline

**Built entirely in Flowise, triggered by n8n:**

```javascript
// In Flowise: Create Multi-Agent Research System

// Agent 1: Web Researcher
Tools: Google Search, Web Scraper
Task: Find information about {{topic}}

// Agent 2: Data Analyst  
Tools: Code Interpreter
Task: Analyze findings and extract insights

// Agent 3: Report Writer
Tools: Document Generator
Task: Create executive summary

// Supervisor
Coordinates: Research → Analysis → Writing
Returns: Complete research report

// In n8n:
// 1. Schedule Trigger - Daily at 9 AM

// 2. Code Node - Define research topics
return [
  { topic: "AI automation trends 2025" },
  { topic: "LLM cost optimization strategies" },
  { topic: "Enterprise RAG implementations" }
];

// 3. HTTP Request - Call Flowise Multi-Agent
// (Loop over topics)
URL: https://flowise.yourdomain.com/api/v1/prediction/research-team-id
Body: {
  "question": "Research {{$json.topic}} and provide comprehensive report"
}

// 4. Google Drive - Save reports
File Name: Research_{{$json.topic}}_{{$now}}.pdf
Content: {{$json.text}}

// 5. Slack - Notify team
Message: "Daily research reports completed: {{$json.length}} topics"
```

#### Example 3: RAG Document Q&A System

**Flowise Setup:**

1. **Create Chatflow with RAG:**
   - Add **Document Loaders**: PDF, DOCX, Web Scraper
   - Add **Text Splitter**: Recursive Character Splitter (chunk size: 1000)
   - Add **Embeddings**: OpenAI Embeddings
   - Add **Vector Store**: Qdrant (internal: `http://qdrant:6333`)
   - Add **Retriever**: Vector Store Retriever (top k: 5)
   - Add **LLM Chain**: GPT-4o with RAG prompt
   - Connect: Documents → Splitter → Embeddings → Vector Store → Retriever → LLM

2. **Upload Documents:**
   - Company policies, product docs, FAQs
   - Flowise processes and stores in Qdrant

3. **Deploy & Get API Key**

**n8n Integration:**

```javascript
// 1. Slack Trigger - When message in #questions channel

// 2. HTTP Request - Query Flowise RAG
URL: https://flowise.yourdomain.com/api/v1/prediction/rag-chatbot-id
Body: {
  "question": "{{$json.text}}"
}

// 3. Slack Reply
Reply to thread: {{$json.text}}
Message: {{$json.response}}
Citations: {{$json.sourceDocuments}}
```

### Advanced Features

**AgentFlow V2 (Sequential Workflows):**

- **Tool Node**: Execute specific tools deterministically
- **Condition Node**: Branch logic based on outputs
- **Loop Node**: Iterate over results
- **Variable Node**: Store and retrieve state
- **SubFlow Node**: Call other Flowise flows as modules

**Example - Invoice Processing Flow:**

```
Start
  ↓
Tool Node: Extract text from PDF invoice
  ↓
LLM Node: Parse invoice data (amount, date, vendor)
  ↓
Condition Node: Amount > $1000?
  ├─ Yes → SubFlow: Approval workflow
  └─ No → Tool Node: Auto-approve
  ↓
Tool Node: Update accounting system
  ↓
End
```

### Best Practices

**Prompt Engineering:**
- Be specific in system instructions
- Include examples of desired outputs
- Define behavior for edge cases
- Use variables for dynamic content

**RAG Optimization:**
- Chunk size: 500-1500 characters (depends on use case)
- Overlap: 10-20% for better context
- Top K retrieval: 3-7 chunks
- Use metadata filtering when possible
- Regularly update vector store with new docs

**Multi-Agent Design:**
- Keep worker agents specialized (single responsibility)
- Supervisor should have clear delegation rules
- Test agents individually before combining
- Monitor token usage per agent

**Performance:**
- Use streaming for better UX
- Cache embeddings when possible
- Set reasonable timeout limits
- Implement rate limiting for public endpoints

### Troubleshooting

**Agent Not Responding:**

```bash
# 1. Check Flowise is running
docker ps | grep flowise

# 2. Check logs
docker logs flowise -f

# 3. Verify API key
# In Flowise: Settings → API Keys → Check if key is valid

# 4. Test with curl
curl -X POST https://flowise.yourdomain.com/api/v1/prediction/YOUR_FLOW_ID \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello"}'
```

**RAG Not Finding Documents:**

```bash
# 1. Check if documents were processed
# In Flowise: Open flow → Check Vector Store node → View stored docs

# 2. Verify Qdrant is running
docker ps | grep qdrant
curl http://localhost:6333/health

# 3. Check embeddings model
# Ensure OpenAI API key is set or Ollama is running for local embeddings

# 4. Test retrieval directly
# In Flowise: Test mode → Ask question → Check "Source Documents" in response

# 5. Adjust retrieval settings
# Increase top K value (try 5-10)
# Lower similarity threshold
# Try different chunk sizes
```

**Multi-Agent Errors:**

```bash
# 1. Check worker agents individually
# Test each worker separately before supervisor

# 2. Verify tool availability
# Check if tools (Google Search, APIs) are configured with valid credentials

# 3. Check LLM supports function calling
# Not all models support tool calling - use GPT-4o, Claude 3.5, or Mistral

# 4. Review supervisor prompt
# Ensure supervisor has clear instructions on when to use which worker

# 5. Monitor logs for specific errors
docker logs flowise | grep -i error
```

**n8n Integration Issues:**

```bash
# 1. Verify Flowise API endpoint
# Check exact URL in Flowise API tab

# 2. Test authentication
# Regenerate API key in Flowise if getting 401/403 errors

# 3. Check request format
# Body must be JSON with "question" field

# 4. Enable CORS if needed
# Set CORS_ORIGINS env variable in Flowise

# 5. Check n8n HTTP Request timeout
# Increase timeout for long-running agents (60-120 seconds)
```

**Slow Performance:**

```bash
# 1. Check model speed
# GPT-4o: Slow but accurate
# GPT-4o-mini: Faster, good quality
# Groq: Very fast (try llama-3.1-70b)

# 2. Optimize RAG retrieval
# Reduce top K value
# Use smaller embedding models

# 3. Enable streaming
# In Flowise chatflow settings: Enable streaming responses

# 4. Monitor Flowise resources
docker stats flowise
# High CPU/Memory? Upgrade server or reduce concurrent requests

# 5. Use caching
# Enable conversation memory caching
# Cache embeddings for frequently accessed docs
```

### Integration with AI LaunchKit Services

**Flowise + Qdrant:**
- Use Qdrant as vector store for RAG
- Internal URL: `http://qdrant:6333`
- Create collections in Qdrant UI, reference in Flowise

**Flowise + Ollama:**
- Use local LLMs instead of OpenAI
- Add Ollama Chat Models node
- Base URL: `http://ollama:11434`
- Models: llama3.2, mistral, qwen2.5-coder

**Flowise + n8n:**
- n8n triggers Flowise agents via API
- Flowise can call n8n webhooks as tools
- Bidirectional integration for complex workflows

**Flowise + Open WebUI:**
- Both can use same Ollama backend
- Flowise for agentic workflows
- Open WebUI for simple chat interface

### Resources

- **Official Website**: [flowiseai.com](https://flowiseai.com)
- **Documentation**: [docs.flowiseai.com](https://docs.flowiseai.com)
- **GitHub**: [github.com/FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise)
- **Marketplace**: Pre-built templates and flows in Flowise UI
- **Community**: [Discord](https://discord.gg/jbaHfsRVBW)
- **YouTube Tutorials**: Search "Flowise tutorial" for video guides
- **Template Library**: Built-in templates in Flowise for common use cases

### Security Notes

- **Authentication Required**: Set up API keys for production
- **Rate Limiting**: Implement rate limits on public endpoints
- **API Key Management**: Store keys in environment variables, never hardcode
- **CORS Configuration**: Configure CORS_ORIGINS for web embeds
- **Data Privacy**: Documents uploaded to RAG are stored in vector DB
- **LLM API Keys**: Keep OpenAI/Anthropic keys secure
- **Access Control**: Limit Flowise dashboard access to trusted users

### Pricing & Resources

**Resource Requirements:**
- **Basic Chatbot**: 2GB RAM, minimal CPU
- **RAG System**: 4GB RAM, moderate CPU (for embeddings)
- **Multi-Agent**: 8GB+ RAM, higher CPU
- **With Ollama**: +8GB RAM per LLM model

**API Costs (when using external LLMs):**
- OpenAI: ~$0.01 per conversation with GPT-4o-mini
- Anthropic: ~$0.025 per conversation with Claude 3.5 Sonnet
- Groq: Free tier available, then usage-based
- Ollama: Free (self-hosted)

**Cost Optimization:**
- Use Ollama for development/testing
- Switch to external APIs for production quality
- Implement caching to reduce API calls
- Use cheaper models (GPT-4o-mini) when possible


### What is Python Runner?

Python Runner (officially **n8n Task Runners**) is a sidecar container (`n8nio/runners`) that enables **native Python execution** in n8n workflows. Unlike n8n's legacy Pyodide-based Python (WebAssembly), Python Runner uses **real Python 3.x** with full access to the standard library and third-party packages.

This allows you to use powerful Python libraries like `pandas`, `numpy`, `requests`, `scikit-learn`, and many others directly in your n8n Code nodes - perfect for data processing, machine learning, API interactions, and complex transformations that would be difficult or impossible with JavaScript.

**Currently in Beta:** This feature is actively being developed and will become the default Python execution method in future n8n versions.

### Features

- **Native Python 3.x:** Real CPython interpreter (not WebAssembly) with full standard library
- **Rich Package Support:** Install `pandas`, `numpy`, `requests`, `scikit-learn`, `beautifulsoup4`, and hundreds more
- **Better Performance:** Faster execution compared to Pyodide for compute-intensive tasks
- **Sandboxed Execution:** Each task runs in an isolated environment for security
- **Automatic Lifecycle:** Python processes spawn on-demand and shut down after idle timeout
- **WebSocket Communication:** Fast, real-time communication between n8n and Python runner
- **Custom Dependencies:** Add your own Python packages via custom Docker image
- **Concurrent Execution:** Run multiple Python tasks simultaneously (configurable concurrency)

### How It Works

1. **n8n Main Container:** Handles workflow orchestration and UI
2. **n8nio/runners Sidecar:** Runs Python (and JavaScript) task runners
3. **Code Node Execution:** When a Code node with Python is triggered:
   - n8n sends the Python code to the runner via WebSocket
   - Runner spawns a Python process, executes the code
   - Returns results back to n8n
   - Python process terminates after idle timeout

**Architecture:**
```
n8n Container ← WebSocket → n8nio/runners Container
(Workflow Engine)             (Python + JS Runners)
```

### Initial Setup

Python Runner is **already configured in AI LaunchKit** if you installed with the latest version. Verify it's enabled:

#### Step 1: Check if Python Runner is Enabled

```bash
# Check n8n environment variables
docker exec n8n env | grep N8N_RUNNERS

# Should show:
# N8N_RUNNERS_ENABLED=true
# N8N_RUNNERS_MODE=external
# N8N_RUNNERS_AUTH_TOKEN=<secret>
```

#### Step 2: Verify Runner Container is Running

```bash
# Check if n8nio/runners container exists
docker ps | grep runners

# Should show container named 'python-runner' or similar
```

#### Step 3: Test Python in n8n Code Node

1. **Open n8n:** Navigate to `https://n8n.yourdomain.com`
2. **Create Test Workflow:**
   - Add **Manual Trigger** node
   - Add **Code** node
   - Select **Python** as language (not JavaScript)
   
3. **Test Code:**
```python
# Test native Python with standard library
import sys
import json
from datetime import datetime

result = {
    "python_version": sys.version,
    "current_time": datetime.now().isoformat(),
    "message": "Native Python is working!"
}

return [result]
```

4. **Execute Workflow:**
   - Click "Execute Workflow"
   - Should see Python version and current time in output
   - If working: Python Runner is properly configured! ✅

#### Step 4: Install Additional Python Packages (Optional)

To use packages beyond Python's standard library, you need to build a custom `n8nio/runners` image:

**Create Custom Dockerfile:**
```dockerfile
# custom-runners.Dockerfile
FROM n8nio/runners:latest

# Switch to root to install packages
USER root

# Install additional Python packages
RUN pip install --no-cache-dir \
    pandas==2.1.4 \
    numpy==1.26.3 \
    requests==2.31.0 \
    beautifulsoup4==4.12.3 \
    scikit-learn==1.4.0 \
    pillow==10.2.0

# Switch back to non-root user
USER node

# Update allowlist for Code node (IMPORTANT!)
# This file controls which packages can be imported
COPY n8n-task-runners.json /usr/local/lib/node_modules/@n8n/task-runner/
```

**Create Allowlist File (`config/task-runners.json`):**
```json
{
  "N8N_RUNNERS_PYTHON_ALLOW_BUILTIN": "*",
  "N8N_RUNNERS_PYTHON_ALLOW_EXTERNAL": [
    "pandas",
    "numpy",
    "requests",
    "bs4",
    "sklearn",
    "PIL"
  ]
}
```

**Build and Deploy:**
```bash
# Build custom image
docker build -f custom-runners.Dockerfile -t custom-runners:latest .

# Update docker-compose.yml to use custom image
# Change: image: n8nio/runners:latest
# To: image: custom-runners:latest

# Restart containers
docker compose down
docker compose up -d
```

### Using Python in n8n Code Nodes

#### Access Input Data

Python Code nodes receive data from previous nodes via the `_items` variable:

```python
# Get all input items
items = _items

# Process each item
for item in items:
    # Access JSON data
    name = item["json"]["name"]
    age = item["json"]["age"]
    
    # Modify or add fields
    item["json"]["greeting"] = f"Hello, {name}! You are {age} years old."

# Return modified items
return items
```

#### Common Patterns

**Pattern 1: Data Transformation with Pandas**
```python
import pandas as pd

# Convert input items to DataFrame
df = pd.DataFrame([item["json"] for item in _items])

# Perform transformations
df["total"] = df["price"] * df["quantity"]
df["category"] = df["product"].str.upper()

# Filter rows
df = df[df["total"] > 100]

# Convert back to n8n items
result = []
for _, row in df.iterrows():
    result.append({"json": row.to_dict()})

return result
```

**Pattern 2: API Requests**
```python
import requests

results = []
for item in _items:
    url = item["json"]["api_url"]
    
    # Make HTTP request
    response = requests.get(url, timeout=10)
    
    # Add response to results
    results.append({
        "json": {
            "url": url,
            "status_code": response.status_code,
            "data": response.json()
        }
    })

return results
```

**Pattern 3: Machine Learning Prediction**
```python
from sklearn.ensemble import RandomForestClassifier
import numpy as np

# Assuming model was trained elsewhere
# Here we just demonstrate the pattern

# Extract features from input
features = []
for item in _items:
    features.append([
        item["json"]["feature1"],
        item["json"]["feature2"],
        item["json"]["feature3"]
    ])

X = np.array(features)

# Make predictions (example - you'd load a trained model)
# predictions = model.predict(X)

# For demo, just return processed data
results = []
for i, item in enumerate(_items):
    results.append({
        "json": {
            **item["json"],
            "processed": True,
            "index": i
        }
    })

return results
```

**Pattern 4: Web Scraping**
```python
from bs4 import BeautifulSoup
import requests

url = _items[0]["json"]["url"]

# Fetch webpage
response = requests.get(url)
soup = BeautifulSoup(response.content, 'html.parser')

# Extract data
titles = soup.find_all('h2')
links = soup.find_all('a')

results = [{
    "json": {
        "url": url,
        "title_count": len(titles),
        "link_count": len(links),
        "titles": [t.text.strip() for t in titles[:5]]
    }
}]

return results
```

### n8n Integration Examples

#### Example 1: CSV Data Analysis

Analyze CSV data uploaded via n8n:

```
1. HTTP Request Node: Download CSV file
2. Code Node (Python):
```

```python
import pandas as pd
import io

# Get CSV content from previous node
csv_content = _items[0]["binary"]["data"]

# Read CSV
df = pd.read_csv(io.StringIO(csv_content.decode('utf-8')))

# Perform analysis
summary = {
    "total_rows": len(df),
    "columns": list(df.columns),
    "numeric_summary": df.describe().to_dict(),
    "missing_values": df.isnull().sum().to_dict()
}

return [{"json": summary}]
```

#### Example 2: Batch Image Processing

Process images using Pillow:

```
1. Loop Over Items Node
2. HTTP Request: Download image
3. Code Node (Python):
```

```python
from PIL import Image
import io
import base64

# Get image from previous node
image_data = _items[0]["binary"]["data"]

# Open and resize image
img = Image.open(io.BytesIO(image_data))
img_resized = img.resize((800, 600))

# Convert to base64
buffer = io.BytesIO()
img_resized.save(buffer, format="PNG")
img_base64 = base64.b64encode(buffer.getvalue()).decode()

return [{
    "json": {
        "original_size": img.size,
        "new_size": img_resized.size
    },
    "binary": {
        "data": img_base64
    }
}]
```

#### Example 3: Natural Language Processing

Analyze text sentiment (requires TextBlob):

```
1. Webhook Trigger: Receive text input
2. Code Node (Python):
```

```python
# Note: Requires custom runner image with textblob installed

from textblob import TextBlob

results = []
for item in _items:
    text = item["json"]["text"]
    
    # Analyze sentiment
    blob = TextBlob(text)
    sentiment = blob.sentiment
    
    results.append({
        "json": {
            "text": text,
            "polarity": sentiment.polarity,  # -1 to 1
            "subjectivity": sentiment.subjectivity,  # 0 to 1
            "sentiment": "positive" if sentiment.polarity > 0 else "negative"
        }
    })

return results
```

#### Example 4: Database Operations with SQLAlchemy

Direct database access (requires custom runner with sqlalchemy):

```
1. Schedule Trigger: Daily at 9 AM
2. Code Node (Python):
```

```python
from sqlalchemy import create_engine, text
import pandas as pd

# Database connection
engine = create_engine("postgresql://user:pass@postgres:5432/mydb")

# Query data
query = """
SELECT customer_id, SUM(amount) as total
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY customer_id
ORDER BY total DESC
LIMIT 10
"""

df = pd.read_sql(query, engine)

# Convert to n8n items
results = []
for _, row in df.iterrows():
    results.append({"json": row.to_dict()})

return results
```

### Troubleshooting

**Issue 1: Python Runner Not Starting**

```bash
# Check runner container logs
docker logs python-runner --tail 100

# Common error: "connection refused"
# Solution: Verify N8N_RUNNERS_AUTH_TOKEN matches in both containers

# Check n8n environment
docker exec n8n env | grep N8N_RUNNERS_AUTH_TOKEN

# Check runner environment
docker exec python-runner env | grep N8N_RUNNERS_AUTH_TOKEN

# Should be identical
```

**Solution:**
- Ensure `N8N_RUNNERS_AUTH_TOKEN` is set and matches in both n8n and runners container
- Restart both containers: `docker compose restart n8n python-runner`
- Check network connectivity: `docker exec n8n ping python-runner`

**Issue 2: "Module not found" Error**

```python
# Error: ModuleNotFoundError: No module named 'pandas'
```

**Solution:**
- Python Runner only includes standard library by default
- To use third-party packages, build custom runner image (see Setup Step 4)
- Add package to allowlist in `n8n-task-runners.json`
- Verify package is installed: `docker exec python-runner pip list | grep pandas`

**Issue 3: Code Execution Timeout**

```bash
# Check timeout settings
docker exec n8n env | grep N8N_RUNNERS_TASK_TIMEOUT

# Default is 60 seconds
```

**Solution:**
- Increase timeout for long-running tasks:
```yaml
# docker-compose.yml
environment:
  - N8N_RUNNERS_TASK_TIMEOUT=300  # 5 minutes
```
- Optimize Python code for performance
- Use batch processing instead of loops where possible
- Consider breaking task into smaller chunks

**Issue 4: High Memory Usage**

```bash
# Monitor runner memory usage
docker stats python-runner --no-stream

# Check max memory allocation
docker exec python-runner env | grep N8N_RUNNERS_MAX_OLD_SPACE_SIZE
```

**Solution:**
- Increase memory limit in docker-compose.yml:
```yaml
python-runner:
  image: n8nio/runners:latest
  deploy:
    resources:
      limits:
        memory: 2G  # Increase from default 1G
```
- Optimize Python code (use generators, process in batches)
- Check for memory leaks in custom packages

**Issue 5: "Permission Denied" Errors**

```bash
# Check runner user
docker exec python-runner whoami

# Should be: node (not root)
```

**Solution:**
- Runner runs as non-root user for security
- Don't try to install system packages at runtime
- Build custom image with packages pre-installed as root
- Avoid file operations requiring root permissions

### Resources

- **n8n Task Runners Documentation:** https://docs.n8n.io/hosting/configuration/task-runners/
- **Task Runner Environment Variables:** https://docs.n8n.io/hosting/configuration/environment-variables/task-runners/
- **Code Node Documentation:** https://docs.n8n.io/code/code-node/
- **n8nio/runners Docker Image:** https://hub.docker.com/r/n8nio/runners
- **GitHub - n8n Repository:** https://github.com/n8n-io/n8n
- **Adding Extra Dependencies:** https://github.com/n8n-io/n8n/tree/master/docker/images/runners
- **Python Built-in Modules:** https://docs.python.org/3/library/
- **n8n Community Forum:** https://community.n8n.io/
- **Task Runner Launcher:** https://github.com/n8n-io/task-runner-launcher

### Best Practices

**Performance:**
- Use native Python instead of Pyodide for compute-intensive tasks
- Process data in batches to reduce number of Python task invocations
- Set appropriate `N8N_RUNNERS_MAX_CONCURRENCY` (default: 5) based on server resources
- Monitor memory usage and adjust limits accordingly
- Use generator expressions instead of list comprehensions for large datasets

**Security:**
- Never disable `N8N_RUNNERS_PYTHON_DENY_INSECURE_BUILTINS` in production
- Only allowlist packages you actually need in `n8n-task-runners.json`
- Keep Python packages updated in custom runner image
- Use secrets/environment variables for sensitive data (not hardcoded in code)
- Validate and sanitize all input data before processing

**Package Management:**
- Pin exact package versions in custom Dockerfile (e.g., `pandas==2.1.4`)
- Test custom runner image thoroughly before deploying to production
- Document all installed packages and their purposes
- Regularly update packages for security patches
- Keep custom runner image in version control

**Debugging:**
- Enable debug logging: `N8N_RUNNERS_LAUNCHER_LOG_LEVEL=debug`
- Use `print()` statements in Python code (output appears in Code node)
- Monitor runner logs: `docker logs python-runner --follow`
- Test Python code locally before adding to n8n
- Start with simple examples and gradually add complexity

**Code Organization:**
```python
# Good: Organized and reusable
def process_item(item):
    """Process a single item."""
    # Processing logic here
    return modified_item

results = [process_item(item) for item in _items]
return results

# Bad: Everything in one block
# (Hard to read and debug)
```

**Error Handling:**
```python
# Always include error handling
results = []
for item in _items:
    try:
        # Processing logic
        result = process(item)
        results.append({"json": result})
    except Exception as e:
        # Log error and continue
        results.append({
            "json": {
                "error": str(e),
                "item": item["json"]
            }
        })

return results
```

**Resource Monitoring:**
```bash
# Check runner health
docker exec python-runner curl -f http://localhost:5680/healthz || echo "Runner unhealthy"

# Monitor concurrent tasks
docker logs python-runner | grep "concurrent tasks"

# Memory and CPU usage
docker stats python-runner --no-stream
```

**Typical Resource Usage:**
- **Idle:** ~50-100MB RAM, <1% CPU
- **Active (light tasks):** ~200-500MB RAM, 5-20% CPU
- **Active (heavy tasks):** ~500MB-2GB RAM, 50-100% CPU

### Data Management

The n8n service uses a structured approach for managing workflows and credentials:

*   **`config/workflows/`**: Place version-controlled workflow JSON files here. These are imported when running the import command.
*   **`config/credentials/`**: Place credential JSON files here.
*   **`data/backups/`**: Exports generated by the CLI are stored here.

**CLI Commands:**

You can manage data using the `launchkit run` command:

*   **Import**: Imports workflows and credentials from `config/`.
    ```bash
    launchkit run n8n import
    ```

*   **Export**: Exports current workflows and credentials to `data/backups/`.
    ```bash
    launchkit run n8n export
    ```
