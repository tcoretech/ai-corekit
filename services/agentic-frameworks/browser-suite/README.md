### What is Browser-use?

Browser-use is an LLM-powered browser automation tool that allows you to control a web browser using natural language instructions. Unlike traditional automation tools that require explicit programming, Browser-use leverages large language models (GPT-4, Claude, or local models via Ollama) to interpret commands like "Go to LinkedIn and extract the first 10 AI Engineer profiles in Berlin" and autonomously execute the necessary browser actions.

Browser-use runs on top of Browserless (a centralized Chrome/Chromium instance), providing a powerful combination for web scraping, form filling, data extraction, and automated testing.

### Features

- **Natural Language Control** - Control browsers with plain English commands
- **LLM-Powered** - Uses GPT-4, Claude, or Ollama for intelligent task interpretation
- **Multi-Step Workflows** - Execute complex sequences of browser actions
- **Data Extraction** - Extract structured data from websites automatically
- **Form Automation** - Fill out forms, click buttons, navigate pages
- **WebSocket Connection** - Integrates with Browserless for reliable browser access
- **Headless or Visible** - Run in headless mode or watch automation in real-time
- **Session Management** - Handle cookies, authentication, and state
- **Error Recovery** - LLM adapts to page changes and handles errors gracefully
- **No Selector Engineering** - No need to write CSS selectors or XPaths

### Initial Setup

**Browser-use runs as part of the Browser Automation Suite:**

Browser-use is not a standalone service with a web UI. Instead, it's a Python library that you run within Docker containers or n8n workflows. It connects to the **Browserless** service for actual browser control.

**Prerequisites:**
1. **Browserless must be running** - Browser-use requires a Browserless WebSocket connection
2. **LLM API key** - OpenAI, Anthropic, or Groq API key (or use Ollama for free local models)
3. **Python environment** - Available via the Python Runner container or custom Docker execution

**Configure LLM Provider:**

Add your API key to `.env` file:

```bash
# For OpenAI (recommended for best results)
OPENAI_API_KEY=sk-...

# For Anthropic Claude
ANTHROPIC_API_KEY=sk-ant-...

# For Groq (fast, free tier available)
GROQ_API_KEY=gsk_...

# For Ollama (local, no API key needed)
ENABLE_OLLAMA=true
OLLAMA_BASE_URL=http://ollama:11434
```

**Verify Browserless Connection:**

```bash
# Check Browserless is running
docker ps | grep browserless

# Test WebSocket connection
curl http://localhost:3000/json/version

# Should return Chrome version info
```

### n8n Integration Setup

**Browser-use via Python Execute Node:**

Browser-use doesn't have a native n8n node. Use the **Execute Command** or **Python Runner** to run Browser-use scripts.

**Method 1: Execute Command Node (Direct)**

```javascript
// 1. Code Node - Prepare Task
const task = {
  command: "Go to example.com and extract all product prices",
  browserless_url: "ws://browserless:3000",
  model: "gpt-4o-mini"
};

return { json: task };

// 2. Execute Command Node
Command:
docker exec browser-use python3 -c "
from browser_use import Browser, Agent
import asyncio

async def main():
    browser = Browser(websocket_url='{{ $json.browserless_url }}')
    agent = Agent(browser=browser, model='{{ $json.model }}')
    result = await agent.execute('{{ $json.command }}')
    print(result)

asyncio.run(main())
"

// 3. Code Node - Parse Output
const output = $input.first().json.stdout;
return { json: JSON.parse(output) };
```

**Method 2: Python Script File (Recommended)**

Create a Python script in the `/shared` directory:

```python
# File: /shared/browser_automation.py
from browser_use import Browser, Agent
import asyncio
import sys
import json

async def main():
    task = sys.argv[1] if len(sys.argv) > 1 else "Extract data"
    
    browser = Browser(
        websocket_url="ws://browserless:3000",
        headless=True
    )
    
    agent = Agent(
        browser=browser,
        model="gpt-4o-mini",  # or "claude-3-5-sonnet-20241022"
        # model="ollama/llama3.2" for local
    )
    
    result = await agent.execute(task)
    
    # Return as JSON
    print(json.dumps(result))

if __name__ == "__main__":
    asyncio.run(main())
```

**n8n Workflow:**

```javascript
// 1. Webhook Trigger - Receive automation request

// 2. Execute Command Node
Command: python3 /data/shared/browser_automation.py "{{ $json.task }}"
Working Directory: /data

// 3. Code Node - Process Results
const output = JSON.parse($input.first().json.stdout);
return { 
  json: {
    success: true,
    data: output,
    timestamp: new Date().toISOString()
  }
};
```

**Internal URLs:**
- **Browserless WebSocket:** `ws://browserless:3000`
- **Browserless HTTP:** `http://browserless:3000` (for debugging)

### Example Workflows

#### Example 1: LinkedIn Profile Scraper

Extract profiles from LinkedIn with natural language:

```python
# Save as /shared/linkedin_scraper.py
from browser_use import Browser, Agent
import asyncio
import json

async def scrape_linkedin(search_query, count=10):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o")
    
    task = f"""
    Go to LinkedIn and search for '{search_query}'.
    Extract the first {count} profiles including:
    - Name
    - Job Title
    - Company
    - Location
    - Profile URL
    
    Return as structured JSON.
    """
    
    result = await agent.execute(task)
    return result

# Run
result = asyncio.run(scrape_linkedin("AI Engineers in Berlin", 10))
print(json.dumps(result, indent=2))
```

**n8n Integration:**

```javascript
// 1. Schedule Trigger - Daily at 9 AM

// 2. Set Parameters
const searchQuery = "Machine Learning Engineers in Munich";
const profileCount = 20;

// 3. Execute Command
Command: python3 /data/shared/linkedin_scraper.py

// 4. Code Node - Parse Results
const profiles = JSON.parse($input.first().json.stdout);

// 5. Loop - Process each profile
// 6. Supabase Node - Store in database
// 7. Email Node - Send daily summary
```

