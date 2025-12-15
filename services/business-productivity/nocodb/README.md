# 📋 NocoDB - Airtable Alternative

### What is NocoDB?

NocoDB transforms any relational database into a smart spreadsheet interface, providing an open-source alternative to Airtable. Unlike Baserow, NocoDB offers both REST and GraphQL APIs, more field types (25+), advanced formulas, and 7 different view types including Calendar, Kanban, and Gantt charts. It's lightweight, highly performant, and perfect for complex data relationships with many-to-many support.

### Features

- **25+ Field Types:** Text, Number, Date, Formula, Rollup, Lookup, Barcode/QR, Attachments, Rating, and more
- **Multiple Views:** Grid, Gallery, Kanban, Calendar, Form, Gantt, and more
- **Dual APIs:** Both REST and GraphQL for maximum flexibility
- **Built-in Webhooks:** Real-time triggers for n8n workflows
- **Advanced Formulas:** Excel-like formulas with 50+ functions
- **Many-to-Many Relationships:** Support for complex data models
- **Lightweight:** Uses minimal resources compared to alternatives
- **Database-Agnostic:** Works with MySQL, PostgreSQL, SQL Server, SQLite

### Initial Setup

**First Login to NocoDB:**

1. Navigate to `https://nocodb.yourdomain.com`
2. Login with admin credentials from installation report:
   - Email: Your email address (set during installation)
   - Password: Check `.env` file for `NOCODB_ADMIN_PASSWORD`
3. Create your first base (database)
4. Generate API token:
   - Click on your profile (top right)
   - Go to "Account Settings"
   - Navigate to "API Tokens"
   - Click "Create New Token"
   - Name it "n8n Integration"
   - Copy the token for use in n8n

### n8n Integration Setup

**Note:** NocoDB does not have a native n8n node. Use HTTP Request nodes instead.

**Create NocoDB Credentials in n8n:**

1. In n8n, create credentials:
   - Type: Header Auth
   - Name: NocoDB API Token
   - Header Name: `xc-token`
   - Header Value: Your generated token from NocoDB

**Internal URL for n8n:** `http://nocodb:8080`

### Example Workflows

#### Example 1: Customer Data Pipeline

```javascript
// Automate customer onboarding with smart data management

// 1. Webhook Trigger - Receive new customer signup

// 2. HTTP Request Node - Create customer in NocoDB
Method: POST
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Authentication: Use NocoDB Credentials
Headers:
  Content-Type: application/json
Body (JSON):
{
  "Name": "{{$json.name}}",
  "Email": "{{$json.email}}",
  "Company": "{{$json.company}}",
  "Status": "New",
  "Created": "{{$now.toISO()}}"
}

// 3. HTTP Request Node - Create linked project record
Method: POST
URL: http://nocodb:8080/api/v2/tables/{PROJECTS_TABLE_ID}/records
Body (JSON):
{
  "Customer": "{{$('Create Customer').json.Id}}",
  "ProjectName": "Onboarding - {{$json.company}}",
  "Status": "Active",
  "StartDate": "{{$now.toISODate()}}"
}

// 4. Slack Notification
Channel: #new-customers
Message: |
  🎉 New customer onboarded!
  
  Name: {{$('Create Customer').json.Name}}
  Company: {{$('Create Customer').json.Company}}
  Project: Onboarding - {{$json.company}}
```

#### Example 2: Form to Database Automation

```javascript
// Create public forms that feed directly into your database

// 1. NocoDB Form View
// Create a form view in NocoDB UI for public data collection

// 2. NocoDB Webhook - Configured in table settings
// Triggers this n8n workflow on form submission

// 3. Code Node - Process and validate data
const formData = $input.first().json;

// Validate email
if (!formData.email || !formData.email.includes('@')) {
  throw new Error('Invalid email address');
}

// Validate phone number (basic check)
if (formData.phone && !/^\+?[\d\s-()]+$/.test(formData.phone)) {
  throw new Error('Invalid phone number format');
}

// Enrich data
return {
  json: {
    ...formData,
    source: 'nocodb_form',
    processed: true,
    timestamp: new Date().toISOString(),
    validation_passed: true
  }
};

// 4. HTTP Request Node - Update record with enrichment
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
{
  "Id": "{{$json.Id}}",
  "ProcessedData": "{{JSON.stringify($json)}}",
  "Status": "Processed",
  "ValidationPassed": true
}

// 5. Send Email Node - Confirmation to user
To: {{$json.email}}
Subject: "Thank you for your submission!"
Body: |
  Hi {{$json.name}},
  
  Your form submission has been received and processed successfully.
  
  Reference ID: {{$json.Id}}
  Submission Date: {{$json.timestamp}}
```

#### Example 3: Sync with External Services

