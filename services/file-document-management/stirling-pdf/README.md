# 📋 Stirling-PDF - PDF Toolkit

### What is Stirling-PDF?

Stirling-PDF is a comprehensive, locally hosted web-based PDF manipulation toolkit with over 100 features. It provides a complete solution for all your PDF needs, from basic operations like merging and splitting to advanced features like OCR, digital signatures, form processing, and security features. Built with privacy in mind, all processing happens on your server - no data is sent to external services. With built-in user management and a REST API, it's ideal for both manual operations through the web UI and automated workflows via n8n integration.

### Features

- **100+ PDF Operations** - Merge, split, rotate, compress, convert, sign, watermark, and more
- **OCR Support** - Extract text from scanned documents with Tesseract OCR in 50+ languages
- **Document Conversion** - PDF ↔ Word/Excel/PowerPoint, Images to PDF, HTML to PDF
- **Security & Compliance** - Password protection, encryption, digital signatures, metadata removal, redaction
- **Form Processing** - Extract form data, fill forms programmatically, flatten forms
- **PDF/A Archival** - Convert to long-term archival formats for compliance
- **Batch Processing** - Handle multiple files simultaneously
- **API-First Design** - Full REST API for automation and integration
- **User Management** - Multi-user support with authentication and permissions
- **No External Dependencies** - All processing happens locally, complete privacy
- **Web UI** - User-friendly interface for manual operations
- **Open Source** - Free, transparent, and customizable

### Initial Setup

**First Login to Stirling-PDF:**

1. Navigate to `https://pdf.yourdomain.com`
2. **Login with credentials from installation:**
   - Username: Your email address (set during installation)
   - Password: Check `.env` file for `STIRLING_PASSWORD`
3. Explore the web interface for manual operations
4. **API documentation available at:** `https://pdf.yourdomain.com/swagger-ui/index.html`

**Change Default Password:**

```bash
# Edit .env file
nano .env

# Find and update:
STIRLING_PASSWORD=your-new-secure-password

# Restart Stirling-PDF
docker compose restart stirling-pdf
```

**Verify Installation:**

```bash
# Check if Stirling-PDF is running
docker ps | grep stirling-pdf

# Test API endpoint
curl http://localhost:8080/api/v1/info/status

# View logs
docker logs stirling-pdf --tail 50
```

### n8n Integration Setup

**No credentials needed!** Stirling-PDF API can be accessed directly from n8n using HTTP Request nodes.

**Internal URL:** `http://stirling-pdf:8080`

**API Base Path:** `/api/v1/`

**Authentication:** Session cookie or API key (if configured in Stirling-PDF settings)

**Basic Integration Pattern:**

1. In n8n, add an **HTTP Request** node
2. Configure:
   - **Method:** POST (most operations)
   - **URL:** `http://stirling-pdf:8080/api/v1/[operation]`
   - **Body Content Type:** Multipart-Form Data
   - **Body Parameters:** Add your PDF files and operation parameters
3. Execute to get processed PDF binary output

**API Documentation:**

- Swagger UI: `https://pdf.yourdomain.com/swagger-ui/index.html`
- All available endpoints and parameters documented
- Test operations directly in Swagger UI before building workflows

### Example Workflows

#### Example 1: Invoice Processing Pipeline

Automatically extract text from invoices and parse data.

