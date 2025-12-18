### What is GPT Researcher?

GPT Researcher is an autonomous research agent that creates comprehensive 2000+ word reports on any topic in minutes. Unlike simple web scrapers, it intelligently searches across multiple sources, analyzes content, extracts relevant information, and generates structured reports with proper citations in academic formats (APA, MLA, Chicago). It automates the entire research process from query formulation through multi-source analysis to final report generation, replacing hours of manual research with a few API calls.

### Features

- **🔬 Autonomous Research**: Automatically searches the web across 20+ sources with intelligent query generation
- **📄 Comprehensive Reports**: Generates 2000-5000 word reports with complete structure and analysis
- **📚 Multiple Report Types**: Research reports, outlines, resource lists, subtopic analysis
- **🎓 Academic Citations**: Supports APA, MLA, Chicago citation formats with proper bibliography
- **⚡ Fast & Efficient**: Complete research reports in 2-5 minutes instead of hours
- **🌐 Multi-Source Aggregation**: Synthesizes information from diverse web sources
- **🔄 Iterative Refinement**: Refines research based on initial findings for comprehensive coverage

### Initial Setup

**First Access to GPT Researcher:**

1. **Test API Health:**
```bash
curl http://gpt-researcher:8000/health
# Should return: {"status": "healthy"}
```

2. **Start Simple Research:**
```bash
curl -X POST http://gpt-researcher:8000/api/research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Latest trends in AI automation 2025",
    "report_type": "research_report"
  }'
```

Response contains `task_id` for status tracking.

3. **Check Research Status:**
```bash
curl http://gpt-researcher:8000/api/status/{task_id}
```

4. **Web Interface (Optional):**
Access via `https://research.yourdomain.com`
- Requires Basic Authentication (configured during installation)
- Username/Password: Check `.env` file

### API Access

GPT Researcher runs as an internal service accessible to other containers:

**Internal API Endpoint:**
```
http://gpt-researcher:8000
```

**Key API Endpoints:**
- `POST /api/research` - Start new research task
- `GET /api/status/{task_id}` - Check research progress
- `GET /api/result/{task_id}` - Get completed report
- `GET /health` - Service health check

### n8n Integration Setup

GPT Researcher has no native n8n node - integration is via HTTP Request nodes.

**Internal URL:** `http://gpt-researcher:8000`

**No credentials required** for internal access (container-to-container communication).

### Example Workflows

#### Example 1: Automated Research Report Generation

Generate comprehensive research reports on demand or schedule.

**Workflow Structure:**
1. **Webhook/Schedule Trigger**
   ```javascript
   Input: {
     "topic": "Impact of AI on healthcare 2025",
     "report_format": "APA"
   }
   ```

2. **HTTP Request Node - Start Research**
   ```javascript
   Method: POST
   URL: http://gpt-researcher:8000/api/research
   Headers:
     Content-Type: application/json
   Body: {
     "query": "{{ $json.topic }}",
     "report_type": "research_report",
     "max_iterations": 5,
     "report_format": "{{ $json.report_format }}",
     "total_words": 2000
   }
   
   // Response: { "task_id": "abc-123-xyz" }
   ```

3. **Wait Node**
   ```javascript
   Duration: 180 seconds  // Give time for research (typical 2-5 min)
   ```

4. **HTTP Request Node - Check Status**
   ```javascript
   Method: GET
   URL: http://gpt-researcher:8000/api/status/{{ $json.task_id }}
   
   // Returns: { "status": "completed", "progress": 100 }
   ```

5. **IF Node - Check if Complete**
   ```javascript
   Condition: {{ $json.status }} === "completed"
   ```

6. **HTTP Request Node - Fetch Report**
   ```javascript
   Method: GET
   URL: http://gpt-researcher:8000/api/result/{{ $('Start Research').json.task_id }}
   
   // Returns complete report with sources
   ```

7. **Code Node - Process Report**
   ```javascript
   // Extract and format report
   const report = $json.report;
   const sources = $json.sources;
   
   return [{
     json: {
       title: $json.query,
       content: report,
       wordCount: report.split(' ').length,
       sourceCount: sources.length,
       sources: sources.map(s => ({
         title: s.title,
         url: s.url,
         relevance: s.relevance_score
       })),
       generatedAt: new Date().toISOString()
     }
   }];
   ```

