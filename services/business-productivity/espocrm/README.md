# 📞 EspoCRM - CRM Platform

### What is EspoCRM?

EspoCRM is a comprehensive, full-featured open-source CRM platform designed for businesses of all sizes. It provides advanced email campaign management, workflow automation, detailed reporting, and role-based access control. Unlike lightweight CRMs, EspoCRM offers enterprise-grade features including marketing automation, service management, and extensive customization options.

### Features

- **Complete CRM Suite** - Leads, contacts, accounts, opportunities, cases, documents
- **Email Marketing** - Campaign management, mass emails, tracking, templates
- **Workflow Automation** - Advanced BPM (Business Process Management) with visual designer
- **Advanced Reporting** - Custom reports, dashboards, charts, list views with filters
- **Role-Based Access** - Granular permissions, team hierarchies, field-level security
- **Email Integration** - IMAP/SMTP sync, group inboxes, email-to-case
- **Calendar & Activities** - Meetings, calls, tasks with scheduling and reminders
- **Custom Entities** - Create custom modules for any business process
- **REST API** - Comprehensive API for integrations and automation
- **Multi-Language** - 40+ languages supported out of the box
- **Portal** - Customer self-service portal for cases and knowledge base
- **Advanced Workflows** - Formulas, calculated fields, conditional logic

### Initial Setup

**First Login to EspoCRM:**

1. Navigate to `https://espocrm.yourdomain.com`
2. Login with admin credentials from installation report:
   - **Username:** Check `.env` file for `ESPOCRM_ADMIN_USERNAME` (default: `admin`)
   - **Password:** Check `.env` file for `ESPOCRM_ADMIN_PASSWORD`
3. Complete initial configuration:
   - Administration → System → Settings
   - Configure company information
   - Set timezone and date/time format
   - Configure currency and language
4. Set up email integration:
   - Administration → Outbound Emails
   - Configure Mailpit (pre-configured) or Docker-Mailserver
5. Generate API key:
   - Administration → API Users
   - Create new API user
   - Generate API key for n8n integration
   - Save key securely

**Important:** For production use, change the default admin password immediately!

### n8n Integration Setup

**Create EspoCRM Credentials in n8n:**

EspoCRM does not have a native n8n node. Use HTTP Request nodes with API Key authentication.

1. In n8n, create credentials:
   - Type: Header Auth
   - Name: EspoCRM API
   - Header Name: `X-Api-Key`
   - Header Value: Your generated API key from EspoCRM

**Internal URL for n8n:** `http://espocrm:80`

**API Base URL:** `http://espocrm:80/api/v1`

**Common Endpoints:**
- `/Lead` - Lead management
- `/Contact` - Contact records
- `/Account` - Account/Company records
- `/Opportunity` - Sales opportunities
- `/Case` - Support cases
- `/Task` - Tasks and todos
- `/Meeting` - Meetings and calls
- `/Campaign` - Email campaigns

### Example Workflows

#### Example 1: AI-Powered Email Campaign Automation

Automate lead research and email campaign enrollment:

```javascript
// Research new leads and add to nurture campaign

// 1. Schedule Trigger - Daily at 10 AM

// 2. HTTP Request Node - Get new leads from last 24 hours
Method: GET
URL: http://espocrm:80/api/v1/Lead
Authentication: Use EspoCRM Credentials
Query Parameters:
  where[0][type]: after
  where[0][attribute]: createdAt
  where[0][value]: {{$now.minus(1, 'day').toISO()}}
  select: id,name,emailAddress,companyName,website,status

// 3. Loop Over Items - Process each lead

// 4. Perplexica Node - Research lead company
Method: POST
URL: http://perplexica:3000/api/search
Body (JSON):
{
  "query": "{{$json.companyName}} company latest news revenue funding",
  "focusMode": "webSearch"
}

// 5. OpenAI Node - Score and analyze lead
Operation: Message a Model
Model: gpt-4o-mini
Messages:
  System: "You are a lead qualification expert. Analyze company research and provide a quality score (0-100)."
  User: |
    Company: {{$json.companyName}}
    Website: {{$json.website}}
    Research: {{$('Perplexica').json.answer}}
    
    Provide JSON response:
    {
      "score": <0-100>,
      "reasoning": "<analysis>",
      "industry": "<detected industry>",
      "company_size": "<estimated size>",
      "priority": "<High/Medium/Low>"
    }

// 6. Code Node - Parse AI response
const aiResult = JSON.parse($input.first().json.message.content);
return {
  json: {
    leadId: $('Loop Over Items').item.json.id,
    score: aiResult.score,
    reasoning: aiResult.reasoning,
    industry: aiResult.industry,
    companySize: aiResult.company_size,
    priority: aiResult.priority
  }
};

// 7. HTTP Request Node - Update lead with AI insights
Method: PUT
URL: http://espocrm:80/api/v1/Lead/{{$json.leadId}}
Body (JSON):
{
  "description": "{{$json.reasoning}}",
  "leadScore": {{$json.score}},
  "industry": "{{$json.industry}}",
  "status": "{{$json.score >= 70 ? 'Qualified' : 'New'}}"
}

// 8. IF Node - Check if qualified (score >= 70)

// Branch: Qualified Leads
// 9a. HTTP Request - Add to nurture email campaign
Method: POST
URL: http://espocrm:80/api/v1/CampaignLogRecord
Body (JSON):
{
  "campaignId": "your-nurture-campaign-id",
  "targetId": "{{$json.leadId}}",
  "targetType": "Lead",
  "action": "Sent"
}

// 10a. HTTP Request - Create follow-up task for sales rep
Method: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Follow up with {{$('Loop Over Items').item.json.name}}",
  "status": "Not Started",
  "priority": "{{$json.priority}}",
  "parentType": "Lead",
  "parentId": "{{$json.leadId}}",
  "dateEnd": "{{$now.plus(2, 'days').toISO()}}"
}

// 11a. Slack Node - Notify sales team
Channel: #sales-qualified-leads
Message: |
  🎯 **Qualified Lead Alert**
  
  Company: {{$('Loop Over Items').item.json.companyName}}
  Score: {{$json.score}}/100
  Priority: {{$json.priority}}
  
  AI Analysis: {{$json.reasoning}}
  
  👉 Follow up within 48 hours

// Branch: Lower Priority Leads
// 9b. HTTP Request - Add to general nurture campaign
// 10b. Set follow-up reminder for 7 days
```

#### Example 2: Service Request Automation with SLA Management

Manage support cases with automatic SLA tracking:

```javascript
// Automated case management with SLA calculations

// 1. Webhook Trigger - New service request created
// Configure webhook in EspoCRM: Administration → Webhooks

// 2. HTTP Request Node - Get related account details
Method: GET
URL: http://espocrm:80/api/v1/Account/{{$json.accountId}}
Authentication: Use EspoCRM Credentials
Query Parameters:
  select: name,website,industry,assignedUserId

// 3. HTTP Request Node - Check service contract/SLA
Method: GET
URL: http://espocrm:80/api/v1/ServiceContract
Query Parameters:
  where[0][type]: equals
  where[0][attribute]: accountId
  where[0][value]: {{$json.accountId}}
  select: id,name,type,slaHours

// 4. Code Node - Calculate priority and SLA deadline
const account = $('Get Account').item.json;
const contract = $('Check SLA').item.json.list?.[0];

// Determine priority based on contract type
const priority = contract?.type === 'Premium' ? 'High' : 
                 contract?.type === 'Standard' ? 'Normal' : 'Low';

// Calculate SLA hours
const slaHours = {
  'Premium': 4,
  'Standard': 24,
  'Basic': 48
}[contract?.type] || 72;

// Calculate due date
const dueDate = new Date();
dueDate.setHours(dueDate.getHours() + slaHours);

return {
  json: {
    caseId: $('Webhook').item.json.id,
    priority,
    slaHours,
    dueDate: dueDate.toISOString(),
    assignedUserId: account.assignedUserId,
    accountName: account.name,
    contractType: contract?.type || 'None'
  }
};

// 5. HTTP Request Node - Update case with SLA info
Method: PUT
URL: http://espocrm:80/api/v1/Case/{{$json.caseId}}
Body (JSON):
{
  "priority": "{{$json.priority}}",
  "status": "Assigned",
  "assignedUserId": "{{$json.assignedUserId}}",
  "dateEnd": "{{$json.dueDate}}"
}

// 6. HTTP Request Node - Create task for assigned user
Method: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Service Request: {{$('Webhook').item.json.subject}}",
  "description": "SLA: {{$json.slaHours}} hours | Due: {{$json.dueDate}}",
  "status": "Not Started",
  "priority": "{{$json.priority}}",
  "dateEnd": "{{$json.dueDate}}",
  "assignedUserId": "{{$json.assignedUserId}}",
  "parentType": "Case",
  "parentId": "{{$json.caseId}}"
}

// 7. Email Node - Send confirmation to customer
To: {{$('Webhook').item.json.contactEmail}}
Subject: Case #{{$json.caseId}} - {{$('Webhook').item.json.subject}}
Body: |
  Dear Customer,
  
  Your service request has been received and assigned.
  
  Case ID: #{{$json.caseId}}
  Priority: {{$json.priority}}
  Expected Response: Within {{$json.slaHours}} hours
  Assigned To: {{$json.assignedUserId}}
  
  We will update you as soon as we have more information.
  
  Best regards,
  Support Team

// 8. Slack Node - Notify support team
Channel: #support-cases
Message: |
  🆕 New Service Request
  
  Case: #{{$json.caseId}}
  Account: {{$json.accountName}}
  Priority: {{$json.priority}}
  SLA: {{$json.slaHours}}h
  Contract: {{$json.contractType}}
  Due: {{$json.dueDate}}
```

