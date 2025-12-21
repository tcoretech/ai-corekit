# 🕷️ Crawl4Ai - AI-Optimized Web Crawler

### What is Crawl4AI?

Crawl4AI is the #1 trending open-source web crawler on GitHub, specifically optimized for large language models and AI agents. It delivers blazing-fast, AI-ready web crawling that's 6x faster than traditional tools, with built-in stealth capabilities to bypass bot detection systems like Cloudflare and Akamai. The crawler outputs clean Markdown that's perfect for RAG pipelines, knowledge bases, and AI training data.

Unlike basic scrapers, Crawl4AI uses intelligent adaptive crawling with information foraging algorithms to determine when sufficient information has been collected, making it highly efficient for large-scale data extraction.

### Features

- **AI-First Architecture**: Outputs clean, structured Markdown optimized for LLMs, RAG systems, and fine-tuning
- **Blazing Fast Performance**: 6x faster than traditional crawlers with async architecture for parallel processing
- **Stealth & Anti-Detection**: Undetected browser mode bypasses Cloudflare, Akamai, and custom bot protection
- **Deep Crawling Strategies**: DFS and BFS algorithms for comprehensive multi-page extraction with depth control
- **Smart Content Extraction**: Heuristic filtering, lazy-loaded content handling, and adaptive stopping
- **Session Management**: Cookies, proxies, custom headers, and JavaScript execution support
- **No API Keys Required**: Fully self-hosted, no rate limits, complete data ownership

### API Access

Crawl4AI runs as an internal service and is accessible to other containers:

**Internal API Endpoint:**
```
http://crawl4ai:11235
```

**Service Features:**
- RESTful API for crawling operations
- Async crawling with job management
- Multi-URL batch processing
- Configurable extraction strategies
- Session persistence across requests

### n8n Integration Setup

Crawl4AI doesn't require credentials in n8n - it's accessed via HTTP Request nodes to the internal API.

**Integration Methods:**

1. **Basic HTTP Request (Simple Crawling)**

```javascript
// HTTP Request Node Configuration
Method: POST
URL: http://crawl4ai:11235/api/crawl
Body (JSON):
{
  "url": "https://example.com",
  "markdown": true,
  "remove_forms": true,
  "bypass_cache": false
}
```

2. **Advanced Crawling with Extraction Strategy**

```javascript
// HTTP Request Node - Advanced Configuration
Method: POST
URL: http://crawl4ai:11235/api/crawl/advanced
Body (JSON):
{
  "url": "https://example.com/docs",
  "extraction_strategy": {
    "type": "css",
    "selectors": {
      "title": "h1.title",
      "content": "div.content",
      "links": "a.internal"
    }
  },
  "markdown": true,
  "wait_for": "networkidle",
  "timeout": 30000
}
```

### Example Workflows

#### Example 1: Documentation Scraper for RAG

This workflow scrapes technical documentation and prepares it for a RAG system.

**Workflow Structure:**
1. **Webhook/Schedule Trigger** - Trigger crawling on schedule or demand
2. **HTTP Request** - Crawl documentation site
   ```javascript
   // Node: Crawl Documentation
   Method: POST
   URL: http://crawl4ai:11235/api/crawl
   Body:
   {
     "url": "{{ $json.documentationUrl }}",
     "markdown": true,
     "wait_for_images": true,
     "bypass_cache": true,
     "extraction_strategy": {
       "type": "markdown",
       "include_links": true,
       "include_images": false
     }
   }
   ```
3. **Code Node** - Process and chunk markdown
   ```javascript
   // Split markdown into chunks for vector storage
   const markdown = $json.markdown;
   const chunkSize = 1000;
   const chunks = [];
   
   const lines = markdown.split('\n');
   let currentChunk = '';
   
   for (const line of lines) {
     if (currentChunk.length + line.length > chunkSize && currentChunk.length > 0) {
       chunks.push({
         content: currentChunk.trim(),
         source: $json.url,
         timestamp: new Date().toISOString()
       });
       currentChunk = line;
     } else {
       currentChunk += line + '\n';
     }
   }
   
   if (currentChunk.length > 0) {
     chunks.push({
       content: currentChunk.trim(),
       source: $json.url,
       timestamp: new Date().toISOString()
     });
   }
   
   return chunks.map(chunk => ({ json: chunk }));
   ```
4. **Qdrant/Weaviate Node** - Store in vector database

**Use Case**: Automatically keep your AI knowledge base updated with the latest documentation.

#### Example 2: Competitive Intelligence Monitor

Monitor competitor websites and extract product information.

**Workflow Structure:**
1. **Schedule Trigger** - Run daily at specific time
2. **HTTP Request** - Deep crawl competitor site
   ```javascript
   // Node: Deep Crawl Competitor
   Method: POST
   URL: http://crawl4ai:11235/api/crawl/deep
   Body:
   {
     "url": "https://competitor.com/products",
     "strategy": "bfs",
     "max_depth": 2,
     "max_pages": 50,
     "include_external": false,
     "extraction_strategy": {
       "type": "json_css",
       "schema": {
         "product_name": ".product-title",
         "price": ".product-price",
         "description": ".product-description",
         "features": [".feature-list li"]
       }
     }
   }
   ```
