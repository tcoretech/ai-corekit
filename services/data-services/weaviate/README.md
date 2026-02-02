# 🗄️ Weaviate - AI Vector Database

### What is Weaviate?

Weaviate (pronounced "we-vee-eight") is an open-source, AI-native vector database written in Go. It stores both data objects and their vector embeddings, enabling advanced semantic search capabilities by comparing meaning encoded in vectors rather than relying solely on keyword matching. Weaviate combines the power of vector similarity search with structured filtering, multi-tenancy, and cloud-native scalability, making it ideal for RAG applications, recommendation systems, and agent-driven workflows.

### Features

- **Hybrid Search** - Combine vector similarity (semantic) with keyword search (BM25) for best-of-both-worlds results
- **Multi-Modal Support** - Search across text, images, audio, and other data types with built-in vectorizers
- **GraphQL & REST APIs** - Flexible querying with GraphQL for complex searches and REST for CRUD operations
- **Built-in Vectorizers** - Automatic embedding generation via OpenAI, Cohere, HuggingFace, Google, and more
- **Multi-Tenancy** - Isolated data namespaces for SaaS applications
- **Distributed Architecture** - Horizontal scaling with sharding and replication
- **Real-time RAG** - Native integration with generative models for retrieval-augmented generation

### Initial Setup

**Access Weaviate:**

Weaviate is pre-installed and running on your AI CoreKit instance.

1. **GraphQL Playground:** `https://weaviate.yourdomain.com/v1/graphql`
   - Interactive query builder and testing interface
   - No authentication required (internal use only)
2. **REST API:** `http://weaviate:8080` (internal) or `https://weaviate.yourdomain.com` (external)
3. **gRPC API:** `weaviate:50051` (internal, high-performance queries)

**First Steps:**

```bash
# Check if Weaviate is running
curl http://localhost:8080/v1/.well-known/ready
# Response: {"status": "ok"}

# Check Weaviate version and modules
curl http://localhost:8080/v1/meta

# Create your first collection (called "class" in Weaviate)
curl -X POST http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "Article",
    "vectorizer": "none",
    "properties": [
      {
        "name": "title",
        "dataType": ["text"]
      },
      {
        "name": "content",
        "dataType": ["text"]
      }
    ]
  }'

# Verify collection was created
curl http://localhost:8080/v1/schema
```

### n8n Integration Setup

**Connect to Weaviate from n8n:**

- **Internal REST URL:** `http://weaviate:8080`
- **Internal GraphQL URL:** `http://weaviate:8080/v1/graphql`
- **No authentication** required for internal access

#### Example 1: Create Collection & Insert Objects

Set up a new collection for semantic search:

```javascript
// 1. HTTP Request: Create Collection (Schema)
Method: POST
URL: http://weaviate:8080/v1/schema
Headers:
  Content-Type: application/json
Body: {
  "class": "Document",
  "vectorizer": "none",  // We'll provide our own vectors
  "properties": [
    {
      "name": "title",
      "dataType": ["text"],
      "tokenization": "word"
    },
    {
      "name": "content",
      "dataType": ["text"],
      "tokenization": "word"
    },
    {
      "name": "category",
      "dataType": ["text"],
      "tokenization": "field"  // For exact matching
    },
    {
      "name": "created_at",
      "dataType": ["date"]
    }
  ]
}

// 2. HTTP Request: Generate Embedding (OpenAI)
Method: POST
URL: https://api.openai.com/v1/embeddings
Headers:
  Authorization: Bearer {{ $env.OPENAI_API_KEY }}
Body: {
  "input": "{{ $json.content }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Prepare Weaviate Object
const embedding = $json.data[0].embedding;
const weaviateObject = {
  class: "Document",
  properties: {
    title: $json.title,
    content: $json.content,
    category: $json.category,
    created_at: new Date().toISOString()
  },
  vector: embedding
};
return { object: weaviateObject };

// 4. HTTP Request: Insert Object into Weaviate
Method: POST
URL: http://weaviate:8080/v1/objects
Body: {{ $json.object }}
```

#### Example 2: Vector Search with GraphQL

Perform semantic search using GraphQL:

