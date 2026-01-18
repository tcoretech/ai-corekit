# 📄 Gotenberg - Document Converter

### What is Gotenberg?

Gotenberg is a containerized, stateless API for seamless PDF conversion. It provides a developer-friendly HTTP API that leverages powerful tools like Chromium (for HTML/URL rendering) and LibreOffice (for Office document conversion) to convert numerous document formats into PDF files. Written in Go, Gotenberg is designed for scalability, distributed systems, and high-volume document processing. It's the perfect solution for automated PDF generation in workflows, invoice systems, report generation, and document archiving.

### Features

- **Multi-Engine Document Conversion** - Chromium for HTML/Markdown/URLs, LibreOffice for Office documents (Word, Excel, PowerPoint)
- **Versatile Input Formats** - HTML, Markdown, URLs, .docx, .xlsx, .pptx, .odt, .ods, and more
- **Stateless & Scalable** - No local storage, perfect for horizontal scaling and distributed systems
- **HTTP/2 Support** - Modern protocol support with H2C (HTTP/2 Cleartext) for performance
- **Webhook Integration** - Asynchronous workflows with automatic file uploads to destinations
- **PDF Manipulation** - Merge, split, compress, and convert to PDF/A archival format
- **Custom Headers & Metadata** - Inject PDF metadata (author, title, creation date) via API headers
- **Multi-Architecture Support** - Available on amd64, arm64, armhf, i386, and ppc64le
- **No Dependencies** - Everything bundled in Docker image (Chromium, LibreOffice, PDFtk, QPDF)
- **Container-Native** - Simple Docker deployment, works in Kubernetes, Cloud Run, ECS, etc.

### Initial Setup

**Gotenberg is Pre-Configured in AI CoreKit:**

Gotenberg is already running and accessible at `http://gotenberg:3000` internally. You can start converting documents immediately from n8n or any other service.

**Test Gotenberg from Command Line:**

```bash
# Test 1: Convert URL to PDF
curl --request POST http://localhost:3000/forms/chromium/convert/url \
  --form 'url="https://example.com"' \
  -o example.pdf

# Test 2: Convert HTML string to PDF
echo '<html><body><h1>Hello Gotenberg!</h1></body></html>' > test.html

curl --request POST http://localhost:3000/forms/chromium/convert/html \
  --form 'files=@"test.html"' \
  -o output.pdf

# Test 3: Convert Word document to PDF (if you have a .docx file)
curl --request POST http://localhost:3000/forms/libreoffice/convert \
  --form 'files=@"document.docx"' \
  -o document.pdf

# Test 4: Merge multiple PDFs
curl --request POST http://localhost:3000/forms/pdfengines/merge \
  --form 'files=@"file1.pdf"' \
  --form 'files=@"file2.pdf"' \
  -o merged.pdf
```

**Check Gotenberg Status:**

```bash
# Check if Gotenberg is running
docker ps | grep gotenberg

# View Gotenberg logs
docker logs gotenberg --tail 50

# Check Gotenberg health (should return 200 OK)
curl -I http://localhost:3000/health

# View Gotenberg version and modules
curl http://localhost:3000/health
```

### API Endpoints Overview

Gotenberg provides several conversion endpoints:

**Chromium-based conversions (HTML/URLs):**
- `POST /forms/chromium/convert/url` - Convert a URL to PDF
- `POST /forms/chromium/convert/html` - Convert HTML files to PDF
- `POST /forms/chromium/convert/markdown` - Convert Markdown files to PDF

**LibreOffice conversions (Office documents):**
- `POST /forms/libreoffice/convert` - Convert Office documents (.docx, .xlsx, .pptx, etc.) to PDF

**PDF manipulation:**
- `POST /forms/pdfengines/merge` - Merge multiple PDFs into one
- `POST /forms/pdfengines/convert` - Convert PDF to PDF/A format

**Screenshot:**
- `POST /forms/chromium/screenshot/url` - Capture screenshot of a URL
- `POST /forms/chromium/screenshot/html` - Capture screenshot from HTML

### n8n Integration Setup

**No credentials needed!** Gotenberg has no authentication by default. Use HTTP Request nodes with `multipart/form-data` to call the API.

**Internal URL:** `http://gotenberg:3000`

**Basic Integration Pattern:**

