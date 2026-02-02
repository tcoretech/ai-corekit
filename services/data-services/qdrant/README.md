# 🔍 Qdrant - Vector Database

### What is Qdrant?

Qdrant (pronounced "quadrant") is a high-performance, open-source vector database and similarity search engine written in Rust. It provides production-ready infrastructure for storing, searching, and managing high-dimensional vectors with additional JSON-like payloads. Qdrant is optimized for AI applications like RAG (Retrieval-Augmented Generation), semantic search, recommendation systems, and anomaly detection, offering both speed and scalability for billion-scale vector operations.

### Features

- **Fast Vector Search** - HNSW (Hierarchical Navigable Small World) indexing for efficient nearest neighbor search
- **Multiple Distance Metrics** - Cosine similarity, Dot product, and Euclidean distance
- **Payload Filtering** - Rich filtering on metadata while searching vectors (hybrid search)
- **Distributed Mode** - Horizontal scaling with sharding and replication
- **REST & gRPC API** - Flexible APIs with client libraries for Python, JavaScript, Rust, Go, and more
- **Quantization Support** - Reduce memory usage with scalar, product, and binary quantization
- **On-Disk Storage** - Store vectors on disk to save RAM for large datasets

### Initial Setup

**Access Qdrant:**

Qdrant is pre-installed and running on your AI CoreKit instance.

1. **Web UI:** `https://qdrant.yourdomain.com`
   - View collections, browse points, inspect vectors
   - No authentication required (internal use only)
2. **REST API:** `http://qdrant:6333` (internal) or `https://qdrant.yourdomain.com` (external)
3. **gRPC API:** `qdrant:6334` (internal, faster for high-throughput)

**First Steps:**

```bash
# Check if Qdrant is running
curl http://localhost:6333/

# Create your first collection
curl -X PUT http://localhost:6333/collections/test_collection \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }'

# Verify collection was created
curl http://localhost:6333/collections/test_collection
```

### n8n Integration Setup

**Connect to Qdrant from n8n:**

- **Internal URL:** `http://qdrant:6333` (use this for HTTP Request nodes)
- **gRPC URL:** `qdrant:6334` (for high-performance operations)
- **No authentication** required for internal access

#### Example 1: Create Collection & Insert Vectors

Set up a new vector collection for semantic search:

```javascript
// 1. HTTP Request: Create Collection
Method: PUT
URL: http://qdrant:6333/collections/documents
Headers:
  Content-Type: application/json
Body: {
  "vectors": {
    "size": 1536,  // OpenAI text-embedding-3-small
    "distance": "Cosine"
  },
  "optimizers_config": {
    "indexing_threshold": 10000
  }
}

// 2. HTTP Request: Generate Embeddings (OpenAI)
Method: POST
URL: https://api.openai.com/v1/embeddings
Headers:
  Authorization: Bearer {{ $env.OPENAI_API_KEY }}
  Content-Type: application/json
Body: {
  "input": "{{ $json.text }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Prepare Point for Qdrant
const embedding = $json.data[0].embedding;
const point = {
  id: $json.document_id,
  vector: embedding,
  payload: {
    text: $json.text,
    source: $json.source,
    timestamp: new Date().toISOString(),
    metadata: $json.metadata
  }
};
return { points: [point] };

// 4. HTTP Request: Upsert Vector to Qdrant
Method: PUT
URL: http://qdrant:6333/collections/documents/points
Body: {
  "points": {{ $json.points }}
}
```

#### Example 2: Semantic Search Pipeline

Search for similar documents using vector similarity:

```javascript
// 1. Webhook: Receive search query

// 2. HTTP Request: Generate Query Embedding
Method: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": "{{ $json.query }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Extract Embedding
const queryVector = $json.data[0].embedding;
return { query_vector: queryVector };

// 4. HTTP Request: Search Qdrant
Method: POST
URL: http://qdrant:6333/collections/documents/points/query
Headers:
  Content-Type: application/json
Body: {
  "query": {{ $json.query_vector }},
  "limit": 5,
  "with_payload": true,
  "with_vector": false
}

// 5. Code Node: Format Results
const results = $json.result.map(point => ({
  id: point.id,
  score: point.score,
  text: point.payload.text,
  source: point.payload.source
}));
return { results };

// 6. Respond to webhook with results
```

#### Example 3: Filtered Vector Search

Combine vector similarity with metadata filtering:

```javascript
// 1. Trigger: User query with filters

// 2. HTTP Request: Search with Filters
Method: POST
URL: http://qdrant:6333/collections/documents/points/query
Body: {
  "query": [0.1, 0.2, ...],  // Your query vector
  "filter": {
    "must": [
      {
        "key": "source",
        "match": { "value": "documentation" }
      },
      {
        "key": "timestamp",
        "range": {
          "gte": "2024-01-01T00:00:00Z"
        }
      }
    ]
  },
  "limit": 10,
  "with_payload": ["text", "source", "timestamp"]
}

// Result: Only vectors matching BOTH:
// - Semantic similarity to query
// - source = "documentation"
// - timestamp >= 2024-01-01
```

