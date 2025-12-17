# 🔎 Perplexica - AI-Powered Search Engine

### What is Perplexica?

Perplexica is an open-source AI-powered search engine that provides Perplexity AI-like functionality for deep research and intelligent information retrieval. Unlike traditional search engines, Perplexica uses AI to understand your query context, search multiple sources, and synthesize comprehensive answers with citations. It combines web search capabilities with large language models to provide contextual, well-researched responses - perfect for research automation, content generation, and knowledge discovery.

### Features

- **AI-Powered Search** - Uses LLMs to understand queries and synthesize comprehensive answers
- **Multiple Focus Modes** - Web search, academic papers, YouTube, Reddit, writing assistant, WolframAlpha
- **Source Citations** - All answers include clickable sources and references
- **Chat Interface** - Conversational search with context retention across queries
- **RESTful API** - Full API access for automation and n8n integration
- **SearXNG Integration** - Uses your self-hosted SearXNG for privacy-respecting search
- **Local LLM Support** - Works with Ollama for completely private, offline research

### Initial Setup

**First Access to Perplexica:**

1. Navigate to `https://perplexica.yourdomain.com`
2. No login required - start searching immediately
3. Try different focus modes:
   - **Web Search:** General internet search with AI synthesis
   - **Academic Search:** Scientific papers and research
   - **YouTube Search:** Video content discovery
   - **Reddit Search:** Community discussions and opinions
   - **Writing Assistant:** Help with content creation
   - **WolframAlpha:** Mathematical and computational queries
4. Chat history is saved in your browser (local storage)

**Configure LLM Backend:**

Configure AI providers via the Web UI after first login:

1. Click the **Settings icon** (⚙️) in the bottom left
2. Go to **Providers** tab
3. Choose your AI provider:
   - **Ollama** (local, private): Use `http://ollama:11434`
   - **OpenAI**: Enter your API key
   - **Anthropic Claude**: Enter your API key
   - **Groq**: Enter your API key
4. Select your preferred **Chat Model** and **Embedding Model**
5. Click **Save** - settings apply immediately

No config files or container restarts needed!

### n8n Integration Setup

Perplexica provides a REST API for programmatic access from n8n.

**Internal URL:** `http://perplexica:3000`

**API Endpoints:**
- `POST /api/search` - Perform AI-powered search
- `GET /api/models` - List available LLM models
- `GET /api/config` - Get current configuration

### Example Workflows

#### Example 1: AI Research Assistant

```javascript
// Build an AI-powered research assistant with deep web search

// 1. Chat Trigger Node
// User asks a research question

// 2. HTTP Request Node - Perplexica Search
Method: POST
URL: http://perplexica:3000/api/search
Headers:
  Content-Type: application/json
Send Body: JSON
Body: {
  "query": "{{ $json.chatInput }}",
  "focusMode": "webSearch",
  "chatHistory": []
}

// Response format:
{
  "message": "Comprehensive AI-generated answer...",
  "sources": [
    {
      "title": "Source Title",
      "url": "https://example.com",
      "snippet": "Relevant excerpt..."
    }
  ]
}

// 3. Code Node - Format Response with Sources
const answer = $input.item.json.message;
const sources = $input.item.json.sources || [];

const formattedResponse = `${answer}\n\n**Sources:**\n${sources.map((s, i) => 
  `${i + 1}. [${s.title}](${s.url})`
).join('\n')}`;

return {
  response: formattedResponse,
  sourceCount: sources.length
};

// 4. Chat Response Node
// Send formatted answer back to user with clickable sources
```

#### Example 2: Academic Research Aggregator