#### Example 3: Sales Pipeline Automation

Automate opportunity management with stage-based workflows:

```javascript
// Automated actions based on opportunity stage changes

// 1. EspoCRM Webhook - Opportunity stage changed
// Configure in EspoCRM: Administration → Webhooks → Create for Opportunity entity

// 2. Switch Node - Route based on new stage
Mode: Rules
Output Key: {{$json.stage}}

// Branch 1: "Proposal Sent"
// 3a. HTTP Request - Generate proposal document
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/create-pdf
Body (Multipart):
  template: proposal_template.html
  data: {{JSON.stringify($json)}}

// 4a. HTTP Request - Attach proposal to opportunity
Method: POST
URL: http://espocrm:80/api/v1/Attachment
Body (JSON):
{
  "name": "Proposal_{{$json.name}}_{{$now.format('YYYY-MM-DD')}}.pdf",
  "type": "application/pdf",
  "role": "Attachment",
  "relatedType": "Opportunity",
  "relatedId": "{{$json.id}}",
  "contents": "{{$('Generate PDF').json.base64}}"
}

// 5a. Invoice Ninja Node - Create draft invoice
Operation: Create Invoice
Customer: {{$json.accountName}}
Items: Parse from opportunity products
Status: Draft

// 6a. Email Node - Send proposal with tracking
To: {{$json.contactEmail}}
Subject: Proposal for {{$json.name}}
Attachments: Generated proposal PDF
Body: Professional proposal email template

// Branch 2: "Negotiation"
// 3b. Cal.com HTTP Request - Schedule negotiation meeting
Method: POST
URL: http://cal:3000/api/bookings
Body (JSON):
{
  "eventTypeId": 456, // Negotiation meeting event type
  "start": "{{$now.plus(3, 'days').toISO()}}",
  "responses": {
    "name": "{{$json.contactName}}",
    "email": "{{$json.contactEmail}}",
    "notes": "Negotiation meeting for opportunity: {{$json.name}}"
  }
}

// 4b. HTTP Request - Update opportunity probability
Method: PUT
URL: http://espocrm:80/api/v1/Opportunity/{{$json.id}}
Body (JSON):
{
  "probability": 60
}

// 5b. Slack Node - Alert sales manager
Channel: #sales-pipeline
Message: |
  💼 Opportunity in Negotiation
  
  Deal: {{$json.name}}
  Amount: ${{$json.amount}}
  Meeting scheduled: {{$('Schedule Meeting').json.start}}

// Branch 3: "Closed Won"
// 3c. HTTP Request - Convert opportunity to account (if new customer)
Method: POST
URL: http://espocrm:80/api/v1/Account
Body (JSON):
{
  "name": "{{$json.accountName}}",
  "website": "{{$json.website}}",
  "industry": "{{$json.industry}}",
  "type": "Customer"
}

// 4c. Twenty CRM HTTP Request - Sync to secondary CRM
Method: POST
URL: http://twenty-crm:3000/rest/companies
Body (JSON):
{
  "name": "{{$json.accountName}}",
  "domainName": "{{$json.website}}",
  "customFields": {
    "espocrmId": "{{$json.id}}",
    "dealValue": {{$json.amount}}
  }
}

// 5c. Kimai HTTP Request - Create project for time tracking
Method: POST
URL: http://kimai:8001/api/projects
Body (JSON):
{
  "name": "{{$json.accountName}} - Implementation",
  "customer": "{{$json.accountName}}",
  "visible": true,
  "budget": {{$json.amount}}
}

// 6c. Vikunja HTTP Request - Create onboarding tasks
Method: POST
URL: http://vikunja:3456/api/v1/projects
Body (JSON):
{
  "title": "Customer Onboarding: {{$json.accountName}}",
  "description": "Onboarding tasks for new customer"
}

// 7c. Email Node - Welcome email to customer
To: {{$json.contactEmail}}
Subject: Welcome to {{$env.COMPANY_NAME}}!
Body: Welcome email with next steps

// Branch 4: "Closed Lost"
// 3d. HTTP Request - Create follow-up task for 90 days
Method: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Follow up with {{$json.name}} - Lost Opportunity",
  "status": "Not Started",
  "dateEnd": "{{$now.plus(90, 'days').toISO()}}",
  "parentType": "Opportunity",
  "parentId": "{{$json.id}}"
}

// 4d. Formbricks HTTP Request - Send loss reason survey
Method: POST
URL: http://formbricks:3000/api/v1/client/displays
Body: Survey to understand why deal was lost

// 5d. Metabase HTTP Request - Update analytics dashboard
// Log lost deal for reporting
```

