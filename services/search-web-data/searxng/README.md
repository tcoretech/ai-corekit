# 🔍 SearXNG - Privacy-Focused Metasearch Engine

### What is SearXNG?

SearXNG is an open-source, privacy-respecting metasearch engine that aggregates results from over 70 search engines (including Google, Bing, DuckDuckGo, Wikipedia, and more) while ensuring complete user anonymity. Unlike traditional search engines, SearXNG does not track searches, store IP addresses, create user profiles, or serve personalized ads. It acts as a privacy shield between you and search engines, making it perfect for AI agents, research workflows, and privacy-conscious organizations.

### Features

- **70+ Search Engines** - Aggregates results from Google, Bing, DuckDuckGo, Wikipedia, GitHub, arXiv, and many more
- **Complete Privacy** - No tracking, no cookies, no search history, no user profiling
- **Category-Based Search** - Filter by General, Images, Videos, News, Files, IT, Maps, Music, Science, Social Media
- **Customizable** - Choose which engines to use, customize themes, configure safe search levels
- **JSON API** - RESTful API for programmatic access and automation
- **Self-Hosted** - Full control over your search infrastructure and data
- **Multi-Language** - 58 translations and language-specific search capabilities

### Initial Setup

**First Access to SearXNG:**

1. Navigate to `https://searxng.yourdomain.com`
2. No login required - SearXNG is public by default (can be restricted via Caddy auth)
3. Explore the interface:
   - **Categories:** General, Images, Videos, News, Files, IT, Science, etc.
   - **Preferences:** Configure default engines, themes, language, safe search
   - **Settings:** Customize which search engines to use
4. Test a search to verify it's working

**Enable JSON API (Required for n8n):**

The JSON API is **disabled by default** and must be enabled:

```bash
# Navigate to your SearXNG configuration
cd ~/ai-launchkit

# Edit the settings.yml file
nano searxng/settings.yml

# Find the 'search:' section and add 'json' to formats:
search:
  formats:
    - html
    - json    # Add this line to enable JSON API
    - csv
    - rss

# Save and restart SearXNG
docker compose restart searxng
```

**Test JSON API:**

```bash
# Test that JSON format is working
curl "https://searxng.yourdomain.com/search?q=test&format=json"

# Should return JSON with search results
```

### n8n Integration Setup

SearXNG has **native n8n integration** with a built-in Tool node!

**Method 1: SearXNG Tool Node (Recommended for AI Agents)**

1. Add **SearXNG Tool** node to workflow
2. Create SearXNG credentials:
   - Click **Create New Credential**
   - **API URL:** `http://searxng:8080` (internal) or `https://searxng.yourdomain.com` (external)
   - Save credentials
3. The node is now ready to use with AI Agent nodes!

**Method 2: HTTP Request Node (More Control)**

Use HTTP Request for custom queries and advanced parameters.

**Internal URL:** `http://searxng:8080`

**API Endpoint:** `GET /search` or `GET /`

**Required Parameters:**
- `q`: Search query (required)
- `format`: Must be `json` for API usage

### Example Workflows

#### Example 1: AI Research Assistant with Web Search

```javascript
// Build an AI agent with real-time web search capabilities

// 1. Chat Trigger Node
// User asks a question

// 2. AI Agent Node (OpenAI or Claude)
Model: gpt-4o-mini
System Prompt: You are a research assistant. Use web search when needed to provide accurate, up-to-date information.

// 3. Add SearXNG Tool Node to Agent
// The Tool node is automatically available to the agent
Credential: SearXNG (http://searxng:8080)

// 4. Agent automatically calls SearXNG when needed!
// User: "What are the latest developments in quantum computing?"
// Agent: *Searches SearXNG* → *Synthesizes results* → Provides answer

// The agent will automatically:
// - Determine when web search is needed
// - Execute searches via SearXNG
// - Integrate results into responses
```

#### Example 2: Competitive Intelligence Monitoring