```javascript
// Automated academic paper search and summarization

// 1. Schedule Trigger
Cron: 0 9 * * MON  // Every Monday at 9 AM

// 2. Set Node - Research topics
[
  "quantum computing error correction",
  "CRISPR gene therapy clinical trials",
  "carbon capture technologies 2025"
]

// 3. Loop Node - Research each topic
Items: {{ $json }}

// 4. HTTP Request - Perplexica Academic Search
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} latest research papers",
  "focusMode": "academicSearch",  // Searches arXiv, Scholar, PubMed
  "chatHistory": []
}

// 5. Code Node - Parse papers and extract metadata
const response = $input.item.json;
const sources = response.sources || [];

// Filter for academic sources
const papers = sources.filter(s => 
  s.url.includes('arxiv.org') || 
  s.url.includes('scholar.google') ||
  s.url.includes('pubmed')
).map(paper => ({
  title: paper.title,
  url: paper.url,
  snippet: paper.snippet,
  topic: $('Loop').item.json.topic,
  discovered: new Date().toISOString()
}));

return papers;

// 6. Loop Node - Process each paper
Items: {{ $json }}

// 7. HTTP Request - Fetch full abstract (if available)
// Use paper URL or DOI to get more details

// 8. Qdrant Node - Store paper embedding
// Create vector embedding for semantic search later

// 9. Notion Node - Add to research database
Database: Academic Papers
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Abstract: {{ $json.snippet }}
  Topic: {{ $json.topic }}
  Date Added: {{ $json.discovered }}
  Status: "To Review"

// 10. Gmail Node - Weekly digest
To: research-team@company.com
Subject: Weekly Academic Research Digest
Body: |
  This week's research findings across all topics:
  
  {{ $('Loop').itemCount }} new papers discovered
  
  By Topic:
  {{ groupedByTopic }}
  
  View full database: [Notion Link]
```

#### Example 3: Content Research Pipeline

```javascript
// Research topics and generate content with AI

// 1. Webhook Trigger
// Input: { "topic": "sustainable packaging innovations", "contentType": "blog post" }

// 2. HTTP Request - Initial research via Perplexica
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} comprehensive overview latest trends statistics",
  "focusMode": "webSearch",
  "chatHistory": []
}

// 3. Code Node - Extract key points and subtopics
const research = $input.item.json.message;
const sources = $input.item.json.sources || [];

// Parse the AI response for headings/structure
const sections = research.match(/###? (.+)/g) || [];
const keyPoints = sections.map(s => s.replace(/###? /, ''));

return {
  mainResearch: research,
  keyPoints: keyPoints.slice(0, 5),  // Top 5 points
  sources: sources,
  originalTopic: $('Webhook').json.topic
};

// 4. Loop Node - Deep dive into each key point
Items: {{ $json.keyPoints }}

// 5. HTTP Request - Research each subtopic
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.item }} detailed information examples case studies",
  "focusMode": "webSearch",
  "chatHistory": [
    {
      "role": "user",
      "content": "{{ $('Code Node').json.originalTopic }}"
    },
    {
      "role": "assistant", 
      "content": "{{ $('Code Node').json.mainResearch }}"
    }
  ]  // Maintain context across searches!
}

// 6. Aggregate Node - Combine all research
const mainResearch = $('Code Node').json;
const deepDives = $input.all().map(x => x.json);

const completeResearch = {
  topic: mainResearch.originalTopic,
  overview: mainResearch.mainResearch,
  sections: mainResearch.keyPoints.map((point, i) => ({
    heading: point,
    content: deepDives[i]?.message || '',
    sources: deepDives[i]?.sources || []
  })),
  allSources: [
    ...mainResearch.sources,
    ...deepDives.flatMap(d => d.sources || [])
  ]
};

// Remove duplicate sources
completeResearch.allSources = [...new Map(
  completeResearch.allSources.map(s => [s.url, s])
).values()];

return completeResearch;

// 7. OpenAI Node - Generate structured article
Model: gpt-4o
System: "You are an expert content writer. Create well-structured, engaging content."
Prompt: |
  Write a comprehensive {{ $('Webhook').json.contentType }} about:
  {{ $json.topic }}
  
  Use this research:
  Overview: {{ $json.overview }}
  
  Sections to cover:
  {{ $json.sections.map(s => `- ${s.heading}: ${s.content.substring(0, 200)}...`).join('\n') }}
  
  Requirements:
  - 1500-2000 words
  - Use provided research accurately
  - Include relevant statistics and examples
  - Professional but engaging tone
  - SEO-friendly structure with H2/H3 headings

// 8. Code Node - Format with citations
const article = $input.item.json.article;
const sources = $('Aggregate Node').json.allSources;

// Add references section
const references = sources.map((s, i) => 
  `${i + 1}. ${s.title} - ${s.url}`
).join('\n');

const completeArticle = `${article}\n\n---\n\n## References\n\n${references}`;

return {
  article: completeArticle,
  wordCount: article.split(' ').length,
  sourceCount: sources.length
};