8. **Action Nodes** - Send report (Email, Slack, save to Drive)

**Use Case**: Automated market research, competitive analysis, technology trend reports.

#### Example 2: Multi-Topic Batch Research

Research multiple topics in a single workflow run.

**Workflow Structure:**
1. **Schedule Trigger**
   ```javascript
   Cron: 0 9 * * *  // Daily at 9 AM
   ```

2. **Code Node - Define Research Topics**
   ```javascript
   return [
     { topic: "AI automation trends 2025" },
     { topic: "LLM cost optimization strategies" },
     { topic: "Enterprise RAG implementations" },
     { topic: "Open-source AI tools comparison" }
   ];
   ```

3. **Loop Over Items**
   ```javascript
   Items: {{ $json }}
   ```

4. **HTTP Request Node - Start Research (Inside Loop)**
   ```javascript
   Method: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.item.topic }}",
     "report_type": "outline_report",  // Faster for batch
     "max_iterations": 3,
     "total_words": 1000
   }
   ```

5. **Wait Node**
   ```javascript
   Duration: 120 seconds per topic
   ```

6. **HTTP Request - Fetch Results**
   ```javascript
   Method: GET
   URL: http://gpt-researcher:8000/api/result/{{ $json.task_id }}
   ```

7. **Aggregate Node - Combine All Reports**
   ```javascript
   const allReports = $input.all();
   const completed = allReports
     .filter(r => r.json.status === 'completed')
     .map(r => ({
       topic: r.json.query,
       summary: r.json.report.substring(0, 500) + '...',
       fullReport: r.json.report,
       sourceCount: r.json.sources.length,
       url: `https://research.yourdomain.com/reports/${r.json.task_id}`
     }));
   
   return [{
     json: {
       date: new Date().toISOString().split('T')[0],
       reportsGenerated: completed.length,
       reports: completed
     }
   }];
   ```

8. **Slack/Email - Send Digest**
   ```javascript
   Message: |
     📊 Daily Research Digest - {{ $json.date }}
     
     Generated {{ $json.reportsGenerated }} reports:
     
     {{ $json.reports.map(r => `• ${r.topic} (${r.sourceCount} sources)`).join('\n') }}
     
     Full reports available in shared folder.
   ```

**Use Case**: Daily intelligence briefings, market monitoring, competitive tracking.

#### Example 3: Competitive Analysis Workflow

Deep research on competitors with comparative analysis.

**Workflow Structure:**
1. **Manual Trigger**
   ```javascript
   Input: {
     "competitors": ["OpenAI GPT-4", "Anthropic Claude", "Google Gemini"],
     "focus_area": "pricing and features"
   }
   ```

2. **Loop Over Competitors**

3. **HTTP Request - Research Each Competitor**
   ```javascript
   Method: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.item }} {{ $('Manual Trigger').item.json.focus_area }} 2025",
     "report_type": "resource_report",
     "max_iterations": 4
   }
   ```

4. **Wait & Fetch (as previous examples)**

5. **Aggregate Competitor Data**
   ```javascript
   const reports = $input.all().map(r => r.json);
   return [{
     json: {
       competitors: reports,
       comparisonDate: new Date().toISOString()
     }
   }];
   ```

6. **OpenAI Node - Generate Comparison**
   ```javascript
   Model: gpt-4o
   System: "You are a business analyst. Create a comparison table."
   Prompt: |
     Based on these research reports:
     
     {{ $json.competitors.map(c => c.report).join('\n\n---\n\n') }}
     
     Create a detailed comparison table covering:
     - Pricing tiers
     - Key features
     - API capabilities
     - Limitations
     - Best use cases
   ```

7. **Save Comparison** - To document or database

**Use Case**: Competitive intelligence, product positioning, market analysis.

### Troubleshooting

**Issue 1: Research Takes Too Long**

```bash
# Check if service is running
docker compose -p localai ps | grep gpt-researcher

# Check service logs
docker compose -p localai logs gpt-researcher --tail 100

