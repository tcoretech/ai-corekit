# 🏢 Odoo 18 - ERP/CRM

### What is Odoo 18?

Odoo 18 is a comprehensive open-source ERP (Enterprise Resource Planning) and CRM system that brings together all business functions into one unified platform. Released in 2024, Odoo 18 introduces built-in AI features for lead scoring, content generation, and sales forecasting. It's a complete business management suite covering sales, CRM, inventory, accounting, HR, projects, and more - all with native n8n integration for powerful automation workflows.

### Features

- **AI-Powered Lead Scoring:** Automatically scores leads based on interaction history and data patterns
- **AI Content Generation:** Generate emails, product descriptions, and sales quotes with AI
- **Complete CRM:** Lead management, opportunities, pipeline visualization, activity tracking
- **Sales Automation:** Quotations, orders, invoicing, payment tracking
- **Inventory Management:** Stock control, warehouse management, product variants
- **Accounting:** Invoicing, expenses, bank reconciliation, financial reports
- **HR Management:** Employee records, time off, recruitment, appraisals
- **Project Management:** Tasks, time tracking, Gantt charts, resource planning
- **Manufacturing:** Bill of materials, work orders, quality control
- **E-commerce:** Online store, product catalog, payment integration
- **Marketing:** Email campaigns, events, surveys, social media
- **Multi-Company:** Manage multiple companies from one instance
- **Customizable:** 30,000+ apps in the app store, custom modules support

### Initial Setup

**First Login to Odoo:**

1. Navigate to `https://odoo.yourdomain.com`
2. Create your database:
   - Database name: `odoo` (or your company name)
   - Master password: Check `.env` file for `ODOO_MASTER_PASSWORD`
   - Email: Your admin email address
   - Password: Choose a strong admin password
   - Language: Select your preferred language
   - Country: Select your country for localization
3. Complete the initial configuration wizard:
   - Select apps to install (CRM, Sales, Inventory, Accounting, etc.)
   - Configure company details
   - Set up users and permissions
4. Access Settings → Technical → API Keys to generate API credentials

**Important:** Save your admin credentials and master password securely!

### n8n Integration Setup

**Native Odoo Node in n8n:**

n8n provides a native Odoo node for seamless integration!

**Create Odoo Credentials in n8n:**

1. In n8n, go to Credentials → New → Odoo API
2. Configure:
   - **URL:** `http://odoo:8069` (internal) or `https://odoo.yourdomain.com` (external)
   - **Database:** `odoo` (your database name from setup)
   - **Username:** Your admin email
   - **API Key or Password:** Generate API key in Odoo Settings → Technical → API Keys

**Internal URL for n8n:** `http://odoo:8069`

**Tip:** Use API keys instead of passwords for better security and to avoid session timeouts.

### Example Workflows

#### Example 1: AI-Enhanced Lead Management

Automate lead qualification with AI scoring and company research:

```javascript
// Automatically qualify new leads with AI and enrich with company data

// 1. Schedule Trigger - Every hour
// Or: Webhook from website form submission

// 2. Odoo Node - Get New Leads
Operation: Get All
Resource: Lead/Opportunity
Filters:
  stage_id: 1  // New leads stage
  probability: 0  // Not yet scored
Limit: 50

// 3. Loop Over Items

// 4. Perplexica Node - Research Company
Method: POST
URL: http://perplexica:3000/api/search
Body (JSON):
{
  "query": "{{$json.partner_name}} company information revenue employees",
  "focusMode": "webSearch"
}

// 5. Code Node - Parse research and prepare for AI scoring
const lead = $input.first().json;
const research = $input.all()[1].json;

// Extract key information
const companyInfo = {
  name: lead.partner_name,
  industry: lead.industry_id?.name || 'Unknown',
  country: lead.country_id?.name || 'Unknown',
  employees: research.employees || 'Unknown',
  revenue: research.revenue || 'Unknown',
  recentNews: research.summary || '',
  website: lead.website || '',
  contactName: lead.contact_name || '',
  email: lead.email_from || '',
  phone: lead.phone || ''
};

return [{
  json: {
    leadId: lead.id,
    companyInfo: companyInfo,
    scoringPrompt: `Analyze this B2B lead and score from 0-100:
      