```javascript
// 1. Webhook: Receive search query

// 2. HTTP Request: Generate Query Embedding
Method: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": "{{ $json.query }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Prepare GraphQL Query
const queryVector = $json.data[0].embedding;
const graphqlQuery = {
  query: `{
    Get {
      Document(
        nearVector: {
          vector: ${JSON.stringify(queryVector)}
        }
        limit: 5
      ) {
        title
        content
        category
        _additional {
          distance
          id
        }
      }
    }
  }`
};
return graphqlQuery;

// 4. HTTP Request: Search Weaviate
Method: POST
URL: http://weaviate:8080/v1/graphql
Headers:
  Content-Type: application/json
Body: {{ $json }}

// 5. Code Node: Extract Results
const results = $json.data.Get.Document.map(doc => ({
  id: doc._additional.id,
  title: doc.title,
  content: doc.content,
  category: doc.category,
  similarity: 1 - doc._additional.distance  // Convert distance to similarity
}));
return { results };

// 6. Respond with results
```

#### Example 3: Hybrid Search (Vector + Keyword)

Combine semantic and keyword search for best results:

```javascript
// 1. Trigger: User query

// 2. HTTP Request: GraphQL Hybrid Search
Method: POST
URL: http://weaviate:8080/v1/graphql
Headers:
  Content-Type: application/json
Body: {
  "query": "{
    Get {
      Document(
        hybrid: {
          query: \"{{ $json.query }}\"
          alpha: 0.5
        }
        limit: 10
      ) {
        title
        content
        category
        _additional {
          score
          explainScore
        }
      }
    }
  }"
}

// alpha: 0.0 = pure keyword (BM25)
// alpha: 0.5 = balanced hybrid
// alpha: 1.0 = pure vector (semantic)

// Result: Best of both worlds!
// - Finds semantically similar content
// - Boosts exact keyword matches
```

#### Example 4: Filtered Vector Search

Combine vector similarity with metadata filtering:

```javascript
// 1. Trigger: User query with filters

// 2. HTTP Request: Filtered Vector Search
Method: POST
URL: http://weaviate:8080/v1/graphql
Body: {
  "query": "{
    Get {
      Document(
        nearText: {
          concepts: [\"{{ $json.query }}\"]
        }
        where: {
          operator: And
          operands: [
            {
              path: [\"category\"]
              operator: Equal
              valueText: \"documentation\"
            },
            {
              path: [\"created_at\"]
              operator: GreaterThanEqual
              valueDate: \"2024-01-01T00:00:00Z\"
            }
          ]
        }
        limit: 5
      ) {
        title
        content
        category
        created_at
        _additional {
          distance
        }
      }
    }
  }"
}

// This search:
// 1. Finds semantically similar documents
// 2. Filters to category = "documentation"
// 3. Only shows docs from 2024 onwards
```

#### Example 5: Batch Import with REST API

Efficiently import many objects at once:

```javascript
// 1. Database Trigger: New records

// 2. Split in Batches Node: Create batches of 100

// 3. Loop over Batches

// 4. HTTP Request: Batch Generate Embeddings
Method: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": {{ $json.batch.map(item => item.content) }},
  "model": "text-embedding-3-small"
}

// 5. Code Node: Prepare Batch Objects
const objects = $json.data.map((emb, idx) => ({
  class: "Document",
  properties: {
    title: $json.batch[idx].title,
    content: $json.batch[idx].content,
    category: $json.batch[idx].category,
    created_at: new Date().toISOString()
  },
  vector: emb.embedding
}));
return { objects };

// 6. HTTP Request: Batch Insert
Method: POST
URL: http://weaviate:8080/v1/batch/objects
Body: {
  "objects": {{ $json.objects }}
}

// 7. Check response for errors
// Weaviate returns per-object status

// 8. Wait Node: 1 second (avoid rate limits)

// 9. Loop continues
```

#### Example 6: Generative Search (RAG)

Use Weaviate's built-in RAG capabilities:

```javascript
// 1. Webhook: Receive user question

// 2. HTTP Request: Generative Search
Method: POST
URL: http://weaviate:8080/v1/graphql
Body: {
  "query": "{
    Get {
      Document(
        nearText: {
          concepts: [\"{{ $json.question }}\"]
        }
        limit: 3
      ) {
        title
        content
        _additional {
          generate(
            singleResult: {
              prompt: \"Answer this question: {{ $json.question }}\\n\\nUsing this context: {content}\"
            }
          ) {
            singleResult
            error
          }
        }
      }
    }
  }"
}

// Weaviate will:
// 1. Find top 3 relevant documents
// 2. Send them to configured LLM (OpenAI, Cohere, etc.)
// 3. Return generated answer

// 3. Code Node: Extract Answer
const answer = $json.data.Get.Document[0]._additional.generate.singleResult;
const sources = $json.data.Get.Document.map(doc => ({
  title: doc.title,
  content: doc.content.substring(0, 200) + "..."
}));
return { answer, sources };

// 4. Send response
```