// 9. WordPress/Ghost Node - Publish draft
Title: {{ $('Webhook').json.topic }}
Content: {{ $json.article }}
Status: Draft
Tags: [{{ $('Webhook').json.topic }}, Research-Based]

// 10. Slack Node - Notify content team
Channel: #content-team
Message: |
  📝 New article draft ready for review
  
  **Topic:** {{ $('Webhook').json.topic }}
  **Word Count:** {{ $json.wordCount }}
  **Sources:** {{ $json.sourceCount }} references
  
  Review at: [WordPress Link]
```

#### Example 4: Competitive Intelligence Monitor

```javascript
// Monitor competitors with AI-powered research

// 1. Schedule Trigger
Cron: 0 */6 * * *  // Every 6 hours

// 2. Set Node - Competitor list
[
  "Competitor A",
  "Competitor B",
  "Competitor C"
]

// 3. Loop Node - Research each competitor
Items: {{ $json }}

// 4. HTTP Request - Recent news search
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.competitor }} latest news announcements funding product launches last 24 hours",
  "focusMode": "webSearch",
  "chatHistory": []
}

// 5. HTTP Request - Community sentiment
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.competitor }} reddit discussions reviews opinions sentiment",
  "focusMode": "redditSearch",  // Reddit-specific search
  "chatHistory": []
}

// 6. Code Node - Combine intelligence
const competitor = $('Loop').item.json.competitor;
const news = $input.all()[0].json;
const sentiment = $input.all()[1].json;

return {
  competitor: competitor,
  newsFindings: news.message,
  newsSources: news.sources || [],
  sentimentAnalysis: sentiment.message,
  sentimentSources: sentiment.sources || [],
  timestamp: new Date().toISO()
};

// 7. OpenAI Node - Analyze and summarize
Model: gpt-4o-mini
Prompt: |
  Analyze this competitive intelligence:
  
  Competitor: {{ $json.competitor }}
  
  Recent News:
  {{ $json.newsFindings }}
  
  Community Sentiment:
  {{ $json.sentimentAnalysis }}
  
  Provide:
  1. Key developments summary (2-3 sentences)
  2. Sentiment score (-10 to +10)
  3. Strategic implications for us
  4. Threat level (Low/Medium/High)
  5. Recommended actions

// 8. PostgreSQL Node - Store intelligence
Table: competitive_intel
Fields:
  competitor: {{ $('Code Node').json.competitor }}
  news_summary: {{ $('OpenAI').json.summary }}
  sentiment_score: {{ $('OpenAI').json.sentiment }}
  threat_level: {{ $('OpenAI').json.threat }}
  raw_data: {{ $('Code Node').json }}
  analyzed_at: {{ $now }}

// 9. IF Node - Alert on high-priority intel
Condition: {{ $('OpenAI').json.threat === 'High' }}

// 10. Slack Node - Send alert
Channel: #competitive-intel
Priority: High
Message: |
  🚨 High Priority Intel Alert
  
  **Competitor:** {{ $('Code Node').json.competitor }}
  **Threat Level:** {{ $('OpenAI').json.threat }}
  
  **Key Developments:**
  {{ $('OpenAI').json.summary }}
  
  **Recommended Actions:**
  {{ $('OpenAI').json.actions }}
  
  **Sources:**
  {{ $('Code Node').json.newsSources.slice(0, 3).map(s => s.url).join('\n') }}
```

#### Example 5: YouTube Content Curation

```javascript
// Discover and curate YouTube content on specific topics

// 1. Webhook Trigger
// Input: { "topic": "machine learning tutorials", "minViews": 10000 }

// 2. HTTP Request - YouTube Search via Perplexica
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} tutorial beginner to advanced comprehensive",
  "focusMode": "youtubeSearch",  // YouTube-specific search
  "chatHistory": []
}

// Response includes YouTube video recommendations

// 3. Code Node - Parse video results
const response = $input.item.json;
const sources = response.sources || [];

// Extract YouTube videos
const videos = sources.filter(s => s.url.includes('youtube.com')).map(video => ({
  title: video.title,
  url: video.url,
  description: video.snippet,
  videoId: video.url.match(/watch\?v=(.+)/)?.[1],
  addedAt: new Date().toISO()
}));

return videos;

// 4. Loop Node - Enrich each video
Items: {{ $json }}