Company: ${companyInfo.name}
Industry: ${companyInfo.industry}
Size: ${companyInfo.employees} employees
Revenue: ${companyInfo.revenue}
Location: ${companyInfo.country}
Recent News: ${companyInfo.recentNews}

Contact Info:
- Name: ${companyInfo.contactName}
- Email: ${companyInfo.email}
- Phone: ${companyInfo.phone}

Consider:
1. Company size and revenue potential
2. Industry fit for our products
3. Growth indicators from recent news
4. Contact quality (decision-maker level)
5. Geographic fit

Respond with JSON: {"score": 0-100, "reasoning": "explanation", "priority": "low/medium/high"}`
  }
}];

// 6. OpenAI Node - AI Lead Scoring
Model: gpt-4o-mini
Prompt: {{$json.scoringPrompt}}
Response Format: JSON

// 7. Code Node - Parse AI response
const aiResponse = JSON.parse($json.choices[0].message.content);
const previousData = $input.all()[0].json;

return [{
  json: {
    leadId: previousData.leadId,
    score: aiResponse.score,
    reasoning: aiResponse.reasoning,
    priority: aiResponse.priority,
    companyInfo: previousData.companyInfo
  }
}];

// 8. Odoo Node - Update Lead with AI Score
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  probability: {{$json.score}}
  priority: {{$json.priority === 'high' ? '3' : $json.priority === 'medium' ? '2' : '1'}}
  description: |
    AI Lead Score: {{$json.score}}/100
    Priority: {{$json.priority}}
    
    AI Analysis:
    {{$json.reasoning}}
    
    Company Research:
    Employees: {{$json.companyInfo.employees}}
    Revenue: {{$json.companyInfo.revenue}}
    Industry: {{$json.companyInfo.industry}}
    Recent News: {{$json.companyInfo.recentNews}}

// 9. IF Node - Check if high-priority lead
Condition: {{$json.priority}} === 'high' AND {{$json.score}} >= 70

// IF TRUE - High Priority Actions:

// 10a. Odoo Node - Assign to Sales Manager
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  user_id: 2  // Sales Manager user ID

// 10b. Odoo Node - Create Activity (Follow-up call)
Operation: Create
Resource: Mail Activity
Fields:
  res_model: crm.lead
  res_id: {{$json.leadId}}
  activity_type_id: 2  // Call activity type
  summary: "🔥 HOT LEAD - Priority Follow-up"
  note: |
    AI Score: {{$json.score}}/100
    Reasoning: {{$json.reasoning}}
    
    Action: Call within 24 hours
  date_deadline: {{$now.plus({days: 1}).toISO()}}
  user_id: 2  // Assign to sales manager

// 10c. Slack Notification - Alert sales team
Channel: #sales
Message: |
  🔥 **HOT LEAD ALERT** 🔥
  
  Company: {{$json.companyInfo.name}}
  AI Score: {{$json.score}}/100
  Priority: {{$json.priority}}
  
  {{$json.reasoning}}
  
  Contact: {{$json.companyInfo.contactName}}
  Email: {{$json.companyInfo.email}}
  
  [View in Odoo](https://odoo.yourdomain.com/web#id={{$json.leadId}}&model=crm.lead&view_type=form)

// 10d. Send Email - To assigned salesperson
To: sales-manager@yourdomain.com
Subject: 🔥 New Hot Lead: {{$json.companyInfo.name}}
Body: |
  A new high-priority lead has been assigned to you:
  
  Company: {{$json.companyInfo.name}}
  AI Lead Score: {{$json.score}}/100
  
  AI Analysis:
  {{$json.reasoning}}
  
  Company Details:
  - Industry: {{$json.companyInfo.industry}}
  - Size: {{$json.companyInfo.employees}} employees
  - Location: {{$json.companyInfo.country}}
  
  Contact:
  - Name: {{$json.companyInfo.contactName}}
  - Email: {{$json.companyInfo.email}}
  - Phone: {{$json.companyInfo.phone}}
  
  Next Steps:
  - Review the lead in Odoo
  - Call within 24 hours
  - Prepare personalized pitch
  
  [Open in Odoo](https://odoo.yourdomain.com/web#id={{$json.leadId}}&model=crm.lead&view_type=form)

// IF FALSE - Normal Priority:

// 11. Odoo Node - Add to nurture campaign
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  stage_id: 2  // Qualified stage
  tag_ids: [[6, 0, [1]]]  // Add "Nurture Campaign" tag
```

