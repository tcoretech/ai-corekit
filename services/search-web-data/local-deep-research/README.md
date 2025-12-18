### What is Local Deep Research?

Local Deep Research is LangChain's iterative deep research tool that achieves ~95% accuracy through research loops with reflection and self-criticism. Unlike simple web searches, Local Deep Research performs multiple iterations, validates information against multiple sources, identifies contradictions, and continuously refines results. Perfect for fact-checking, detailed analysis, and situations requiring the highest accuracy.

The tool uses an iterative approach: it researches, reflects on what it found, identifies gaps or inconsistencies, and then conducts additional research to fill those gaps - repeating until confidence is high or iteration limit is reached.

### Features

- **🎯 Highest Accuracy**: ~95% accuracy through iterative validation and reflection
- **🔄 Research Loops**: Multiple research passes with continuous refinement
- **🧠 Self-Reflection**: Identifies gaps, contradictions, and insufficient information
- **✅ Fact-Checking**: Multi-source validation for maximum reliability
- **📊 Confidence Scoring**: Every statement with confidence score and source citations
- **🌐 Multi-Search Backend**: Supports SearXNG, Tavily, and other search engines
- **⏱️ Deep Analysis**: 10-20 minutes for comprehensive research (vs. 2-5 min for GPT Researcher)

### Initial Setup

**First Access to Local Deep Research:**

1. **Test API Health:**
```bash
curl http://local-deep-research:2024/health
# Should return: {"status": "healthy", "version": "1.0"}
```

2. **Start Simple Research:**
```bash
curl -X POST http://local-deep-research:2024/api/research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Is quantum computing viable for commercial use in 2025?",
    "iterations": 3
  }'
```

Response contains `task_id` and `websocket_url` for real-time updates.

3. **Check Research Progress:**
```bash
curl http://local-deep-research:2024/api/status/{task_id}
```

4. **WebSocket for Live Updates (Optional):**
```bash
wscat -c ws://local-deep-research:2024/ws/{task_id}
# Receive real-time progress updates
```

**Important:** Local Deep Research runs only internally (no HTTPS subdomain) for n8n/internal services.

### API Access

Local Deep Research runs as an internal service accessible to other containers:

**Internal API Endpoint:**
```
http://local-deep-research:2024
```

**Key API Endpoints:**
- `POST /api/research` - Start iterative research
- `POST /api/verify` - Fact-check specific claim
- `GET /api/status/{task_id}` - Check progress
- `GET /api/result/{task_id}` - Get final analysis
- `GET /health` - Service health check

### n8n Integration Setup

Local Deep Research has no native n8n node - integration is via HTTP Request nodes.

**Internal URL:** `http://local-deep-research:2024`

**No credentials required** for internal container-to-container communication.

### Example Workflows

#### Example 1: High-Accuracy Fact-Checking

Verify claims with multi-source validation and reflection.

**Workflow Structure:**
1. **Webhook/Manual Trigger**
   ```javascript
   Input: {
     "claim": "Quantum computers can break RSA-2048 encryption today",
     "confidence_required": 0.9
   }
   ```

2. **HTTP Request Node - Fact-Check with Local Deep Research**
   ```javascript
   Method: POST
   URL: http://local-deep-research:2024/api/verify
   Headers:
     Content-Type: application/json
   Body: {
     "statement": "{{ $json.claim }}",
     "confidence_threshold": {{ $json.confidence_required }},
     "sources_required": 3,
     "iterations": 5
   }
   
   // Response: { "task_id": "xyz-789", "websocket_url": "ws://..." }
   ```

3. **Wait Node**
   ```javascript
   Duration: 300 seconds  // 5 minutes for deep analysis
   ```

