# 📊 Baserow - Airtable Alternative

### What is Baserow?

Baserow is an open-source Airtable alternative with real-time collaboration, making it perfect for data management workflows in n8n. With its intuitive spreadsheet-like interface, REST API, and native n8n integration, it's ideal for building databases, CRM systems, project trackers, and more.

### Features

- **Real-time Collaboration:** Multiple users can edit simultaneously with instant updates
- **Spreadsheet-Like Interface:** Familiar grid view with drag-and-drop functionality
- **Multiple View Types:** Grid, Gallery, Form views for different data visualization needs
- **Field Types:** Text, Number, Date, Select, File, URL, Formula, and more
- **REST API:** Auto-generated API for every table with full CRUD operations
- **Native n8n Node:** Seamless integration with n8n workflows
- **Trash/Undo:** Built-in data safety with trash bin and undo functionality

### Initial Setup

**First Login to Baserow:**

1. Navigate to `https://baserow.yourdomain.com`
2. Click "Register" to create your account
3. First registered user automatically becomes admin
4. Create your first workspace
5. Create your first database and table
6. Generate API token:
   - Click on your profile (top right)
   - Go to Settings → API Tokens
   - Click "Create New Token"
   - Name it "n8n Integration"
   - Copy the token for use in n8n

### n8n Integration Setup

**Native Baserow Node in n8n:**

n8n provides a native Baserow node for seamless integration!

**Create Baserow Credentials in n8n:**

1. In n8n, go to Credentials → New → Baserow API
2. Configure:
   - **Host:** `http://baserow:80` (internal) or `https://baserow.yourdomain.com` (external)
   - **Database ID:** Get from database URL (e.g., `/database/123` → ID is 123)
   - **Token:** Your generated token from Baserow settings

**Internal URL for n8n:** `http://baserow:80`

### Example Workflows

#### Example 1: Customer Data Management Pipeline

```javascript
// Automate customer data collection and enrichment

// 1. Webhook Trigger - Receive new customer data

// 2. Baserow Node - Create new customer record
Operation: Create
Database: Customers
Table ID: 1 (get from table URL)
Fields:
  Name: {{$json.name}}
  Email: {{$json.email}}
  Company: {{$json.company}}
  Status: New Lead
  Created: {{$now.toISO()}}

// 3. HTTP Request - Research company (optional)
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{$json.company}} company information",
  "focusMode": "webSearch"
}

// 4. Baserow Node - Update customer with research
Operation: Update
Database: Customers
Row ID: {{$('Create Customer').json.id}}
Fields:
  Company Info: {{$json.research_summary}}
  Industry: {{$json.detected_industry}}
  Status: Researched

// 5. Slack Notification
Channel: #new-customers
Message: |
  🎉 New customer added!
  
  Name: {{$('Create Customer').json.Name}}
  Company: {{$('Create Customer').json.Company}}
  Status: Researched
```

#### Example 2: Project Task Management

```javascript
// Sync project tasks and send reminders

// 1. Schedule Trigger - Daily at 9 AM

// 2. Baserow Node - Get pending tasks
Operation: List
Database: Projects
Table ID: 2
Filters:
  Status__equal: Pending
  Due Date__date_before: {{$now.plus(3, 'days').toISODate()}}

// 3. Loop Over Items

// 4. Slack Node - Send reminder to assignee
Channel: {{$json['Assignee Slack ID']}}
Message: |
  ⏰ Task due in 3 days
  
  Task: {{$json['Task Name']}}
  Project: {{$json['Project']}}
  Due: {{$json['Due Date']}}

// 5. Baserow Node - Update task status
Operation: Update
Row ID: {{$json.id}}
Fields:
  Reminder Sent: true
  Last Notified: {{$now.toISO()}}
```

#### Example 3: Data Enrichment with AI

```javascript
// Enhance existing records with AI-generated content

// 1. Baserow Node - Get records missing descriptions
Operation: List
Database: Products
Table ID: 3
Filters:
  Description__empty: true
Limit: 10

// 2. Loop Over Items

// 3. OpenAI Node - Generate product description
Model: gpt-4o-mini
System Message: "You are a product marketing copywriter."
User Message: |
  Create a compelling product description for:
  
  Product: {{$json['Product Name']}}
  Features: {{$json['Features']}}
  Target audience: {{$json['Target Market']}}
  
  Make it engaging and SEO-friendly (100-150 words).

// 4. Baserow Node - Update with generated content
Operation: Update
Row ID: {{$json.id}}
Fields:
  Description: {{$('OpenAI').json.choices[0].message.content}}
  SEO Keywords: {{$('OpenAI').json.suggested_keywords}}
  Last Updated: {{$now.toISO()}}
  Updated By: AI Assistant
```