#### Example 2: Automated Invoice Processing from Email

Process vendor bills automatically from email attachments:

```javascript
// Extract invoice data from PDFs and create vendor bills in Odoo

// 1. IMAP Email Trigger - Monitor inbox for invoices
Mailbox: INBOX
Search Criteria:
  Subject contains: "invoice" OR "bill"
  Has attachments: true
  Unseen: true

// 2. Loop Over Attachments

// 3. IF Node - Check if PDF
Condition: {{$json.filename}} ends with ".pdf"

// 4. HTTP Request Node - OCR Service (Tesseract)
Method: POST
URL: http://tesseract:8000/ocr
Body:
  Binary Data: {{$binary.data}}
  Language: eng
Options:
  Response Type: JSON

// 5. Code Node - Parse Invoice Data
const ocrText = $json.text;

// Extract invoice details using regex patterns
const invoiceNumber = ocrText.match(/Invoice\s*#?\s*:?\s*(\w+-?\d+)/i)?.[1] || '';
const invoiceDate = ocrText.match(/Date\s*:?\s*([\d\/\-\.]+)/i)?.[1] || '';
const vendorName = ocrText.match(/From\s*:?\s*(.+?)\n/i)?.[1] || 
                   ocrText.match(/Vendor\s*:?\s*(.+?)\n/i)?.[1] || '';

// Extract total amount (look for various patterns)
const totalPatterns = [
  /Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Amount\s*Due\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Grand\s*Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i
];

let totalAmount = 0;
for (const pattern of totalPatterns) {
  const match = ocrText.match(pattern);
  if (match) {
    totalAmount = parseFloat(match[1].replace(',', ''));
    break;
  }
}

// Extract line items
const lineItems = [];
const itemRegex = /(.+?)\s+(\d+)\s+\$?([\d,]+\.?\d*)\s+\$?([\d,]+\.?\d*)/g;
let itemMatch;

while ((itemMatch = itemRegex.exec(ocrText)) !== null) {
  lineItems.push({
    description: itemMatch[1].trim(),
    quantity: parseInt(itemMatch[2]),
    unit_price: parseFloat(itemMatch[3].replace(',', '')),
    total: parseFloat(itemMatch[4].replace(',', ''))
  });
}

return [{
  json: {
    vendor: vendorName.trim(),
    invoice_number: invoiceNumber,
    invoice_date: invoiceDate,
    total_amount: totalAmount,
    line_items: lineItems,
    raw_text: ocrText,
    original_filename: $input.first().json.filename
  }
}];

// 6. Odoo Node - Search for Vendor
Operation: Get All
Resource: Contact
Filters:
  name: {{$json.vendor}}
  supplier_rank: [">", 0]  // Is a supplier
Limit: 1

// 7. IF Node - Vendor exists?
Condition: {{$json.id}} is not empty

// IF YES - Vendor found:

// 8a. Odoo Node - Create Vendor Bill
Operation: Create
Resource: Vendor Bill
Fields:
  partner_id: {{$('Search Vendor').json.id}}
  ref: {{$('Parse Invoice').json.invoice_number}}
  invoice_date: {{$('Parse Invoice').json.invoice_date}}
  move_type: in_invoice
  state: draft

// 8b. Loop Over Line Items

// 8c. Odoo Node - Add Invoice Line
Operation: Create
Resource: Account Move Line
Fields:
  move_id: {{$('Create Vendor Bill').json.id}}
  name: {{$json.description}}
  quantity: {{$json.quantity}}
  price_unit: {{$json.unit_price}}
  account_id: 15  // Default expense account

// 8d. Odoo Node - Attach original PDF
Operation: Create
Resource: Attachment
Fields:
  name: {{$('Parse Invoice').json.original_filename}}
  datas: {{$binary.data}}
  res_model: account.move
  res_id: {{$('Create Vendor Bill').json.id}}

// 8e. Slack Notification - Success
Channel: #accounting
Message: |
  ✅ **Invoice Processed Successfully**
  
  Vendor: {{$('Parse Invoice').json.vendor}}
  Invoice #: {{$('Parse Invoice').json.invoice_number}}
  Amount: ${{$('Parse Invoice').json.total_amount}}
  
  Bill created in Odoo (Draft status)
  [Review Bill](https://odoo.yourdomain.com/web#id={{$('Create Vendor Bill').json.id}}&model=account.move&view_type=form)

// IF NO - Vendor not found:

// 9. Odoo Node - Create Support Ticket (Vikunja/Leantime)
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "New Vendor Setup Required: {{$('Parse Invoice').json.vendor}}",
  "description": |
    Invoice received from unknown vendor.
    
    Vendor: {{$('Parse Invoice').json.vendor}}
    Invoice #: {{$('Parse Invoice').json.invoice_number}}
    Amount: ${{$('Parse Invoice').json.total_amount}}
    
    Please:
    1. Create vendor in Odoo
    2. Create vendor bill manually
    3. Attach invoice PDF
  "priority": 2,
  "project_id": 1,
  "labels": ["accounting", "new-vendor"]
}

// 10. Send Email - Alert accounting team
To: accounting@yourdomain.com
Subject: Action Required: New Vendor Invoice
Body: |
  An invoice was received from an unknown vendor:
  
  Vendor: {{$('Parse Invoice').json.vendor}}
  Invoice #: {{$('Parse Invoice').json.invoice_number}}
  Date: {{$('Parse Invoice').json.invoice_date}}
  Amount: ${{$('Parse Invoice').json.total_amount}}
  
  Please set up this vendor in Odoo and process the invoice manually.
  
  Task created: [View Task](https://vikunja.yourdomain.com/tasks/{{$json.id}})

Attachments: Original PDF
```