#### Example 4: Monthly Report Generation and Distribution

Automated executive reports with data from EspoCRM:

```javascript
// Generate comprehensive monthly CRM reports

// 1. Schedule Trigger - First Monday of each month at 9 AM

// 2. HTTP Request Node - Get monthly opportunity metrics
Method: GET
URL: http://espocrm:80/api/v1/Opportunity
Authentication: Use EspoCRM Credentials
Query Parameters:
  select: id,name,amount,stage,closeDate,probability,assignedUserId
  where[0][type]: currentMonth
  where[0][attribute]: closeDate

// 3. Code Node - Calculate KPIs
const opportunities = $input.first().json.list;

const kpis = {
  total_opportunities: opportunities.length,
  total_pipeline: opportunities.reduce((sum, opp) => sum + opp.amount, 0),
  weighted_forecast: opportunities.reduce((sum, opp) => 
    sum + (opp.amount * opp.probability / 100), 0),
  average_deal_size: opportunities.length > 0 ? 
    opportunities.reduce((sum, opp) => sum + opp.amount, 0) / opportunities.length : 0,
  won_deals: opportunities.filter(o => o.stage === 'Closed Won').length,
  lost_deals: opportunities.filter(o => o.stage === 'Closed Lost').length,
  conversion_rate: opportunities.length > 0 ?
    (opportunities.filter(o => o.stage === 'Closed Won').length / opportunities.length * 100).toFixed(2) : 0
};

// Group by stage
kpis.by_stage = {};
opportunities.forEach(opp => {
  if (!kpis.by_stage[opp.stage]) {
    kpis.by_stage[opp.stage] = { count: 0, value: 0 };
  }
  kpis.by_stage[opp.stage].count++;
  kpis.by_stage[opp.stage].value += opp.amount;
});

// Top performers
const performanceByUser = {};
opportunities.forEach(opp => {
  if (opp.stage === 'Closed Won') {
    if (!performanceByUser[opp.assignedUserId]) {
      performanceByUser[opp.assignedUserId] = { deals: 0, value: 0 };
    }
    performanceByUser[opp.assignedUserId].deals++;
    performanceByUser[opp.assignedUserId].value += opp.amount;
  }
});

kpis.top_performers = Object.entries(performanceByUser)
  .sort((a, b) => b[1].value - a[1].value)
  .slice(0, 5);

return { json: kpis };

// 4. HTTP Request Node - Get activity metrics
Method: GET
URL: http://espocrm:80/api/v1/Meeting
Query Parameters:
  where[0][type]: currentMonth
  where[0][attribute]: dateStart
  select: id,assignedUserId,status

// 5. Code Node - Activity analysis
const meetings = $input.first().json.list;
const kpis = $('Calculate KPIs').item.json;

kpis.total_meetings = meetings.length;
kpis.completed_meetings = meetings.filter(m => m.status === 'Held').length;

return { json: kpis };

// 6. Metabase HTTP Request - Update executive dashboard
Method: POST
URL: http://metabase:3000/api/card/{{$env.SALES_DASHBOARD_ID}}/query
Headers:
  X-Metabase-Session: {{$env.METABASE_SESSION}}
Body: Send calculated KPIs

// 7. Google Sheets Node - Export to spreadsheet
Operation: Append
Spreadsheet: Monthly CRM Reports
Sheet: {{$now.format('YYYY-MM')}}
Data: All calculated KPIs and metrics

// 8. HTTP Request - Generate PDF report
Method: POST
URL: http://stirling-pdf:8080/api/v1/convert/html-to-pdf
Body (Multipart):
  html: Formatted HTML report with all metrics and charts

// 9. Email Node - Send report to stakeholders
To: executives@company.com, sales-team@company.com
CC: finance@company.com
Subject: Monthly CRM Report - {{$now.format('MMMM YYYY')}}
Body: |
  📊 **Monthly CRM Performance Report**
  
  **Key Metrics:**
  • Total Opportunities: {{$json.total_opportunities}}
  • Pipeline Value: ${{$json.total_pipeline.toLocaleString()}}
  • Weighted Forecast: ${{$json.weighted_forecast.toLocaleString()}}
  • Average Deal Size: ${{$json.average_deal_size.toLocaleString()}}
  • Won Deals: {{$json.won_deals}}
  • Lost Deals: {{$json.lost_deals}}
  • Conversion Rate: {{$json.conversion_rate}}%
  
  **Activities:**
  • Total Meetings: {{$json.total_meetings}}
  • Completed: {{$json.completed_meetings}}
  
  **Pipeline by Stage:**
  {{#each $json.by_stage}}
  • {{@key}}: {{this.count}} deals (${{this.value.toLocaleString()}})
  {{/each}}
  
  **Top Performers:**
  {{#each $json.top_performers}}
  {{@index + 1}}. User {{this[0]}}: {{this[1].deals}} deals (${{this[1].value.toLocaleString()}})
  {{/each}}
  
  📎 Full report attached
  📊 View live dashboard: https://analytics.yourdomain.com

Attachments: 
  - Generated PDF report
  - Excel export from Google Sheets

// 10. Slack Node - Post summary to team channel
Channel: #sales-team
Message: |
  📊 **Monthly CRM Report Published**
  
  Key Highlights:
  • ${{$json.total_pipeline.toLocaleString()}} in pipeline
  • {{$json.conversion_rate}}% conversion rate
  • {{$json.won_deals}} deals closed
  
  📧 Full report sent to executives
  📊 Dashboard: https://analytics.yourdomain.com
```