3. **Code Node** - Compare with previous data
   ```javascript
   // Detect price changes and new products
   const currentProducts = $json.products;
   const previousData = $('Compare with Storage').first().json;
   
   const changes = {
     new_products: [],
     price_changes: [],
     discontinued: []
   };
   
   // Compare logic
   currentProducts.forEach(product => {
     const previous = previousData.find(p => p.product_name === product.product_name);
     if (!previous) {
       changes.new_products.push(product);
     } else if (previous.price !== product.price) {
       changes.price_changes.push({
         name: product.product_name,
         old_price: previous.price,
         new_price: product.price
       });
     }
   });
   
   return [{ json: changes }];
   ```
4. **Send Email/Slack** - Notify team of significant changes

#### Example 3: Research Data Collection

Collect academic papers or articles for research analysis.

**Workflow Structure:**
1. **Manual Trigger** - Start with research query
2. **HTTP Request** - Crawl research sources
   ```javascript
   Method: POST
   URL: http://crawl4ai:11235/api/crawl
   Body:
   {
     "url": "{{ $json.searchUrl }}",
     "markdown": true,
     "javascript_enabled": true,
     "wait_for": "networkidle2",
     "extraction_strategy": {
       "type": "llm",
       "instruction": "Extract academic paper titles, authors, abstracts, and publication dates. Focus on papers related to artificial intelligence and machine learning."
     }
   }
   ```
3. **Code Node** - Clean and structure data
4. **Store** - Save to database or export to CSV

### Troubleshooting

**Issue 1: Crawler Gets Blocked by Target Site**

Many sites have anti-bot protection. Use stealth mode and proxies.

```bash
# Check if Crawl4AI service is running
launchkit ps | grep crawl4ai

# View Crawl4AI logs for blocking indicators
launchkit logs crawl4ai | grep -i "blocked\|captcha\|403\|429"
```

**Solution:**
- Enable stealth mode in your API request:
  ```json
  {
    "url": "https://protected-site.com",
    "stealth_mode": true,
    "user_agent": "custom-agent-string"
  }
  ```
- Add delays between requests to avoid rate limiting
- Use proxy rotation if crawling at scale

**Issue 2: JavaScript-Heavy Site Not Fully Loading**

Modern SPAs may need time for JavaScript to execute.

```bash
# Check crawler logs for timeout errors
launchkit logs crawl4ai --tail 100
```

**Solution:**
- Increase wait time and use appropriate wait conditions:
  ```json
  {
    "url": "https://spa-site.com",
    "wait_for": "networkidle",
    "wait_for_images": true,
    "timeout": 60000,
    "page_load_delay": 3000
  }
  ```
- For specific elements: `"wait_for_selector": ".content-loaded"`

**Issue 3: Extracted Content is Incomplete or Wrong**

The default extraction might not work for all site structures.

**Diagnostic:**
```bash
# Test crawl directly to see raw output
curl -X POST http://localhost:11235/api/crawl \
  -H "Content-Type: application/json" \
  -d '{"url": "https://target-site.com", "markdown": true}'
```

**Solution:**
- Use CSS selectors for precise extraction:
  ```json
  {
    "extraction_strategy": {
      "type": "css",
      "selectors": {
        "main_content": "article.main",
        "title": "h1",
        "metadata": ".post-meta"
      }
    }
  }
  ```
- For complex sites, use the LLM extraction strategy with specific instructions

**Issue 4: Container Resource Issues**

Crawling many pages simultaneously can be resource-intensive.

```bash
# Check container resource usage
docker stats crawl4ai

# Check available memory
launchkit exec crawl4ai free -h
```

**Solution:**
- Limit concurrent crawls in your workflow
- Add delays between large batch operations
- Increase container resources in `docker-compose.yml` if needed:
  ```yaml
  crawl4ai:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
  ```

### Advanced Features

**Multi-URL Batch Processing:**
Process multiple URLs with different strategies in one request.

```json
{
  "urls": [
    {
      "url": "https://site1.com",
      "strategy": "fast",
      "markdown": true
    },
    {
      "url": "https://site2.com/docs",
      "strategy": "deep",
      "max_depth": 2
    }
  ]
}
```

**Session Management:**
Maintain state across multiple requests (useful for sites requiring login).

```json
{
  "url": "https://members.site.com/content",
  "session_id": "my-session-123",
  "cookies": [
    {"name": "auth_token", "value": "xxx", "domain": ".site.com"}
  ]
}
```

**Custom JavaScript Execution:**
Execute JavaScript on the page before extraction.

```json
{
  "url": "https://dynamic-site.com",
  "js_code": "document.querySelector('.load-more-button').click();",
  "wait_after_js": 2000
}
```

### Resources

- **Official Documentation**: https://docs.crawl4ai.com/
- **GitHub Repository**: https://github.com/unclecode/crawl4ai
- **Discord Community**: https://discord.gg/jP8KfhDhyN
- **Internal API**: `http://crawl4ai:11235`
- **API Documentation**: `http://crawl4ai:11235/docs` (Swagger UI)
- **Example Notebooks**: https://github.com/unclecode/crawl4ai/tree/main/docs/examples

**Related Services:**
- Use with **SearXNG** for initial URL discovery
- Feed extracted content to **Qdrant** or **Weaviate** for vector search
- Process with **Ollama** for content analysis
- Store structured data in **Supabase** or **PostgreSQL**