```javascript
// 1. Email Trigger Node
Trigger: On New Email Received
Filter: Subject contains "Invoice"
Download Attachments: Yes

// 2. Filter Node - Only Process PDFs
Condition: {{ $binary.data.mimeType }} === 'application/pdf'

// 3. HTTP Request Node - Extract Text with OCR
Method: POST
URL: http://stirling-pdf:8080/api/v1/convert/pdf-to-text
Body Content Type: Multipart-Form Data

Body Parameters:
  file: {{ $binary.data }}  // PDF attachment
  outputFormat: txt
  ocrLanguages: eng  // or "deu" for German

// 4. Code Node - Parse Invoice Data
const text = $json.text;

// Extract invoice details using regex
const invoiceNumber = text.match(/Invoice #:?\s*(\d+)/i)?.[1];
const invoiceDate = text.match(/Date:?\s*([\d-/]+)/i)?.[1];
const totalAmount = text.match(/Total:?\s*\$?([\d,]+\.?\d*)/i)?.[1];
const vendor = text.match(/From:?\s*(.+)/i)?.[1];

return {
  json: {
    invoice_number: invoiceNumber,
    date: invoiceDate,
    total: parseFloat(totalAmount?.replace(/,/g, '') || '0'),
    vendor: vendor?.trim(),
    raw_text: text,
    processed_at: new Date().toISOString()
  }
};

// 5. IF Node - Validate Data
Condition: {{ $json.invoice_number }} && {{ $json.total > 0 }}

// 6. Supabase/Baserow Node - Store Invoice Data
Table: invoices
Operation: Insert
Data: {{ $json }}

// 7. Slack Notification
Channel: #finance
Message: |
  💰 **New Invoice Processed**
  
  Invoice #: {{ $json.invoice_number }}
  Vendor: {{ $json.vendor }}
  Amount: ${{ $json.total }}
  Date: {{ $json.date }}

// 8. Error Branch - Manual Review Needed
Slack: #finance-errors
Message: |
  ⚠️ Invoice processing failed - manual review needed
  Attachment: {{ $('Email Trigger').json.subject }}
```

#### Example 2: Document Watermarking Workflow

Add watermarks and password protection to sensitive documents.

```javascript
// 1. Webhook Trigger
Method: POST
Path: /protect-document
Authentication: Header Auth

// 2. HTTP Request Node - Add Watermark
Method: POST
URL: http://stirling-pdf:8080/api/v1/security/add-watermark
Body Content Type: Multipart-Form Data

Body Parameters:
  file: {{ $binary.data }}
  watermarkText: CONFIDENTIAL - {{ $now.format('YYYY-MM-DD') }}
  fontSize: 48
  opacity: 0.3
  rotation: 45
  watermarkType: text
  alphabet: roman  // or "arabic", "japanese", etc.

// 3. HTTP Request Node - Add Password Protection
Method: POST
URL: http://stirling-pdf:8080/api/v1/security/add-password
Body Content Type: Multipart-Form Data

Body Parameters:
  file: {{ $json.data }}  // Watermarked PDF from previous step
  password: {{ $json.password || 'default-password-123' }}
  keyLength: 256
  permissions: 2052  // Allow printing and copying, prevent editing

// 4. Code Node - Generate Secure Password (Optional)
const crypto = require('crypto');
const password = crypto.randomBytes(8).toString('hex');

return {
  json: {
    password: password,
    recipient: $('Webhook').json.recipient_email
  },
  binary: {
    protected_pdf: $binary.data
  }
};

// 5. Email Node - Send Protected Document
To: {{ $json.recipient }}
Subject: Confidential Document - Password Required
Message: |
  You have received a confidential document.
  
  Password: {{ $json.password }}
  
  Please keep this password secure and do not share.

Attachments: {{ $binary.protected_pdf }}

// 6. Supabase Storage - Archive Protected Document
Bucket: confidential-documents
Path: {{ $now.format('YYYY/MM') }}/{{ $('Webhook').json.filename }}
File: {{ $binary.protected_pdf }}
```

#### Example 3: PDF Merge & Split Automation

Daily report generation by merging multiple sources and splitting by sections.

