# ✍️ DocuSeal - E-Signature Platform

### What is DocuSeal?

DocuSeal is an open-source alternative to DocuSign, providing a complete electronic signature platform with document templates, form building, and signature workflows. It offers legally binding e-signatures, audit trails, and API access for automation, making it perfect for contracts, agreements, and any document requiring signatures.

### Features

- **E-Signatures:** Legally binding electronic signatures
- **Document Templates:** Create reusable templates
- **Form Builder:** Drag-and-drop form creation
- **Multiple Signers:** Sequential or parallel signing workflows
- **Audit Trail:** Complete signature history and timestamps
- **PDF Generation:** Auto-generate PDFs from templates
- **API Access:** REST API for automation
- **Webhooks:** Real-time notifications
- **Branding:** Custom branding options
- **Mobile Support:** Sign on any device
- **Bulk Send:** Send documents to multiple recipients
- **Cloud Storage:** Integration with S3/Google Drive

### Initial Setup

**First Login to DocuSeal:**

1. Navigate to `https://sign.yourdomain.com`
2. Click "Sign Up" to create admin account
3. Enter admin email and password
4. Configure organization settings:
   - Company name
   - Logo upload
   - Signature appearance
5. Create first template or upload document

**API Key Generation:**

1. Go to Settings → API
2. Click "Generate API Key"
3. Copy key for n8n integration
4. Set webhook URL: `https://n8n.yourdomain.com/webhook/docuseal`

### n8n Integration

**Create DocuSeal Credentials:**
```javascript
// HTTP Header Auth
Name: DocuSeal API
Header Name: X-Api-Key
Header Value: your-api-key
```

**Webhook Configuration:**
```javascript
// In DocuSeal: Settings → Webhooks
URL: https://n8n.yourdomain.com/webhook/docuseal
Events: All events
Secret: your-webhook-secret
```

### Example Workflows

#### Example 1: Contract Automation
```javascript
// Automate contract sending and tracking

// 1. Trigger - New customer in CRM

// 2. HTTP Request - Create document from template
Method: POST
URL: https://sign.yourdomain.com/api/v1/submissions
Headers:
  X-Api-Key: your-api-key
Body:
{
  "template_id": "contract-template-id",
  "send_email": true,
  "submitters": [
    {
      "email": "{{$json.customer_email}}",
      "name": "{{$json.customer_name}}",
      "role": "Customer",
      "fields": [
        {
          "name": "company_name",
          "value": "{{$json.company}}"
        },
        {
          "name": "contract_value",
          "value": "{{$json.deal_amount}}"
        },
        {
          "name": "start_date",
          "value": "{{$now.format('yyyy-MM-dd')}}"
        }
      ]
    },
    {
      "email": "sales@company.com",
      "name": "Sales Manager",
      "role": "Company"
    }
  ],
  "message": "Please review and sign the attached contract."
}

// 3. Store submission ID in database
// Save to your CRM or database for tracking

// 4. Slack Notification
Channel: #sales
Message: |
  📄 Contract sent for signature
  Customer: {{$json.customer_name}}
  Company: {{$json.company}}
  Value: ${{$json.deal_amount}}
  DocuSeal ID: {{$('Create Document').json.submission.id}}
```

#### Example 2: Signature Completion Handler
```javascript
// Process completed signatures

// 1. Webhook Trigger - DocuSeal webhook
// Event: submission.completed

// 2. HTTP Request - Download signed document
Method: GET
URL: https://sign.yourdomain.com/api/v1/submissions/{{$json.submission_id}}/download
Headers:
  X-Api-Key: your-api-key
Response Format: File

// 3. Upload to Cloud Storage
// Google Drive, S3, or internal storage

// 4. Update CRM
Method: PATCH
URL: your-crm-api/deals/{{$json.metadata.deal_id}}
Body:
{
  "contract_status": "signed",
  "contract_signed_date": "{{$now.toISO()}}",
  "contract_url": "{{$node['Upload'].json.url}}"
}

// 5. Email Notification
To: {{$json.submitters[0].email}}
Subject: Contract Signed - Thank You!
Attachments: {{$node['Download'].json}}
Body: |
  Dear {{$json.submitters[0].name}},
  
  Your contract has been fully executed.
  A copy is attached for your records.
  
  Thank you for your business!
```