```javascript
// Keep NocoDB synchronized with other systems

// 1. Schedule Trigger - Every hour

// 2. HTTP Request Node - Get NocoDB records modified recently
Method: GET
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Authentication: Use NocoDB Credentials
Query Parameters:
  where: (UpdatedAt,gt,{{$now.minus({hours: 1}).toISO()}})
  limit: 100

// 3. Loop Over Records

// 4. Switch Node - Sync based on status

// Branch 1 - New Records
// HTTP Request - Create in external CRM
Method: POST
URL: https://external-crm.com/api/customers
Body: {
  "name": "{{$json.Name}}",
  "email": "{{$json.Email}}",
  "company": "{{$json.Company}}",
  "source": "nocodb"
}

// HTTP Request - Update NocoDB with external ID
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "ExternalCRMId": "{{$('External CRM').json.id}}",
  "LastSynced": "{{$now.toISO()}}"
}

// Branch 2 - Updated Records
// HTTP Request - Update external system
Method: PUT
URL: https://external-crm.com/api/customers/{{$json.ExternalCRMId}}
Body: {
  "name": "{{$json.Name}}",
  "email": "{{$json.Email}}",
  "company": "{{$json.Company}}"
}

// HTTP Request - Log sync timestamp
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "LastSynced": "{{$now.toISO()}}",
  "SyncStatus": "Success"
}

// Branch 3 - Deleted Records (marked with DeletedAt)
// HTTP Request - Archive in external system
Method: DELETE
URL: https://external-crm.com/api/customers/{{$json.ExternalCRMId}}

// HTTP Request - Mark as synced
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "SyncStatus": "Archived",
  "LastSynced": "{{$now.toISO()}}"
}
```

### NocoDB Features for Automation

**Multiple Views (7 types):**
- **Grid View:** Spreadsheet-like interface
- **Gallery View:** Card-based visualization
- **Kanban View:** Drag-and-drop task management
- **Calendar View:** Time-based data visualization
- **Form View:** Public data collection
- **Gantt View:** Project timeline visualization
- **Map View:** Geographic data visualization

**Field Types (25+):**
- **LinkToAnotherRecord:** Many-to-many relationships
- **Lookup:** Fetch data from related tables
- **Rollup:** Aggregate calculations (sum, avg, count)
- **Formula:** Excel-like formulas with 50+ functions
- **Barcode/QR Code:** Generate scannable codes
- **Attachment:** File uploads with preview
- **Rating:** Star ratings for feedback
- **Duration:** Time tracking
- **Currency:** Multi-currency support
- **Percent:** Progress tracking
- **Geometry:** Geographic coordinates
- And 14 more types...

**API Capabilities:**
- **REST API:** Auto-generated, fully documented
- **GraphQL API:** Query flexibility, nested relations
- **Webhooks:** Real-time triggers on CRUD operations
- **Bulk Operations:** Batch create/update/delete
- **Filtering:** Complex queries with operators
- **Sorting:** Multi-field sorting
- **Pagination:** Efficient large dataset handling
- **Authentication:** API tokens with granular permissions

### NocoDB API Examples

#### Get Table Records with Filters

```javascript
// HTTP Request Node
Method: GET
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Query Parameters:
  where: (Status,eq,Active)~and(CreatedAt,gt,2025-01-01)
  sort: -CreatedAt
  limit: 50
  offset: 0
```

#### Create Record with Linked Data

```javascript
// HTTP Request Node
Method: POST
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
{
  "CustomerName": "John Doe",
  "Email": "john@example.com",
  "Projects": ["rec123", "rec456"],  // Link to existing project records
  "Status": "Active"
}
```

#### Bulk Update Records

```javascript
// HTTP Request Node
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
[
  {
    "Id": "rec001",
    "Status": "Completed"
  },
  {
    "Id": "rec002",
    "Status": "Completed"
  }
]
```

#### Using Webhooks in NocoDB

Configure webhooks in NocoDB UI (Table Settings → Webhooks):

```javascript
// NocoDB Webhook Configuration:
Trigger: After Insert, After Update, After Delete
URL: https://n8n.yourdomain.com/webhook/nocodb-changes
Method: POST
Headers:
  x-webhook-secret: your-secret-key

// n8n Webhook Trigger receives:
{
  "type": "after.insert",
  "data": {
    "table_name": "customers",
    "record": {
      "Id": "rec123",
      "Name": "John Doe",
      "Email": "john@example.com"
    }
  }
}
```

### Tips for NocoDB + n8n Integration

1. **Use Internal URLs:** Always use `http://nocodb:8080` from n8n (faster, no SSL overhead)
2. **API Token Security:** Store tokens in n8n credentials, never in code
3. **Webhook Configuration:** Set up webhooks in table settings for real-time triggers
4. **Bulk Operations:** Use bulk endpoints for better performance with large datasets
5. **Field References:** Use field names exactly as they appear in NocoDB
6. **Relationships:** Leverage LinkToAnotherRecord for complex data models (many-to-many support!)
7. **Views API:** Different views can have different API endpoints
8. **Formula Fields:** Use for calculated values that update automatically
9. **GraphQL Advantage:** Use GraphQL for nested data queries (more efficient than multiple REST calls)
10. **Lookup & Rollup:** These fields pull data from related tables automatically