#### Example 4: Batch Upsert for Large Datasets

Efficiently upload many vectors at once:

```javascript
// 1. Database Trigger: New records added

// 2. Split in Batches Node: Create batches of 100

// 3. Loop over Batches

// 4. HTTP Request: Batch Generate Embeddings
Method: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": {{ $json.batch.map(item => item.text) }},
  "model": "text-embedding-3-small"
}

// 5. Code Node: Prepare Batch Points
const points = $json.data.map((emb, idx) => ({
  id: $json.batch[idx].id,
  vector: emb.embedding,
  payload: {
    text: $json.batch[idx].text,
    category: $json.batch[idx].category,
    created_at: $json.batch[idx].created_at
  }
}));
return { points };

// 6. HTTP Request: Batch Upsert to Qdrant
Method: PUT
URL: http://qdrant:6333/collections/documents/points
Body: {
  "points": {{ $json.points }}
}

// 7. Wait Node: 1 second (avoid rate limits)

// 8. Loop continues until all batches processed
```

#### Example 5: Hybrid Search (Vector + Text)

Combine dense vectors with sparse text search:

```javascript
// 1. Create collection with both dense and sparse vectors
// HTTP Request: Create Collection
Method: PUT
URL: http://qdrant:6333/collections/hybrid_docs
Body: {
  "vectors": {
    "dense": {
      "size": 1536,
      "distance": "Cosine"
    }
  },
  "sparse_vectors": {
    "sparse": {}
  }
}

// 2. HTTP Request: Hybrid Search
Method: POST
URL: http://qdrant:6333/collections/hybrid_docs/points/query
Body: {
  "prefetch": [
    {
      "query": {
        "indices": [1, 2, 5, 10],  // Sparse vector (BM25 keywords)
        "values": [0.5, 0.8, 0.3, 0.9]
      },
      "using": "sparse",
      "limit": 100
    }
  ],
  "query": [0.1, 0.2, ...],  // Dense vector (semantic)
  "using": "dense",
  "limit": 10
}

// This performs:
// 1. BM25 keyword search (sparse) -> 100 candidates
// 2. Semantic reranking (dense) -> top 10 results
```

### Advanced Configuration

#### Optimizing Collection Settings

```bash
# Create collection with custom HNSW parameters
curl -X PUT http://localhost:6333/collections/optimized \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    },
    "hnsw_config": {
      "m": 32,  # Higher = better accuracy, more memory
      "ef_construct": 256,  # Higher = better index quality
      "full_scan_threshold": 20000
    },
    "optimizers_config": {
      "indexing_threshold": 50000,
      "memmap_threshold": 100000  # Store index on disk
    }
  }'
```

#### Creating Payload Indexes for Fast Filtering

```bash
# Index a field for faster filtering
curl -X PUT http://localhost:6333/collections/documents/index \
  -H 'Content-Type: application/json' \
  -d '{
    "field_name": "category",
    "field_schema": "keyword"
  }'

# Index a numeric field
curl -X PUT http://localhost:6333/collections/documents/index \
  -H 'Content-Type: application/json' \
  -d '{
    "field_name": "price",
    "field_schema": "float"
  }'
```

#### Quantization for Memory Efficiency

```bash
# Enable scalar quantization
curl -X PATCH http://localhost:6333/collections/documents \
  -H 'Content-Type: application/json' \
  -d '{
    "quantization_config": {
      "scalar": {
        "type": "int8",
        "quantile": 0.99,
        "always_ram": true
      }
    }
  }'

# Result: 4x memory reduction with minimal accuracy loss
```

### Troubleshooting

**Collection creation fails:**

```bash
# 1. Check if Qdrant is running
docker ps | grep qdrant

# 2. Check logs for errors
docker logs qdrant --tail 50

# 3. Verify API is accessible
curl http://localhost:6333/
# Should return: {"title":"qdrant - vector search engine","version":"1.x.x"}

# 4. Check available collections
curl http://localhost:6333/collections

# 5. Delete and recreate collection if corrupted
curl -X DELETE http://localhost:6333/collections/broken_collection
```

**Search returns no results:**

```bash
# 1. Check collection has points
curl http://localhost:6333/collections/documents

# Should show: "points_count": > 0

# 2. Verify vector dimensions match
# Collection size: 384
# Query vector size must also be: 384

# 3. Test with scroll to see raw data
curl -X POST http://localhost:6333/collections/documents/points/scroll \
  -H 'Content-Type: application/json' \
  -d '{"limit": 5, "with_payload": true, "with_vector": true}'

# 4. Check distance metric
# If using normalized vectors, use Dot product instead of Cosine

# 5. Increase limit or adjust threshold
# Try limit: 100 to see if results exist but scored low
```

**High memory usage:**

```bash
# 1. Check collection stats
curl http://localhost:6333/collections/documents

# 2. Enable quantization
# Reduces memory by 4-16x (see Advanced Configuration)

# 3. Store vectors on disk
curl -X PATCH http://localhost:6333/collections/documents \
  -d '{
    "vectors": {
      "on_disk": true
    }
  }'

# 4. Reduce HNSW parameters
# Lower m and ef_construct values

# 5. Monitor memory
docker stats qdrant
```