```javascript
// 1. Schedule Trigger
Cron: 0 2 * * *  // Daily at 2 AM

// 2. Code Node - Define Report Sections
const sections = [
  { name: 'Sales Report', url: 'http://reports.company.com/sales.pdf' },
  { name: 'Financial Summary', url: 'http://reports.company.com/finance.pdf' },
  { name: 'Operations Update', url: 'http://reports.company.com/ops.pdf' }
];

return sections.map(s => ({ json: s }));

// 3. Loop Over Items

// 4. HTTP Request Node - Download Each PDF
Method: GET
URL: {{ $json.url }}
Response Format: File

// 5. Aggregate to Array Node
// Collect all downloaded PDFs

// 6. HTTP Request Node - Merge PDFs
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/merge-pdfs
Body Content Type: Multipart-Form Data

Body Parameters:
  files: {{ $binary.data0 }}  // First PDF
  files: {{ $binary.data1 }}  // Second PDF
  files: {{ $binary.data2 }}  // Third PDF
  sortType: alphabetical

// Note: Add all PDFs as separate "files" parameters with same name

// 7. HTTP Request Node - Add Table of Contents
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/add-page-numbers
Body Parameters:
  file: {{ $binary.data }}
  position: footer-center
  startingNumber: 1
  customMargins: {"top": 10, "bottom": 10, "left": 10, "right": 10}

// 8. HTTP Request Node - Split by Page Numbers (Optional)
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/split-pdfs
Body Parameters:
  file: {{ $binary.data }}
  pageNumbers: 1-10,11-20,21-30  // Split into 3 sections

// 9. Google Drive Upload Node
Folder: /Reports/Daily/{{ $now.format('YYYY-MM-DD') }}
File Name: daily-report-{{ $now.format('YYYY-MM-DD') }}.pdf
Binary Data: {{ $binary.data }}

// 10. Slack Notification
Channel: #reports
Message: |
  📊 **Daily Report Generated**
  
  Date: {{ $now.format('YYYY-MM-DD') }}
  Sections: Sales, Finance, Operations
  
  [View Report](https://drive.google.com/...)
```

#### Example 4: Form Processing Pipeline

Extract and validate PDF form data automatically.

```javascript
// 1. Webhook Trigger
Path: /process-form
Method: POST
Content Type: multipart/form-data

// 2. HTTP Request Node - Extract Form Data
Method: POST
URL: http://stirling-pdf:8080/api/v1/convert/pdf-to-json
Body Content Type: Multipart-Form Data

Body Parameters:
  file: {{ $binary.formPdf }}

// 3. Code Node - Process and Validate Form Fields
const formData = $json.fields || {};

// Validate required fields
const requiredFields = ['full_name', 'email', 'phone', 'company'];
const missingFields = requiredFields.filter(field => !formData[field]);

if (missingFields.length > 0) {
  throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
}

// Clean and format data
const submission = {
  full_name: formData.full_name?.trim(),
  email: formData.email?.toLowerCase().trim(),
  phone: formData.phone?.replace(/\D/g, ''),  // Remove non-digits
  company: formData.company?.trim(),
  additional_info: formData.additional_info || '',
  submitted_at: new Date().toISOString(),
  form_type: 'application',
  status: 'pending'
};

// Validate email format
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(submission.email)) {
  throw new Error('Invalid email format');
}

return { json: submission };

// 4. Supabase/Baserow Node - Store Submission
Table: form_submissions
Operation: Insert
Data: {{ $json }}

// 5. HTTP Request Node - Flatten Form (Remove Editability)
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/flatten
Body Parameters:
  file: {{ $('Webhook').binary.formPdf }}

// 6. Google Drive Upload - Archive Flattened Form
Folder: /Forms/Submissions/{{ $now.format('YYYY-MM') }}
File Name: {{ $json.full_name }}-{{ $now.format('YYYY-MM-DD-HHmmss') }}.pdf
Binary Data: {{ $binary.data }}

// 7. Email Node - Confirmation to Submitter
To: {{ $json.email }}
Subject: Form Submission Received
Message: |
  Dear {{ $json.full_name }},
  
  Thank you for your submission. We have received your application form.
  
  Reference ID: {{ $json.id }}
  Submitted: {{ $json.submitted_at }}
  
  We will review your application and contact you within 3-5 business days.

// 8. Slack Notification - Internal Team
Channel: #new-submissions
Message: |
  📝 **New Form Submission**
  
  Name: {{ $json.full_name }}
  Company: {{ $json.company }}
  Email: {{ $json.email }}
  
  [View in Database](https://supabase.yourdomain.com/...)
```