#### Example 3: AI Content Generation for Products

Generate product descriptions and marketing content automatically:

```javascript
// Create engaging product descriptions using AI

// 1. Schedule Trigger - Daily at midnight
// Or: Odoo Webhook when new product created

// 2. Odoo Node - Get Products Without Descriptions
Operation: Get All
Resource: Product
Filters:
  description_sale: false  // No sales description
  type: product  // Physical products only
Limit: 20  // Process 20 per run

// 3. Loop Over Products

// 4. Odoo Node - Get Product Details
Operation: Get
Resource: Product
ID: {{$json.id}}
Options:
  Include: category, attributes, variants, images

// 5. Code Node - Prepare AI prompt
const product = $json;

const prompt = `Create professional, engaging content for this product:

Product Name: ${product.name}
Category: ${product.categ_id?.name || 'General'}
Type: ${product.type}
List Price: $${product.list_price}

${product.attribute_line_ids?.length > 0 ? `
Attributes:
${product.attribute_line_ids.map(attr => `- ${attr.display_name}`).join('\n')}
` : ''}

Create:
1. **Sales Description** (150-200 words):
   - Engaging product overview
   - Key benefits and features
   - Use case scenarios
   - Call to action

2. **Website Description** (250-300 words):
   - SEO-optimized content
   - Detailed specifications
   - Technical details
   - Comparison points

3. **Meta Keywords** (comma-separated):
   - 5-7 relevant SEO keywords

4. **Short Description** (1 sentence):
   - Catchy tagline for listings