### Advanced Configuration

#### Using Built-in Vectorizers

Configure Weaviate to auto-generate embeddings:

```bash
# Create collection with OpenAI vectorizer
curl -X POST http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -H 'X-OpenAI-Api-Key: YOUR_API_KEY' \
  -d '{
    "class": "Article",
    "vectorizer": "text2vec-openai",
    "moduleConfig": {
      "text2vec-openai": {
        "model": "text-embedding-3-small",
        "dimensions": 1536,
        "vectorizeClassName": false
      }
    },
    "properties": [
      {
        "name": "title",
        "dataType": ["text"]
      },
      {
        "name": "content",
        "dataType": ["text"]
      }
    ]
  }'

# Now objects are automatically vectorized on insert!
curl -X POST http://localhost:8080/v1/objects \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "Article",
    "properties": {
      "title": "Weaviate Tutorial",
      "content": "This is an example article."
    }
  }'
# No vector needed - Weaviate generates it automatically!
```

#### Multi-Tenancy Setup

Isolate data for different users/clients:

```bash
# Enable multi-tenancy on collection
curl -X POST http://localhost:8080/v1/schema \
  -d '{
    "class": "Document",
    "multiTenancyConfig": {
      "enabled": true
    },
    "properties": [...]
  }'

# Create tenant
curl -X POST http://localhost:8080/v1/schema/Document/tenants \
  -d '{
    "tenants": [
      {"name": "tenant_a"},
      {"name": "tenant_b"}
    ]
  }'

# Insert object for specific tenant
curl -X POST http://localhost:8080/v1/objects \
  -d '{
    "class": "Document",
    "tenant": "tenant_a",
    "properties": {...}
  }'

# Query specific tenant only
# GraphQL: Get { Document(tenant: "tenant_a") {...} }
```

#### Replication for High Availability

```bash
# Create collection with replication
curl -X POST http://localhost:8080/v1/schema \
  -d '{
    "class": "Article",
    "replicationConfig": {
      "factor": 2  # 2 copies of each shard
    },
    "properties": [...]
  }'
```

### Troubleshooting

**Collection creation fails:**

```bash
# 1. Check if Weaviate is running
docker ps | grep weaviate

# 2. Check logs
docker logs weaviate --tail 50

# 3. Verify API is accessible
curl http://localhost:8080/v1/.well-known/ready

# 4. Check existing schema
curl http://localhost:8080/v1/schema

# 5. Delete collection if corrupted
curl -X DELETE http://localhost:8080/v1/schema/BrokenCollection
```

**GraphQL queries fail:**

```bash
# 1. Validate GraphQL syntax
# Use GraphQL formatter: https://graphql-formatter.com/

# 2. Check for common issues:
# - Missing quotes around strings
# - Incorrect field names (case-sensitive!)
# - Wrong data types in filters

# 3. Test in GraphQL Playground
# Navigate to: http://localhost:8080/v1/graphql

# 4. Check query response for errors
curl -X POST http://localhost:8080/v1/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query": "..."}'
# Look for "errors" array in response

# 5. Simplify query to isolate issue
# Start with basic Get, then add filters gradually
```

**Objects not being found in search:**

```bash
# 1. Verify objects were inserted
curl http://localhost:8080/v1/objects?class=Document&limit=5

# 2. Check object count
# GraphQL:
# { Aggregate { Document { meta { count } } } }

# 3. Verify vector dimensions match
# Collection expects: 1536 dimensions
# Your vectors must also be: 1536 dimensions

# 4. Test with simple keyword search
# Use BM25 to verify data exists:
# { Get { Document(bm25: {query: "test"}) { title } } }

# 5. Check distance threshold
# Try higher limit or no distance filter
```

**High memory usage:**

```bash
# 1. Check Weaviate stats
curl http://localhost:8080/v1/nodes

# 2. Enable vector quantization
# Product Quantization reduces memory by 4-10x
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "pq": {
        "enabled": true,
        "segments": 96,
        "centroids": 256
      }
    }
  }'

# 3. Adjust HNSW parameters
# Lower ef and maxConnections
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "ef": 64,  # Default: 128
      "maxConnections": 32  # Default: 64
    }
  }'

# 4. Monitor memory
docker stats weaviate

# 5. Consider sharding for large datasets
# Distribute data across multiple nodes
```

**Slow query performance:**