#### Example 5: Contract Redaction Workflow

Automatically redact sensitive information from contracts.

```javascript
// 1. Google Drive Trigger
Trigger: On File Created
Folder: /Contracts/Draft
File Type: PDF

// 2. Google Drive Download
File: {{ $json.id }}

// 3. HTTP Request Node - Auto-Redact SSNs and Credit Cards
Method: POST
URL: http://stirling-pdf:8080/api/v1/security/auto-redact
Body Content Type: Multipart-Form Data

Body Parameters:
  file: {{ $binary.data }}
  redactPattern: (?:\d{3}-\d{2}-\d{4})|(?:\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4})
  // Regex for SSN (###-##-####) and Credit Card numbers
  color: black
  wholeWordSearchOnly: false
  redactType: regex

// 4. HTTP Request Node - Redact Email Addresses
Method: POST
URL: http://stirling-pdf:8080/api/v1/security/auto-redact
Body Parameters:
  file: {{ $binary.data }}
  redactPattern: [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
  color: black

// 5. HTTP Request Node - Remove Metadata
Method: POST
URL: http://stirling-pdf:8080/api/v1/security/sanitize-pdf
Body Parameters:
  file: {{ $binary.data }}
  removeMetadata: true
  removeLinks: false
  removeJavaScript: true
  removeEmbeddedFiles: true
  removeFormFields: false

// 6. HTTP Request Node - Compress Redacted PDF
Method: POST
URL: http://stirling-pdf:8080/api/v1/general/compress-pdf
Body Parameters:
  file: {{ $binary.data }}
  optimizeLevel: 3  // 1=low, 2=medium, 3=high compression

// 7. Code Node - Generate Filename
const originalName = $('Google Drive Trigger').json.name;
const redactedName = originalName.replace('.pdf', '-REDACTED.pdf');

return {
  json: {
    original_name: originalName,
    redacted_name: redactedName,
    processed_at: new Date().toISOString()
  },
  binary: {
    redacted_pdf: $binary.data
  }
};

// 8. Google Drive Upload - Save Redacted Version
Folder: /Contracts/Redacted
File Name: {{ $json.redacted_name }}
Binary Data: {{ $binary.redacted_pdf }}

// 9. Slack Notification
Channel: #legal
Message: |
  🔒 **Contract Redacted**
  
  Original: {{ $json.original_name }}
  Redacted: {{ $json.redacted_name }}
  
  Redacted items:
  • SSNs and credit card numbers
  • Email addresses
  • Metadata removed
  
  [View Redacted Version](https://drive.google.com/...)
```

### Available Operations

**Document Manipulation:**
- Merge/Split PDFs
- Rotate pages (90°, 180°, 270°)
- Reorder pages (drag & drop or API)
- Extract specific pages
- Remove pages
- Scale/resize PDFs
- Crop PDFs
- Add blank pages

**Conversion:**
- PDF to Text (with OCR support)
- PDF to Word (.docx)
- PDF to Excel (.xlsx)
- PDF to PowerPoint (.pptx)
- Images to PDF (JPG, PNG, GIF, TIFF)
- HTML to PDF
- Markdown to PDF
- PDF to Images (PNG/JPEG)
- Office documents to PDF

**Security:**
- Add/remove passwords
- Add watermarks (text/image)
- Digital signatures
- Certificate signing
- Redact content (manual or auto with regex)
- Remove metadata
- Sanitize PDFs (remove scripts, links, embedded files)
- Encrypt/decrypt PDFs

**Forms & Data:**
- Extract form data (to JSON)
- Fill forms programmatically
- Flatten forms (make non-editable)
- Add form fields