#### Example 2: E-Commerce Price Monitor

Monitor competitor prices automatically:

```python
# Save as /shared/price_monitor.py
from browser_use import Browser, Agent
import asyncio

async def monitor_prices(competitor_urls):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o-mini")
    
    results = []
    for url in competitor_urls:
        task = f"""
        Navigate to {url}
        Find the product price
        Extract: product name, current price, currency
        Check if there's a discount or sale banner
        """
        
        result = await agent.execute(task)
        results.append(result)
    
    return results

# Usage
urls = [
    "https://competitor1.com/product-a",
    "https://competitor2.com/product-a"
]

prices = asyncio.run(monitor_prices(urls))
print(prices)
```

**n8n Workflow:**

```javascript
// 1. Schedule Trigger - Every 6 hours

// 2. HTTP Request - Get competitor URLs from database

// 3. Loop - For each URL

// 4. Execute Command
Command: python3 /data/shared/price_monitor.py

// 5. Code Node - Compare with yesterday's prices
const today = $json.price;
const yesterday = $('Database').item.json.last_price;

if (today < yesterday) {
  return {
    json: {
      alert: true,
      product: $json.product_name,
      price_drop: yesterday - today,
      url: $json.url
    }
  };
}

// 6. IF Node - Price dropped?
// 7. Send Alert Email
// 8. Update Database
```

#### Example 3: Form Filling Automation

Automatically fill out forms across multiple websites:

```python
# Save as /shared/form_filler.py
from browser_use import Browser, Agent
import asyncio

async def fill_form(url, form_data):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="claude-3-5-sonnet-20241022")
    
    task = f"""
    Navigate to {url}
    Fill out the form with this information:
    - Name: {form_data['name']}
    - Email: {form_data['email']}
    - Company: {form_data['company']}
    - Message: {form_data['message']}
    
    Submit the form
    Wait for confirmation message
    Return: success status and confirmation text
    """
    
    result = await agent.execute(task)
    return result

# Usage
data = {
    "name": "John Doe",
    "email": "john@example.com",
    "company": "Acme Corp",
    "message": "Interested in your services"
}

result = asyncio.run(fill_form("https://example.com/contact", data))
print(result)
```

#### Example 4: Research & Data Collection

Gather information from multiple sources:

```python
# Save as /shared/research_agent.py
from browser_use import Browser, Agent
import asyncio

async def research_topic(topic, sources):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o")
    
    task = f"""
    Research the topic: {topic}
    
    Visit these sources:
    {', '.join(sources)}
    
    For each source:
    1. Extract key information
    2. Identify main arguments
    3. Find statistics or data points
    
    Compile a comprehensive summary with citations.
    """
    
    result = await agent.execute(task)
    return result

# Usage
topic = "Impact of AI on employment in 2025"
sources = [
    "https://www.mckinsey.com",
    "https://www.weforum.org",
    "https://news.ycombinator.com"
]

research = asyncio.run(research_topic(topic, sources))
print(research)
```

### Troubleshooting

**Cannot connect to Browserless:**

```bash
# 1. Check Browserless is running
docker ps | grep browserless
# Should show browserless container on port 3000

# 2. Test WebSocket connection
curl http://localhost:3000/json/version

# 3. Check Browser-use container logs
docker logs browser-use --tail 50

# 4. Verify network connectivity
docker exec browser-use ping browserless
# Should receive replies

# 5. Restart if needed
docker compose restart browserless browser-use
```

**LLM not understanding tasks:**

```bash
# 1. Use more specific instructions
# Bad:  "Get data from website"
# Good: "Navigate to example.com, find the pricing table, extract all plan names and prices"

# 2. Switch to a better model
# GPT-4o > GPT-4o-mini > Claude > Ollama (for accuracy)

# 3. Break complex tasks into steps
# Instead of one long task, create multiple smaller agent.execute() calls

# 4. Add explicit waits
task = "Go to URL, wait 3 seconds for page load, then extract data"
```

**Session/Cookie issues:**

```python
# Store cookies for authenticated sessions
from browser_use import Browser, Agent

browser = Browser(
    websocket_url="ws://browserless:3000",
    persistent_context=True  # Keeps cookies between runs
)

# First run: Login
agent = Agent(browser=browser, model="gpt-4o")
await agent.execute("Login to example.com with username X and password Y")

# Second run: Authenticated action (cookies preserved)
await agent.execute("Navigate to dashboard and extract user data")
```

**Slow execution:**

```bash
# 1. Switch to faster models
# Groq (llama-3.1-70b) - Very fast
# GPT-4o-mini - Balanced
# GPT-4o - Slow but accurate

# 2. Enable headless mode
browser = Browser(websocket_url="ws://browserless:3000", headless=True)

# 3. Increase Browserless concurrent limit
# In .env file:
BROWSERLESS_CONCURRENT=5  # Allow more parallel sessions

# 4. Use simpler selectors in instructions
# "Click the red button" vs "Click the button with class .primary-btn-submit"
```

**Out of memory errors:**

```bash
# 1. Check container resources
docker stats browserless browser-use

# 2. Limit concurrent sessions
# Reduce BROWSERLESS_CONCURRENT in .env

# 3. Close browsers after use
await browser.close()

# 4. Increase container memory
# In docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 4G  # Increase from default
```

### Configuration Options

**LLM Models (in order of accuracy):**

1. **GPT-4o** - Best accuracy, slower, more expensive
2. **Claude 3.5 Sonnet** - Excellent reasoning, good for complex tasks
3. **GPT-4o-mini** - Balanced speed and accuracy
4. **Groq (llama-3.1-70b)** - Very fast, good for simple tasks
5. **Ollama (llama3.2)** - Local, free, lower accuracy

**Browser Configuration:**