```javascript
// Automated daily competitor research

// 1. Schedule Trigger Node
Cron: 0 9 * * *  // Every day at 9 AM

// 2. HTTP Request Node - Search for Competitor News
Method: GET
URL: http://searxng:8080/search
Query Parameters:
  q: "competitor-name" AND ("funding" OR "product launch" OR "acquisition")
  format: json
  categories: news
  time_range: day  // Only results from last 24 hours
  engines: google,bing,duckduckgo
  language: en

// Response format:
{
  "results": [
    {
      "title": "Competitor raises $50M Series B",
      "url": "https://techcrunch.com/...",
      "content": "Brief description...",
      "engine": "google",
      "category": "news",
      "publishedDate": "2024-01-15"
    }
  ],
  "number_of_results": 15
}

// 3. IF Node - Check if results found
Condition: {{ $json.number_of_results > 0 }}

// 4. Loop Node - Process each result
Items: {{ $json.results }}

// 5. Code Node - Filter relevant news
const result = $input.item.json;

// Check if really relevant
const relevantKeywords = ['funding', 'acquisition', 'product', 'launch', 'partnership'];
const isRelevant = relevantKeywords.some(keyword => 
  result.title.toLowerCase().includes(keyword) ||
  result.content.toLowerCase().includes(keyword)
);

if (!isRelevant) return null;  // Skip this item

return {
  title: result.title,
  url: result.url,
  summary: result.content,
  source: result.engine,
  date: result.publishedDate
};

// 6. OpenAI Node - Generate Intelligence Summary
Model: gpt-4o-mini
Prompt: |
  Analyze this competitor news and provide:
  1. Strategic implications for our business
  2. Potential threats or opportunities
  3. Recommended actions
  
  News: {{ $json.title }}
  Details: {{ $json.summary }}

// 7. Notion Node - Add to Intelligence Database
Database: Competitive Intelligence
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Date: {{ $json.date }}
  Source: {{ $json.source }}
  Analysis: {{ $('OpenAI').json.analysis }}
  Threat Level: {{ $('OpenAI').json.threat_level }}

// 8. Slack Node - Daily Summary
Channel: #competitive-intel
Message: |
  📊 Daily Competitor Intelligence Report
  
  **New Findings:** {{ $('Loop').itemCount }} articles
  
  🔴 High Priority:
  {{ $('Loop').all().filter(x => x.json.threat_level === 'high').map(x => x.json.title).join('\n- ') }}
  
  View full report in Notion
```

#### Example 3: Academic Research Aggregator

```javascript
// Search multiple academic databases simultaneously

// 1. Webhook Trigger - Research query
// Input: { "topic": "machine learning fairness", "year": "2024" }

// 2. HTTP Request - Search Academic Sources
Method: GET
URL: http://searxng:8080/search
Query Parameters:
  q: "{{ $json.topic }}" {{ $json.year }}
  format: json
  categories: science  // Scientific papers only
  engines: arxiv,google scholar,semantic scholar,pubmed
  pageno: 1

// 3. Code Node - Parse and Deduplicate Results
const results = $input.item.json.results;

// Remove duplicates by DOI or URL
const uniqueResults = [];
const seenUrls = new Set();

for (const result of results) {
  const url = result.url;
  if (!seenUrls.has(url)) {
    seenUrls.add(url);
    uniqueResults.push({
      title: result.title,
      url: result.url,
      abstract: result.content,
      source: result.engine,
      published: result.publishedDate || 'Unknown'
    });
  }
}

return uniqueResults;

// 4. Loop Node - Process each paper
Items: {{ $json }}

// 5. HTTP Request - Fetch full paper metadata
// Use DOI or API to get more details

// 6. Qdrant Node - Store paper embeddings
// Create vector embeddings for semantic search

// 7. Notion Node - Create research database
Database: Research Papers
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Abstract: {{ $json.abstract }}
  Source: {{ $json.source }}
  Published: {{ $json.published }}
  Tags: [{{ $json.topic }}]

// 8. Gmail Node - Send digest
To: researcher@university.edu
Subject: Research Digest - {{ $json.topic }}
Body: |
  Found {{ $('Code Node').itemCount }} papers on {{ $json.topic }}:
  
  {{ $('Loop').all().map(x => `- ${x.json.title}\n  ${x.json.url}`).join('\n\n') }}
```