**Optimization:**
- Compress PDFs (3 levels)
- Optimize for web
- Reduce file size
- Fix corrupted PDFs
- Repair PDF structure

**OCR (Optical Character Recognition):**
- Extract text from scanned PDFs
- 50+ languages supported
- Searchable PDF creation
- Tesseract engine integration

**Page Manipulation:**
- Add page numbers
- Add headers/footers
- Add bookmarks
- Generate table of contents
- Multi-page layouts (2-up, 4-up, etc.)

**Comparison & Analysis:**
- Compare two PDFs
- Extract differences
- Side-by-side view

### Troubleshooting

**PDF Processing Fails:**
```bash
# Check Stirling-PDF logs
docker logs stirling-pdf --tail 100

# Verify service is running
docker ps | grep stirling-pdf

# Test API endpoint
curl http://localhost:8080/api/v1/info/status

# Common errors:
# - File too large: Check SYSTEM_MAXFILESIZE in .env
# - Timeout: Increase SYSTEM_CONNECTIONTIMEOUTMINUTES
# - Memory: Increase Docker memory allocation
```

**OCR Not Working:**
```bash
# Check if Tesseract is installed
docker exec stirling-pdf tesseract --version

# Should show: tesseract 5.x.x

# For additional languages (if not already included)
docker exec stirling-pdf apt-get update
docker exec stirling-pdf apt-get install tesseract-ocr-deu  # German
docker exec stirling-pdf apt-get install tesseract-ocr-fra  # French

# Restart Stirling-PDF after installing languages
docker compose restart stirling-pdf

# Test OCR via API
curl -X POST http://localhost:8080/api/v1/convert/pdf-to-text \
  -F "file=@scanned.pdf" \
  -F "ocrLanguages=eng"
```

**Memory Issues with Large PDFs:**
```bash
# Check current memory usage
docker stats stirling-pdf --no-stream

# Increase Docker memory limit
docker update --memory="2g" stirling-pdf

# Or update docker-compose.yml:
services:
  stirling-pdf:
    deploy:
      resources:
        limits:
          memory: 2G

# Restart with new limits
docker compose up -d stirling-pdf

# Increase max file size in .env
SYSTEM_MAXFILESIZE=512  # Increase from default 256MB
```

**n8n Connection Issues:**
```bash
# Test internal connection from n8n
docker exec n8n curl http://stirling-pdf:8080/api/v1/info/status

# Check Docker network
docker network inspect ai-corekit_default
# Verify both stirling-pdf and n8n are on same network

# Restart both services
docker compose restart stirling-pdf n8n
```

**Conversion Errors:**
```bash
# LibreOffice conversion issues
# Check if LibreOffice is running
docker exec stirling-pdf ps aux | grep soffice

# For corrupted Office files, try repairing first in MS Office

# Check supported formats
# Stirling-PDF supports: .docx, .xlsx, .pptx
# Older formats (.doc, .xls, .ppt) may have issues

# View detailed error logs
docker logs stirling-pdf --tail 200 | grep ERROR
```

**API Returns Binary Instead of JSON:**
```bash
# Some endpoints return PDF binary directly
# Others return JSON with metadata
# Check API documentation: /swagger-ui/index.html

# For operations returning PDFs, handle as binary in n8n
Response Format: File  # Not JSON

# For operations returning status/metadata
Response Format: JSON
```

### Advanced Features

**Pipeline Mode:**

Execute multiple operations in a single API call for complex workflows.

```javascript
// HTTP Request Node - Multi-Step Pipeline
Method: POST
URL: http://stirling-pdf:8080/api/v1/pipeline
Body Content Type: JSON

Body:
{
  "pipeline": [
    {
      "operation": "rotate",
      "parameters": {"angle": 90}
    },
    {
      "operation": "compress", 
      "parameters": {"optimizeLevel": 3}
    },
    {
      "operation": "add-watermark",
      "parameters": {
        "watermarkText": "PROCESSED",
        "opacity": 0.3,
        "rotation": 45
      }
    }
  ],
  "input": "{{ $binary.data }}"
}
```