```python
browser = Browser(
    websocket_url="ws://browserless:3000",
    headless=True,           # No GUI (faster)
    persistent_context=True, # Keep cookies/sessions
    timeout=60000,          # 60 second timeout
    viewport={"width": 1920, "height": 1080}
)
```

**Agent Configuration:**

```python
agent = Agent(
    browser=browser,
    model="gpt-4o-mini",
    max_actions=50,          # Max steps before giving up
    verbose=True,            # Log all actions
    screenshot_on_error=True # Save screenshot if task fails
)
```

### Integration with AI CoreKit Services

**Browser-use + Qdrant:**
- Scrape websites and store embeddings in Qdrant
- Build searchable knowledge base from web data

**Browser-use + Supabase:**
- Store scraped data in Supabase database
- Track scraping jobs and results

**Browser-use + n8n:**
- Schedule recurring scraping jobs
- Trigger browser automation from webhooks
- Chain browser tasks with other n8n nodes

**Browser-use + Ollama:**
- Use local LLMs for browser control (free!)
- No API costs for development/testing
- Privacy-focused automation

**Browser-use + Flowise/Dify:**
- Integrate browser automation into AI agents
- Agents can search web and extract data on demand

### Resources

- **GitHub:** https://github.com/browser-use/browser-use
- **Documentation:** https://docs.browser-use.com/
- **Python SDK:** `pip install browser-use`
- **Examples:** https://github.com/browser-use/browser-use/tree/main/examples
- **Community:** Discord (link in GitHub README)
- **Browserless Docs:** https://www.browserless.io/docs

### Best Practices

**Task Writing:**
- Be specific: "Extract product prices" → "Extract all prices from the pricing table with plan names"
- Include wait conditions: "Wait for page to fully load before extracting"
- Specify output format: "Return as JSON with fields: name, price, url"

**Error Handling:**
- Always use try/except in Python scripts
- Set reasonable timeouts (30-60 seconds)
- Log all actions for debugging
- Save screenshots on failures

**Performance:**
- Use headless mode for production
- Close browsers after tasks complete
- Limit concurrent sessions based on server resources
- Cache results when possible

