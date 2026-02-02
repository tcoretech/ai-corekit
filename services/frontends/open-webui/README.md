### What is Open WebUI?

Open WebUI is a self-hosted ChatGPT-like interface that provides a beautiful, feature-rich chat experience for local and remote LLMs. It seamlessly integrates with Ollama for local models, OpenAI API, and other providers, offering conversation management, model switching, and advanced features like RAG (Retrieval-Augmented Generation).

### Features

- **ChatGPT-like Interface** - Familiar chat UI with markdown, code highlighting, and streaming
- **Multiple Model Support** - Switch between Ollama (local), OpenAI, Anthropic, and other providers
- **Conversation Management** - Save, search, and organize chat history
- **RAG Integration** - Upload documents and chat with your data using vector search
- **Multi-user Support** - User accounts, authentication, and role-based access
- **Model Library** - Browse and download Ollama models directly from the UI

### Initial Setup

**First Login to Open WebUI:**

1. Navigate to `https://webui.yourdomain.com`
2. **First user becomes admin** - Create your account
3. Set strong password
4. Setup complete!

**Ollama is pre-configured** - All local models from Ollama are automatically available.

### Connect to Ollama Models

**Ollama is already connected internally:**

- **Internal URL:** `http://ollama:11434`
- All models pulled in Ollama appear automatically in Open WebUI
- No additional configuration needed!

**Available default models:**
- `llama3.2` - Fast, general-purpose (recommended)
- `mistral` - Great for coding and reasoning
- `llama3.2-vision` - Multimodal (text + images)
- `qwen2.5-coder` - Specialized for code generation

### Download Additional Models

**Option 1: From Open WebUI (recommended)**

1. Click Settings (gear icon)
2. Go to **Models** tab
3. Browse available models
4. Click **Pull** to download

**Option 2: From Command Line**

```bash
# Download a specific model
docker exec ollama ollama pull llama3.2

# List installed models
docker exec ollama ollama list

# Remove a model
docker exec ollama ollama rm modelname
```

**Popular Model Recommendations:**

| Model | Size | Best For | RAM Required |
|-------|------|----------|--------------|
| `llama3.2` | 2GB | General chat, fast | 4GB |
| `llama3.2:70b` | 40GB | Best quality | 64GB+ |
| `mistral` | 4GB | Coding, reasoning | 8GB |
| `qwen2.5-coder:7b` | 4GB | Code generation | 8GB |
| `llama3.2-vision` | 5GB | Image understanding | 8GB |
| `deepseek-r1:7b` | 4GB | Reasoning, math | 8GB |

### Add OpenAI API Models

**Connect to OpenAI for faster responses:**

1. Settings → **Connections**
2. **OpenAI API** section
3. Add API Key: `sk-your-key-here`
4. Enable OpenAI models

**Available models:**
- `gpt-4o` - Most capable (recommended)
- `gpt-4o-mini` - Fast and cost-effective
- `o1` - Advanced reasoning

### RAG (Chat with Your Documents)

**Upload and chat with documents:**

1. Click the **+** icon in chat
2. Select **Upload Files**
3. Choose PDF, DOCX, TXT, or other documents
4. Open WebUI automatically:
   - Extracts text
   - Creates embeddings
   - Stores in vector database
5. Ask questions about your documents!

**Example queries:**
```
"Summarize the key findings from the uploaded report"
"What does the contract say about termination?"
"Extract all action items from the meeting notes"
```

### n8n Integration

**HTTP Request to Open WebUI API:**

```javascript
// HTTP Request Node Configuration
Method: POST
URL: http://open-webui:8080/api/chat/completions
Authentication: Bearer Token
  Token: [Your Open WebUI API Key]
  
Body (JSON):
{
  "model": "llama3.2",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant"
    },
    {
      "role": "user",
      "content": "{{$json.user_question}}"
    }
  ],
  "stream": false
}

// Response:
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "AI response here..."
      }
    }
  ]
}
```

**Generate API Key in Open WebUI:**
1. Settings → **Account** → **API Keys**
2. Click **Create new API Key**
3. Copy and save securely

### Example Workflows

#### Example 1: Customer Support Automation

```javascript
// 1. Webhook Trigger - Receive support ticket
// Input: { "customer": "John", "question": "How do I reset password?" }

// 2. HTTP Request - Query Open WebUI
Method: POST
URL: http://open-webui:8080/api/chat/completions
Headers:
  Authorization: Bearer {{$env.OPENWEBUI_API_KEY}}
Body: {
  "model": "llama3.2",
  "messages": [
    {
      "role": "system",
      "content": "You are a customer support assistant. Provide clear, helpful answers based on our knowledge base."
    },
    {
      "role": "user",
      "content": "{{$json.question}}"
    }
  ]
}

// 3. Code Node - Format response
const response = $json.choices[0].message.content;
return {
  customer: $('Webhook').item.json.customer,
  question: $('Webhook').item.json.question,
  ai_response: response,
  timestamp: new Date().toISOString()
};

// 4. Send Email - Reply to customer
To: {{$json.customer}}@company.com
Subject: Re: {{$json.question}}
Message: |
  Hi {{$json.customer}},
  
  {{$json.ai_response}}
  
  Best regards,
  Support Team

// 5. Baserow Node - Log interaction
Table: support_tickets
Fields: {
  customer: {{$json.customer}},
  question: {{$json.question}},
  ai_response: {{$json.ai_response}},
  resolved: true
}
```