**Performance Optimization:**

For high-volume processing, configure Stirling-PDF limits:

```yaml
# docker-compose.yml
stirling-pdf:
  environment:
    - DOCKER_ENABLE_SECURITY=true
    - SYSTEM_MAXFILESIZE=512  # Max file size in MB
    - SYSTEM_CONNECTIONTIMEOUTMINUTES=10  # Timeout for operations
    - UI_APPNAME=AI CoreKit PDF Tools
    - UI_HOMEDESCRIPTION=PDF Processing for Workflows
  deploy:
    resources:
      limits:
        memory: 2G  # Increase for large files
        cpus: '2.0'
      reservations:
        memory: 512M
```

### Common Use Cases

1. **Invoice Automation** - Extract data → Parse with AI → Store in ERP
2. **Contract Management** - Redact sensitive info → Digital signature → Archive
3. **Report Generation** - Merge sections → Add table of contents → Watermark
4. **Form Processing** - Extract data → Validate → Update database → Send confirmation
5. **Document Security** - Password protect → Encrypt → Remove metadata → Distribute
6. **Compliance & Archiving** - Convert to PDF/A → Sanitize metadata → Redact PII → Audit trail

### Tips for Stirling-PDF + n8n Integration

1. **Use Internal URL** - Always use `http://stirling-pdf:8080` from n8n, not the external domain
2. **Binary Data Handling** - Most operations require binary file input via multipart/form-data
3. **Chain Operations** - Combine multiple Stirling-PDF operations in sequence for complex workflows
4. **Error Handling** - Add Error Trigger nodes for robust document processing
5. **File Size Limits** - Default max is 256MB, configurable via `SYSTEM_MAXFILESIZE`
6. **OCR Languages** - Specify correct language codes for best OCR results
7. **Batch Processing** - Use loops with Wait nodes to avoid overloading Stirling-PDF

### Resources

- **Official Documentation:** https://docs.stirlingpdf.com
- **API Reference (Swagger):** `https://pdf.yourdomain.com/swagger-ui/index.html`
- **GitHub Repository:** https://github.com/Stirling-Tools/Stirling-PDF
- **Community Discussions:** https://github.com/Stirling-Tools/Stirling-PDF/discussions
- **Feature Requests:** https://github.com/Stirling-Tools/Stirling-PDF/issues
- **n8n Community Examples:** https://n8n.io/workflows?search=stirling
- **Docker Hub:** https://hub.docker.com/r/stirlingtools/s-pdf

### Integration with AI CoreKit Services

**Stirling-PDF + Gotenberg:**
- Use Gotenberg for HTML → PDF generation
- Use Stirling-PDF for PDF manipulation (merge, split, security)
- Pipeline: Gotenberg (create) → Stirling-PDF (enhance)

**Stirling-PDF + Ollama:**
- Extract text from PDFs with Stirling OCR
- Process text with local Ollama LLMs
- Generate summaries, extract entities, classify documents

**Stirling-PDF + Supabase:**
- Store processed PDFs in Supabase Storage
- Track document metadata in Supabase database
- Trigger processing from database events

**Stirling-PDF + n8n:**
- Complete document automation pipelines
- Invoice processing, form handling, contract management
- Scheduled batch operations

**Stirling-PDF + Open WebUI:**
- Convert chat transcripts to PDF reports
- Archive AI conversations with watermarks
- Generate formatted documentation

**Stirling-PDF + Cal.com:**
- Generate meeting confirmation PDFs
- Create appointment documentation
- Export calendar summaries

**Stirling-PDF + Invoice Ninja:**
- Extract invoice data from PDF uploads
- Auto-populate invoice fields
- Archive paid invoices with watermarks