#### Example 4: Real-time Collaboration Trigger

```javascript
// React to changes in Baserow using webhooks

// 1. Webhook Trigger - Baserow webhook
// Configure in Baserow: Table Settings → Webhooks → Add Webhook
// URL: https://n8n.yourdomain.com/webhook/baserow-changes

// 2. Code Node - Parse webhook data
const action = $json.action; // created, updated, deleted
const tableName = $json.table.name;
const rowData = $json.items;

return {
  action: action,
  table: tableName,
  data: rowData
};

// 3. Switch Node - Route based on action type

// Branch 1: Row Created
// 4a. Send Email - Welcome email for new customers
To: {{$json.data.Email}}
Subject: Welcome to {{$json.data.Company}}!
Message: Custom welcome email...

// 4b. Create Tasks in project management system

// Branch 2: Row Updated
// 5a. Check for status changes
// 5b. Notify team members of updates

// Branch 3: Row Deleted
// 6a. Archive related data
// 6b. Send notification to admin

// 7. Baserow Node - Log action history
Operation: Create
Database: Activity Log
Fields:
  Action: {{$json.action}}
  Table: {{$json.table}}
  User: {{$json.user_name}}
  Timestamp: {{$now.toISO()}}
```

#### Example 5: Form to Database Automation

```javascript
// Public form submissions directly into database

// 1. Baserow Form View - Create public form
// In Baserow: Create Form View → Share publicly

// 2. Webhook from Baserow - On form submission
// Form submissions trigger webhook automatically

// 3. Code Node - Process and validate data
const formData = $json;

// Validate email
if (!formData.email || !formData.email.includes('@')) {
  throw new Error('Invalid email address');
}

// Enrich data
return {
  ...formData,
  source: 'baserow_form',
  validated: true,
  processed_at: new Date().toISOString(),
  ip_address: $json.metadata?.ip_address
};

// 4. IF Node - Check if lead qualifies
Condition: {{$json.score >= 70}}

// 5. Cal.com Node - Schedule demo call (if qualified)
Operation: Create Booking
Event Type: Product Demo
// Auto-schedule based on availability

// 6. Send Email - Confirmation
To: {{$json.email}}
Subject: Thank you for your interest!
Message: |
  Hi {{$json.name}},
  
  Thank you for submitting your information!
  {{#if $json.score >= 70}}
  We've scheduled a demo call for you.
  {{else}}
  We'll review your submission and get back to you soon.
  {{/if}}
```

### Advanced API Usage

For operations not available in the native node, use HTTP Request:

```javascript
// Get database schema information
Method: GET
URL: http://baserow:80/api/database/tables/{{$json.table_id}}/fields/
Headers:
  Authorization: Token your-api-token

// Batch operations
Method: PATCH
URL: http://baserow:80/api/database/rows/table/{{$json.table_id}}/batch/
Headers:
  Authorization: Token your-api-token
  Content-Type: application/json
Body: {
  "items": [
    {"id": 1, "field_123": "updated_value1"},
    {"id": 2, "field_123": "updated_value2"}
  ]
}

// File uploads
Method: POST
URL: http://baserow:80/api/database/rows/table/{{$json.table_id}}/{{$json.row_id}}/upload-file/{{$json.field_id}}/
Headers:
  Authorization: Token your-api-token
Body: Binary file data
```

### Baserow Features Highlights

**Real-time Collaboration:**
- Multiple users can edit simultaneously
- Changes appear instantly for all users
- Built-in conflict resolution
- Activity timeline showing who changed what

**Data Safety:**
- Undo/Redo functionality for all actions
- Trash bin for deleted rows (30-day retention)
- Row history tracking
- Field-level permissions (enterprise)

**Templates and Views:**
- 50+ ready-made templates (CRM, Project Manager, etc.)
- Multiple view types: Grid (spreadsheet), Gallery (cards), Form (public forms)
- Custom filters and sorting per view
- Public sharing with password protection

**Field Types:**
- Text (single line, long text)
- Number (integer, decimal)
- Date (date, datetime)
- Boolean (checkbox)
- Single/Multiple Select (dropdown)
- File (attachments, images)
- URL, Email, Phone
- Formula (calculated fields)
- Link to another record (relationships)

