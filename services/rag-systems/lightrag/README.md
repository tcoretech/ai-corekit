# 🔗 LightRAG - Graph-Based RAG with Automatic Entity Extraction

### What is LightRAG?

LightRAG is a graph-based RAG (Retrieval-Augmented Generation) system that automatically extracts entities and relationships from documents and stores them in a knowledge graph. Unlike traditional vector RAG that only searches for semantic similarity, LightRAG understands **relationships between concepts** and can answer complex queries requiring context across multiple entities. Perfect for enterprise documentation, research papers, and complex knowledge bases.

### Features

- **🕸️ Automatic Knowledge Graph Creation**: Extracts entities and relationships from text automatically
- **🎯 Multi-Mode Querying**: Local (specific), Global (overview), Hybrid (combined), Naive (simple)
- **🧠 Relationship-Aware Retrieval**: Finds connections between concepts, not just similar texts
- **🔄 Incremental Updates**: Adds new documents to existing graph without rebuilding
- **⚡ Fast Graph Queries**: Optimized for quick traversal of large knowledge graphs
- **🎨 Visual Graph Exploration**: Optional Neo4j backend for visualization
- **🌐 Multiple LLM Support**: Ollama (local, default), OpenAI (faster), or others

### Initial Setup

**First Access to LightRAG:**

1. **Access via Web UI:**
```
https://lightrag.yourdomain.com
```
Simple UI for document upload and querying.

2. **Test API Health:**
```bash
curl http://lightrag:9621/health
# Should return: {"status": "healthy"}
```

3. **Insert First Document:**
```bash
curl -X POST http://lightrag:9621/api/insert \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Alice works at TechCorp as a software engineer. Bob is the CEO of TechCorp. Charlie knows Alice from university.",
    "metadata": {"source": "test_document"}
  }'
```

LightRAG automatically extracts:
- **Entities**: Alice (Person), Bob (Person), Charlie (Person), TechCorp (Company)
- **Relationships**: Alice-WORKS_AT→TechCorp, Bob-CEO_OF→TechCorp, Charlie-KNOWS→Alice

4. **Query the Knowledge Graph:**
```bash
curl -X POST http://lightrag:9621/api/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Who works at TechCorp?",
    "mode": "local"
  }'
```

### Query Modes Explained

LightRAG offers 4 different query modes for different use cases:

| Mode | Use Case | How It Works | Best For |
|------|----------|--------------|----------|
| **`local`** | Specific entity information | Searches for direct entity relationships | "What is Alice's role?" |
| **`global`** | High-level overview | Analyzes entire knowledge graph | "What are the main themes?" |
| **`hybrid`** | Combined analysis | Combines local + global | "How does TechCorp implement SDGs?" |
| **`naive`** | Simple keyword search | Traditional vector similarity | "Find 'Sustainability'" |

**Mode Comparison Examples:**

```javascript
// Local Mode - Specific entity information
{
  "query": "What is the role of Petra Hedorfer?",
  "mode": "local",
  "max_results": 5
}
// Returns: Direct information about Petra and her immediate relationships

// Global Mode - High-level summaries
{
  "query": "What are the main sustainability initiatives?",
  "mode": "global",
  "max_results": 10
}
// Returns: Overall themes and patterns across all documents

// Hybrid Mode - Combines both approaches (RECOMMENDED)
{
  "query": "How does DZT implement SDGs in tourism?",
  "mode": "hybrid",
  "stream": false
}
// Returns: Specific examples + overall context

// Naive Mode - Simple keyword search
{
  "query": "sustainability reports",
  "mode": "naive"
}
// Returns: Documents matching keywords (no graph reasoning)
```

### API Access

LightRAG runs as an internal service accessible to other containers:

**Internal API Endpoint:**
```
http://lightrag:9621
```

**Key API Endpoints:**
- `POST /api/insert` - Insert document and extract entities
- `POST /api/query` - Query knowledge graph
- `GET /api/health` - Health check
- `DELETE /api/clear` - Clear knowledge graph (use with caution!)

### n8n Integration Setup

LightRAG has no native n8n node - integration is via HTTP Request nodes.

**Internal URL:** `http://lightrag:9621`

**No credentials required** for internal container-to-container communication.

### Example Workflows

#### Example 1: Build Knowledge Graph from Documents

Automatically build knowledge graph from uploaded PDFs.

**Workflow Structure:**
1. **Google Drive Trigger** - Watch folder for new PDFs
   ```javascript
   Folder: /Documents/KnowledgeBase
   File Type: PDF
   ```

