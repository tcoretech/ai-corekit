### What is Twenty CRM?

Twenty CRM is a modern, open-source customer relationship management platform with a Notion-like interface. It offers a lightweight, flexible solution perfect for startups and small teams that need powerful GraphQL and REST APIs without the complexity of traditional CRM systems.

### Features

- **Notion-like Interface** - Intuitive, modern UI with customizable views and fields
- **Powerful APIs** - Both GraphQL and REST APIs for maximum flexibility
- **Customer Pipelines** - Visual pipeline management for sales and opportunities
- **Team Collaboration** - Real-time collaboration with shared workspaces
- **Custom Fields** - Flexible data model with custom field types
- **Lightweight & Fast** - Minimal resource usage compared to traditional CRMs
- **Open Source** - Self-hosted, privacy-focused, no vendor lock-in

### Initial Setup

**First Login to Twenty CRM:**

1. Navigate to `https://twenty.yourdomain.com`
2. Create your first workspace during initial setup
3. Configure workspace settings and customize fields
4. Generate API key:
   - Go to Settings → Developers → API Keys
   - Click "Create New API Key"
   - Name it "n8n Integration"
   - Copy the token for use in n8n
5. Set up your first pipeline and custom fields

### n8n Integration Setup

**Create Twenty CRM Credentials in n8n:**

Twenty CRM does not have a native n8n node. Use HTTP Request nodes with Bearer token authentication.

1. In n8n, create credentials:
   - Type: Header Auth
   - Name: Twenty CRM API
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_API_KEY_HERE`

**Internal URL for n8n:** `http://twenty-crm:3000`

**Base API Endpoints:**
- REST API: `http://twenty-crm:3000/rest/`
- GraphQL API: `http://twenty-crm:3000/graphql`

### Example Workflows

#### Example 1: AI Lead Qualification Pipeline

Automatically qualify and score leads using AI:

```javascript
// Automate lead scoring with AI analysis

// 1. Webhook Trigger - Receive new lead from website form

// 2. HTTP Request Node - Create lead in Twenty CRM
Method: POST
URL: http://twenty-crm:3000/rest/companies
Authentication: Use Twenty CRM Credentials
Headers:
  Content-Type: application/json
Body (JSON):
{
  "name": "{{$json.company_name}}",
  "domainName": "{{$json.website}}",
  "employees": "{{$json.company_size}}",
  "address": "{{$json.location}}"
}

// 3. OpenAI Node - Analyze lead quality
Operation: Message a Model
Model: gpt-4o-mini
Messages:
  System: "You are a lead qualification expert. Analyze leads and provide a score (1-10) with reasoning."
  User: |
    Analyze this lead:
    Company: {{$json.company_name}}
    Industry: {{$json.industry}}
    Size: {{$json.company_size}}
    Budget: {{$json.budget_range}}
    Website: {{$json.website}}
    
    Provide score and reasoning in JSON format:
    {
      "score": <number>,
      "reasoning": "<why this score>",
      "priority": "<High/Normal/Low>"
    }

// 4. Code Node - Parse AI response
const aiResponse = JSON.parse($input.first().json.message.content);
return {
  json: {
    companyId: $('Create Lead').item.json.id,
    score: aiResponse.score,
    reasoning: aiResponse.reasoning,
    priority: aiResponse.priority
  }
};

// 5. HTTP Request Node - Update lead with AI score
Method: PATCH
URL: http://twenty-crm:3000/rest/companies/{{$json.companyId}}
Body (JSON):
{
  "customFields": {
    "leadScore": {{$json.score}},
    "aiAnalysis": "{{$json.reasoning}}",
    "priority": "{{$json.priority}}"
  }
}

// 6. IF Node - Check if high-value lead
Condition: {{$json.score}} >= 8

// Branch: High-value leads
// 7a. Slack Node - Notify sales team
Channel: #sales-alerts
Message: |
  🔥 **High-Value Lead Alert!**
  
  Company: {{$('Create Lead').json.name}}
  Score: {{$json.score}}/10
  Priority: {{$json.priority}}
  
  AI Analysis: {{$json.reasoning}}
  
  👉 Action required: Contact within 24 hours

// 8a. Email Node - Send personalized email to sales rep
To: sales@company.com
Subject: High-Priority Lead: {{$('Create Lead').json.name}}
Body: Detailed lead information with AI insights

// Branch: Normal leads
// 7b. HTTP Request - Add to nurture campaign
// 8b. Email - Send automated welcome sequence
```

#### Example 2: Customer Onboarding Automation

Streamline customer onboarding with automated tasks:

