# 🦙 Ollama - Local LLMs

### What is Ollama?

Ollama is an open-source framework that allows you to run large language models (LLMs) locally on your own hardware with minimal setup. Think of it as "Docker for AI models" – it simplifies the complex process of downloading, configuring, and running sophisticated AI models like Llama 3.3, Mistral, Qwen, DeepSeek, Phi, and dozens of others. Ollama eliminates the need for expensive cloud API services, provides complete privacy control (your data never leaves your machine), and offers an OpenAI-compatible REST API for seamless integration with other tools.

### Features

- **Simple Model Management** - Download and run models with single commands: `ollama pull llama3.3`, `ollama run mistral`
- **Extensive Model Library** - 100+ pre-configured models including Llama 3.3 (70B), DeepSeek-R1, Qwen3, Phi-4, Mistral, Gemma, CodeLlama, and more
- **OpenAI-Compatible API** - REST API at `http://localhost:11434` works as drop-in replacement for OpenAI API
- **Quantization Support** - Run large models efficiently with GGUF quantization (Q4_0, Q8_0 variants)
- **Multi-Modal Capabilities** - Vision models like LLaVA and Llama 3.2 Vision support image + text inputs
- **No Cloud Dependencies** - Complete privacy, zero API costs, works offline
- **GPU Acceleration** - Automatic NVIDIA CUDA and Apple Metal support for fast inference
- **Custom Model Support** - Import your own fine-tuned models or custom Modelfiles
- **Lightweight & Fast** - Minimal installation, models load in seconds, low memory footprint with quantization

### Initial Setup

**Ollama is Pre-Configured in AI CoreKit:**

Ollama is already running and accessible at `http://ollama:11434` internally. You can interact with it from n8n, Open WebUI, and other services immediately.

**Pull Your First Model:**

```bash
# SSH into your server
ssh user@yourdomain.com

# Pull a lightweight model (2GB, fast)
docker exec ollama ollama pull llama3.2

# Pull a powerful reasoning model (4GB)
docker exec ollama ollama pull qwen2.5:7b

# Pull a coding specialist model (4GB)
docker exec ollama ollama pull qwen2.5-coder:7b

# Pull a vision model (5GB, supports images)
docker exec ollama ollama pull llama3.2-vision

# List installed models
docker exec ollama ollama list
```

**Test Ollama from Command Line:**

```bash
# Simple chat test
docker exec -it ollama ollama run llama3.2 "Explain quantum computing in simple terms"

# Code generation test
docker exec -it ollama ollama run qwen2.5-coder:7b "Write a Python function to calculate fibonacci numbers"

# Vision test (if you have llama3.2-vision)
docker exec -it ollama ollama run llama3.2-vision "Describe this image: /path/to/image.jpg"
```

**Test Ollama API:**

```bash
# Basic completion request
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'

# Chat format request (OpenAI-compatible)
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hello! Who are you?"}
  ]
}'
```

### Recommended Models for Different Use Cases

**General Chat & Reasoning (Best Quality):**
```bash
docker exec ollama ollama pull qwen2.5:14b        # 8GB RAM, excellent reasoning
docker exec ollama ollama pull llama3.3:70b       # 40GB RAM, GPT-4 class quality
docker exec ollama ollama pull deepseek-r1:7b     # 5GB RAM, strong reasoning
```

**Fast & Lightweight (Low Resources):**
```bash
docker exec ollama ollama pull phi4:3.8b          # 2.3GB, Microsoft's efficient model
docker exec ollama ollama pull qwen2.5:3b         # 2GB, fast and accurate
docker exec ollama ollama pull llama3.2:1b        # 1GB, ultra-lightweight
```

**Code Generation:**
```bash
docker exec ollama ollama pull qwen2.5-coder:7b   # Best for coding
docker exec ollama ollama pull codellama:13b      # Meta's code specialist
docker exec ollama ollama pull deepseek-coder:6.7b # Strong at debugging
```

**Vision (Image + Text):**
```bash
docker exec ollama ollama pull llama3.2-vision:11b # Image understanding
docker exec ollama ollama pull llava:13b           # Visual question answering
```

**Embeddings (for RAG):**
```bash
docker exec ollama ollama pull nomic-embed-text    # 275M params, fast embeddings
docker exec ollama ollama pull mxbai-embed-large   # Higher quality, slower
```

### n8n Integration Setup