1. In n8n, add an **HTTP Request** node
2. Configure:
   - **Method:** POST
   - **URL:** `http://gotenberg:3000/forms/chromium/convert/html` (or other endpoint)
   - **Body Content Type:** Multipart-Form Data
   - **Body Parameters:** Add your files and options
3. Execute to get PDF binary output

### Example Workflows

#### Example 1: Convert HTML to PDF (Simple Invoice Generator)

Generate invoices from HTML templates and convert to PDF.

```javascript
// 1. Manual Trigger or Webhook
// Input: Customer data, invoice items

// 2. Code Node - Generate Invoice HTML
const customer = $json.customer || {
  name: "John Doe",
  email: "john@example.com",
  address: "123 Main St"
};

const items = $json.items || [
  { description: "Web Development", quantity: 10, rate: 100 },
  { description: "Consulting", quantity: 5, rate: 150 }
];

const total = items.reduce((sum, item) => sum + (item.quantity * item.rate), 0);

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    .header { text-align: center; margin-bottom: 30px; }
    .invoice-info { margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #4CAF50; color: white; }
    .total { font-size: 18px; font-weight: bold; text-align: right; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>INVOICE</h1>
    <p>Invoice #${Date.now()}</p>
  </div>
  
  <div class="invoice-info">
    <strong>Bill To:</strong><br>
    ${customer.name}<br>
    ${customer.email}<br>
    ${customer.address}
  </div>
  
  <table>
    <tr>
      <th>Description</th>
      <th>Quantity</th>
      <th>Rate</th>
      <th>Amount</th>
    </tr>
    ${items.map(item => `
      <tr>
        <td>${item.description}</td>
        <td>${item.quantity}</td>
        <td>$${item.rate}</td>
        <td>$${item.quantity * item.rate}</td>
      </tr>
    `).join('')}
  </table>
  
  <div class="total">
    Total: $${total}
  </div>
</body>
</html>
`;

return {
  json: {
    html: html,
    customer: customer,
    total: total
  }
};

// 3. Code Node - Convert HTML to Binary File
const htmlContent = $json.html;

return {
  json: {},
  binary: {
    data: {
      data: Buffer.from(htmlContent, 'utf-8').toString('base64'),
      mimeType: 'text/html',
      fileName: 'index.html'
    }
  }
};

// 4. HTTP Request Node - Call Gotenberg API
Method: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body Content Type: Multipart-Form Data
Specify Body: Using Fields Below

Body Parameters:
  files = {{ $binary.data }}  // Select "Binary Data" from dropdown

Headers:
  Gotenberg-Output-Filename: invoice-{{ $('Code Node').first().json.customer.name }}.pdf

// 5. Code Node - Rename PDF Binary (Optional)
return {
  json: $json,
  binary: {
    invoice: $binary.data  // Rename from 'data' to 'invoice' for clarity
  }
};

// 6. Send Email Node (Gmail/SMTP)
Operation: Send Email
To: {{ $('Code Node').first().json.customer.email }}
Subject: Your Invoice
Message: Please find attached your invoice.
Attachments: {{ $binary.invoice }}  // Attach the PDF

// Result: Automated invoice generation and delivery via email
```

#### Example 2: Convert URL to PDF (Website Archiving)

Automatically archive web pages as PDFs on a schedule.

```javascript
// 1. Schedule Trigger
// Every day at 2 AM

// 2. Set Node - Define URLs to Archive
urls = [
  { name: "Company Homepage", url: "https://example.com" },
  { name: "Product Page", url: "https://example.com/products" },
  { name: "Blog", url: "https://example.com/blog" }
]

// 3. Loop Over Items

// 4. HTTP Request Node - Convert URL to PDF
Method: POST
URL: http://gotenberg:3000/forms/chromium/convert/url
Body Content Type: Multipart-Form Data

Body Parameters:
  url = {{ $json.url }}

Headers:
  Gotenberg-Output-Filename: {{ $json.name }}-{{ $now.format('YYYY-MM-DD') }}.pdf
  Gotenberg-Chromium-Wait-Delay: 2s  // Wait 2 seconds for page to load
  Gotenberg-Chromium-Emulated-Media-Type: print  // Use print CSS

// 5. Move/Upload PDF
// Option A: Save to Google Drive
// Option B: Save to local storage
// Option C: Upload to S3/Supabase Storage