```javascript
// Complete onboarding automation workflow

// 1. Twenty CRM Webhook - On opportunity won
// Configure webhook in Twenty CRM to trigger when opportunity stage = "Won"

// 2. HTTP Request Node - Get customer details
Method: GET
URL: http://twenty-crm:3000/rest/companies/{{$json.companyId}}
Authentication: Use Twenty CRM Credentials

// 3. Invoice Ninja Node - Create customer account
Operation: Create Customer
Name: {{$json.name}}
Email: {{$json.email}}
Address: {{$json.address}}
Currency: USD

// 4. Cal.com HTTP Request - Schedule onboarding call
Method: POST
URL: http://cal:3000/api/bookings
Body (JSON):
{
  "eventTypeId": 123, // Your onboarding call event type ID
  "start": "{{$now.plus(2, 'days').toISO()}}",
  "responses": {
    "name": "{{$json.name}}",
    "email": "{{$json.email}}",
    "notes": "Customer onboarding call - Opportunity won"
  }
}

// 5. HTTP Request Node - Update Twenty CRM pipeline stage
Method: PATCH
URL: http://twenty-crm:3000/rest/opportunities/{{$json.opportunityId}}
Body (JSON):
{
  "stage": "Onboarding",
  "customFields": {
    "onboardingStarted": "{{$now.toISO()}}",
    "invoiceCreated": true,
    "meetingScheduled": "{{$json.booking_time}}"
  }
}

// 6. Vikunja Node - Create onboarding tasks
Operation: Create Task
Project: Customer Onboarding
Title: "Onboarding: {{$json.name}}"
Description: |
  - Send welcome email
  - Provide access credentials
  - Schedule training session
  - Assign account manager
Due Date: {{$now.plus(7, 'days').toISO()}}

// 7. Email Node - Send welcome package
To: {{$json.email}}
Subject: Welcome to {{$env.COMPANY_NAME}}! 🎉
Body: |
  Hi {{$json.name}},
  
  Welcome aboard! We're excited to have you as a customer.
  
  Your onboarding call is scheduled for {{$json.booking_time}}.
  
  In the meantime, here's what you can expect:
  ✅ Account setup (completed)
  ✅ Welcome package (attached)
  📅 Onboarding call scheduled
  📚 Training materials (coming soon)
  
  Your dedicated account manager will reach out shortly.
  
  Best regards,
  The Team

Attachments: Welcome package PDF, Getting started guide

// 8. Slack Notification - Internal team
Channel: #customer-success
Message: |
  🎉 New customer onboarded!
  
  Company: {{$json.name}}
  Email: {{$json.email}}
  Onboarding call: {{$json.booking_time}}
  
  ✅ Invoice created
  ✅ Welcome email sent
  ✅ Tasks created in Vikunja
```

#### Example 3: GraphQL Advanced Queries

Leverage Twenty's powerful GraphQL API for complex operations:

```javascript
// Weekly sales pipeline report with metrics

// 1. Schedule Trigger - Weekly on Monday at 9 AM

// 2. HTTP Request Node - GraphQL query for pipeline metrics
Method: POST
URL: http://twenty-crm:3000/graphql
Authentication: Use Twenty CRM Credentials
Headers:
  Content-Type: application/json
Body (JSON):
{
  "query": "query GetPipelineMetrics { opportunities(where: { createdAt: { gte: \"{{$now.minus(7, 'days').toISO()}}\" } }) { edges { node { id name amount stage probability company { name domainName } } } } }"
}

// 3. Code Node - Calculate metrics
const opportunities = $input.first().json.data.opportunities.edges;

// Calculate key metrics
const metrics = {
  total_opportunities: opportunities.length,
  total_value: opportunities.reduce((sum, opp) => sum + opp.node.amount, 0),
  weighted_pipeline: opportunities.reduce((sum, opp) => 
    sum + (opp.node.amount * opp.node.probability / 100), 0),
  by_stage: {},
  top_deals: []
};

// Group by stage
opportunities.forEach(opp => {
  const stage = opp.node.stage;
  if (!metrics.by_stage[stage]) {
    metrics.by_stage[stage] = { count: 0, value: 0 };
  }
  metrics.by_stage[stage].count++;
  metrics.by_stage[stage].value += opp.node.amount;
});

// Get top 5 deals
metrics.top_deals = opportunities
  .map(opp => opp.node)
  .sort((a, b) => b.amount - a.amount)
  .slice(0, 5);

return { json: metrics };

// 4. Metabase HTTP Request - Update dashboard
Method: POST
URL: http://metabase:3000/api/card/{{$env.SALES_DASHBOARD_ID}}/query
Body: Send calculated metrics

// 5. Google Sheets Node - Export to spreadsheet
Operation: Append
Spreadsheet: Weekly Sales Reports
Sheet: {{$now.format('YYYY-MM')}}
Data: Pipeline metrics

// 6. Email Node - Send report to stakeholders
To: executives@company.com, sales-team@company.com
Subject: Weekly Sales Pipeline Report - {{$now.format('MMMM D, YYYY')}}
Body: |
  📊 Weekly Sales Pipeline Report
  
  **Key Metrics (Last 7 Days):**
  • Total Opportunities: {{$json.total_opportunities}}
  • Total Pipeline Value: ${{$json.total_value.toLocaleString()}}
  • Weighted Forecast: ${{$json.weighted_pipeline.toLocaleString()}}
  
  **By Stage:**
  {{#each $json.by_stage}}
  • {{@key}}: {{this.count}} deals (${{this.value.toLocaleString()}})
  {{/each}}
  
  **Top 5 Deals:**
  {{#each $json.top_deals}}
  {{@index + 1}}. {{this.company.name}} - ${{this.amount.toLocaleString()}} ({{this.probability}}%)
  {{/each}}
  
  View full dashboard: https://analytics.yourdomain.com

Attachments: Generated PDF report
```