2. **Read Binary File** - Get PDF content

3. **HTTP Request** - Extract Text from PDF
   ```javascript
   Method: POST
   URL: http://gotenberg:3000/forms/pdfengines/convert
   // Or use any PDF-to-text service
   ```

4. **Code Node - Split into Chunks**
   ```javascript
   const text = $input.item.json.text;
   const chunkSize = 3000;  // Characters per chunk
   const chunks = [];
   
   for (let i = 0; i < text.length; i += chunkSize) {
     chunks.push({
       text: text.substring(i, i + chunkSize),
       chunk_index: Math.floor(i / chunkSize)
     });
   }
   
   return chunks.map(c => ({ json: c }));
   ```

5. **Loop Node** - Process Each Chunk

6. **HTTP Request - Insert into LightRAG**
   ```javascript
   Method: POST
   URL: http://lightrag:9621/api/insert
   Headers:
     Content-Type: application/json
   Body: {
     "text": "{{ $json.text }}",
     "metadata": {
       "source": "{{ $('Google Drive Trigger').item.json.name }}",
       "chunk_index": {{ $json.chunk_index }},
       "timestamp": "{{ $now.toISO() }}"
     }
   }
   
   // LightRAG automatically:
   // - Extracts entities (people, companies, concepts)
   // - Identifies relationships
   // - Builds knowledge graph
   // - Creates embeddings
   ```

7. **Wait Node**
   ```javascript
   Duration: 2 seconds  // Give time for processing
   ```

8. **Aggregate Results**
   ```javascript
   const processedChunks = $input.all().length;
   const document = $('Google Drive Trigger').item.json.name;
   
   return [{
     json: {
       document: document,
       chunks_processed: processedChunks,
       knowledge_graph_updated: true
     }
   }];
   ```

9. **Slack Notification**
   ```javascript
   Message: |
     📚 Knowledge Graph Updated
     
     Document: {{ $json.document }}
     Chunks processed: {{ $json.chunks_processed }}
     
     Query your knowledge graph at https://lightrag.yourdomain.com
   ```

**Use Case**: Automatic knowledge base building from company documentation.

#### Example 2: Intelligent Document Q&A

Answer questions using graph-based understanding.

**Workflow Structure:**
1. **Webhook Trigger**
   ```javascript
   Input: {
     "question": "What are TechCorp's main sustainability initiatives and who leads them?",
     "query_mode": "hybrid"
   }
   ```

2. **HTTP Request - Query LightRAG**
   ```javascript
   Method: POST
   URL: http://lightrag:9621/api/query
   Headers:
     Content-Type: application/json
   Body: {
     "query": "{{ $json.question }}",
     "mode": "{{ $json.query_mode }}",
     "max_results": 5,
     "stream": false
   }
   
   // Response includes:
   {
     "answer": "Comprehensive answer based on graph reasoning...",
     "entities": ["TechCorp", "Sustainability Initiative X", "Alice Smith"],
     "relationships": [
       {"from": "Alice Smith", "type": "LEADS", "to": "Sustainability Initiative X"},
       {"from": "Sustainability Initiative X", "type": "PART_OF", "to": "TechCorp"}
     ],
     "sources": [
       {"document": "Annual Report 2024", "relevance": 0.95}
     ]
   }
   ```

3. **Code Node - Format Response with Graph Context**
   ```javascript
   const answer = $input.item.json.answer;
   const entities = $input.item.json.entities || [];
   const relationships = $input.item.json.relationships || [];
   const sources = $input.item.json.sources || [];
   
   const formattedResponse = `
   **Answer:**
   ${answer}
   
   **Key Entities:**
   ${entities.map(e => `- ${e}`).join('\n')}
   
   **Relationships Found:**
   ${relationships.map(r => `- ${r.from} ${r.type} ${r.to}`).join('\n')}
   
   **Sources:**
   ${sources.map((s, i) => `${i+1}. ${s.document} (relevance: ${(s.relevance * 100).toFixed(0)}%)`).join('\n')}
   `;
   
   return [{
     json: {
       question: $('Webhook').item.json.question,
       response: formattedResponse,
       entities: entities,
       sources: sources
     }
   }];
   ```

4. **Send Response** - Email, Slack, or API response

**Use Case**: Internal knowledge base assistant, customer support automation.

#### Example 3: Compare Naive vs Graph-Based RAG

Demonstrate the power of graph-based reasoning.

**Workflow Structure:**
1. **Manual Trigger**
   ```javascript
   Input: {
     "question": "What is the connection between Alice and the sustainability project?"
   }
   ```

