# 🎨 OpenUI - UI Component Generator</b> 🧪</summary>

### What is OpenUI?

OpenUI is an **experimental** AI-powered tool that generates UI components directly from text descriptions. It uses large language models to create React, Vue, Svelte, or plain HTML components based on your prompts. While it can rapidly produce component code, output quality varies significantly depending on the LLM model used.

**⚠️ Important:** OpenUI is experimental and best suited for prototyping and inspiration rather than production-ready code. For complex UI requirements or full applications, consider using **bolt.diy** instead.

### Features

- **Multi-Framework Support** - Generate React, Vue, Svelte, or HTML components
- **Live Preview** - See components render in real-time as they're generated
- **AI-Powered** - Uses Claude, GPT-4, Groq, or Ollama models
- **Copy/Export** - Get clean code ready to paste into your project
- **Styling Options** - Choose between Tailwind CSS, plain CSS, or styled-components
- **Component Variations** - Generate multiple design options for comparison
- **Fast Iteration** - Quickly refine components with follow-up prompts

### Initial Setup

**First Access to OpenUI:**

1. Navigate to `https://openui.yourdomain.com`
2. No login required - OpenUI starts immediately
3. Configure your AI provider:
   - Click **Settings** (gear icon)
   - Choose provider: OpenAI, Anthropic, Groq, or Ollama
   - Enter API key (if using external provider)
   - Select model

**Recommended Model Configuration:**

| Provider | Model | Quality | Speed | Cost | Best For |
|----------|-------|---------|-------|------|----------|
| **Anthropic** | Claude 3.5 Sonnet | ⭐⭐⭐⭐⭐ | Medium | $$ | Production-quality components |
| **OpenAI** | GPT-4o | ⭐⭐⭐⭐⭐ | Medium | $$ | Complex layouts, accessibility |
| **OpenAI** | GPT-4o-mini | ⭐⭐⭐⭐ | Fast | $ | Quick prototypes |
| **Groq** | llama-3.1-70b | ⭐⭐⭐ | Very Fast | $ | Rapid iteration |
| **Ollama** | Local models | ⭐⭐ | Varies | Free | Privacy, experimentation |

**⚠️ Critical:** For best results, use **Claude 3.5 Sonnet** or **GPT-4o**. Lower-quality models may produce unusable components.

### Basic Usage

**Generate a Simple Component:**

1. Open `https://openui.yourdomain.com`
2. Select framework: **React**, **Vue**, **Svelte**, or **HTML**
3. Enter description in the prompt box:
   ```
   Modern pricing card with gradient background, 
   three tiers (Basic, Pro, Enterprise), 
   with feature lists and call-to-action buttons
   ```
4. Click **Generate**
5. Wait 10-30 seconds for generation
6. View live preview on right side
7. Click **Copy Code** to use in your project

**Refine with Follow-ups:**

```
"Make the gradient purple instead of blue"
"Add hover animations to the cards"
"Make it mobile-responsive"
"Add icons for each feature"
```

### Component Examples

#### Example 1: Dashboard Card

```
Prompt: "Create a dashboard stats card showing:
- Large number (metric value)
- Percentage change with up/down arrow
- Small chart/sparkline
- Tooltip on hover
- Use Tailwind CSS with shadcn/ui design style"

Framework: React
Model: Claude 3.5 Sonnet

Result: Production-ready component with:
✓ Proper TypeScript types
✓ Responsive design
✓ Accessible markup
✓ Clean, commented code
```

#### Example 2: Form Component

```
Prompt: "Modern contact form with:
- Name, Email, Message fields
- Real-time validation
- Submit button with loading state
- Success/error toast notifications
- Dark mode support"

Framework: React
Model: GPT-4o

Result: Functional form component with:
✓ Form validation
✓ State management
✓ Error handling
✓ Accessibility features
```

#### Example 3: Navigation Menu

```
Prompt: "Responsive navigation bar:
- Logo on left
- Menu items in center
- Search bar and profile avatar on right
- Mobile: hamburger menu with slide-out drawer
- Sticky on scroll
- Glassmorphism effect"

Framework: Vue 3
Model: Claude 3.5 Sonnet

Result: Complete nav component with:
✓ Mobile responsiveness
✓ Smooth animations
✓ Vue 3 Composition API
✓ Modern styling
```

### Integration Patterns

**OpenUI + bolt.diy Workflow:**

1. **Generate components in OpenUI** - Quick UI mockups
2. **Copy to bolt.diy** - Integrate into full app
3. **Refine with AI** - Use bolt.diy for functionality
4. **Deploy** - Complete application with working backend

**OpenUI + n8n Workflow:**

```javascript
// Use OpenUI-generated components as email templates

// 1. Generate email template component in OpenUI
Prompt: "Responsive email template with header, content section, 
         and footer. Use inline CSS for email compatibility."

// 2. Copy HTML output

// 3. Use in n8n Send Email node
HTML: [Paste OpenUI-generated HTML]

// 4. Personalize with n8n variables
Subject: Order Confirmation - {{ $json.orderId }}
Body: Replace placeholders with {{ $json.customerName }}
```

### Best Practices

**Prompt Engineering for OpenUI:**

✅ **Do:**
- Be specific about layout and structure
- Mention framework-specific patterns (hooks, composables)
- Specify styling approach (Tailwind, CSS modules)
- Request responsive design explicitly
- Ask for accessibility features
- Mention dark mode if needed