// 6. Slack Notification
Channel: #archives
Message: |
  📄 *Website Archive Complete*
  
  Archived pages: {{ $('Set').all().length }}
  Date: {{ $now.format('YYYY-MM-DD') }}
```

#### Example 3: Convert Office Documents to PDF (Document Pipeline)

Monitor a folder for Office documents and auto-convert to PDF.

```javascript
// 1. Google Drive Trigger (or FTP Watch)
Trigger: On File Created/Updated
Folder: /Documents/ToConvert
File Extensions: .docx, .xlsx, .pptx

// 2. Google Drive Download Node
Operation: Download
File: {{ $json.id }}

// 3. HTTP Request Node - Convert to PDF
Method: POST
URL: http://gotenberg:3000/forms/libreoffice/convert
Body Content Type: Multipart-Form Data

Body Parameters:
  files = {{ $binary.data }}

Headers:
  Gotenberg-Output-Filename: {{ $json.name.replace(/\.[^/.]+$/, "") }}.pdf

// 4. Code Node - Add Metadata
const originalName = $('Google Drive Trigger').first().json.name;
const pdfName = originalName.replace(/\.[^/.]+$/, '.pdf');

return {
  json: {
    original_file: originalName,
    pdf_file: pdfName,
    converted_at: new Date().toISOString()
  },
  binary: {
    pdf: $binary.data
  }
};

// 5. Google Drive Upload Node
Operation: Upload
Folder: /Documents/Converted
File Name: {{ $json.pdf_file }}
Binary Data: {{ $binary.pdf }}

// 6. Notify User (Email/Slack)
Message: |
  ✅ Document converted successfully
  
  Original: {{ $json.original_file }}
  PDF: {{ $json.pdf_file }}
  Time: {{ $json.converted_at }}
```

#### Example 4: Merge Multiple PDFs (Report Aggregation)

Combine multiple PDF reports into a single document.

```javascript
// 1. Webhook/Manual Trigger
// Receives array of PDF URLs or file IDs

// 2. Loop to Download PDFs
// For each PDF URL/ID

// 3. HTTP Request - Download PDF
Method: GET
URL: {{ $json.pdf_url }}
Response Format: File

// 4. Aggregate to List Node
// Collect all PDF binaries

// 5. HTTP Request - Merge PDFs
Method: POST
URL: http://gotenberg:3000/forms/pdfengines/merge
Body Content Type: Multipart-Form Data

Body Parameters:
  files = {{ $binary.data0 }}  // First PDF
  files = {{ $binary.data1 }}  // Second PDF
  files = {{ $binary.data2 }}  // Third PDF
  // ... add all PDFs
  // Note: n8n will automatically send multiple files with same parameter name

Headers:
  Gotenberg-Output-Filename: merged-report-{{ $now.format('YYYY-MM-DD') }}.pdf
  Gotenberg-Pdf-Format: PDF/A-1b  // Convert to archival format

// 6. Upload Merged PDF
// Save to storage or send via email
```

#### Example 5: Dynamic PDF with Images (Certificate Generator)

Generate certificates with dynamic text and images using HTML + Gotenberg.

```javascript
// 1. Webhook Trigger
// Receives: name, course, date

// 2. Code Node - Generate Certificate HTML with Embedded Image
const name = $json.name || "John Doe";
const course = $json.course || "Web Development";
const date = $json.date || new Date().toLocaleDateString();