// 5. HTTP Request - Get video metadata (YouTube API alternative)
// Or scrape video page for view count, duration, etc.

// 6. IF Node - Filter by criteria
Condition: {{ $json.viewCount >= $('Webhook').json.minViews }}

// 7. Notion Node - Add to content library
Database: Video Library
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Topic: {{ $('Webhook').json.topic }}
  Views: {{ $json.viewCount }}
  Duration: {{ $json.duration }}
  Added: {{ $json.addedAt }}
  Status: "To Review"

// 8. Discord/Slack - Share with team
Channel: #learning-resources
Message: |
  📺 New videos curated for: {{ $('Webhook').json.topic }}
  
  Found {{ $('Loop').itemCount }} quality videos:
  {{ $('Loop').all().map(v => `- ${v.json.title}\n  ${v.json.url}`).join('\n\n') }}
```

### Focus Modes Reference

Perplexica supports different focus modes for specialized searches:

| Focus Mode | Description | Best For | Example Query |
|------------|-------------|----------|---------------|
| **webSearch** | General web search across all sources | Broad research, current events | "Latest AI developments 2025" |
| **academicSearch** | Scientific papers (arXiv, Scholar, PubMed) | Research papers, academic work | "CRISPR gene editing clinical trials" |
| **youtubeSearch** | Video content discovery | Tutorials, talks, visual learning | "React hooks tutorial explained" |
| **redditSearch** | Community discussions | Opinions, experiences, reviews | "Best VPS provider recommendations" |
| **writingAssistant** | Content creation help | Drafting, editing, ideation | "Write introduction about blockchain" |
| **wolframAlphaSearch** | Math & computational queries | Calculations, data analysis | "Solve differential equation x^2 + 3x" |

### API Request Format

**Basic Search Request:**
```json
POST http://perplexica:3000/api/search
Content-Type: application/json

{
  "query": "Your search query here",
  "focusMode": "webSearch",
  "chatHistory": []
}
```

**With Chat History (Contextual Search):**
```json
{
  "query": "Tell me more about the second point",
  "focusMode": "webSearch",
  "chatHistory": [
    {
      "role": "user",
      "content": "What is quantum computing?"
    },
    {
      "role": "assistant",
      "content": "Quantum computing is..."
    }
  ]
}
```

**Response Format:**
```json
{
  "message": "AI-generated comprehensive answer with context...",
  "sources": [
    {
      "title": "Article Title",
      "url": "https://example.com/article",
      "snippet": "Relevant excerpt from the source..."
    }
  ]
}
```

### Troubleshooting

**Issue 1: Perplexica Not Responding**

```bash
# Check if Perplexica is running
docker ps | grep perplexica

# Check logs for errors
docker logs perplexica --tail 100

# Restart Perplexica
docker compose restart perplexica

# Check if SearXNG is accessible (Perplexica depends on it)
docker exec perplexica curl http://searxng:8080/
```

**Solution:**
- Perplexica requires SearXNG to be running and JSON API enabled
- Check SearXNG configuration (see SearXNG section above)
- Verify Ollama is running if using local LLMs
- Check Docker network connectivity

**Issue 2: Slow Response Times**

```bash
# Check which LLM backend is configured
# Via Web UI: Settings → Providers → View current configuration

# If using Ollama, check model is downloaded
docker exec ollama ollama list

# Pull smaller/faster model if needed
docker exec ollama ollama pull llama3.2:3b  # Smaller, faster model
```

**Solution:**
- Use faster LLM models (llama3.2:3b instead of llama3.2:70b)
- Reduce search depth/sources in config
- Use webSearch mode instead of academicSearch (faster)
- Ensure Ollama has sufficient RAM allocated

**Issue 3: No Sources in Response**

```bash
# Check SearXNG integration
docker logs perplexica | grep -i "searxng\|search"

# Test SearXNG directly
curl "http://searxng:8080/search?q=test&format=json"

# If SearXNG returns no results, check SearXNG logs
docker logs searxng --tail 50
```

**Solution:**
- Verify SearXNG JSON API is enabled (see SearXNG section)
- Check if search engines in SearXNG are working
- Try different search query
- Verify network connectivity between Perplexica and SearXNG

**Issue 4: "Out of Memory" Errors**

```bash
# Check Ollama memory usage
docker stats ollama --no-stream

# Check Perplexica memory usage
docker stats perplexica --no-stream