### NocoDB vs Baserow Comparison

| Feature | NocoDB | Baserow |
|---------|--------|---------|
| **API** | REST + GraphQL | REST only |
| **Webhooks** | Built-in | Via n8n |
| **Field Types** | 25+ types | 15+ types |
| **Formula Support** | Advanced (50+ functions) | Basic |
| **Views** | 7 types (Grid, Gallery, Kanban, Calendar, Form, Gantt, Map) | 3 types (Grid, Gallery, Form) |
| **Relationships** | Many-to-Many | One-to-Many |
| **Performance** | Excellent | Excellent |
| **Resource Usage** | Lightweight | Moderate |
| **Native n8n Node** | ❌ No (HTTP Request only) | ✅ Yes |
| **Trash/Restore** | ❌ No | ✅ Yes |
| **Database Support** | MySQL, PostgreSQL, SQL Server, SQLite | PostgreSQL only |
| **Self-Hosting** | Very easy | Very easy |
| **Learning Curve** | Moderate | Easy |

**Choose NocoDB when you need:**
- GraphQL API support for efficient nested queries
- Advanced formula fields with 50+ functions
- More view types (Calendar, Gantt, Kanban, Map)
- Many-to-many relationships for complex data models
- Lower resource consumption
- Support for multiple database types
- Advanced data modeling capabilities

**Choose Baserow when you need:**
- Native n8n node for easier workflows (no HTTP Request configuration)
- Simpler, more intuitive interface
- Real-time collaboration focus
- Trash/restore functionality
- Faster learning curve for non-technical users
- Built-in user management

### Troubleshooting

#### Connection Refused Error

```bash
# Test NocoDB availability
docker exec -it n8n curl http://nocodb:8080/api/v2/meta/tables

# Check NocoDB logs
docker logs nocodb --tail 100

# Restart NocoDB
docker compose restart nocodb
```

#### API Token Invalid

```bash
# Verify token in .env
grep NOCODB_API_TOKEN .env

# Regenerate token in NocoDB UI:
# Profile → Account Settings → API Tokens → Create New Token

# Update n8n credentials with new token
```

#### Webhook Not Triggering

```bash
# Check webhook configuration in NocoDB UI
# Table Settings → Webhooks → Verify URL and triggers

# Test webhook manually
curl -X POST https://n8n.yourdomain.com/webhook/nocodb-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check n8n webhook logs
docker logs n8n --tail 100 | grep webhook
```

#### Slow Query Performance

```bash
# Add indexes to frequently queried fields in NocoDB UI
# Table Settings → Fields → Select field → Enable Index

# Use pagination for large datasets
# Query Parameters: limit=100&offset=0

# Monitor NocoDB performance
docker stats nocodb
```

#### Import/Export Issues

```bash
# Export base as CSV/JSON
# NocoDB UI → Base → Export

# Import via API
curl -X POST http://nocodb:8080/api/v2/tables/{TABLE_ID}/records \
  -H "xc-token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @import.json

# Check import logs
docker logs nocodb --tail 50
```

### Resources

- **Documentation:** https://docs.nocodb.com
- **API Reference:** https://docs.nocodb.com/developer-resources/rest-apis
- **GraphQL API:** https://docs.nocodb.com/developer-resources/graphql-apis
- **GitHub:** https://github.com/nocodb/nocodb
- **Forum:** https://community.nocodb.com
- **Examples:** https://github.com/nocodb/nocodb/tree/develop/packages/nocodb/tests

### Best Practices

**Data Modeling:**
- Use LinkToAnotherRecord for relationships
- Leverage Lookup fields to display related data
- Use Rollup for aggregations (sum, avg, count)
- Formula fields for calculated values
- Keep table names descriptive and consistent

**API Usage:**
- Use GraphQL for nested data (more efficient)
- Implement pagination for large datasets
- Cache frequently accessed data
- Use bulk operations for batch updates
- Handle rate limits gracefully

**Automation:**
- Set up webhooks for real-time updates
- Use n8n for complex workflows
- Implement error handling and retries
- Log all automation activities
- Test webhooks thoroughly before production

**Security:**
- Rotate API tokens regularly
- Use different tokens for different integrations
- Set up proper table permissions
- Enable 2FA for admin accounts
- Review audit logs regularly

**Performance:**
- Index frequently queried fields
- Limit number of fields per table (<50 recommended)
- Use views to organize data
- Paginate large result sets
- Monitor resource usage