#### Example 4: Multi-Engine Image Search

```javascript
// Search images across multiple engines

// 1. Webhook Trigger
// Input: { "query": "minimalist office design" }

// 2. HTTP Request - Image Search
Method: GET
URL: http://searxng:8080/search
Query Parameters:
  q: {{ $json.query }}
  format: json
  categories: images  // Images only
  engines: google images,bing images,flickr,unsplash
  safesearch: 1  // Moderate safe search
  pageno: 1

// Response includes image results:
{
  "results": [
    {
      "title": "Minimalist Office Setup",
      "url": "https://example.com/image.jpg",
      "thumbnail_src": "https://example.com/thumb.jpg",
      "img_src": "https://example.com/full.jpg",
      "engine": "google images",
      "resolution": "1920x1080"
    }
  ]
}

// 3. Code Node - Filter high-resolution images
const images = $input.item.json.results;

const highRes = images.filter(img => {
  if (!img.resolution) return false;
  const [width, height] = img.resolution.split('x').map(Number);
  return width >= 1920 && height >= 1080;  // Full HD or higher
});

return highRes.slice(0, 20);  // Top 20 results

// 4. Loop Node - Download images
Items: {{ $json }}

// 5. HTTP Request - Download image
Method: GET
URL: {{ $json.img_src }}
Response Format: File

// 6. Google Drive Node - Upload to folder
Folder: /Design Inspiration/{{ $('Webhook').json.query }}
File: {{ $binary.data }}
```

#### Example 5: News Aggregation with Sentiment Analysis

```javascript
// Multi-source news monitoring with AI analysis

// 1. Schedule Trigger
Cron: 0 */6 * * *  // Every 6 hours

// 2. Set Node - Define topics
[
  "artificial intelligence regulation",
  "climate change policy",
  "cryptocurrency market"
]

// 3. Loop Node - Search each topic
Items: {{ $json }}

// 4. HTTP Request - Search news
Method: GET
URL: http://searxng:8080/search
Query Parameters:
  q: {{ $json.topic }}
  format: json
  categories: news
  engines: google news,bing news,yahoo news
  time_range: day  // Last 24 hours
  language: en

// 5. Code Node - Extract and clean results
const articles = $input.item.json.results;

return articles.map(article => ({
  topic: $('Loop').item.json.topic,
  title: article.title,
  url: article.url,
  snippet: article.content,
  source: article.engine,
  published: article.publishedDate
}));

// 6. OpenAI Node - Sentiment Analysis
Model: gpt-4o-mini
Prompt: |
  Analyze sentiment of this news article:
  Title: {{ $json.title }}
  Snippet: {{ $json.snippet }}
  
  Return JSON:
  {
    "sentiment": "positive/neutral/negative",
    "confidence": 0.0-1.0,
    "key_points": ["point 1", "point 2"],
    "impact": "low/medium/high"
  }

// 7. PostgreSQL Node - Store results
Table: news_monitoring
Fields:
  topic: {{ $json.topic }}
  title: {{ $json.title }}
  url: {{ $json.url }}
  sentiment: {{ $('OpenAI').json.sentiment }}
  impact: {{ $('OpenAI').json.impact }}
  key_points: {{ $('OpenAI').json.key_points }}
  monitored_at: {{ $now }}

// 8. IF Node - Alert on high-impact negative news
If: {{ $('OpenAI').json.sentiment === 'negative' && $('OpenAI').json.impact === 'high' }}

// 9. Slack Node - Send alert
Channel: #alerts
Message: |
  ⚠️ High Impact Negative News Alert
  
  **Topic:** {{ $json.topic }}
  **Headline:** {{ $json.title }}
  **Sentiment:** {{ $('OpenAI').json.sentiment }} ({{ $('OpenAI').json.confidence * 100 }}% confident)
  **Impact:** {{ $('OpenAI').json.impact }}
  
  **Key Points:**
  {{ $('OpenAI').json.key_points.join('\n- ') }}
  
  Read more: {{ $json.url }}
```