### Troubleshooting

**Issue 1: API Authentication Fails**

```bash
# Check if EspoCRM is running
docker ps | grep espocrm

# View EspoCRM logs
docker logs espocrm

# Test API connection
curl -H "X-Api-Key: YOUR_API_KEY" \
  http://localhost:80/api/v1/Lead

# Verify API key in EspoCRM
# Administration → API Users → Check your API user
```

**Solution:**
- Regenerate API key in EspoCRM (Administration → API Users)
- Ensure API user has appropriate permissions
- Check that header name is exactly `X-Api-Key` (case-sensitive)
- Verify firewall rules allow internal Docker network access
- Check that EspoCRM is fully initialized (may take 2-3 minutes on first start)

**Issue 2: Webhook Not Triggering**

```bash
# Test webhook manually
curl -X POST https://your-n8n.com/webhook/espocrm \
  -H "Content-Type: application/json" \
  -d '{"id": "test123", "entityType": "Lead", "action": "create"}'

# Check n8n webhook logs
docker logs n8n | grep webhook

# Verify webhook configuration in EspoCRM
# Administration → Webhooks → Check URL and event types
```

**Solution:**
- Webhook URL must be accessible from EspoCRM container
- Use internal URL if both services on same Docker network: `http://n8n:5678/webhook/...`
- Enable webhook in EspoCRM: Administration → Webhooks
- Set correct entity type (Lead, Contact, Opportunity, etc.)
- Choose correct event (create, update, delete)
- Test webhook with "Test" button in EspoCRM