2. **Split in Batches** - Execute parallel queries

3a. **HTTP Request - Naive RAG** (keyword-based)
   ```javascript
   Method: POST
   URL: http://lightrag:9621/api/query
   Body: {
     "query": "{{ $json.question }}",
     "mode": "naive"
   }
   ```

3b. **HTTP Request - Graph-Based RAG** (relationship-aware)
   ```javascript
   Method: POST
   URL: http://lightrag:9621/api/query
   Body: {
     "query": "{{ $json.question }}",
     "mode": "hybrid"
   }
   ```

4. **Aggregate & Compare**
   ```javascript
   const naiveAnswer = $item(0).json.answer;
   const graphAnswer = $item(1).json.answer;
   
   return [{
     json: {
       question: $('Manual Trigger').item.json.question,
       naive_rag: {
         answer: naiveAnswer,
         method: "Simple keyword matching"
       },
       graph_rag: {
         answer: graphAnswer,
         method: "Relationship traversal + semantic understanding",
         entities: $item(1).json.entities,
         relationships: $item(1).json.relationships
       },
       winner: graphAnswer.length > naiveAnswer.length ? "Graph RAG" : "Naive RAG"
     }
   }];
   
   // Typical results:
   // Naive: "Alice is mentioned in sustainability documents."
   // Graph: "Alice leads the Green Initiative project, which is part of TechCorp's 
   //         sustainability efforts. She reports to Bob, the CEO, and collaborates 
   //         with the Environmental Team."
   ```

**Use Case**: Demonstrate superiority of graph-based RAG for relationship queries.

### Open WebUI Integration

**Add LightRAG as a chat model in Open WebUI:**

LightRAG can be integrated directly into Open WebUI as an Ollama-compatible model!

**Setup Steps:**
1. **Open WebUI Settings → Connections**
2. **Add new Ollama connection:**
   - **URL:** `http://lightrag:9621`
   - **Model name:** `lightrag:latest`
3. **Select LightRAG from model dropdown in chat**

**Now you can chat with your knowledge graph directly!**

This enables:
- Natural conversation with the knowledge graph
- Automatic entity and relationship recognition
- Graph-based answers instead of just vector search
- Visualization of entity relationships

### Switch from Ollama to OpenAI (Optional)

LightRAG defaults to using local Ollama models. For better performance with large documents, switch to OpenAI:

**Why Switch to OpenAI?**
- ⚡ **10-100x faster** than CPU-based Ollama
- 📄 **Large Documents**: Handle PDFs with 50+ pages without timeouts
- 🎯 **Better Quality**: More accurate entity and relationship extraction
- 💰 **Cost-Efficient**: gpt-4o-mini costs ~$0.15 per million tokens

**Configuration Steps:**

1. **Add OpenAI API Key to .env:**
```bash
cd /root/ai-corekit
nano .env

# Add or update:
OPENAI_API_KEY=sk-proj-YOUR-API-KEY-HERE
```

2. **Update docker-compose.yml:**
```yaml
lightrag:
  environment:
    - OPENAI_API_KEY=${OPENAI_API_KEY}
    - LLM_BINDING=openai                           # Changed from ollama
    - LLM_BINDING_HOST=https://api.openai.com/v1   # OpenAI endpoint
    - LLM_MODEL=gpt-4o-mini                        # Cost-efficient model
    - EMBEDDING_BINDING=openai                     # Changed from ollama
    - EMBEDDING_BINDING_HOST=https://api.openai.com/v1
    - EMBEDDING_MODEL=text-embedding-3-small       # OpenAI embeddings
    - EMBEDDING_DIM=1536                           # OpenAI dimension (not 768!)
```

3. **Restart LightRAG:**
```bash
corekit restart lightrag
```

**Performance Comparison:**

| Metric | Ollama (CPU) | OpenAI API |
|--------|--------------|------------|
| Entity Extraction (10-page PDF) | 2-5 minutes | 10-30 seconds |
| Query Response | 5-15 seconds | 1-3 seconds |
| Cost (1M tokens) | Free (local) | ~$0.15-0.60 |
| Quality | Good | Excellent |

### Troubleshooting

**Issue 1: Slow Entity Extraction**

```bash
# Check if using Ollama (slow) or OpenAI (fast)
corekit logs lightrag | grep -E "LLM_BINDING|EMBEDDING_BINDING"

# If using Ollama on CPU:
# Solution 1: Switch to OpenAI (see above)
# Solution 2: Use smaller documents (< 5 pages at once)
# Solution 3: Reduce chunk size in preprocessing

# Check Ollama is running
corekit ps | grep ollama
curl http://ollama:11434/api/tags
```