4. **Code Node - Poll for Completion**
   ```javascript
   const taskId = $('HTTP Request').item.json.task_id;
   const maxAttempts = 20;
   let attempts = 0;
   
   while (attempts < maxAttempts) {
     const status = await $http.request({
       method: 'GET',
       url: `http://local-deep-research:2024/api/status/${taskId}`
     });
     
     if (status.status === 'completed') {
       return { taskId, ready: true };
     }
     
     if (status.status === 'failed') {
       throw new Error('Research failed: ' + status.error);
     }
     
     // Wait 30 seconds between checks
     await new Promise(resolve => setTimeout(resolve, 30000));
     attempts++;
   }
   
   throw new Error('Research timeout after 10 minutes');
   ```

5. **HTTP Request Node - Get Verification Result**
   ```javascript
   Method: GET
   URL: http://local-deep-research:2024/api/result/{{ $json.taskId }}
   ```

6. **Code Node - Parse Verification**
   ```javascript
   const result = $input.item.json;
   
   return [{
     json: {
       claim: $('Webhook').item.json.claim,
       verdict: result.verified ? 'TRUE' : 'FALSE',
       confidence: result.confidence_score,
       reasoning: result.reasoning,
       sources: result.sources,
       contradictions: result.contradictions_found || [],
       iterations_used: result.iterations_completed,
       warnings: result.warnings || []
     }
   }];
   ```

7. **IF Node - Check Confidence**
   ```javascript
   Condition: {{ $json.confidence }} >= {{ $('Webhook').item.json.confidence_required }}
   ```

8. **Action Nodes**
   - **High Confidence Path**: Accept and save result
   - **Low Confidence Path**: Escalate to human review with all sources

**Use Case**: Verify marketing claims, validate statistics for reports, fact-check articles.

#### Example 2: Combined Quick + Deep Research Strategy

Use GPT Researcher for overview, Local Deep Research for accuracy verification.

**Workflow Structure:**
1. **Webhook Trigger**
   ```javascript
   Input: { 
     "topic": "Impact of AI regulation on European startups",
     "depth": "comprehensive"
   }
   ```

2. **GPT Researcher - Quick Overview (3 minutes)**
   ```javascript
   Method: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.topic }}",
     "report_type": "outline_report",
     "max_iterations": 3
   }
   ```

3. **Wait + Fetch GPT Researcher Results**

4. **Code Node - Extract Key Claims**
   ```javascript
   const report = $json.report;
   
   // Extract bold statements, statistics, predictions
   const claimPatterns = [
     /\d+%/g,  // Percentages
     /\$[\d,]+/g,  // Dollar amounts
     /by \d{4}/gi,  // Year predictions
     /research shows/gi,  // Research claims
     /studies indicate/gi  // Study references
   ];
   
   const claims = [];
   for (const pattern of claimPatterns) {
     const matches = report.match(pattern);
     if (matches) {
       // Extract sentences containing these patterns
       matches.forEach(match => {
         const sentences = report.split(/[.!?]/);
         const claimSentences = sentences.filter(s => s.includes(match));
         claims.push(...claimSentences.map(s => s.trim()));
       });
     }
   }
   
   // Return unique claims
   return [...new Set(claims)].map(claim => ({ json: { claim } }));
   ```

5. **Loop Over Claims**

6. **HTTP Request - Verify Each Claim (Inside Loop)**
   ```javascript
   Method: POST
   URL: http://local-deep-research:2024/api/verify
   Body: {
     "statement": "{{ $json.item.claim }}",
     "context": "{{ $('GPT Researcher').json.report.substring(0, 1000) }}",
     "iterations": 3,
     "confidence_threshold": 0.8
   }
   ```

7. **Wait + Poll + Fetch Results** (as in Example 1)

8. **Aggregate Node - Compile Verified Report**
   ```javascript
   const gptReport = $('GPT Researcher').first().json.report;
   const verifications = $input.all().map(v => v.json);
   
   const verified = verifications.filter(v => v.verified && v.confidence >= 0.8);
   const unverified = verifications.filter(v => !v.verified || v.confidence < 0.8);
   
   return [{
     json: {
       originalReport: gptReport,
       verifiedClaims: verified.length,
       unverifiedClaims: unverified.length,
       confidenceAverage: verifications.reduce((sum, v) => sum + v.confidence, 0) / verifications.length,
       flaggedForReview: unverified,
       fullVerifications: verifications
     }
   }];
   ```

9. **Action Nodes** - Save verified report or escalate unverified claims

**Use Case**: High-stakes business reports, regulatory filings, investor communications.

#### Example 3: Continuous Fact-Checking Pipeline

Monitor published content and verify accuracy continuously.

**Workflow Structure:**
1. **Schedule Trigger**
   ```javascript
   Cron: 0 */6 * * *  // Every 6 hours
   ```

2. **HTTP Request - Fetch Recent Articles**
   ```javascript
   // From CMS, website, or content API
   Method: GET
   URL: https://your-cms.com/api/articles/recent
   ```

3. **Loop Over Articles**

4. **Code Node - Extract Factual Claims**
   ```javascript
   const article = $json.item;
   
   // Use regex or simple LLM call to extract claims
   // Focus on: statistics, dates, quotes, research references
   const claims = extractFactualClaims(article.content);
   
   return claims.map(claim => ({
     json: {
       article_id: article.id,
       article_title: article.title,
       claim: claim,
       published_date: article.publishedAt
     }
   }));
   ```

5. **HTTP Request - Verify Claims with Local Deep Research**
   ```javascript
   Method: POST
   URL: http://local-deep-research:2024/api/verify
   Body: {
     "statement": "{{ $json.claim }}",
     "published_date": "{{ $json.published_date }}",
     "iterations": 4
   }
   ```

6. **Wait + Poll + Results**

7. **IF Node - Check for False Claims**
   ```javascript
   Condition: {{ $json.verified }} === false || {{ $json.confidence }} < 0.7
   ```

8. **Alert Path - Notify Editorial Team**
   ```javascript
   // Slack/Email notification
   Message: |
     ⚠️ Potential Inaccuracy Detected
     
     Article: {{ $json.article_title }}
     Claim: {{ $json.claim }}
     Verdict: {{ $json.verdict }}
     Confidence: {{ $json.confidence }}
     
     Sources consulted: {{ $json.sources.length }}
     
     Please review and update if necessary.
   ```

**Use Case**: Content quality assurance, editorial fact-checking, compliance monitoring.

### Troubleshooting

**Issue 1: Research Takes Too Long (>20 minutes)**

```bash
# Check container status
docker compose -p localai ps | grep local-deep-research