#### Example 3: HR Onboarding Documents
```javascript
// Automate employee onboarding paperwork

// 1. Trigger - New employee in HR system

// 2. Code Node - Prepare document batch
const documents = [
  { template: 'employment-agreement', order: 1 },
  { template: 'nda', order: 2 },
  { template: 'tax-forms', order: 3 },
  { template: 'benefits-enrollment', order: 4 }
];

return documents.map(doc => ({
  json: {
    ...doc,
    employee: $input.first().json
  }
}));

// 3. Loop - Send each document

// 4. HTTP Request - Create submission
Method: POST
URL: https://sign.yourdomain.com/api/v1/submissions
Body:
{
  "template_id": "{{$json.template}}",
  "submitters": [
    {
      "email": "{{$json.employee.email}}",
      "name": "{{$json.employee.name}}",
      "fields": [
        {
          "name": "employee_name",
          "value": "{{$json.employee.name}}"
        },
        {
          "name": "start_date",
          "value": "{{$json.employee.start_date}}"
        },
        {
          "name": "position",
          "value": "{{$json.employee.position}}"
        },
        {
          "name": "salary",
          "value": "{{$json.employee.salary}}"
        }
      ]
    },
    {
      "email": "hr@company.com",
      "name": "HR Manager",
      "role": "Company"
    }
  ],
  "metadata": {
    "employee_id": "{{$json.employee.id}}",
    "document_type": "{{$json.template}}"
  }
}

// 5. Wait Node - 1 hour between documents
// Avoid overwhelming new employee

// 6. Check completion status
Method: GET
URL: https://sign.yourdomain.com/api/v1/submissions/{{$json.submission_id}}

// 7. Update HR system
// Mark onboarding documents as complete
```

### Template Management
```javascript
// Create template via API
Method: POST
URL: https://sign.yourdomain.com/api/v1/templates
Headers:
  X-Api-Key: your-api-key
  Content-Type: multipart/form-data
Body:
  name: "Service Agreement"
  file: [PDF file]
  fields: [
    {
      "name": "customer_name",
      "type": "text",
      "required": true
    },
    {
      "name": "signature",
      "type": "signature",
      "required": true
    },
    {
      "name": "date",
      "type": "date",
      "required": true
    }
  ]

// List templates
Method: GET
URL: https://sign.yourdomain.com/api/v1/templates

// Get template details
Method: GET
URL: https://sign.yourdomain.com/api/v1/templates/{template_id}
```

### Webhook Events

DocuSeal sends these webhook events:
```javascript
// Submission created
{
  "event": "submission.created",
  "submission_id": "123",
  "template_id": "abc",
  "submitters": [...]
}

// Document viewed
{
  "event": "submission.viewed",
  "submission_id": "123",
  "submitter_email": "user@example.com",
  "viewed_at": "2024-01-01T10:00:00Z"
}

// Document signed by one party
{
  "event": "submitter.completed",
  "submission_id": "123",
  "submitter_email": "user@example.com",
  "signed_at": "2024-01-01T10:30:00Z"
}

// All signatures complete
{
  "event": "submission.completed",
  "submission_id": "123",
  "completed_at": "2024-01-01T11:00:00Z",
  "download_url": "https://..."
}
```

### Bulk Operations
```javascript
// Send document to multiple recipients
Method: POST
URL: https://sign.yourdomain.com/api/v1/submissions/bulk
Body:
{
  "template_id": "template-123",
  "submitters": [
    {
      "email": "user1@example.com",
      "name": "User 1"
    },
    {
      "email": "user2@example.com",
      "name": "User 2"
    }
  ]
}

// Check bulk status
Method: GET
URL: https://sign.yourdomain.com/api/v1/submissions/bulk/{bulk_id}
```

### Troubleshooting

#### Emails Not Sending
```bash
# Check email configuration
docker exec docuseal env | grep SMTP

# Test email
docker exec docuseal rails console
> ActionMailer::Base.mail(to: "test@example.com", subject: "Test", body: "Test").deliver_now

# Check logs
docker logs docuseal --tail 100 | grep -i mail
```

#### API Authentication Failed
```bash
# Verify API key
curl -H "X-Api-Key: your-key" \
  https://sign.yourdomain.com/api/v1/templates

# Regenerate key if needed
# Settings → API → Regenerate
```

#### Webhook Not Triggering
```bash
# Test webhook manually
curl -X POST https://n8n.yourdomain.com/webhook/docuseal \
  -H "Content-Type: application/json" \
  -d '{"event":"test","data":"test"}'

# Check DocuSeal webhook logs
# Settings → Webhooks → View Logs
```

### Tips

1. **Templates:** Create reusable templates for common documents
2. **Fields:** Use conditional fields for dynamic forms
3. **Branding:** Customize with your logo and colors
4. **Reminders:** Set automatic reminder emails
5. **Expiry:** Set document expiry dates
6. **Audit Trail:** Download audit logs for compliance
7. **Bulk Send:** Use CSV upload for mass sending
8. **API Limits:** 1000 requests per hour by default

### Resources

- **Documentation:** https://www.docuseal.co/docs
- **API Reference:** https://www.docuseal.co/docs/api
- **GitHub:** https://github.com/docusealco/docuseal
- **Templates:** https://www.docuseal.co/templates
- **Support:** https://github.com/docusealco/docuseal/discussions