**Security:**
- Never hardcode credentials in scripts
- Store API keys in environment variables
- Be respectful of websites (don't overload with requests)
- Follow robots.txt and terms of service


### What is Skyvern?

Skyvern is an AI-powered browser automation platform that uses computer vision and large language models to interact with websites without requiring predefined selectors or scripts. Unlike traditional automation tools that break when websites change their HTML structure, Skyvern "sees" web pages like a human does and adapts to layout changes automatically. This makes it ideal for automating complex workflows on dynamic websites, handling CAPTCHAs, and navigating sites that are difficult to script.

Skyvern runs on top of Browserless and is designed for tasks where traditional automation fails: visual verification, dynamic content, anti-bot detection, and workflows that require understanding context rather than just following predefined paths.

### Features

- **Computer Vision-Based** - Uses AI vision to understand web pages visually, no CSS selectors needed
- **Self-Healing Automation** - Adapts to website changes automatically, no script maintenance
- **CAPTCHA Handling** - Can solve visual CAPTCHAs and navigate anti-bot protections
- **Natural Language Goals** - Define automation tasks in plain English
- **Multi-Step Workflows** - Execute complex sequences with branching logic
- **Data Extraction** - Extract structured data from visually complex layouts
- **Form Filling** - Fill out forms intelligently based on field labels and context
- **Screenshot Validation** - Visual verification of task completion
- **Proxy Support** - Rotate IPs and manage session isolation
- **Webhook Callbacks** - Real-time task status updates

### Initial Setup

**Skyvern runs as part of the Browser Automation Suite:**

Skyvern is not a standalone service with a web UI. It's an API service that you call from n8n workflows or other applications. It connects to **Browserless** for browser control.

**Prerequisites:**
1. **Browserless must be running** - Skyvern requires Browserless for browser automation
2. **API Key configured** - Set during installation in `.env` file

**Verify Setup:**

```bash
# Check Skyvern is running
docker ps | grep skyvern
# Should show skyvern container on port 8000

# Check Browserless connection
docker exec skyvern curl http://browserless:3000/json/version

# Test API endpoint
curl http://localhost:8000/v1/health
```

**Get API Key:**

Your Skyvern API key is automatically generated during installation and stored in `.env`:

```bash
# View your API key
grep SKYVERN_API_KEY .env
```

### n8n Integration Setup

**Using HTTP Request Nodes:**

Skyvern doesn't have a native n8n node. Use **HTTP Request** nodes to interact with the Skyvern API.

**Create Skyvern Credentials in n8n:**

1. In n8n, create credentials:
   - Type: **Header Auth**
   - Name: **Skyvern API**
   - Header Name: `X-API-Key`
   - Header Value: Your `SKYVERN_API_KEY` from `.env`

**Internal URL:** `http://skyvern:8000`

**API Endpoints:**
- Execute task: `POST /v1/execute`
- Get task status: `GET /v1/tasks/{task_id}`
- Get task result: `GET /v1/tasks/{task_id}/result`
- List tasks: `GET /v1/tasks`

### Example Workflows

#### Example 1: Form Automation with Visual Intelligence

Automatically fill out complex forms on any website:

```javascript
// Intelligent form filling that adapts to different layouts

// 1. Webhook Trigger - Receive form submission request

// 2. Code Node - Prepare Task
const taskData = {
  url: $json.target_url || "https://example.com/contact-form",
  navigation_goal: "Fill out the contact form with the provided information and submit it",
  data: {
    name: $json.customer_name || "John Doe",
    email: $json.customer_email || "john@example.com",
    company: $json.company_name || "Acme Corp",
    phone: $json.phone || "+49 123 456789",
    message: $json.message || "I'm interested in your services"
  },
  wait_for: "Thank you for your submission",  // Wait for this text
  timeout: 60000,  // 60 seconds
  screenshot: true  // Take screenshot after completion
};

return { json: taskData };

// 3. HTTP Request - Execute Skyvern Task
Method: POST
URL: http://skyvern:8000/v1/execute
Authentication: Skyvern API (Header Auth)
Body:
{
  "url": "{{ $json.url }}",
  "navigation_goal": "{{ $json.navigation_goal }}",
  "data": {{ $json.data }},
  "wait_for": "{{ $json.wait_for }}",
  "timeout": {{ $json.timeout }},
  "screenshot": {{ $json.screenshot }}
}

// 4. Set Variable - Store Task ID
task_id: {{ $json.task_id }}

// 5. Wait - Initial processing time
Amount: 5 seconds

// 6. Loop - Poll for completion (max 12 times = 60 seconds)
For: 12 iterations

// 7. HTTP Request - Check Status
Method: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Set Variable').item.json.task_id }}
Authentication: Skyvern API

// 8. IF Node - Check if complete
Condition: {{ $json.status }} === "completed"

// Branch: Completed
// 9a. HTTP Request - Get Results
Method: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Set Variable').item.json.task_id }}/result

// 10a. Code Node - Process Results
const result = $json;

return {
  json: {
    success: result.success,
    url: result.final_url,
    screenshot_url: result.screenshot_url,
    extracted_data: result.extracted_data,
    execution_time: result.execution_time_ms
  }
};

// 11a. Email Node - Send success notification

// Branch: Not Complete
// 9b. Wait - 5 seconds before next poll
// 10b. Continue loop

// Branch: Failed/Timeout
// 9c. Error Handler - Log and notify
```

#### Example 2: Data Extraction from Dynamic Websites

Extract product information from e-commerce sites:

```javascript
// Extract structured data from visually complex pages

// 1. Schedule Trigger - Daily at 6 AM

// 2. Spreadsheet/Database - Load competitor URLs
// Read list of product pages to scrape

// 3. Loop - For each URL

// 4. HTTP Request - Execute Skyvern Extraction
Method: POST
URL: http://skyvern:8000/v1/execute
Authentication: Skyvern API
Body:
{
  "url": "{{ $json.product_url }}",
  "navigation_goal": "Extract all product information including name, price, description, specifications, availability, and customer reviews",
  "data_extraction": {
    "product_name": "text",
    "current_price": "number",
    "original_price": "number",
    "currency": "text",
    "in_stock": "boolean",
    "product_description": "text",
    "specifications": "object",
    "rating": "number",
    "review_count": "number",
    "image_urls": "array"
  },
  "screenshot": true,
  "timeout": 90000
}

// 5. Wait - Processing time
Amount: 10 seconds

// 6. HTTP Request - Get Results
Method: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Execute Skyvern').json.task_id }}/result

// 7. Code Node - Structure Data
const extracted = $json.extracted_data;
const product = {
  url: $('Loop').item.json.product_url,
  name: extracted.product_name,
  current_price: extracted.current_price,
  original_price: extracted.original_price,
  discount_percentage: extracted.original_price > 0 
    ? ((extracted.original_price - extracted.current_price) / extracted.original_price * 100).toFixed(2)
    : 0,
  in_stock: extracted.in_stock,
  rating: extracted.rating,
  review_count: extracted.review_count,
  scraped_at: new Date().toISOString(),
  screenshot: $json.screenshot_url
};

return { json: product };

// 8. Supabase/Database Node - Store data

// 9. IF Node - Price dropped?
Condition: {{ $json.discount_percentage }} > 20

// 10. Send Alert - Significant discount found
```

#### Example 3: CAPTCHA Solving & Anti-Bot Navigation

Navigate protected sites and solve CAPTCHAs:

```javascript
// Skyvern can handle visual CAPTCHAs automatically

// 1. Webhook Trigger - Automation request

// 2. HTTP Request - Navigate Protected Site
Method: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "url": "https://protected-site.com/login",
  "navigation_goal": "Login to the website using provided credentials, solve any CAPTCHA if present, and navigate to the dashboard",
  "data": {
    "username": "{{ $json.username }}",
    "password": "{{ $json.password }}"
  },
  "handle_captcha": true,
  "wait_for": "Dashboard",
  "timeout": 120000,  // 2 minutes for CAPTCHA
  "screenshot": true
}

// 3. Wait & Poll for completion (similar to Example 1)

// 4. IF Node - Check login success
Condition: {{ $json.success }} === true

// Branch: Success
// 5a. HTTP Request - Execute post-login actions
Method: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "session_id": "{{ $('Login').json.session_id }}",  // Continue same session
  "navigation_goal": "Navigate to reports section and download the latest monthly report",
  "timeout": 60000
}

// 6a. Download and process report

// Branch: Failed
// 5b. Retry Node - Try again (max 3 attempts)
// 6b. Alert admin if all retries fail
```

#### Example 4: Multi-Step Purchase Flow

Automate complete checkout processes:

```javascript
// Complex multi-page workflows with decision logic

// 1. Webhook Trigger - Purchase order received

// 2. HTTP Request - Start Shopping Flow
Method: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "url": "https://supplier-website.com",
  "navigation_goal": "Search for product '{{ $json.product_sku }}', add it to cart with quantity {{ $json.quantity }}, proceed to checkout",
  "data": {
    "search_term": "{{ $json.product_sku }}",
    "quantity": {{ $json.quantity }}
  },
  "wait_for": "Shopping Cart",
  "screenshot": true
}

// 3. Wait & Poll

// 4. HTTP Request - Complete Checkout
Method: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "session_id": "{{ $('Start Shopping').json.session_id }}",
  "navigation_goal": "Complete checkout with provided billing and shipping information, select standard shipping, and confirm order",
  "data": {
    "billing_name": "{{ $json.billing_name }}",
    "billing_address": "{{ $json.billing_address }}",
    "billing_city": "{{ $json.billing_city }}",
    "billing_zip": "{{ $json.billing_zip }}",
    "card_number": "{{ $json.card_number }}",
    "card_expiry": "{{ $json.card_expiry }}",
    "card_cvv": "{{ $json.card_cvv }}"
  },
  "wait_for": "Order Confirmed",
  "extract": {
    "order_number": "text",
    "order_total": "number",
    "estimated_delivery": "date"
  }
}

// 5. Store order details in database

// 6. Send confirmation email with order number
```

### Task Configuration Options

**Basic Task:**
```json
{
  "url": "https://example.com",
  "navigation_goal": "What to accomplish",
  "timeout": 60000
}
```

**Advanced Task with Data:**
```json
{
  "url": "https://example.com/form",
  "navigation_goal": "Fill and submit the form",
  "data": {
    "field1": "value1",
    "field2": "value2"
  },
  "wait_for": "Success message",
  "screenshot": true,
  "handle_captcha": true,
  "extract": {
    "confirmation_number": "text",
    "status": "text"
  },
  "timeout": 120000
}
```

**Session Continuation:**
```json
{
  "session_id": "previous_task_session_id",
  "navigation_goal": "Continue previous session and do X",
  "timeout": 60000
}
```

### Troubleshooting

**Task timeout or failure:**

```bash
# 1. Check Skyvern logs
docker logs skyvern --tail 100

# 2. Verify Browserless connection
docker exec skyvern curl http://browserless:3000/json/version

# 3. Increase timeout for complex tasks
# In task body: "timeout": 180000  (3 minutes)

# 4. Check if website has anti-bot protection
# Some sites may block headless browsers
# Try with "stealth_mode": true in task

# 5. Test task manually first
curl -X POST http://localhost:8000/v1/execute \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "navigation_goal": "Test task",
    "screenshot": true
  }'
```

**CAPTCHA not solving:**

```bash
# 1. Ensure handle_captcha is enabled
"handle_captcha": true

# 2. Increase timeout (CAPTCHAs take longer)
"timeout": 120000  # 2 minutes minimum

# 3. Check CAPTCHA type support
# Skyvern handles:
# - reCAPTCHA v2 (image selection)
# - hCaptcha
# - Basic image CAPTCHAs
# 
# Does NOT handle:
# - reCAPTCHA v3 (invisible, score-based)
# - Audio CAPTCHAs

# 4. Some sites use advanced bot detection
# Consider using residential proxies if available
```

**Data extraction incomplete:**

```bash
# 1. Be specific in navigation_goal
# Bad:  "Extract product info"
# Good: "Extract product name, price from pricing section, description from overview tab, and customer rating"

# 2. Define extraction schema
"extract": {
  "product_name": "text",
  "price": "number",
  "in_stock": "boolean"
}

# 3. Add wait conditions
"wait_for": "Price loaded"  # Wait for dynamic content

# 4. Take screenshots to debug
"screenshot": true
# Check screenshot in task result to see what Skyvern sees
```

**High resource usage:**

```bash
# 1. Check concurrent tasks
docker stats skyvern browserless

# 2. Limit concurrent executions
# In .env file:
BROWSERLESS_CONCURRENT=3  # Reduce from default 10

# 3. Reduce screenshot quality/frequency
# Only enable screenshots when debugging

# 4. Clean up old sessions
curl -X DELETE http://localhost:8000/v1/tasks/old  # Clear old task data
```

### Best Practices

**Task Design:**
- **Be specific:** "Click the blue 'Submit' button at bottom right" vs "Submit form"
- **Add context:** Include visual descriptions for complex pages
- **Set realistic timeouts:** 60s for simple tasks, 120s+ for complex flows
- **Use wait_for:** Specify text/elements that indicate task completion

**Data Extraction:**
- Define clear extraction schema with field types
- Use descriptive field names matching visible labels
- Extract from specific page sections for accuracy
- Validate extracted data before downstream processing

**Error Handling:**
- Always implement polling for task status
- Set maximum retry attempts
- Save screenshots on failures for debugging
- Log task IDs for troubleshooting

**Performance:**
- Reuse sessions for multi-step workflows
- Disable screenshots in production (faster)
- Batch similar tasks together
- Monitor Browserless resource usage

**Security:**
- Never log credentials in task descriptions
- Store API keys securely in environment variables
- Use separate API keys per environment
- Rotate API keys regularly

### Integration with AI CoreKit Services

**Skyvern + Browser-use:**
- Use Skyvern for complex visual tasks (CAPTCHAs, dynamic content)
- Use Browser-use for simpler scripted automation
- Combine both for robust automation pipelines

**Skyvern + Supabase:**
- Store scraped data in Supabase database
- Track task history and results
- Build dashboards for monitoring

**Skyvern + n8n:**
- Schedule recurring automation tasks
- Chain Skyvern with data processing workflows
- Implement retry logic and error handling

**Skyvern + Flowise/Dify:**
- AI agents can trigger Skyvern for web interactions
- Extract data for RAG knowledge bases
- Automate research and data collection

### Resources

- **Official Website:** https://www.skyvern.com/
- **Documentation:** https://docs.skyvern.com/
- **GitHub:** https://github.com/Skyvern-AI/skyvern
- **API Reference:** https://docs.skyvern.com/api-reference
- **Community:** Discord (link on website)
- **Examples:** https://github.com/Skyvern-AI/skyvern/tree/main/examples

### When to Use Skyvern

**Use Skyvern for:**
- ✅ Websites that frequently change their layout
- ✅ Complex forms with conditional fields
- ✅ Sites with CAPTCHA protection
- ✅ Visual verification tasks
- ✅ Data extraction from complex layouts
- ✅ Multi-step workflows with branching logic
- ✅ Sites with anti-bot protection

**Use Browser-use instead for:**
- ❌ Simple, stable websites
- ❌ When you need fastest execution
- ❌ When website structure is consistent
- ❌ Basic form filling without CAPTCHAs
- ❌ When cost is primary concern (Skyvern uses more resources)

**Use traditional Puppeteer/Selenium for:**
- ❌ Very high-volume automation (1000+ runs/day)
- ❌ When you have complete website documentation
- ❌ Performance-critical applications
- ❌ When websites never change


### What is Browserless?

Browserless is a headless Chrome/Chromium service that provides a centralized, scalable browser runtime for automation tools. Instead of each tool managing its own browser instances, Browserless acts as a shared "browser hub" that multiple services (Browser-use, Skyvern, Puppeteer, Playwright) connect to via WebSocket. This architecture provides better resource management, concurrent session handling, and simplified browser lifecycle management.

Think of Browserless as the "browser engine room" of your automation infrastructure - it handles all the complexity of running Chrome instances while other tools focus on their specific automation logic.

### Features

- **Centralized Chrome Runtime** - One service manages all browser instances
- **WebSocket API** - Clean interface for Puppeteer/Playwright connections
- **Concurrent Sessions** - Handle 10+ parallel browser sessions
- **Resource Management** - Automatic cleanup and memory limits
- **HTTP APIs** - REST endpoints for screenshots, PDFs, and content
- **Session Recording** - Debug with video recordings of automation runs
- **Stealth Mode** - Anti-bot detection evasion
- **Proxy Support** - Route browser traffic through proxies
- **Container Isolation** - Each session runs in isolated environment
- **Health Monitoring** - Built-in health checks and metrics

### Initial Setup

**Browserless runs automatically with the Browser Automation Suite:**

Browserless has no web UI - it's a backend service that other tools connect to. It starts automatically when you install Browser-use or Skyvern.

**Verify Setup:**

```bash
# Check Browserless is running
docker ps | grep browserless
# Should show browserless container on port 3000

# Test HTTP endpoint
curl http://localhost:3000/json/version
# Should return Chrome version info

# Check WebSocket health
curl http://localhost:3000/pressure
# Shows current session load
```

**Configuration:**

Browserless is configured via environment variables in `.env`:

```bash
# View Browserless settings
grep BROWSERLESS .env

# Key settings:
BROWSERLESS_CONCURRENT=10        # Max concurrent sessions
BROWSERLESS_TIMEOUT=30000       # Session timeout (ms)
BROWSERLESS_DEBUGGER=false      # Enable Chrome DevTools
BROWSERLESS_TOKEN=your_token    # Authentication token
```

### Internal Access

**WebSocket URL (for automation tools):**
```
ws://browserless:3000
```

**With authentication:**
```
ws://browserless:3000?token=YOUR_TOKEN
```

**HTTP API Base URL:**
```
http://browserless:3000
```

### n8n Integration Setup

Browserless is primarily used through other tools (Browser-use, Skyvern), but you can also use it directly with Puppeteer nodes.

**Method 1: Puppeteer Community Node**

1. Install community node:
   - Go to n8n Settings → **Community Nodes**
   - Search: `n8n-nodes-puppeteer`
   - Click **Install**
   - Restart n8n: `docker compose restart n8n`

2. Configure Puppeteer Node:
   ```javascript
   // In Puppeteer node settings:
   WebSocket URL: ws://browserless:3000
   Executable Path: (leave empty)
   Launch Options:
   {
     "headless": true,
     "args": [
       "--no-sandbox",
       "--disable-setuid-sandbox",
       "--disable-dev-shm-usage"
     ]
   }
   ```

**Method 2: HTTP API (Direct)**

Use HTTP Request nodes to call Browserless APIs:

```javascript
// Screenshot API
Method: POST
URL: http://browserless:3000/screenshot
Headers:
  Content-Type: application/json
Body:
{
  "url": "https://example.com",
  "options": {
    "fullPage": true,
    "type": "png"
  }
}

// PDF API
Method: POST
URL: http://browserless:3000/pdf
Body:
{
  "url": "https://example.com",
  "options": {
    "format": "A4",
    "printBackground": true
  }
}

// Content API (HTML extraction)
Method: POST
URL: http://browserless:3000/content
Body:
{
  "url": "https://example.com",
  "waitForSelector": ".main-content"
}
```

### Example Workflows

#### Example 1: Bulk Screenshot Generation

Generate screenshots of multiple websites:

```javascript
// Efficient bulk screenshot workflow

// 1. Spreadsheet Node - Load URLs
// Table with columns: url, name

// 2. Loop Over Items

// 3. HTTP Request - Generate Screenshot
Method: POST
URL: http://browserless:3000/screenshot
Headers:
  Content-Type: application/json
Body:
{
  "url": "{{ $json.url }}",
  "options": {
    "fullPage": true,
    "type": "png",
    "quality": 90
  },
  "gotoOptions": {
    "waitUntil": "networkidle2",
    "timeout": 30000
  }
}
Response Format: File

// 4. Move Binary - Rename screenshot
From Property: data
To Property: screenshot
New File Name: {{ $json.name }}_{{ $now.format('YYYY-MM-DD') }}.png

// 5. Google Drive Node - Upload
Operation: Upload
File: {{ $binary.screenshot }}
Folder: Website Screenshots
Name: {{ $json.name }}.png

// 6. Supabase Node - Store metadata
Table: screenshots
Data:
  website: {{ $json.url }}
  name: {{ $json.name }}
  screenshot_url: {{ $('Google Drive').json.webViewLink }}
  created_at: {{ $now.toISO() }}
```

#### Example 2: PDF Report Generation

Convert web pages to professional PDFs:

```javascript
// Generate PDF reports from web pages

// 1. Webhook Trigger - Receive report request
// Payload: { "url": "https://example.com/report", "filename": "monthly_report" }

// 2. HTTP Request - Generate PDF
Method: POST
URL: http://browserless:3000/pdf
Headers:
  Content-Type: application/json
Body:
{
  "url": "{{ $json.url }}",
  "options": {
    "format": "A4",
    "printBackground": true,
    "margin": {
      "top": "1cm",
      "right": "1cm",
      "bottom": "1cm",
      "left": "1cm"
    },
    "displayHeaderFooter": true,
    "headerTemplate": "<div style='font-size:10px; text-align:center; width:100%'>Company Report</div>",
    "footerTemplate": "<div style='font-size:10px; text-align:center; width:100%'>Page <span class='pageNumber'></span> of <span class='totalPages'></span></div>"
  },
  "gotoOptions": {
    "waitUntil": "networkidle0"
  }
}
Response Format: File

// 3. Move Binary - Rename PDF
To Property: pdf_report
New File Name: {{ $json.filename }}_{{ $now.format('YYYY-MM-DD') }}.pdf

// 4. Email Node - Send report
Attachments: {{ $binary.pdf_report }}
To: {{ $json.recipient_email }}
Subject: Monthly Report - {{ $now.format('MMMM YYYY') }}
Message: Please find attached the monthly report.

// 5. S3/Cloudflare R2 - Archive
Bucket: company-reports
Key: reports/{{ $now.format('YYYY/MM') }}/{{ $json.filename }}.pdf
File: {{ $binary.pdf_report }}
```

#### Example 3: Advanced Web Scraping with Puppeteer

Use Puppeteer node for complex interactions:

```javascript
// Multi-step scraping with JavaScript execution

// 1. Schedule Trigger - Daily at 6 AM

// 2. Puppeteer Node - Launch Browser
Action: Launch Browser
WebSocket URL: ws://browserless:3000

// 3. Puppeteer Node - Navigate
Action: Navigate
URL: https://example.com/products
Browser Connection: {{ $('Launch Browser').json }}

// 4. Puppeteer Node - Wait for Selector
Action: Wait for Selector
Selector: .product-list
Browser Connection: {{ $('Launch Browser').json }}

// 5. Puppeteer Node - Execute JavaScript
Action: Evaluate
JavaScript Code:
```javascript
// Extract product data
const products = [];
const items = document.querySelectorAll('.product-item');

items.forEach(item => {
  products.push({
    name: item.querySelector('.product-name')?.textContent.trim(),
    price: item.querySelector('.product-price')?.textContent.trim(),
    image: item.querySelector('.product-image')?.src,
    url: item.querySelector('a')?.href
  });
});

return products;
```

// 6. Code Node - Process Results
const products = $json;
return products.map(p => ({ json: p }));

// 7. Loop Over Products

// 8. Puppeteer Node - Navigate to Product Page
Action: Navigate
URL: {{ $json.url }}

// 9. Puppeteer Node - Take Screenshot
Action: Screenshot
Full Page: true

// 10. Supabase Node - Store Product
Table: products
Data: {{ $json }}

// 11. Puppeteer Node - Close Browser (after loop)
Action: Close Browser
```

#### Example 4: Performance Testing

Monitor website load times:

```javascript
// Automated performance monitoring

// 1. Schedule Trigger - Every 15 minutes

// 2. HTTP Request - Performance Metrics
Method: POST
URL: http://browserless:3000/performance
Body:
{
  "url": "{{ $json.website_url }}",
  "metrics": [
    "firstContentfulPaint",
    "largestContentfulPaint",
    "totalBlockingTime",
    "cumulativeLayoutShift",
    "timeToInteractive"
  ]
}

// 3. Code Node - Evaluate Performance
const metrics = $json;
const score = {
  fcp: metrics.firstContentfulPaint < 1800 ? "good" : "poor",
  lcp: metrics.largestContentfulPaint < 2500 ? "good" : "poor",
  tbt: metrics.totalBlockingTime < 200 ? "good" : "poor",
  cls: metrics.cumulativeLayoutShift < 0.1 ? "good" : "poor",
  tti: metrics.timeToInteractive < 3800 ? "good" : "poor"
};

const overallScore = Object.values(score).filter(s => s === "good").length;

return {
  json: {
    website: $('Schedule Trigger').json.website_url,
    metrics: metrics,
    scores: score,
    overall: `${overallScore}/5`,
    timestamp: new Date().toISOString()
  }
};

// 4. IF Node - Performance degraded?
Condition: {{ $json.overall }} < "4/5"

// Branch: Alert
// 5a. Slack Node - Send alert
Channel: #monitoring
Message: |
  ⚠️ Performance degradation detected!
  
  Website: {{ $json.website }}
  Score: {{ $json.overall }}
  
  Issues:
  {{#each $json.scores}}
  - {{@key}}: {{this}}
  {{/each}}

// Branch: OK
// 5b. InfluxDB/Prometheus - Log metrics
```

### HTTP API Endpoints

**Screenshot:**
```bash
POST /screenshot
{
  "url": "https://example.com",
  "options": {
    "fullPage": true,
    "type": "png",
    "quality": 90,
    "omitBackground": false
  }
}
```

**PDF:**
```bash
POST /pdf
{
  "url": "https://example.com",
  "options": {
    "format": "A4",
    "landscape": false,
    "printBackground": true,
    "scale": 1
  }
}
```

**Content (HTML):**
```bash
POST /content
{
  "url": "https://example.com",
  "waitForSelector": "#main-content",
  "waitForTimeout": 5000
}
```

**Function (Execute JavaScript):**
```bash
POST /function
{
  "code": "return document.title;"
}
```

**Performance:**
```bash
POST /performance
{
  "url": "https://example.com",
  "metrics": ["firstContentfulPaint", "domContentLoaded"]
}
```

### Configuration Options

**Environment Variables (.env):**

```bash
# Maximum concurrent browser sessions
BROWSERLESS_CONCURRENT=10

# Session timeout in milliseconds
BROWSERLESS_TIMEOUT=30000

# Enable Chrome DevTools debugger
BROWSERLESS_DEBUGGER=false

# Authentication token
BROWSERLESS_TOKEN=your-secure-token

# Maximum queue length
BROWSERLESS_MAX_QUEUE_LENGTH=100

# Enable session recordings
BROWSERLESS_ENABLE_RECORDING=false

# Proxy configuration
BROWSERLESS_PROXY_URL=http://proxy.example.com:8080

# Memory limit per session
BROWSERLESS_MAX_MEMORY_MB=512
```

**Resource Limits:**

```yaml
# In docker-compose.yml
browserless:
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 4G
      reservations:
        cpus: '1.0'
        memory: 2G
```

### Troubleshooting

**Sessions timing out:**

```bash
# 1. Check current session load
curl http://localhost:3000/pressure
# Shows: { "running": 5, "queued": 2, "maxConcurrent": 10 }

# 2. Increase concurrent limit
# In .env file:
BROWSERLESS_CONCURRENT=15

# 3. Increase timeout for slow sites
BROWSERLESS_TIMEOUT=60000  # 60 seconds

# 4. Restart Browserless
docker compose restart browserless
```

**Out of memory errors:**

```bash
# 1. Check memory usage
docker stats browserless

# 2. Increase container memory limit
# In docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 6G

# 3. Reduce concurrent sessions
BROWSERLESS_CONCURRENT=5

# 4. Enable automatic cleanup
# Add to docker-compose.yml environment:
BROWSERLESS_MAX_MEMORY_PERCENT=90
```

**WebSocket connection failed:**

```bash
# 1. Verify Browserless is running
docker ps | grep browserless

# 2. Test WebSocket endpoint
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  http://localhost:3000

# Should return: 101 Switching Protocols

# 3. Check network connectivity
docker exec browser-use ping browserless

# 4. Verify token if using authentication
# In connection string: ws://browserless:3000?token=YOUR_TOKEN
```

**Chrome crashes:**

```bash
# 1. Check Chrome logs
docker logs browserless --tail 100 | grep -i "chrome"

# 2. Add more memory
# See "Out of memory errors" above

# 3. Disable GPU acceleration
# In .env, add:
BROWSERLESS_CHROME_ARGS=--disable-gpu,--no-sandbox,--disable-dev-shm-usage

# 4. Enable shared memory
# In docker-compose.yml:
volumes:
  - /dev/shm:/dev/shm

# 5. Reduce page complexity
# Use: { "waitUntil": "domcontentloaded" } instead of "networkidle0"
```

**Slow performance:**

```bash
# 1. Check CPU usage
docker stats browserless

# 2. Reduce concurrent sessions
BROWSERLESS_CONCURRENT=5

# 3. Enable headless mode (should be default)
# In Puppeteer options: "headless": true

# 4. Disable unnecessary features
BROWSERLESS_ENABLE_RECORDING=false
BROWSERLESS_DEBUGGER=false

# 5. Use lighter wait strategies
# "waitUntil": "domcontentloaded" instead of "networkidle2"
```

### Best Practices

**Resource Management:**
- Set `BROWSERLESS_CONCURRENT` based on server RAM (2GB RAM per session)
- Use timeouts to prevent hung sessions
- Monitor with `/pressure` endpoint
- Close browsers explicitly after use

**Performance:**
- Use `domcontentloaded` for fast pages
- Use `networkidle0` only when necessary
- Reuse browser contexts when possible
- Enable headless mode (faster)

**Reliability:**
- Implement retry logic in workflows
- Set reasonable timeouts (30-60s)
- Handle browser crashes gracefully
- Log session IDs for debugging

**Security:**
- Use `BROWSERLESS_TOKEN` for authentication
- Limit concurrent sessions to prevent abuse
- Don't execute untrusted JavaScript
- Run in isolated Docker network

**Debugging:**
- Enable `BROWSERLESS_DEBUGGER=true` for troubleshooting
- Use session recordings (`BROWSERLESS_ENABLE_RECORDING=true`)
- Check `/metrics` endpoint for diagnostics
- Save screenshots on errors

### Integration with AI CoreKit Services

**Browserless + Browser-use:**
- Browser-use connects via WebSocket: `ws://browserless:3000`
- Centralized browser management
- Resource sharing across automation tasks

**Browserless + Skyvern:**
- Skyvern uses Browserless for visual automation
- Handles CAPTCHA and dynamic content
- Computer vision over shared browser

**Browserless + n8n Puppeteer:**
- Native Puppeteer node integration
- Visual workflow building
- Easy debugging with node UI

**Browserless + Gotenberg:**
- Browserless: Interactive screenshots, scraping
- Gotenberg: Static document conversion
- Use both for complete document workflow

### Monitoring & Metrics

**Health Check:**
```bash
curl http://localhost:3000/json/version
```

**Pressure/Load:**
```bash
curl http://localhost:3000/pressure
# Returns: {"running": 3, "queued": 0, "maxConcurrent": 10}
```

**Metrics (Prometheus format):**
```bash
curl http://localhost:3000/metrics
```

**Active Sessions:**
```bash
curl http://localhost:3000/json/list
# Lists all active browser sessions
```

### Resources

- **Official Website:** https://www.browserless.io/
- **Documentation:** https://docs.browserless.io/
- **GitHub:** https://github.com/browserless/chrome
- **API Reference:** https://docs.browserless.io/docs/api-reference
- **Docker Hub:** https://hub.docker.com/r/browserless/chrome
- **Community:** Discord (link on website)

### When to Use Browserless Directly vs Other Tools

**Use Browserless HTTP API for:**
- ✅ Simple screenshots
- ✅ PDF generation
- ✅ Quick content extraction
- ✅ Performance testing
- ✅ When you need REST interface

**Use Puppeteer Node (via Browserless) for:**
- ✅ Complex multi-step automation
- ✅ Custom JavaScript execution
- ✅ Form interactions
- ✅ When you need full browser control

**Use Browser-use (via Browserless) for:**
- ✅ Natural language automation
- ✅ Dynamic website scraping
- ✅ LLM-powered data extraction

**Use Skyvern (via Browserless) for:**
- ✅ Visual-based automation
- ✅ CAPTCHA solving
- ✅ Anti-bot navigation
- ✅ Self-healing workflows