**Ollama is Already Connected Internally:**

Ollama runs at `http://ollama:11434` inside the Docker network. You can use it from n8n without any credentials or authentication.

**Option 1: Use n8n's OpenAI-Compatible Nodes**

Ollama's API is OpenAI-compatible, so you can use n8n's OpenAI nodes by pointing them to Ollama:

1. In n8n, add a new credential
2. Select **OpenAI API**
3. Configure:
   - **API Key:** `ollama` (any value works, Ollama doesn't check auth)
   - **Base URL:** `http://ollama:11434/v1`
4. Save credential

Now use OpenAI nodes with Ollama models!

**Option 2: Use HTTP Request Nodes (More Flexible)**

For full control, use HTTP Request nodes to call Ollama's API directly:

```javascript
// HTTP Request Node Configuration
Method: POST
URL: http://ollama:11434/api/generate
Body (JSON):
{
  "model": "llama3.2",
  "prompt": "{{ $json.userMessage }}",
  "stream": false
}

// Response: $json.response contains the AI's answer
```

**Option 3: Use Code Node with Ollama SDK**

```javascript
// Install ollama package in n8n (Settings > Community Nodes)
// or use HTTP requests directly

const model = 'qwen2.5:7b';
const prompt = $input.first().json.question;

const response = await fetch('http://ollama:11434/api/generate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: model,
    prompt: prompt,
    stream: false
  })
});

const result = await response.json();

return {
  json: {
    answer: result.response,
    model: model,
    prompt: prompt
  }
};
```

### Example Workflows

#### Example 1: AI Email Responder with Local Privacy

Build a workflow that monitors Gmail, generates replies with Ollama (100% private), and sends responses.

```javascript
// 1. Gmail Trigger Node
Trigger: On New Email
Label: Inbox
Polling Interval: Every 5 minutes

// 2. Code Node - Extract Question from Email
const emailBody = $json.text || $json.snippet;
return {
  json: {
    from: $json.from,
    subject: $json.subject,
    question: emailBody
  }
};

// 3. HTTP Request Node - Ollama Generation
Method: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5:7b",
  "prompt": "You are a helpful email assistant. Reply professionally to this email:\n\nFrom: {{ $json.from }}\nSubject: {{ $json.subject }}\n\nEmail content:\n{{ $json.question }}\n\nYour reply:",
  "stream": false,
  "temperature": 0.7
}

// 4. Code Node - Format Response
const response = $json.response;
return {
  json: {
    reply: response.trim(),
    original_from: $('Code Node').first().json.from,
    original_subject: $('Code Node').first().json.subject
  }
};

// 5. Gmail Node - Send Reply
Operation: Send Email
To: {{ $json.original_from }}
Subject: Re: {{ $json.original_subject }}
Message: {{ $json.reply }}

// Result: Automated email responses with complete privacy
```

#### Example 2: Document Summarization Pipeline

Process PDFs/documents and create summaries using local Ollama models.

```javascript
// 1. Webhook Trigger
Method: POST
Path: /summarize
Authentication: None (or configure as needed)

// 2. Extract from File Node (if PDF uploaded)
Binary Property: data
Format: Text

// 3. Code Node - Chunk Text (if document is large)
const text = $json.data;
const chunkSize = 3000; // Ollama context window
const chunks = [];

for (let i = 0; i < text.length; i += chunkSize) {
  chunks.push({
    chunk: text.slice(i, i + chunkSize),
    index: Math.floor(i / chunkSize)
  });
}

return chunks.map(c => ({ json: c }));

// 4. Loop Over Items (for each chunk)
// 5. HTTP Request - Ollama Summarization
Method: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5:7b",
  "prompt": "Summarize this text concisely:\n\n{{ $json.chunk }}",
  "stream": false
}

// 6. Code Node - Combine Summaries
const summaries = $input.all().map(item => item.json.response);
const finalSummary = summaries.join('\n\n');

return {
  json: {
    summary: finalSummary,
    chunks_processed: summaries.length
  }
};

// 7. Respond to Webhook
Status Code: 200
Body: {{ $json.summary }}
```

#### Example 3: Code Review Assistant

Automatically review pull requests or code snippets using local LLM.

```javascript
// 1. Webhook/Manual Trigger
// Accept code snippet as input

// 2. Set Node - Define Code to Review
code = """
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total
"""

// 3. HTTP Request - Ollama Code Review
Method: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5-coder:7b",
  "prompt": "Review this code for bugs, performance issues, and best practices:\n\n```python\n{{ $json.code }}\n```\n\nProvide specific suggestions.",
  "stream": false
}

// 4. Code Node - Parse Review Results
const review = $json.response;

return {
  json: {
    code_reviewed: $('Set').first().json.code,
    review_feedback: review,
    model: 'qwen2.5-coder:7b',
    timestamp: new Date().toISOString()
  }
};

// 5. Slack/Email Node - Send Review
Channel: #code-review
Message: |
  🤖 *Automated Code Review*
  
  *Model:* {{ $json.model }}
  
  *Feedback:*
  {{ $json.review_feedback }}
```

#### Example 4: Multi-Model Comparison

Compare responses from different Ollama models to find the best answer.

```javascript
// 1. Manual/Webhook Trigger
question = "Explain the difference between async/await and promises in JavaScript"

// 2. Code Node - Create Model Array
const models = ['llama3.2', 'qwen2.5:7b', 'deepseek-r1:7b'];

return models.map(model => ({
  json: {
    model: model,
    question: $json.question
  }
}));

// 3. Loop Over Items
// 4. HTTP Request - Query Each Model
Method: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "{{ $json.model }}",
  "prompt": "{{ $json.question }}",
  "stream": false,
  "temperature": 0.3
}

// 5. Code Node - Aggregate Results
const responses = $input.all().map(item => ({
  model: item.json.model,
  answer: item.json.response
}));

return {
  json: {
    question: $('Manual Trigger').first().json.question,
    responses: responses,
    comparison_complete: true
  }
};

// 6. Format Output (Markdown/Slack/Email)
```

#### Example 5: Vision-Powered Image Analysis

Use Ollama's vision models to analyze images (requires llama3.2-vision or llava).

```javascript
// 1. Webhook Trigger - Receives Image
Method: POST
Path: /analyze-image

// 2. Code Node - Encode Image to Base64
const imageBuffer = Buffer.from($binary.data.data);
const base64Image = imageBuffer.toString('base64');

return {
  json: {
    image_base64: base64Image
  }
};

// 3. HTTP Request - Ollama Vision Analysis
Method: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "llama3.2-vision",
  "prompt": "Describe this image in detail. What objects, people, and activities do you see?",
  "images": ["{{ $json.image_base64 }}"],
  "stream": false
}

// 4. Code Node - Format Response
const description = $json.response;

return {
  json: {
    image_description: description,
    analysis_timestamp: new Date().toISOString(),
    model: 'llama3.2-vision'
  }
};

// 5. Respond to Webhook or Save to Database
```

### Troubleshooting

**Model not found:**
```bash
# Check installed models
docker exec ollama ollama list

# Pull the required model
docker exec ollama ollama pull llama3.2

# Verify model name matches exactly (case-sensitive)
# Correct: "llama3.2"
# Incorrect: "llama3.2:latest" or "Llama3.2"
```

**Ollama service not responding:**
```bash
# Check if Ollama container is running
docker ps | grep ollama

# Check Ollama logs
docker logs ollama --tail 100

# Restart Ollama service
docker compose restart ollama

# Test connection
curl http://localhost:11434/api/tags
```

**Out of memory errors:**
```bash
# Use smaller/quantized models
docker exec ollama ollama pull qwen2.5:3b        # Instead of 7b
docker exec ollama ollama pull llama3.2:1b       # Ultra-lightweight

# Use Q4_0 quantized versions (half the memory)
docker exec ollama ollama pull llama3.2:7b-q4_0

# Check current memory usage
docker stats ollama

# Free up disk space by removing unused models
docker exec ollama ollama rm <model-name>
```

**Slow generation speed:**
```bash
# Check if GPU is being used (much faster than CPU)
docker exec ollama nvidia-smi  # For NVIDIA GPUs

# Verify GPU is accessible
docker exec ollama ollama run llama3.2 --verbose "test"
# Look for "using GPU" in output

# Use faster models
docker exec ollama ollama pull phi4:3.8b         # Very fast, small
docker exec ollama ollama pull qwen2.5:3b        # Fast generation

# Reduce max_tokens in API requests
{
  "model": "llama3.2",
  "prompt": "...",
  "options": {
    "num_predict": 128  # Limit response length
  }
}
```

**n8n timeout errors:**
```bash
# Increase n8n timeout setting
# n8n > Settings > Workflows > Execution Timeout: 300 seconds

# Use streaming: false for synchronous responses
{
  "model": "qwen2.5:7b",
  "prompt": "...",
  "stream": false  # Wait for complete response
}

# Use smaller prompts
# Long prompts = slower generation
```

**Connection refused from n8n:**
```bash
# Check Docker network
docker network inspect ai-corekit_default
# Verify ollama and n8n are on same network

# Test internal URL
docker exec n8n curl http://ollama:11434/api/tags

# If fails, restart both services
docker compose restart ollama n8n
```

### Resources

- **Official Website:** https://ollama.com
- **Model Library:** https://ollama.com/library (Browse 100+ models)
- **GitHub Repository:** https://github.com/ollama/ollama
- **API Documentation:** https://github.com/ollama/ollama/blob/main/docs/api.md
- **Modelfile Reference:** https://github.com/ollama/ollama/blob/main/docs/modelfile.md
- **Discord Community:** https://discord.gg/ollama
- **Blog & Tutorials:** https://ollama.com/blog
- **Comparison with Cloud APIs:** https://ollama.com/blog/openai-compatibility

### Best Practices

**Model Selection:**
- Start with lightweight models (3B-7B parameters) for testing
- Use 13B+ models only if you need higher quality and have 16GB+ RAM
- For coding tasks: `qwen2.5-coder:7b` or `deepseek-coder:6.7b`
- For reasoning: `qwen2.5:14b` or `deepseek-r1:7b`
- For vision: `llama3.2-vision:11b`
- For embeddings (RAG): `nomic-embed-text`

**Performance Optimization:**
- Always use GPU acceleration when available (10-100x faster than CPU)
- Use quantized models (Q4_0 variants) to reduce memory usage by 50%
- Set `num_predict` limit to avoid generating unnecessarily long responses
- Cache frequently used models in memory (Ollama keeps recently used models loaded)
- Use `temperature: 0.3` for factual tasks, `0.7` for creative tasks

**Privacy & Security:**
- All data stays on your server - perfect for GDPR compliance
- No API keys needed, no usage tracking
- Ideal for processing sensitive documents, code, or customer data
- Use Ollama for development, switch to OpenAI for production if needed

**Integration Patterns:**
- Use Ollama for prototyping (free, fast iteration)
- Switch to OpenAI API for production if you need guaranteed uptime
- Run Ollama + OpenAI in parallel: Ollama for privacy-sensitive tasks, OpenAI for complex reasoning
- Combine Ollama with RAG: Use `nomic-embed-text` for embeddings + `qwen2.5:7b` for generation

**Resource Management:**
- Monitor disk space: Models can be 2-40GB each
- Remove unused models regularly: `docker exec ollama ollama rm <model>`
- Only keep 3-5 models active at a time
- Use smaller models for high-volume tasks (APIs, batch processing)
- Use larger models for occasional deep analysis

**Cost Optimization:**
- Ollama = $0/month for unlimited usage
- Compare to OpenAI: 1M tokens ≈ $2-20 (depending on model)
- If processing >1M tokens/month, Ollama pays for itself quickly
- Best ROI: Use Ollama for high-volume, low-stakes tasks

### Integration with AI CoreKit Services

**Ollama + Open WebUI:**
- Open WebUI auto-detects all Ollama models
- Switch between models instantly in the UI
- No configuration needed - works out of the box

**Ollama + Dify:**
- Add Ollama as LLM provider: `http://ollama:11434`
- Use for RAG workflows, agents, and chatbots
- Zero API costs for unlimited conversations

**Ollama + Letta (MemGPT):**
- Configure as LLM provider for stateful agents
- Agents remember conversations across sessions
- Completely private memory storage

**Ollama + RAGApp:**
- Use `nomic-embed-text` for document embeddings
- Use `qwen2.5:7b` for question answering
- Build private knowledge bases with zero cloud dependencies

**Ollama + Flowise:**
- Drag-and-drop Ollama nodes in visual builder
- Combine with other tools (web scraping, databases)
- Build complex AI agents without code

**Ollama + ComfyUI:**
- Some ComfyUI nodes support Ollama for image descriptions
- Use vision models to analyze generated images
- Caption images automatically

**Ollama + bolt.diy:**
- Set Ollama as code generation backend (experimental)
- Privacy-first development with local LLMs
- No API costs for prototyping