**Issue 3: Email Integration Not Working**

```bash
# Check email account configuration
docker exec espocrm cat data/.htaccess

# View email sync logs
docker logs espocrm | grep -i "email\|imap\|smtp"

# Test SMTP connection
docker exec espocrm php command.php app:test-email YOUR_EMAIL

# Check Mailpit is receiving emails
curl http://localhost:8025/api/v1/messages
```

**Solution:**
- Mailpit SMTP settings: Host=`mailpit`, Port=`1025`, no auth
- For Docker-Mailserver: Host=`mailserver`, Port=`587`, TLS enabled
- Check email account in Administration → Email Accounts
- Verify group inbox configuration
- Enable Personal Email Accounts in user settings
- Check spam folders if emails not arriving

**Issue 4: Performance Issues with Large Datasets**

```bash
# Check database size
docker exec espocrm-db mysql -u espocrm -p -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = 'espocrm' ORDER BY (data_length + index_length) DESC;"

# Optimize database tables
docker exec espocrm-db mysql -u espocrm -p espocrm -e "OPTIMIZE TABLE lead, contact, account, opportunity;"

# Check container resources
docker stats espocrm --no-stream

# Clear EspoCRM cache
docker exec espocrm rm -rf data/cache/*
docker compose restart espocrm
```

**Solution:**
- Add database indexes for frequently queried fields
- Use pagination in API requests (`offset` and `maxSize` parameters)
- Archive old records (Administration → Jobs → scheduled cleanup)
- Increase PHP memory limit in docker-compose.yml
- Use filters instead of fetching all records
- Enable query caching in Administration → System → Settings
- Consider database optimization (run OPTIMIZE TABLE monthly)

### Resources

- **Official Documentation:** https://docs.espocrm.com/
- **API Documentation:** https://docs.espocrm.com/development/api/
- **REST API Client:** https://docs.espocrm.com/development/api-client-php/
- **GitHub:** https://github.com/espocrm/espocrm
- **Community Forum:** https://forum.espocrm.com/
- **Extensions:** https://www.espocrm.com/extensions/
- **Workflow Guide:** https://docs.espocrm.com/administration/workflows/
- **Admin Guide:** https://docs.espocrm.com/administration/

### Best Practices

**When to Use EspoCRM:**
- Established businesses needing full CRM features
- Email marketing and campaign management requirements
- Complex workflow automation with BPM
- Advanced reporting and analytics needs
- Service/case management with SLA tracking
- Multi-user teams with role-based permissions
- Organizations requiring extensive customization

**When to Use Twenty CRM Instead:**
- Startups needing lightweight, modern interface
- Projects requiring GraphQL API
- Simple sales pipeline management
- Notion-style workspace organization
- Minimal resource usage priority

**Combining Multiple CRMs:**
```javascript
// Best practices for multi-CRM strategy

// Use EspoCRM for:
- Email campaigns and marketing automation
- Complex sales processes with multiple stages
- Service case management
- Detailed reporting and analytics
- Team collaboration with permissions

// Use Twenty CRM for:
- Daily operations and quick updates
- Modern, fast interface for field teams
- Custom field flexibility
- GraphQL-based integrations

// Sync data with n8n:
- Bi-directional contact sync
- Opportunity status updates
- Activity logging in both systems
- Unified reporting via Metabase
```

**API Best Practices:**
1. **Use Pagination:** Always use `offset` and `maxSize` for large datasets
2. **Field Selection:** Use `select` parameter to fetch only needed fields
3. **Filters:** Apply `where` conditions to reduce data transfer
4. **Batch Operations:** Process records in batches of 50-100
5. **Error Handling:** Implement retry logic for API failures
6. **Rate Limiting:** Respect API limits (usually 100 requests/minute)
7. **Webhooks:** Use webhooks instead of polling for real-time updates
8. **Caching:** Cache frequently accessed data (users, enums, settings)
9. **Authentication:** Use API keys, not passwords, for integrations
10. **Logging:** Log all API calls for debugging and audit trails