Format response as JSON:
{
  "sales_description": "...",
  "website_description": "...",
  "meta_keywords": "keyword1, keyword2, ...",
  "short_description": "..."
}`;

return [{
  json: {
    productId: product.id,
    productName: product.name,
    prompt: prompt
  }
}];

// 6. OpenAI Node - Generate Content
Model: gpt-4o
Temperature: 0.7  // Balanced creativity
Prompt: {{$json.prompt}}
Response Format: JSON

// 7. Code Node - Parse AI Response
const aiContent = JSON.parse($json.choices[0].message.content);
const productData = $input.first().json;

return [{
  json: {
    productId: productData.productId,
    productName: productData.productName,
    salesDescription: aiContent.sales_description,
    websiteDescription: aiContent.website_description,
    metaKeywords: aiContent.meta_keywords,
    shortDescription: aiContent.short_description
  }
}];

// 8. Odoo Node - Update Product
Operation: Update
Resource: Product
ID: {{$json.productId}}
Fields:
  description_sale: {{$json.salesDescription}}
  website_description: {{$json.websiteDescription}}
  website_meta_keywords: {{$json.metaKeywords}}
  description: {{$json.shortDescription}}

// 9. Odoo Node - Add Internal Note
Operation: Create
Resource: Mail Message
Fields:
  model: product.template
  res_id: {{$json.productId}}
  body: |
    <p><strong>AI-Generated Content Added</strong></p>
    <p>Product descriptions generated by AI on {{$now.format('MMMM DD, YYYY')}}</p>
    <p>Review and adjust as needed before publishing.</p>
  message_type: comment

// 10. After Loop - Summary notification

// 11. Code Node - Generate summary
const products = $input.all();
const successCount = products.length;

return [{
  json: {
    count: successCount,
    products: products.map(p => p.json.productName)
  }
}];

// 12. Slack Notification
Channel: #marketing
Message: |
  ✨ **AI Product Descriptions Generated**
  
  {{$json.count}} products updated with AI-generated content.
  
  Products:
  {{$json.products.map(name => `• ${name}`).join('\n')}}
  
  Please review content in Odoo before publishing to website.
```

#### Example 4: Sales Automation Workflow

Automate follow-ups and task creation for sales team:

```javascript
// Automate sales activities and follow-ups based on opportunity stages

// 1. Schedule Trigger - Daily at 9 AM

// 2. Odoo Node - Get Opportunities Needing Follow-up
Operation: Get All
Resource: Lead/Opportunity
Filters:
  probability: [">", 50]  // Qualified leads
  activity_date_deadline: ["<", "{{$now.plus({days: 3}).toISO()}}"]  // Activity due soon
  stage_id: ["in", [2, 3, 4]]  // Qualified, Proposition, Negotiation stages
Limit: 100

// 3. Loop Over Opportunities

// 4. Code Node - Determine action based on stage
const opp = $json;
const daysUntilDeadline = Math.ceil(
  (new Date(opp.activity_date_deadline) - new Date()) / (1000 * 60 * 60 * 24)
);

let action, priority, message;

if (daysUntilDeadline <= 0) {
  action = 'overdue';
  priority = 'high';
  message = '🚨 Overdue activity';
} else if (daysUntilDeadline === 1) {
  action = 'urgent';
  priority = 'high';
  message = '⚠️ Activity due tomorrow';
} else {
  action = 'reminder';
  priority = 'normal';
  message = '📅 Activity due in ' + daysUntilDeadline + ' days';
}

return [{
  json: {
    oppId: opp.id,
    oppName: opp.name,
    partner: opp.partner_id?.name || 'Unknown',
    stage: opp.stage_id?.name || 'Unknown',
    expectedRevenue: opp.expected_revenue,
    probability: opp.probability,
    assignedUser: opp.user_id?.name || 'Unassigned',
    assignedEmail: opp.user_id?.email || '',
    action: action,
    priority: priority,
    message: message,
    deadline: opp.activity_date_deadline,
    activitySummary: opp.activity_summary || 'Follow-up'
  }
}];

// 5. Odoo Node - Create New Activity
Operation: Create
Resource: Mail Activity
Fields:
  res_model: crm.lead
  res_id: {{$json.oppId}}
  activity_type_id: 2  // Call
  summary: "{{$json.message}} - {{$json.activitySummary}}"
  note: |
    Automated reminder for opportunity: {{$json.oppName}}
    Customer: {{$json.partner}}
    Expected Revenue: ${{$json.expectedRevenue}}
    Probability: {{$json.probability}}%
    
    Previous activity deadline was: {{$json.deadline}}
  date_deadline: {{$now.plus({days: 1}).toISO()}}
  user_id: {{$json.user_id}}

// 6. IF Node - High priority?
Condition: {{$json.priority}} === 'high'

// IF YES:

// 7a. Send Email - To assigned salesperson
To: {{$json.assignedEmail}}
Subject: {{$json.message}}: {{$json.oppName}}
Body: |
  Hi {{$json.assignedUser}},
  
  {{$json.message}} for opportunity: {{$json.oppName}}
  
  Opportunity Details:
  - Customer: {{$json.partner}}
  - Stage: {{$json.stage}}
  - Expected Revenue: ${{$json.expectedRevenue}}
  - Win Probability: {{$json.probability}}%
  - Activity: {{$json.activitySummary}}
  - Original Deadline: {{$json.deadline}}
  
  A new follow-up activity has been created for tomorrow.
  
  [Open in Odoo](https://odoo.yourdomain.com/web#id={{$json.oppId}}&model=crm.lead&view_type=form)
  
  Best regards,
  Sales Automation System

// 7b. Slack Notification
Channel: #sales
Message: |
  {{$json.message}}
  
  Opportunity: {{$json.oppName}}
  Customer: {{$json.partner}}
  Value: ${{$json.expectedRevenue}}
  Assigned: {{$json.assignedUser}}
  
  [View](https://odoo.yourdomain.com/web#id={{$json.oppId}}&model=crm.lead&view_type=form)

// IF NO - Normal priority:

// 8. Odoo Node - Log internal note
Operation: Create
Resource: Mail Message
Fields:
  model: crm.lead
  res_id: {{$json.oppId}}
  body: |
    <p>Automated follow-up reminder created.</p>
    <p>Activity scheduled for tomorrow.</p>
  message_type: comment
```