// Option 1: Use base64 embedded image (logo, signature, etc.)
const logoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAUA...";  // Your logo in base64

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Georgia', serif;
      text-align: center;
      margin: 100px 50px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }
    .certificate {
      background: white;
      color: #333;
      padding: 60px;
      border: 10px solid gold;
      box-shadow: 0 0 30px rgba(0,0,0,0.3);
      max-width: 800px;
    }
    h1 { font-size: 48px; color: #667eea; margin-bottom: 30px; }
    .name { font-size: 36px; font-weight: bold; color: #764ba2; margin: 30px 0; }
    .course { font-size: 24px; margin: 20px 0; }
    .logo { width: 120px; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="certificate">
    <img src="data:image/png;base64,${logoBase64}" class="logo" alt="Logo">
    <h1>Certificate of Completion</h1>
    <p>This certifies that</p>
    <div class="name">${name}</div>
    <p>has successfully completed the course</p>
    <div class="course">${course}</div>
    <p>on ${date}</p>
  </div>
</body>
</html>
`;

return {
  json: {
    html: html,
    recipient_name: name
  }
};

// 3. Code Node - Convert HTML to Binary
const htmlContent = $json.html;

return {
  json: $json,
  binary: {
    html: {
      data: Buffer.from(htmlContent, 'utf-8').toString('base64'),
      mimeType: 'text/html',
      fileName: 'certificate.html'
    }
  }
};

// 4. HTTP Request - Generate PDF
Method: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body Content Type: Multipart-Form Data

Body Parameters:
  files = {{ $binary.html }}

Headers:
  Gotenberg-Output-Filename: certificate-{{ $('Code Node').first().json.recipient_name }}.pdf
  Gotenberg-Chromium-Paper-Width: 11  // Letter size width (inches)
  Gotenberg-Chromium-Paper-Height: 8.5  // Letter size height (inches)
  Gotenberg-Chromium-Landscape: true  // Landscape orientation

// 5. Send Certificate via Email
To: {{ $json.recipient_email }}
Subject: Your Course Certificate
Attachments: {{ $binary.data }}
```

### Troubleshooting

**Gotenberg not responding:**
```bash
# Check if Gotenberg container is running
docker ps | grep gotenberg

# Check Gotenberg logs for errors
docker logs gotenberg --tail 100

# Restart Gotenberg service
docker compose restart gotenberg

# Test health endpoint
curl http://localhost:3000/health
```

**Conversion timeout errors:**
```bash
# Increase timeout for large documents (add header to n8n HTTP Request)
Gotenberg-Chromium-Wait-Delay: 10s  # Wait longer for page load

# Or increase global timeout in docker-compose.yml
environment:
  - CHROMIUM_REQUEST_TIMEOUT=30s
  - LIBREOFFICE_REQUEST_TIMEOUT=30s
```

**PDF output is blank or incomplete:**
```bash
# Add wait delay for JavaScript-heavy pages
Gotenberg-Chromium-Wait-Delay: 3s

# Ensure page fully loads before conversion
Gotenberg-Chromium-Wait-For-Selector: .content-ready  # CSS selector

# For Office docs: Check if file is corrupted
# Gotenberg uses LibreOffice - test opening file in LibreOffice first
```

**Images not loading in PDF:**
```bash
# Use base64 embedded images in HTML instead of external URLs
<img src="data:image/png;base64,iVBORw0KG..." />

# Or ensure external URLs are accessible from Gotenberg container
# Add extra headers if needed:
Gotenberg-Chromium-Extra-Http-Headers: {"Authorization": "Bearer token"}

# For local file references, include them as additional files in request
```

**Invalid multipart/form-data in n8n:**
```bash
# Common mistake: Using wrong binary reference
# Correct:
Body Parameters:
  files = {{ $binary.data }}  # Select "Binary Data" from dropdown

# Incorrect:
  files = {{ $json.html }}  # This sends JSON, not binary

# Make sure to convert HTML string to binary first (use Code Node)
```

**LibreOffice conversion fails:**
```bash
# Check LibreOffice is running
docker exec gotenberg ps aux | grep soffice

# Check supported formats
# .docx, .xlsx, .pptx work best
# .doc, .xls, .ppt (older formats) may have issues

# Increase memory if converting large files
# docker-compose.yml:
services:
  gotenberg:
    image: gotenberg/gotenberg:8
    deploy:
      resources:
        limits:
          memory: 2G  # Increase from default 1G
```

**n8n connection refused:**
```bash
# Check Docker network
docker network inspect ai-corekit_default
# Verify gotenberg and n8n are on same network

# Test internal connection from n8n container
docker exec n8n curl http://gotenberg:3000/health

# If fails, restart both services
docker compose restart gotenberg n8n
```

### Advanced Features

**Custom Headers for PDF Metadata:**

```javascript
// HTTP Request Node Headers
Headers:
  Gotenberg-Output-Filename: report.pdf
  Gotenberg-Pdf-Metadata-Author: John Doe
  Gotenberg-Pdf-Metadata-Title: Monthly Sales Report
  Gotenberg-Pdf-Metadata-Subject: Sales Analytics
  Gotenberg-Pdf-Metadata-Keywords: sales, report, analytics
  Gotenberg-Pdf-Metadata-Creator: AI CoreKit n8n
```

**Webhook for Asynchronous Processing:**

```javascript
// Useful for very large documents or batch processing
Headers:
  Gotenberg-Webhook-Url: https://n8n.yourdomain.com/webhook/pdf-complete
  Gotenberg-Webhook-Method: POST
  Gotenberg-Webhook-Error-Url: https://n8n.yourdomain.com/webhook/pdf-error
```

**PDF/A Archival Format:**

```javascript
// Convert to PDF/A-1b for long-term archiving
Headers:
  Gotenberg-Pdf-Format: PDF/A-1b
  Gotenberg-Pdf-Universal-Access: true  // PDF/UA for accessibility
```

**Custom Paper Size & Margins:**

```javascript
// Custom page dimensions
Headers:
  Gotenberg-Chromium-Paper-Width: 8.5   // inches
  Gotenberg-Chromium-Paper-Height: 11   // inches
  Gotenberg-Chromium-Margin-Top: 0.5    // inches
  Gotenberg-Chromium-Margin-Bottom: 0.5
  Gotenberg-Chromium-Margin-Left: 0.5
  Gotenberg-Chromium-Margin-Right: 0.5
  Gotenberg-Chromium-Landscape: false
```

### Resources

- **Official Website:** https://gotenberg.dev
- **Documentation:** https://gotenberg.dev/docs/getting-started/introduction
- **API Reference:** https://gotenberg.dev/docs/routes
- **Configuration Guide:** https://gotenberg.dev/docs/configuration
- **GitHub Repository:** https://github.com/gotenberg/gotenberg
- **Docker Hub:** https://hub.docker.com/r/gotenberg/gotenberg
- **n8n Community Examples:** https://n8n.io/workflows?search=gotenberg
- **Support:** https://github.com/gotenberg/gotenberg/discussions

### Best Practices

**HTML to PDF Optimization:**
- Use inline CSS instead of external stylesheets for faster rendering
- Embed images as base64 data URIs to avoid external dependencies
- Test HTML in Chrome browser first (Gotenberg uses Chromium)
- Use print media queries: `@media print { ... }`
- Set explicit page breaks: `page-break-after: always;`

**Performance Optimization:**
- Use LibreOffice for Office docs, Chromium for HTML/URLs
- Batch process multiple conversions in parallel (Gotenberg is stateless)
- Set appropriate timeouts based on document complexity
- For high volume: Deploy multiple Gotenberg instances behind load balancer
- Use webhooks for async processing of large documents

**Error Handling in n8n:**
- Always add error workflow branches for timeout/conversion failures
- Validate binary data before sending to Gotenberg
- Log failed conversions for debugging
- Implement retry logic with exponential backoff

**Security Considerations:**
- Gotenberg has no built-in authentication - secure with reverse proxy/firewall
- Sanitize HTML input to prevent XSS in generated PDFs
- Limit file upload sizes to prevent DoS attacks
- Use internal Docker network for n8n ↔ Gotenberg communication
- Never expose Gotenberg port directly to the internet

**Resource Management:**
- Gotenberg uses ~500MB-1GB RAM per instance
- LibreOffice conversions are more memory-intensive than Chromium
- Monitor container resources: `docker stats gotenberg`
- Set memory limits in docker-compose.yml for production
- Clean up temporary files if custom deployment (not needed with Docker)

### Integration with AI CoreKit Services

**Gotenberg + n8n:**
- Automate document generation workflows
- Convert form submissions to PDFs
- Generate invoices, reports, certificates
- Archive web content on schedule

**Gotenberg + Supabase:**
- Store generated PDFs in Supabase Storage
- Trigger PDF generation from database events
- Build document management systems

**Gotenberg + Open WebUI:**
- Generate conversation transcripts as PDFs
- Export AI chat histories for archiving
- Create formatted reports from AI outputs

**Gotenberg + Ollama:**
- Generate AI-written reports and convert to PDF
- Create AI-generated invoices/documents
- Combine LLM content generation + PDF conversion pipeline

**Gotenberg + Cal.com:**
- Generate meeting confirmation PDFs
- Create appointment summaries
- Export calendar schedules as PDFs

**Gotenberg + Vikunja:**
- Export task lists and project plans to PDF
- Generate project reports
- Archive completed project documentation