# Free up RAM by stopping unused services
docker compose stop <unused-service>
```

**Solution:**
- Use smaller LLM models (3B instead of 7B or 13B parameters)
- Increase Docker memory limits in docker-compose.yml
- Close other heavy services temporarily
- Consider using OpenAI API instead of local Ollama for memory-constrained systems

**Issue 5: Cannot Access from n8n**

```bash
# Test connectivity from n8n container
docker exec n8n curl http://perplexica:3000/

# Should return HTML page

# Test API endpoint
docker exec n8n curl -X POST http://perplexica:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test","focusMode":"webSearch","chatHistory":[]}'

# Check if both containers are in same network
docker network inspect localai | grep -E "perplexica|n8n"
```

**Solution:**
- Use internal URL: `http://perplexica:3000` (not localhost)
- Verify both containers are running
- Check Docker network configuration
- Ensure API endpoint path is correct: `/api/search`

### Configuration Options

**Model Selection:**

All configuration is done via the Web UI at `https://perplexica.yourdomain.com`:

1. **Settings** → **Providers**:
   - Select AI provider (Ollama, OpenAI, Claude, Groq)
   - Choose chat model and embedding model
   - Configure API keys if needed

2. **Settings** → **General**:
   - Set default focus mode
   - Configure search depth
   - Adjust UI preferences

**Environment Variables (docker-compose.yml):**
```yaml
environment:
  - SEARXNG_API_URL=http://searxng:8080  # Your SearXNG instance
  - OPENAI_API_KEY=${OPENAI_API_KEY:-}   # Optional pre-configuration
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
```

Configuration persists in the `perplexica_data` Docker volume.

### Resources

- **GitHub:** https://github.com/ItzCrazyKns/Perplexica
- **Web Interface:** `https://perplexica.yourdomain.com`
- **API Endpoint:** `http://perplexica:3000/api/search`
- **Perplexity AI (Inspiration):** https://www.perplexity.ai
- **SearXNG Integration:** See SearXNG section above

### Best Practices

**For Research Workflows:**
- Use `chatHistory` parameter to maintain context across multiple searches
- Start with `webSearch`, then use `academicSearch` for deeper dive
- Extract sources and store in vector database (Qdrant) for future reference
- Combine with LightRAG or Neo4j to build knowledge graphs from research

**For Content Generation:**
- Research topic with Perplexica first
- Use comprehensive answer as context for content generation (OpenAI, Claude)
- Always include source citations in final content
- Verify facts from multiple Perplexica searches

**For Competitive Intelligence:**
- Schedule regular searches (every 6-12 hours)
- Use multiple focus modes (webSearch + redditSearch) for comprehensive view
- Store results in database for trend analysis
- Set up alerts for significant changes or new developments

**Performance Tips:**
- Cache common queries in Redis or PostgreSQL
- Use smaller LLM models for faster responses
- Implement request queuing for high-volume workflows
- Consider rate limiting to avoid overwhelming SearXNG

**Privacy Considerations:**
- Perplexica uses your self-hosted SearXNG (privacy-respecting)
- With Ollama backend: completely private, no external API calls
- Chat history stored locally in browser, not on server
- For maximum privacy: use local LLMs + self-hosted SearXNG

### When to Use Perplexica

**✅ Perfect For:**
- Deep research requiring AI synthesis
- Academic paper discovery and analysis
- Content research and fact-checking
- Competitive intelligence gathering
- Multi-source information aggregation
- YouTube content curation
- Reddit sentiment analysis
- Writing assistance with current information
- Mathematical queries (WolframAlpha mode)

**❌ Not Ideal For:**
- Simple keyword searches (use SearXNG directly instead)
- Real-time data updates (use dedicated APIs)
- When you need raw search results without AI interpretation
- Highly time-sensitive queries (Perplexica adds processing time)

**Perplexica vs SearXNG:**
- **Perplexica:** AI-synthesized answers with sources, slower, contextual
- **SearXNG:** Raw search results, faster, no AI processing
- **Use Both:** SearXNG for quick lookups, Perplexica for research

**Perplexica vs ChatGPT/Claude:**
- ✅ Always includes source citations
- ✅ Uses real-time web search (not training data)
- ✅ Completely self-hosted and private
- ❌ Slower than pure LLM queries
- ❌ Requires SearXNG dependency