### Odoo 18 AI Features

Leverage Odoo's built-in AI capabilities in your workflows:

**1. AI Lead Scoring:**
- Automatically scores leads based on interaction history
- Machine learning models trained on your data
- Updates probability scores in real-time
- Identifies high-value opportunities

**2. Content Generation:**
- Generate professional emails
- Create product descriptions
- Write sales quotes
- Draft meeting summaries

**3. Sales Forecasting:**
- ML-based pipeline predictions
- Revenue forecasting by period
- Win probability calculations
- Trend analysis

**4. Expense Processing:**
- OCR for receipt scanning
- Automatic expense categorization
- Duplicate detection
- Policy compliance checking

**5. Document Analysis:**
- Extract data from PDFs
- Invoice data extraction
- Contract parsing
- Automated data entry

### Advanced: Odoo XML-RPC API

For operations not available in the native node, use XML-RPC:

```javascript
// HTTP Request Node - Authenticate
Method: POST
URL: http://odoo:8069/web/session/authenticate
Body (JSON):
{
  "jsonrpc": "2.0",
  "params": {
    "db": "odoo",
    "login": "admin@example.com",
    "password": "your-password"
  }
}

// Response contains session_id in cookies
// Store for subsequent requests

// HTTP Request Node - Call model method
Method: POST
URL: http://odoo:8069/web/dataset/call_kw
Headers:
  Cookie: session_id={{$json.session_id}}
  Content-Type: application/json
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "res.partner",
    "method": "create",
    "args": [{
      "name": "New Customer",
      "email": "customer@example.com",
      "phone": "+1234567890",
      "is_company": true
    }],
    "kwargs": {}
  }
}

// Search records
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "crm.lead",
    "method": "search_read",
    "args": [[["probability", ">", 70]]],
    "kwargs": {
      "fields": ["name", "partner_name", "expected_revenue"],
      "limit": 10
    }
  }
}
```

### Tips for Odoo + n8n Integration

1. **Use Internal URLs:** Always use `http://odoo:8069` from n8n for faster performance
2. **API Keys:** Use API keys instead of passwords to avoid session timeouts
3. **Batch Operations:** Process multiple records in loops to reduce API calls
4. **Error Handling:** Add Try/Catch nodes for resilient workflows (Odoo API can return complex errors)
5. **Caching:** Store frequently accessed data (like product lists, user IDs) in n8n variables
6. **Webhooks:** Set up Odoo automated actions to trigger n8n workflows on record changes
7. **Custom Fields:** Create custom fields in Odoo to store AI-generated content or external data
8. **Record IDs:** Always store and use Odoo record IDs for reliable data updates
9. **Field Names:** Use technical field names (name, partner_id) not display names
10. **Testing:** Test workflows in Odoo's test database first before production

### Odoo Apps Ecosystem