### Troubleshooting

**Can't connect to Baserow:**

```bash
# 1. Check Baserow container status
docker ps | grep baserow
# Should show: STATUS = Up

# 2. Check Baserow logs
docker logs baserow --tail 100

# 3. Test internal connection from n8n
docker exec n8n curl http://baserow:80/api/applications/
# Should return JSON with applications

# 4. Verify API token
# Regenerate in Baserow if needed
```

**API authentication errors:**

```bash
# 1. Verify token format
# Header should be: Authorization: Token YOUR_TOKEN
# NOT: Bearer YOUR_TOKEN

# 2. Check token permissions in Baserow
# Settings → API Tokens → Check token is active

# 3. Test token
curl -H "Authorization: Token YOUR_TOKEN" \
  http://baserow:80/api/applications/

# 4. Regenerate token if expired
```

**Fields not updating:**

```bash
# 1. Check field names are exact (case-sensitive)
# Field "Name" ≠ "name"

# 2. Verify field IDs in table
curl -H "Authorization: Token YOUR_TOKEN" \
  http://baserow:80/api/database/tables/TABLE_ID/fields/

# 3. Check field types match data
# Number field cannot accept text values

# 4. Check Baserow logs for errors
docker logs baserow | grep ERROR
```

**Webhooks not triggering:**

```bash
# 1. Verify webhook is active in Baserow
# Table Settings → Webhooks → Check status

# 2. Check webhook URL is accessible
# Must be publicly accessible HTTPS URL

# 3. Test webhook manually
# Baserow → Webhooks → Test Webhook

# 4. Check n8n webhook logs
# n8n UI → Executions → Look for webhook triggers
```

### Tips for Baserow + n8n Integration

**Best Practices:**

1. **Use Internal URLs:** Always use `http://baserow:80` from n8n (faster, no SSL overhead)
2. **Token Authentication:** Use API tokens instead of username/password
3. **Field Naming:** Use exact field names (case-sensitive), avoid special characters
4. **Batch Operations:** Use HTTP Request node for bulk updates to avoid rate limits
5. **Webhooks:** Set up Baserow webhooks for real-time triggers
6. **Error Handling:** Add Try/Catch nodes for resilient workflows
7. **Field Types:** Respect Baserow field types when creating/updating records
8. **Database Structure:** Use multiple tables with relationships for complex data

**Common Automation Patterns:**

- Form submissions → Database + Email notification
- Database changes → Sync with external CRM
- Scheduled tasks → Data cleanup/enrichment
- API data → Import to Baserow tables
- Baserow → Generate reports/invoices
- Customer data → Automated onboarding workflows

**Data Organization:**

- Use workspaces to separate projects/clients
- Create templates for repeated database structures
- Use views to filter and organize data
- Apply consistent naming conventions
- Document field purposes in descriptions

### Baserow vs NocoDB Comparison

| Feature | Baserow | NocoDB |
|---------|---------|--------|
| **API** | REST only | REST + GraphQL |
| **Webhooks** | Via n8n | Built-in |
| **Field Types** | 15+ types | 25+ types |
| **Formula Support** | Basic | Advanced |
| **Views** | 3 types (Grid, Gallery, Form) | 7 types (includes Calendar, Kanban, Gantt) |
| **Relationships** | One-to-Many | Many-to-Many |
| **Performance** | Excellent | Excellent |
| **Resource Usage** | Moderate | Lightweight |
| **Native n8n Node** | ✅ Yes | ❌ No (HTTP Request only) |
| **Trash/Restore** | ✅ Yes | ❌ No |

**Choose Baserow when you need:**
- Native n8n node for easier workflows
- Simpler, more intuitive interface
- Real-time collaboration focus
- Trash/restore functionality
- Form views for public data collection

**Choose NocoDB when you need:**
- GraphQL API support
- Advanced formula fields
- More view types (Calendar, Gantt, Kanban)
- Many-to-many relationships
- Lower resource consumption

### Resources

- **Documentation:** https://baserow.io/docs
- **API Reference:** https://baserow.io/docs/apis/rest-api
- **GitHub:** https://github.com/bram2w/baserow
- **Forum:** https://community.baserow.io/
- **Templates:** https://baserow.io/templates
- **n8n Node Docs:** Search "Baserow" in n8n node library