#### Example 2: Document Analysis Pipeline

```javascript
// 1. Schedule Trigger - Daily at 9 AM

// 2. Google Drive - Get new PDFs
Folder: /Documents/ToProcess
File Type: PDF

// 3. HTTP Request - Upload to Open WebUI with RAG
Method: POST
URL: http://open-webui:8080/api/documents/upload
Headers:
  Authorization: Bearer {{$env.OPENWEBUI_API_KEY}}
Body (Form Data):
  file: {{$binary.data}}

// 4. HTTP Request - Query document
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [
    {
      "role": "user",
      "content": "Analyze this document and extract: 1) Key topics, 2) Action items, 3) Deadlines"
    }
  ],
  "files": ["{{$json.document_id}}"]
}

// 5. Code Node - Structure results
const analysis = JSON.parse($json.choices[0].message.content);
return {
  document: $('Google Drive').item.json.name,
  key_topics: analysis.key_topics,
  action_items: analysis.action_items,
  deadlines: analysis.deadlines
};

// 6. Notion - Create page with analysis
Database: Project Docs
Properties: {
  title: {{$json.document}},
  topics: {{$json.key_topics}},
  actions: {{$json.action_items}},
  due_dates: {{$json.deadlines}}
}
```

#### Example 3: Multi-Model Comparison

```javascript
// Compare responses from different models

// 1. Webhook Trigger - Receive question

// 2. Split in Batches (parallel execution)

// 3a. HTTP Request - Ollama (Llama)
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 3b. HTTP Request - OpenAI (GPT-4)
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 3c. HTTP Request - Mistral
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "mistral",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 4. Aggregate Results
// Combine all responses

// 5. Code Node - Compare and score
const responses = [
  { model: "llama3.2", answer: $item(0).json.choices[0].message.content },
  { model: "gpt-4o", answer: $item(1).json.choices[0].message.content },
  { model: "mistral", answer: $item(2).json.choices[0].message.content }
];

// Return best answer based on length, clarity, etc.
return responses;
```

### LightRAG Integration

**Add LightRAG as a model in Open WebUI:**

1. Settings → **Connections**
2. Add new Ollama connection:
   - **URL:** `http://lightrag:9621`
   - **Model name:** `lightrag:latest`
3. Select LightRAG from model dropdown

**Now you can chat with your knowledge graph directly!**

### User Management

**Admin Functions:**

1. Settings → **Admin Panel**
2. Manage users, roles, permissions
3. Control model access per user
4. View usage statistics

**Create Additional Users:**

1. Admin Panel → **Users** → **Add User**
2. Set username, email, password
3. Assign role: Admin, User, or Pending
4. Users can also self-register if enabled

### Troubleshooting

**Models not appearing:**

```bash
# Check Ollama is running
docker ps | grep ollama

# Verify connectivity from Open WebUI
docker exec open-webui curl http://ollama:11434/api/tags

# Restart Open WebUI
docker compose restart open-webui
```

**Slow responses:**

```bash
# Check server resources
docker stats ollama

# Model might be too large for RAM
# Switch to smaller model:
# llama3.2 (2GB) instead of llama3.2:70b (40GB)

# Increase CPU allocation in docker-compose.yml
```

**RAG not working:**

```bash
# Check vector database
docker logs open-webui | grep vector

# Clear and rebuild embeddings
# Settings → Admin → Reset Vector Database

# Ensure enough disk space
df -h
```

**API authentication failed:**

```bash
# Regenerate API key in Open WebUI
# Settings → Account → API Keys → Create New

# Update n8n credential
# Replace old key with new one
```

### Resources

- **Official Documentation:** https://docs.openwebui.com/
- **GitHub:** https://github.com/open-webui/open-webui
- **API Reference:** https://docs.openwebui.com/api/
- **Model Library:** https://ollama.com/library
- **Community Discord:** https://discord.gg/open-webui

### Best Practices

**Model Selection:**
- Use `llama3.2` for general tasks (fast, 2GB)
- Use `gpt-4o-mini` for better quality when speed matters
- Use `qwen2.5-coder` for code-heavy tasks
- Use vision models for image analysis

**Performance:**
- Keep 2-3 frequently used models downloaded
- Remove unused models to save disk space
- Use OpenAI API for production (faster, more reliable)
- Use Ollama for privacy-sensitive data

**Security:**
- Change default admin password immediately
- Disable self-registration in production
- Use role-based access for team deployments
- Regularly backup conversation history

**RAG Optimization:**
- Upload documents in supported formats (PDF, DOCX, TXT)
- Keep documents under 10MB for best performance
- Use clear, descriptive questions
- Combine multiple related documents for better context