**Solution:**
- Switch to OpenAI for production workloads
- Process documents in smaller batches
- Use `hybrid` mode instead of `global` for faster queries

**Issue 2: Query Returns No Results**

```bash
# Check if documents were inserted
curl http://lightrag:9621/api/health

# Verify knowledge graph has data
corekit logs lightrag | grep "entities extracted"

# Test with simple query
curl -X POST http://lightrag:9621/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "mode": "naive"}'
```

**Solution:**
- Knowledge graph might be empty - re-insert documents
- Try `naive` mode first to check if documents exist
- Check if entities were actually extracted (view logs)

**Issue 3: Authentication Errors in Open WebUI**

```bash
# Check LightRAG port is accessible
corekit exec open-webui curl http://lightrag:9621/health

# Verify Ollama-compatible API
curl http://lightrag:9621/v1/models
# Should return model list

# Restart Open WebUI
corekit restart open-webui
```

**Solution:**
- Verify internal DNS resolution between containers
- Check Docker network: `docker network inspect ai-corekit_default`
- Ensure LightRAG container is running

**Issue 4: Out of Memory Errors**

```bash
# Check memory usage
docker stats lightrag --no-stream

# LightRAG can be memory-intensive with large graphs
```

**Solution:**
- Increase Docker memory limit in `docker-compose.yml`:
  ```yaml
  lightrag:
    deploy:
      resources:
        limits:
          memory: 4G  # Increase from 2G
  ```
- Clear old knowledge graph: `curl -X DELETE http://lightrag:9621/api/clear`
- Use OpenAI instead of Ollama (less RAM required)

**Issue 5: Container Not Starting**

```bash
# Check container status
corekit ps -a | grep lightrag

# View logs
corekit logs lightrag

# Common issues:
# - Missing LLM configuration
# - Ollama not running
# - Port 9621 already in use
```

**Solution:**
- Verify Ollama is running: `docker ps | grep ollama`
- Check port conflicts: `netstat -tulpn | grep 9621`
- Restart with dependencies: `corekit restart ollama lightrag`

### Best Practices

**Document Processing:**
- **Chunk Size**: 2000-4000 characters for optimal entity extraction
- **Overlap**: Not needed (LightRAG handles context internally)
- **Metadata**: Always include source, timestamp, document type
- **Incremental Updates**: Insert new documents continuously, no rebuild needed

**Query Optimization:**
- **Use `hybrid` mode** for most queries (best balance)
- **Use `local` mode** for specific entity questions
- **Use `global` mode** for overview/summary questions
- **Use `naive` mode** only for simple keyword searches

**Entity Extraction Quality:**
- Use **OpenAI** for production (10x better than Ollama)
- **Pre-process documents**: Remove headers/footers, clean formatting
- **Domain-specific prompts**: Customize entity types if needed
- **Validate extractions**: Review sample entities after first batch

**Performance Tips:**
- Process documents in **batches of 10-20** at a time
- Use **parallel processing** in n8n for large document sets
- **Cache frequent queries** in Redis or PostgreSQL
- **Monitor graph size**: Large graphs (>100K entities) may need optimization

**Integration Patterns:**

```javascript
// Pattern 1: RAG Pipeline
Document Upload → LightRAG Insert → Query with context

// Pattern 2: Hybrid Search
LightRAG (graph-based) + Qdrant (vector-based) → Combine results

// Pattern 3: Entity Enrichment
Extract entities with LightRAG → Enrich with external APIs → Update graph

// Pattern 4: Knowledge Graph Visualization
LightRAG (storage) → Export to Neo4j (visualization)
```

### Resources

- **Official Documentation**: https://github.com/HKUDS/LightRAG
- **GitHub Repository**: https://github.com/HKUDS/LightRAG
- **Research Paper**: [LightRAG: Simple and Fast Retrieval-Augmented Generation](https://arxiv.org/abs/2410.05779)
- **Web UI**: `https://lightrag.yourdomain.com`
- **Internal API**: `http://lightrag:9621`
- **OpenAPI Docs**: `http://lightrag:9621/docs`

**Related Services:**
- Use with **Neo4j** for graph visualization
- Combine with **Qdrant/Weaviate** for hybrid vector+graph search
- Process documents with **Gotenberg** (PDF to text)
- Query from **Open WebUI** for conversational interface
- Analyze with **Ollama** (local) or **OpenAI** (fast)