# View logs for stalled processes
docker compose -p localai logs local-deep-research --tail 100 --follow
```

**Solution:**
- Reduce `iterations` (try 3 instead of 5)
- Simplify query: be more specific
- Check if search backend (SearXNG) is responsive:
  ```bash
  docker compose -p localai exec n8n curl http://searxng:8080/search?q=test
  ```

**Issue 2: Low Confidence Scores**

```bash
# Check if LLM provider is working
docker compose -p localai logs local-deep-research | grep -i "llm\|error"
```

**Solution:**
- Query might be too ambiguous - be more specific
- Increase `iterations` to 5-7 for more thorough research
- Check if topic is actively disputed (low confidence is expected)
- Verify LLM configuration (OpenAI key or Ollama connection)

**Issue 3: Search Engine Connectivity Issues**

```bash
# Test search backend
docker compose -p localai exec local-deep-research curl http://searxng:8080/health

# Check search logs
docker compose -p localai logs searxng --tail 50
```

**Solution:**
- Verify SearXNG or other search backend is working
- Check Docker network connectivity
- Restart search service:
  ```bash
  docker compose -p localai restart searxng local-deep-research
  ```

**Issue 4: Conflicting Information Found**

This is actually a GOOD sign - shows thorough research.

```bash
# The result will include:
{
  "contradictions_found": [
    {
      "claim": "...",
      "source1": "...",
      "source2": "...",
      "contradiction": "..."
    }
  ],
  "confidence_score": 0.65,  // Lower due to conflicts
  "warnings": ["Multiple contradictory sources found"]
}
```

**Next Steps:**
- Review contradictions manually
- Increase iterations to resolve conflicts
- Add context to guide research toward reliable sources

**Issue 5: API Timeout**

```bash
# Check environment variables
docker compose -p localai exec local-deep-research printenv | grep -E "OPENAI|OLLAMA|SEARXNG"

# Check for rate limiting
docker compose -p localai logs local-deep-research | grep -i "rate\|limit\|quota"
```

**Solution:**
- Use Ollama for local inference (no rate limits):
  ```bash
  # In .env:
  LLM_PROVIDER=ollama
  OLLAMA_BASE_URL=http://ollama:11434
  ```
- Add delays between multiple research requests in n8n
- Check if external API quotas are exceeded

### Best Practices

**When to Use Local Deep Research:**

✅ **Perfect For:**
- Fact-checking critical business decisions
- Verifying statistics and financial data
- Academic research requiring high accuracy
- Regulatory compliance research
- Medical/scientific claim verification
- Legal research and due diligence

❌ **Not Ideal For:**
- Quick overviews (use GPT Researcher instead)
- Opinion-based questions
- Creative content generation
- Real-time data (use direct APIs)
- Simple information lookups

**Research Strategy by Time Available:**

**Quick Research (2-5 min):**
```
GPT Researcher (outline_report, 3 iterations)
→ Use for: Overviews, brainstorming, initial exploration
```

**Deep Research (10-20 min):**
```
Local Deep Research (5 iterations, high confidence)
→ Use for: Fact-checking, detailed analysis, decision support
```

**Comprehensive Research (30+ min):**
```
GPT Researcher (outline) → Extract claims
→ Local Deep Research (verify each claim)
→ Synthesize final report
→ Use for: Critical decisions, publications, compliance
```

**Optimization Tips:**

- **Context is Key**: Always provide prior research as context
- **Specific Queries**: "What is the ROI of X?" > "Tell me about X"
- **Iterate Gradually**: Start with 3 iterations, increase if needed
- **Parallel Processing**: Verify multiple claims concurrently in n8n
- **Cache Results**: Store verified facts in database to avoid re-research

**Integration Patterns:**

```javascript
// Pattern 1: Quick + Deep
GPT Researcher (overview) → Local Deep Research (verify key claims)

// Pattern 2: Multi-Source Validation
SearXNG (raw results) → Local Deep Research (synthesize + verify)

// Pattern 3: Continuous Monitoring
Schedule → Collect claims → Local Deep Research → Alert if false

// Pattern 4: Human-in-the-Loop
Local Deep Research → If confidence < 0.8 → Human review
```

### Resources

- **Official Documentation**: https://github.com/langchain-ai/local-deep-researcher
- **GitHub Repository**: https://github.com/langchain-ai/local-deep-researcher
- **LangChain Docs**: https://python.langchain.com/docs/
- **Internal API**: `http://local-deep-research:2024`
- **WebSocket Updates**: `ws://local-deep-research:2024/ws/{task_id}`

**Related Services:**
- Combine with **GPT Researcher** for quick + deep strategy
- Use **SearXNG** as search backend
- Store results in **PostgreSQL** or **Supabase**
- Process with **Ollama** for local LLM inference
- Compare with **Perplexica** for alternative perspectives