### API Parameters Reference

**Search Endpoint:** `GET /search` or `GET /`

**Required Parameters:**
- `q`: Search query string

**Optional Parameters:**
- `format`: Output format (`json`, `csv`, `rss`, `html`) - **Required for API: `json`**
- `categories`: Comma-separated list (`general`, `images`, `videos`, `news`, `files`, `it`, `maps`, `music`, `science`, `social_media`)
- `engines`: Comma-separated list (`google`, `bing`, `duckduckgo`, `wikipedia`, `github`, etc.)
- `language`: Language code (`en`, `de`, `fr`, `es`, `it`, etc.)
- `pageno`: Page number (default: 1)
- `time_range`: Filter by time (`day`, `week`, `month`, `year`)
- `safesearch`: Safe search level (`0`=off, `1`=moderate, `2`=strict)

**Example Request:**
```bash
curl "http://searxng:8080/search?q=n8n+automation&format=json&categories=general&engines=google,bing&language=en&time_range=month"
```

**Response Format:**
```json
{
  "query": "n8n automation",
  "number_of_results": 42,
  "results": [
    {
      "url": "https://example.com",
      "title": "Result Title",
      "content": "Description snippet...",
      "engine": "google",
      "category": "general",
      "publishedDate": "2024-01-15"
    }
  ],
  "infoboxes": [],
  "suggestions": ["n8n workflow", "n8n tutorial"]
}
```

### Troubleshooting

**Issue 1: JSON API Returns HTML Instead of JSON**

```bash
# Check if JSON format is enabled
docker exec searxng cat /etc/searxng/settings.yml | grep -A5 "formats:"

# Should show:
# formats:
#   - html
#   - json    # Must be present

# If missing, add it to settings.yml
nano ~/ai-launchkit/searxng/settings.yml

# Add json to formats section, save, and restart
docker compose restart searxng
```

**Solution:**
- JSON format is disabled by default in SearXNG
- Must manually enable in `settings.yml` file
- Restart container after making changes
- Test with `curl "http://searxng:8080/search?q=test&format=json"`

**Issue 2: Empty or Few Search Results**

```bash
# Check which engines are enabled
curl "http://searxng:8080/config" | jq '.engines[] | select(.enabled==true)'

# Test specific engine
curl "http://searxng:8080/search?q=test&format=json&engines=google"

# Check SearXNG logs
docker logs searxng --tail 100 | grep -i "error\|failed"
```

**Solution:**
- Some engines may be rate-limited or blocked
- Try different engines: `engines=google,bing,duckduckgo`
- Increase timeout in settings.yml
- Some engines require API keys (configure in settings.yml)
- Use `categories=general` for broader results

**Issue 3: Rate Limiting / CAPTCHA Challenges**

```bash
# Check for rate limit errors in logs
docker logs searxng | grep -i "rate\|captcha\|429"

# SearXNG may get rate-limited by search engines
# Solution: Enable more engines to distribute load
```

**Solution:**
- Use multiple engines simultaneously to avoid rate limits on any single engine
- Configure request delays in settings.yml
- Consider using Tor or proxy for additional anonymity (also helps with rate limits)
- Reduce frequency of automated searches
- Use public SearXNG instances for testing (searx.space)

**Issue 4: Specific Engine Not Working**

```bash
# Test individual engine
curl "http://searxng:8080/search?q=test&format=json&engines=google"

# Check engine status in preferences
# Visit: https://searxng.yourdomain.com/preferences

# Some engines require configuration
docker exec searxng cat /etc/searxng/settings.yml | grep -A10 "engines:"
```

**Solution:**
- Not all 70+ engines work out of the box
- Some require API keys (Google Custom Search, Bing API, etc.)
- Configure required engines in settings.yml
- Check official SearXNG docs for engine-specific setup
- Use engines without API requirements: duckduckgo, wikipedia, github

**Issue 5: Cannot Access from n8n**