#### Example 4: Cross-CRM Data Sync

Sync Twenty CRM with other CRM systems for unified data:

```javascript
// Sync contacts between Twenty CRM and EspoCRM

// 1. Schedule Trigger - Every 15 minutes

// 2. HTTP Request - Get recently updated contacts from Twenty
Method: POST
URL: http://twenty-crm:3000/graphql
Body (JSON):
{
  "query": "query GetRecentContacts { people(where: { updatedAt: { gte: \"{{$now.minus(15, 'minutes').toISO()}}\" } }) { edges { node { id firstName lastName email phone company { id name } customFields } } } }"
}

// 3. Loop Over Items - Process each contact

// 4. HTTP Request - Check if contact exists in EspoCRM
Method: GET
URL: http://espocrm:80/api/v1/Contact
Query Parameters:
  where: [{"type":"equals","attribute":"emailAddress","value":"{{$json.email}}"}]

// 5. IF Node - Contact exists?

// Branch: Yes - Update existing
// 6a. HTTP Request - Update in EspoCRM
Method: PUT
URL: http://espocrm:80/api/v1/Contact/{{$json.espocrm_id}}
Body: Updated contact data

// Branch: No - Create new
// 6b. HTTP Request - Create in EspoCRM
Method: POST
URL: http://espocrm:80/api/v1/Contact
Body: New contact data

// 7. HTTP Request - Update Twenty with sync status
Method: PATCH
URL: http://twenty-crm:3000/rest/people/{{$json.twenty_id}}
Body:
{
  "customFields": {
    "lastSyncedAt": "{{$now.toISO()}}",
    "syncStatus": "success",
    "espocrmId": "{{$json.espocrm_id}}"
  }
}
```

### Troubleshooting

**Issue 1: API Authentication Fails**

```bash
# Check if Twenty CRM is running
docker ps | grep twenty

# View Twenty CRM logs
docker logs twenty-crm

# Verify API key in Twenty CRM settings
# Go to Settings → Developers → API Keys

# Test API connection
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/rest/companies
```

**Solution:**
- Regenerate API key in Twenty CRM settings
- Ensure Bearer token format: `Bearer YOUR_KEY`
- Check firewall rules allow internal Docker network access
- Verify `TWENTY_API_KEY` in n8n credentials

**Issue 2: GraphQL Query Errors**

```bash
# Test GraphQL endpoint
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ opportunities { edges { node { id name } } } }"}'

# Check GraphQL schema
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

**Solution:**
- Validate GraphQL syntax in GraphQL Playground
- Check field names match Twenty CRM schema
- Use introspection query to explore available fields
- Ensure proper escaping of quotes in n8n JSON

**Issue 3: Webhook Not Triggering**

```bash
# Check webhook configuration in Twenty CRM
# Settings → Integrations → Webhooks

# Test webhook manually
curl -X POST https://your-n8n.com/webhook/twenty-crm \
  -H "Content-Type: application/json" \
  -d '{"companyId": "test123", "event": "opportunity.won"}'

# Check n8n webhook logs
docker logs n8n | grep webhook
```

**Solution:**
- Verify webhook URL is accessible from Twenty CRM container
- Use internal URL if both services are on same Docker network
- Check webhook secret/authentication if configured
- Enable webhook logging in Twenty CRM for debugging

**Issue 4: Custom Fields Not Syncing**

**Diagnosis:**
```bash
# Get field schema from Twenty
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"query": "{ __type(name: \"Company\") { fields { name type { name } } } }"}'
```

**Solution:**
- Custom fields must be created in Twenty CRM first
- Use exact field names from Twenty CRM schema
- Field types must match (string, number, date, etc.)
- Check permissions for API key to modify custom fields

### Resources

- **Official Documentation:** https://twenty.com/developers
- **GraphQL API Docs:** https://twenty.com/developers/graphql-api
- **REST API Docs:** https://twenty.com/developers/rest-api
- **GitHub:** https://github.com/twentyhq/twenty
- **Community Forum:** https://twenty.com/community
- **API Playground:** `https://twenty.yourdomain.com/graphql` (when logged in)

### Best Practices

**When to Use Twenty CRM:**
- Startups and small teams needing flexibility
- Projects requiring custom fields and views
- GraphQL API integration requirements
- Notion-style workspace organization
- Lightweight resource usage is priority

**Combining with Other CRMs:**
- Use Twenty for daily operations and team collaboration
- Use EspoCRM or Odoo for email campaigns and complex automation
- Sync data between systems using n8n for unified view
- Create unified dashboards in Metabase pulling from both systems

**Data Model Tips:**
- Start with basic fields, add custom fields as needed
- Use relationships to connect companies, people, and opportunities
- Create custom views for different team members
- Use tags for flexible categorization
- Regular backups via API exports