```bash
# 1. Check query complexity
# Avoid deep nested cross-references

# 2. Use filters efficiently
# Indexed properties: faster
# Non-indexed properties: slower

# 3. Optimize HNSW settings
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "ef": 128,  # Higher = better accuracy, slower
      "efConstruction": 256
    }
  }'

# 4. Use limit parameter
# Don't retrieve more results than needed

# 5. Consider caching frequent queries
# Implement query result caching in your application
```

### Best Practices

**Collection Design:**
- Use descriptive class names (PascalCase): `Article`, `UserProfile`
- Define explicit property types
- Enable vectorizer if you want auto-embedding
- Use `tokenization: "field"` for exact-match properties (IDs, categories)
- Use `tokenization: "word"` for full-text search properties

**Property Data Types:**
- `text` - For searchable text
- `text[]` - For arrays of text
- `int`, `number` - For numeric values
- `boolean` - For true/false
- `date` - For timestamps (ISO 8601 format)
- `geoCoordinates` - For lat/lon locations
- `phoneNumber` - For phone numbers
- `blob` - For binary data

**Search Strategy:**
- **Pure semantic:** Use `nearText` or `nearVector` (alpha=1.0)
- **Pure keyword:** Use `bm25` (alpha=0.0)
- **Balanced hybrid:** Use `hybrid` with alpha=0.5
- **Filtered semantic:** Combine `nearText` with `where` filters

**Performance Tips:**
- Batch insert objects (100-1000 at a time)
- Use gRPC for high-throughput queries
- Index properties used in filters
- Limit result size (default 100, adjust as needed)
- Use multi-tenancy for SaaS applications
- Enable replication for high availability

**Data Modeling:**
- Avoid deep cross-references (slow at scale)
- Embed related data in same object when possible
- Use filters instead of cross-references for simple relationships
- Example: Store author name in Book object, not reference

### Integration with Other AI CoreKit Services

**Weaviate + RAGApp:**
- Can configure RAGApp to use Weaviate as vector store
- Alternative to Qdrant with different feature set
- GraphQL interface provides flexibility

**Weaviate + Flowise:**
- Use Weaviate Vector Store node
- URL: `http://weaviate:8080`
- Built-in support in Flowise

**Weaviate + LangChain/LlamaIndex:**
- Native integrations available
- Python: `pip install weaviate-client`
- JavaScript: `npm install weaviate-client`

**Weaviate + n8n:**
- Build custom RAG workflows
- Use HTTP Request or GraphQL nodes
- Combine with other services (Whisper, OCR, etc.)

**Weaviate + Ollama:**
- Configure Ollama as vectorizer
- Local embeddings with `nomic-embed-text`
- Free and private alternative to OpenAI

### Distance Metrics

Weaviate supports multiple distance metrics:

**Cosine Distance:**
- Best for: Text embeddings
- Range: 0 (identical) to 2 (opposite)
- Normalized vectors recommended

**Dot Product:**
- Best for: When magnitude matters
- Range: -∞ to +∞
- Faster than Cosine

**L2 Squared (Euclidean):**
- Best for: Spatial data
- Range: 0 (identical) to +∞
- Actual distance in vector space

**Manhattan (L1):**
- Best for: High-dimensional data
- Range: 0 (identical) to +∞

**Hamming:**
- Best for: Binary vectors
- Counts different bits

### GraphQL vs REST API

**Use GraphQL for:**
- ✅ Complex queries with filters
- ✅ Retrieving specific properties
- ✅ Nested cross-reference queries
- ✅ Aggregations and analytics
- ✅ Interactive development (Playground)

**Use REST for:**
- ✅ CRUD operations on objects
- ✅ Schema management
- ✅ Batch operations
- ✅ Object-by-ID retrieval
- ✅ Simpler integration

**Use gRPC for:**
- ✅ High-throughput queries
- ✅ Low-latency requirements
- ✅ Large data transfers
- ✅ Production search endpoints

### Resources

- **Official Website:** https://weaviate.io/
- **Documentation:** https://weaviate.io/developers/weaviate
- **GitHub:** https://github.com/weaviate/weaviate
- **GraphQL Playground:** `https://weaviate.yourdomain.com/v1/graphql`
- **REST API Docs:** https://weaviate.io/developers/weaviate/api/rest
- **Python Client:** https://github.com/weaviate/weaviate-python-client
- **JS Client:** https://github.com/weaviate/typescript-client
- **Community:** Slack & Forum (links on website)
- **Weaviate Academy:** https://weaviate.io/developers/academy