```bash
# Test connectivity from n8n container
docker exec n8n curl http://searxng:8080/

# Should return HTML page

# Test JSON API
docker exec n8n curl "http://searxng:8080/search?q=test&format=json"

# Check if both containers are in same network
docker network inspect localai | grep -E "searxng|n8n"
```

**Solution:**
- Use internal URL: `http://searxng:8080` (not localhost or external domain)
- Ensure JSON format is enabled (see Issue 1)
- Check Docker network connectivity
- Verify searxng container is running: `docker ps | grep searxng`

### Available Search Engines

SearXNG supports **70+ search engines**. Here are the most useful ones:

**General:**
- Google, Bing, DuckDuckGo, Yahoo, Brave Search, Startpage, Qwant

**Academic/Science:**
- arXiv, Google Scholar, Semantic Scholar, PubMed, BASE, Springer

**Code/Tech:**
- GitHub, StackOverflow, npm, PyPI, Docker Hub, GitLab

**Images:**
- Google Images, Bing Images, Flickr, Unsplash, Pixabay, DeviantArt

**Videos:**
- YouTube, Vimeo, Dailymotion, PeerTube

**News:**
- Google News, Bing News, Yahoo News, Reddit, Hacker News

**Files:**
- The Pirate Bay, Archive.org, Torrentz, Anna's Archive

**Maps:**
- OpenStreetMap, Google Maps, Bing Maps

**Social:**
- Reddit, Mastodon, Lemmy, Twitter (via Nitter)

Full list available at: https://docs.searxng.org/admin/engines/configured_engines.html

### Resources

- **Official Documentation:** https://docs.searxng.org/
- **GitHub:** https://github.com/searxng/searxng
- **Search API Docs:** https://docs.searxng.org/dev/search_api.html
- **Public Instances:** https://searx.space
- **Engine Configuration:** https://docs.searxng.org/admin/engines/index.html
- **n8n Integration:** https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.toolsearxng/

### Best Practices

**For AI Agents:**
- Use SearXNG Tool node - it's specifically designed for agent integration
- Agent automatically decides when to search
- Provide clear system prompts about when web search is needed
- Combine with RAG for best results (SearXNG for fresh data, vector DB for historical)

**For Research Workflows:**
- Use category filters (`categories=science`) for focused results
- Specify multiple engines for comprehensive coverage
- Filter by time_range for recent information
- Deduplicate results across engines

**For Production:**
- Enable only necessary engines to reduce latency
- Configure rate limiting to avoid blocks
- Use result caching (Redis) for frequently searched terms
- Monitor engine availability and adjust workflow

**Privacy Considerations:**
- SearXNG hides your IP from search engines
- No cookies or tracking
- Results are not personalized (same query = same results for everyone)
- For maximum anonymity, combine with Tor or VPN
- Self-hosted instance = complete control over logs and data

**Performance Optimization:**
- Enable only engines you actually need (faster results)
- Use specific categories instead of searching all
- Implement caching for repeated queries
- Limit number of results with `pageno` parameter
- Consider disabling slow/unreliable engines

### When to Use SearXNG

**✅ Perfect For:**
- AI agents needing web search capabilities
- Privacy-conscious search applications
- Research aggregation workflows
- Competitive intelligence monitoring
- News monitoring and aggregation
- Academic paper search
- Multi-engine result comparison
- Internal company search portal
- Alternative to paid search APIs (Google, Bing)

**❌ Not Ideal For:**
- Real-time stock prices (use dedicated financial APIs)
- Highly personalized search (SearXNG is intentionally non-personalized)
- Video streaming (SearXNG finds videos but doesn't stream them)
- When you need Google-quality ranking (results are mixed from many engines)

**SearXNG vs Google Custom Search API:**
- ✅ Free (no API costs)
- ✅ More privacy-focused
- ✅ Combines multiple engines
- ✅ No API rate limits (beyond what engines impose)
- ❌ Slightly slower (queries multiple engines)
- ❌ Less accurate ranking than Google alone
- ❌ Requires self-hosting