# Monitor active research tasks
curl http://gpt-researcher:8000/api/tasks/active
```

**Solution:**
- Reduce `max_iterations` (try 3 instead of 5)
- Use `outline_report` type for faster results
- Check if external search APIs are responsive
- Implement timeout in n8n workflow (5-10 min max)

**Issue 2: Low-Quality or Incomplete Reports**

```bash
# Check source quality in results
curl http://gpt-researcher:8000/api/result/{task_id} | jq '.sources'
```

**Solution:**
- Increase `max_iterations` to 5-7 for more thorough research
- Use more specific queries: "AI automation in healthcare 2025" vs "AI"
- Set `total_words` higher (3000-4000) for detailed reports
- Use `research_report` type instead of `outline_report`

**Issue 3: API Connection Errors from n8n**

```bash
# Test internal connectivity
docker compose -p localai exec n8n curl http://gpt-researcher:8000/health

# Check Docker network
docker network inspect ai-launchkit_default | grep gpt-researcher
```

**Solution:**
- Verify service name: `http://gpt-researcher:8000` (not localhost)
- Check if service is in same Docker network
- Restart both services:
  ```bash
  docker compose -p localai restart gpt-researcher n8n
  ```

**Issue 4: Task Status Shows "Failed"**

```bash
# Check detailed error logs
docker compose -p localai logs gpt-researcher | grep ERROR

# Check task status with error details
curl http://gpt-researcher:8000/api/status/{task_id}
```

**Solution:**
- Check if LLM API keys are configured (OpenAI, etc.)
- Verify internet connectivity from container
- Check rate limits on search APIs
- Review query for invalid characters or formatting

### Configuration Parameters

**Complete Request Structure:**

```json
{
  "query": "Your research topic or question",
  "report_type": "research_report",
  "max_iterations": 5,
  "report_format": "APA",
  "total_words": 2000,
  "language": "english",
  "tone": "objective",
  "sources_min": 10,
  "sources_max": 20
}
```

**Parameter Reference:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | Required | Research topic or question |
| `report_type` | string | `research_report` | Report format (see types below) |
| `max_iterations` | integer | `5` | Search depth (1-10) |
| `report_format` | string | `APA` | Citation style (APA/MLA/Chicago) |
| `total_words` | integer | `2000` | Target word count (1000-5000) |
| `language` | string | `english` | Report language |
| `tone` | string | `objective` | Writing tone (objective/analytical) |
| `sources_min` | integer | `10` | Minimum sources to consult |
| `sources_max` | integer | `20` | Maximum sources to consult |

**Report Types:**
- `research_report` - Comprehensive research with analysis (default)
- `outline_report` - Structured outline without full text
- `resource_report` - Curated list of sources with summaries
- `subtopic_report` - Focused analysis on specific subtopic

### Tips & Best Practices

**Query Optimization:**
- **Be Specific**: "AI automation in healthcare 2025" > "AI"
- **Include Context**: Add year, industry, or geographic focus
- **Avoid Ambiguity**: Clarify acronyms and technical terms

**Performance Tuning:**
- Start with `outline_report` for quick overview
- Use 3-5 `max_iterations` for balanced results
- Set realistic `total_words` (1000-3000 typical)
- Implement delays between batch requests

**Integration Patterns:**
- **Quick + Deep**: GPT Researcher overview → Local Deep Research for verification
- **Multi-Source**: Combine with Perplexica, SearXNG for validation
- **Automated Pipelines**: Schedule recurring research on key topics
- **Post-Processing**: Use OpenAI/Ollama to summarize or restructure

**Error Handling:**
- Always implement timeout logic (5-10 min max)
- Store `task_id` for later retrieval
- Check status before fetching results
- Log failed queries for manual review

### Resources

- **Official Documentation**: https://docs.gptr.dev/
- **GitHub Repository**: https://github.com/assafelovic/gpt-researcher
- **Web Interface**: `https://research.yourdomain.com` (Basic Auth required)
- **API Reference**: https://docs.gptr.dev/api
- **Examples & Tutorials**: https://docs.gptr.dev/examples
- **Internal API**: `http://gpt-researcher:8000`

**Related Services:**
- Use with **SearXNG** for custom search integration
- Feed results to **Qdrant/Weaviate** for knowledge base
- Process with **Ollama** for summarization
- Store reports in **Supabase** or **PostgreSQL**
- Compare with **Local Deep Research** for fact-checking