❌ **Don't:**
- Use vague descriptions ("make it nice")
- Expect complex business logic
- Assume state management is included
- Request backend integration
- Expect perfect code on first try

**Example Good Prompts:**

```
✓ "Create a React component using Tailwind CSS: 
   Card with image on left (40%), text content on right (60%), 
   CTA button at bottom, hover effect to lift card with shadow, 
   mobile: stack image on top"

✓ "Vue 3 composable for form validation with:
   - Email validation regex
   - Password strength checker  
   - Real-time error messages
   - Returns reactive state and validation functions"

✓ "Svelte component: Tabbed interface with 3 tabs,
   smooth slide animations between content,
   active tab indicator line,
   keyboard navigation support (arrow keys),
   ARIA labels for accessibility"
```

**Example Poor Prompts:**

```
✗ "Nice login form"
✗ "Dashboard"
✗ "Make it modern"
✗ "Component like Facebook"
```

### Limitations & Known Issues

**Quality Varies by Model:**

- **Claude 3.5 Sonnet / GPT-4o**: Consistently good, production-usable
- **GPT-4o-mini**: Good for simple components, may struggle with complex layouts
- **Groq models**: Fast but often produce lower-quality code
- **Ollama models**: Very inconsistent, often requires multiple attempts

**Common Issues:**

1. **Incomplete components** - Missing imports, broken JSX
2. **Non-functional logic** - State management doesn't work
3. **Poor responsiveness** - Desktop-only designs
4. **Accessibility gaps** - Missing ARIA labels, keyboard nav
5. **Styling conflicts** - CSS specificity issues

**When to Use OpenUI:**

✅ Good for:
- Quick component mockups
- Design inspiration
- Learning component patterns
- Simple, static UI elements
- Email templates (HTML)

❌ Not good for:
- Production-ready components without review
- Complex business logic
- Full page layouts
- Components with backend integration
- Mission-critical UI

### Troubleshooting

**Poor Quality Output:**

```bash
# 1. Switch to a better model
Settings → Provider: Anthropic
Model: claude-3-5-sonnet-20241022

# 2. Make prompt more specific
Instead of: "Login form"
Use: "React login form with email field, password field with 
      show/hide toggle, remember me checkbox, submit button 
      with loading state, error message display, 
      using Tailwind CSS"

# 3. Try multiple generations
Click "Generate" 2-3 times, pick best result

# 4. Use bolt.diy for complex components
OpenUI is best for simple, isolated components
```

**Component Not Rendering:**

```bash
# 1. Check browser console (F12) for errors

# 2. Common issues:
- Missing imports: Add required dependencies
- JSX syntax errors: Fix bracket mismatches
- CSS issues: Check class names are correct

# 3. Test code outside OpenUI
Copy to CodeSandbox or local project
Install dependencies manually
Debug with proper dev tools
```

**API Errors:**

```bash
# 1. Verify API key
Settings → API Key → Re-enter and save

# 2. Check API limits
OpenAI: platform.openai.com/usage
Anthropic: console.anthropic.com

# 3. Check OpenUI logs
docker logs openui --tail 50

# 4. Restart service if needed
docker compose restart openui
```

**Slow Generation:**

```bash
# 1. Switch to faster model
Groq: llama-3.1-70b (fast, lower quality)
OpenAI: gpt-4o-mini (balanced)

# 2. Simplify prompt
Break complex components into smaller pieces
Generate incrementally

# 3. Check OpenUI resources
docker stats openui
# Low CPU/RAM? Upgrade server

# 4. Check network to AI provider
# Slow API responses may be provider-side
```

### Alternative: bolt.diy

**When OpenUI isn't enough:**

If OpenUI generates poor quality or you need:
- Full application development
- Backend integration
- Complex state management
- Multiple connected components
- Production-ready code

**→ Use bolt.diy instead:**
- More reliable code generation
- Full-stack capabilities
- Better iteration workflow
- Live development environment
- Can generate entire applications

See [bolt.diy section](#ai-powered-development) for full documentation.

### Resources

- **Official Repository**: [github.com/wandb/openui](https://github.com/wandb/openui)
- **Documentation**: Limited - tool is experimental
- **Component Libraries**: 
  - [shadcn/ui](https://ui.shadcn.com) - Copy patterns for better prompts
  - [Tailwind UI](https://tailwindui.com) - Inspiration for designs
- **Alternative Tools**:
  - **bolt.diy** - Full-stack AI development
  - **v0.dev** - Vercel's UI generator (external)
  - **Lovable** - AI app builder (external)

### Security & Best Practices

**Code Review Required:**
- **Always review generated code** before production use
- Check for security vulnerabilities
- Validate input handling
- Test accessibility
- Verify responsive behavior

**API Key Security:**
- Use environment variables for API keys
- Don't commit keys to Git
- Rotate keys regularly
- Monitor API usage for anomalies

**Privacy Considerations:**
- Your prompts are sent to AI providers (OpenAI, Anthropic, etc.)
- Don't include sensitive business logic in prompts
- Use Ollama for private/sensitive projects
- Generated code may be logged by AI providers

**Licensing:**
- AI-generated code licensing is unclear
- Review your AI provider's terms
- Consider legal implications for commercial use
- Test thoroughly as if it's third-party code

</details>

### AI Agents

<details>
<summary><b>🤖 Flowise - Visual AI Builder

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

### Integration with AI CoreKit Services

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