**Slow search performance:**

```bash
# 1. Create payload indexes for filtered fields
# See Advanced Configuration section

# 2. Optimize collection
curl -X POST http://localhost:6333/collections/documents/segments

# 3. Increase ef parameter for HNSW
# In search query: "params": {"hnsw_ef": 128}

# 4. Use smaller result limit
# limit: 10 instead of 100

# 5. Enable gRPC for faster throughput
# Use port 6334 instead of 6333
```

**Points not being indexed:**

```bash
# 1. Check optimizer status
curl http://localhost:6333/collections/documents

# Look for: "optimizer_status": "ok" or "optimizing"

# 2. Wait for indexing to complete
# Collections turn "yellow" during optimization
# Becomes "green" when done

# 3. Force optimization
curl -X POST http://localhost:6333/collections/documents/optimizer

# 4. Check indexing threshold
# Collection must have > indexing_threshold points
# Default: 20,000 points

# 5. Manually trigger indexing
# Lower threshold or insert more points
```

### Best Practices

**Vector Dimensions:**
- **OpenAI text-embedding-3-small:** 1536 dimensions
- **OpenAI text-embedding-3-large:** 3072 dimensions
- **Ollama nomic-embed-text:** 768 dimensions
- **Sentence-Transformers (all-MiniLM-L6-v2):** 384 dimensions

Choose based on accuracy vs memory tradeoff.

**Collection Design:**
- Use **single collection** with payload-based filtering (multitenancy)
- Only create multiple collections if you need hard isolation
- Index frequently filtered payload fields
- Use consistent naming: `{app}_{data_type}` (e.g., `myapp_documents`)

**Payload Structure:**
```json
{
  "id": "doc_123",
  "vector": [...],
  "payload": {
    "text": "Original content",
    "metadata": {
      "source": "web",
      "author": "John Doe",
      "timestamp": "2025-01-01T00:00:00Z"
    },
    "tags": ["ai", "database"],
    "category": "documentation"
  }
}
```

**Search Optimization:**
- Index payload fields used in filters
- Use `with_payload: ["field1", "field2"]` to retrieve only needed fields
- Set `with_vector: false` if you don't need vectors in results
- Batch operations when possible (upsert 100-1000 points at once)
- Use gRPC API for high-throughput scenarios

**Memory Management:**
- Enable quantization for large collections (>1M vectors)
- Store vectors on disk if memory is limited
- Use `on_disk_payload: true` for large payloads
- Monitor memory with `docker stats qdrant`

**Backup & Recovery:**
```bash
# Create snapshot
curl -X POST http://localhost:6333/collections/documents/snapshots

# Download snapshot
curl http://localhost:6333/collections/documents/snapshots/snapshot_name \
  --output snapshot.snapshot

# Restore from snapshot
curl -X PUT http://localhost:6333/collections/documents/snapshots/upload \
  --data-binary @snapshot.snapshot
```

### Integration with Other AI CoreKit Services

**Qdrant + RAGApp:**
- RAGApp uses Qdrant as its default vector store
- Pre-configured at `http://qdrant:6333`
- All RAGApp document embeddings stored in Qdrant

**Qdrant + Flowise:**
- Use Qdrant Vector Store node in Flowise
- URL: `http://qdrant:6333`
- Collections auto-created by Flowise agents
- Enables RAG workflows with visual builder

**Qdrant + Ollama:**
- Generate embeddings locally with Ollama
- Model: `nomic-embed-text` (768 dimensions)
- Free and fast for development
- Example: Embed documents → Store in Qdrant → Search

**Qdrant + Open WebUI:**
- Open WebUI can use Qdrant for document RAG
- Configure in Open WebUI settings
- Upload docs → Auto-embedded → Stored in Qdrant

**Qdrant + n8n:**
- Build custom RAG pipelines
- Automate document ingestion and search
- Combine with SearXNG, Whisper, OCR, etc.
- Create intelligent automation workflows

### Distance Metrics Explained

**Cosine Similarity:**
- Best for: Text embeddings, semantic search
- Range: -1 (opposite) to 1 (identical)
- Normalized vectors: focus on direction, not magnitude

**Dot Product:**
- Best for: When magnitude matters
- Range: -∞ to +∞
- Faster than Cosine (no normalization needed)

**Euclidean Distance:**
- Best for: Spatial data, image embeddings
- Range: 0 (identical) to +∞
- Measures actual distance in vector space

### Resources

- **Official Website:** https://qdrant.tech/
- **Documentation:** https://qdrant.tech/documentation/
- **GitHub:** https://github.com/qdrant/qdrant
- **Web UI:** `https://qdrant.yourdomain.com`
- **REST API Docs:** https://api.qdrant.tech/api-reference
- **Python Client:** https://github.com/qdrant/qdrant-client
- **Community:** Discord (link on website)
- **Benchmarks:** https://qdrant.tech/benchmarks/