**Popular Apps for Automation:**
- **REST API:** Full REST API access for easier integration
- **Webhooks:** Real-time notifications to n8n
- **AI Chat:** Chatbot integration
- **Document Management:** DMS with automation
- **Advanced Inventory:** Barcode, batch tracking
- **HR Analytics:** Employee performance metrics

**Install apps via Odoo UI:**
1. Apps menu → Search for app
2. Install → Configure
3. Access via n8n using model names

### Troubleshooting

#### Odoo Container Won't Start

```bash
# 1. Check logs
docker logs odoo --tail 100

# 2. Common issue: Database connection
docker ps | grep postgres
# Ensure PostgreSQL is running

# 3. Check Odoo configuration
docker exec odoo cat /etc/odoo/odoo.conf

# 4. Reset Odoo database (CAREFUL - loses data!)
docker exec postgres psql -U postgres -c "DROP DATABASE odoo;"
docker compose restart odoo
# Access https://odoo.yourdomain.com to create new database

# 5. Check disk space
df -h
```

#### Can't Login to Odoo

```bash
# 1. Verify master password
grep ODOO_MASTER_PASSWORD .env

# 2. Reset admin password
docker exec -it postgres psql -U postgres -d odoo
UPDATE res_users SET password = 'newpassword' WHERE login = 'admin';
\q

# 3. Check database exists
docker exec postgres psql -U postgres -l | grep odoo

# 4. Clear browser cache and cookies
```

#### API Authentication Errors in n8n

```bash
# 1. Verify credentials in n8n
# Use email (not username) for login

# 2. Generate new API key in Odoo
# Settings → Technical → API Keys → Create

# 3. Test API access manually
curl -X POST http://odoo:8069/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","params":{"db":"odoo","login":"admin@example.com","password":"yourpassword"}}'

# 4. Check Odoo logs for auth errors
docker logs odoo | grep -i auth
```

#### Workflow Fails with "Record Not Found"

```bash
# 1. Verify record ID exists
# Record IDs can change after database resets

# 2. Use search operation first
# Then use returned ID for update/delete

# 3. Add error handling in n8n
# Use Try node to catch missing records

# 4. Check model name is correct
# Use technical name: crm.lead not "Lead"
```

#### Slow Odoo Performance

```bash
# 1. Check resource usage
docker stats odoo

# 2. Increase Odoo workers in .env
# ODOO_WORKERS=4 (default: 2)

# 3. Enable database indexing
# Odoo UI → Settings → Technical → Database Structure

# 4. Clean up old records
# Archive old opportunities, leads, emails

# 5. Optimize PostgreSQL
docker exec postgres psql -U postgres -d odoo -c "VACUUM ANALYZE;"
```

### Resources

- **Documentation:** https://www.odoo.com/documentation/18.0/
- **API Reference:** https://www.odoo.com/documentation/18.0/developer/reference/external_api.html
- **Apps Store:** https://apps.odoo.com
- **Community Forum:** https://www.odoo.com/forum
- **GitHub:** https://github.com/odoo/odoo
- **Video Tutorials:** https://www.odoo.com/slides
- **Developer Docs:** https://www.odoo.com/documentation/18.0/developer.html

### Best Practices

**Data Management:**
- Use stages to organize sales pipeline
- Archive old records regularly
- Set up proper user permissions
- Create custom fields for integrations
- Use tags for categorization
- Regular database backups

**Workflow Automation:**
- Start with simple workflows, add complexity gradually
- Test in Odoo test database first
- Use scheduled actions for recurring tasks
- Set up email templates for consistency
- Monitor workflow performance in n8n
- Document custom automations

**Sales Process:**
- Define clear stage criteria
- Set up activity types for each stage
- Use probability scoring consistently
- Configure email templates
- Set up automated reminders
- Track KPIs in dashboards

**Team Collaboration:**
- Use internal notes for team communication
- Set up proper notification rules
- Create shared dashboards
- Regular team training on Odoo features
- Document company-specific processes
- Use Odoo's built-in chat for quick questions

**Security:**
- Use API keys instead of passwords
- Set up two-factor authentication
- Regular security updates
- Limit external API access
- Monitor user activity logs
- Regular password rotation
