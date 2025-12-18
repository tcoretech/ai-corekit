# 🤖 Paperless AI Extensions - LLM-Powered OCR & RAG Chat

### What are Paperless AI Extensions?

The Paperless AI Extensions are two complementary tools that supercharge your Paperless-ngx installation with advanced AI capabilities:

- **paperless-gpt** - Superior OCR using Vision LLMs (GPT-4o, Claude, Ollama) for accurate text extraction from poor quality scans
- **paperless-ai** - RAG-powered chat interface for natural language document search and Q&A

Together, they transform Paperless-ngx from a document archive into an intelligent document assistant that can answer questions like "What was my electricity bill last month?" or "Show me all contracts expiring this year."

### ⚠️ CRITICAL Setup Requirements

**This suite requires manual configuration after installation. Follow these steps EXACTLY:**

#### Step 1: Generate API Token with Full Permissions
1. Open Paperless-ngx → Settings → Django Admin Panel
2. Click on "Auth tokens" → "Add"
3. Select your user and save
4. Click the pencil icon to edit the token
5. In the popup under "Permissions" click "Choose all permissions"
6. Save and copy the token

#### Step 2: Configure Environment
1. Add token to `.env` file:
```bash
   nano .env
   # Add/update: PAPERLESS_API_TOKEN=your_token_here
```

2. **CRITICAL: Full restart required for token to load:**
```bash
   docker compose -p localai down
   docker compose -p localai up -d
```
   ⚠️ Simple restart is NOT enough - must use `down` then `up -d`!

#### Step 3: Configure paperless-gpt
- Access: `https://paperless-gpt.yourdomain.com`
- Login with Basic Auth (username/password from .env)
- Should now connect successfully to Paperless

#### Step 4: Configure paperless-ai
1. Access: `https://paperless-ai.yourdomain.com`
2. First visit shows setup wizard
3. Create your own username/password (remember them!)
4. Enter configuration:
   - Paperless URL: `http://paperless-ngx:8000`
   - API Token: (paste the token from Step 1)
   - Ollama URL: `http://ollama:11434` (if using)

#### Step 5: Fix RAG Chat (REQUIRED)
```bash
# This fixes a bug where paperless-ai uses different ENV variable names
docker exec paperless-ai sh -c "echo 'PAPERLESS_URL=http://paperless-ngx:8000' >> /app/data/.env"
docker compose -p localai restart paperless-ai
```

### Known Issues & Workarounds

| Issue | Impact | Workaround |
|-------|---------|-----------|
| **paperless-gpt: Documents need tags** | Can't update documents without at least one tag | Add a default tag like "inbox" to all documents |
| **paperless-ai: Inconsistent ENV names** | RAG chat shows "your-paperless-instance" error | Apply Step 5 fix above |
| **Token not loading after update** | Services show "401 Unauthorized" | Use full restart with `docker compose -p localai down` then `up -d` |

### Features Comparison

| Feature | paperless-gpt | paperless-ai |
|---------|--------------|--------------|
| **LLM-based OCR** | ✅ GPT-4o, MiniCPM-V | ❌ |
| **Searchable PDFs** | ✅ With text layers | ❌ |
| **Auto-Tagging** | ✅ AI-powered | ✅ Rule-based |
| **RAG Chat** | ❌ | ✅ Main feature |
| **Semantic Search** | ❌ | ✅ "Find similar" |
| **Batch Processing** | ✅ Queue system | ❌ |
| **Multi-language** | ✅ Configurable | ✅ Auto-detect |
| **Authentication** | Basic Auth (Caddy) | Own system |

### Configuration Options

**Default (CPU-friendly, using OpenAI):**
```yaml
PAPERLESS_GPT_LLM_PROVIDER=openai
PAPERLESS_GPT_LLM_MODEL=gpt-4o-mini
PAPERLESS_GPT_VISION_MODEL=gpt-4o-mini
```

**Local Processing (using Ollama):**
```yaml
PAPERLESS_GPT_LLM_PROVIDER=ollama
PAPERLESS_GPT_LLM_MODEL=qwen2.5:7b
PAPERLESS_GPT_VISION_MODEL=minicpm-v
```

### Usage Examples

#### paperless-gpt OCR Processing
1. Tag document with `paperless-gpt` for manual processing
2. Tag with `paperless-gpt-ocr-auto` for automatic OCR
3. Access web UI at `/manual` to review and confirm
4. Check status at `/ocr` tab

#### paperless-ai Natural Language Search
- "Show me all invoices from last month"
- "What was my electricity bill in January?"
- "Find contracts expiring this year"
- "Which documents mention GDPR?"

### Troubleshooting

**Token Issues:**
```bash
# Verify token in .env
grep PAPERLESS_API_TOKEN .env

# Check if token loads in container
docker exec paperless-gpt env | grep PAPERLESS_API_TOKEN

# If missing, full restart required:
docker compose -p localai down
docker compose -p localai up -d
```

**RAG Not Working:**
```bash
# Check for "your-paperless-instance" error
docker logs paperless-ai | grep "your-paperless"

# Apply fix:
docker exec paperless-ai sh -c "echo 'PAPERLESS_URL=http://paperless-ngx:8000' >> /app/data/.env"
docker compose -p localai restart paperless-ai
```

**Reset paperless-ai (loses settings):**
```bash
docker compose -p localai stop paperless-ai
docker volume rm localai_paperless-ai-data
docker compose -p localai up -d paperless-ai
```

### Resources
- **RAM:** ~1GB additional for both services
- **Disk:** ~500MB for vector databases
- **API Costs:** ~$0.001 per page with GPT-4o-mini

### Documentation
- **paperless-gpt:** https://github.com/icereed/paperless-gpt
- **paperless-ai:** https://github.com/clusterzx/paperless-ai
- **Installation Guide:** See final report after running `bash scripts/06_final_report.sh`


### What is Paperless-ngx?

Paperless-ngx is a powerful document management system that transforms your physical documents into a searchable online archive. It automatically performs OCR on scanned documents, uses AI to tag and categorize them, and provides a clean web interface for managing your digital paperwork. With support for multiple languages, automatic matching algorithms, and GDPR-compliant storage, it's the perfect solution for going paperless while maintaining full control over your data.

### Features

- **OCR Processing** - Automatic text recognition in 100+ languages (configured for German + English)
- **AI Auto-Tagging** - Machine learning automatically categorizes documents
- **Smart Matching** - Learns from your behavior to improve document classification
- **Full-Text Search** - Search inside all documents, even scanned PDFs
- **Document Types** - Automatic detection of invoices, contracts, letters, etc.
- **Correspondent Detection** - Identifies senders/companies automatically
- **Archive Versions** - Keeps original + searchable PDF/A archive version
- **Mobile Apps** - iOS and Android apps for scanning and access
- **Email Import** - Process documents from email attachments
- **Barcode Support** - Use barcodes for document separation and tagging

### Initial Setup

**First Login to Paperless-ngx:**

1. Navigate to `https://docs.yourdomain.com`
2. Login with:
   - **Username:** Your configured email
   - **Password:** Check `.env` file for `PAPERLESS_ADMIN_PASSWORD`
3. Initial configuration:
   - Set your preferred language
   - Configure date format
   - Enable/disable auto-tagging

**Create Document Structure:**

1. **Tags** → Create categories:
   - `Invoice`, `Contract`, `Receipt`, `Personal`, `Work`
2. **Correspondents** → Add common senders:
   - Companies you deal with regularly
3. **Document Types** → Define types:
   - `Bill`, `Letter`, `Report`, `Form`

**Generate API Token:**

1. Go to **Settings** → **Users & Groups**
2. Click on your username
3. Under **Auth Token**, click **Generate**
4. Copy and save the token

### Consume Folder Setup

**Automatic Document Import:**

The consume folder (`./shared`) is monitored for new documents:

```bash
# Upload documents via:
# 1. Direct copy to server
scp invoice.pdf user@server:~/ai-launchkit/shared/

# 2. Via Seafile (if installed)
# Upload to Seafile → paperless-bridge folder

# 3. Via n8n workflow
# HTTP endpoint → Save to consume folder
```

**Folder Structure for Auto-Tagging:**

```
./shared/
├── invoices/     # Auto-tagged as "Invoice"
├── contracts/    # Auto-tagged as "Contract"  
├── receipts/     # Auto-tagged as "Receipt"
└── incoming/     # General documents
```

### n8n Integration

#### Example 1: Email Attachment Processing

```javascript
// Process email attachments automatically

// 1. Email Trigger (IMAP) - Check for new emails
Account: Your email credentials
Folder: INBOX
Filters: Has attachments

// 2. Loop - For each attachment

// 3. IF Node - Check if PDF or image
Condition: {{$binary.attachment.mimeType}} contains "pdf" OR "image"

// 4. HTTP Request - Upload to Paperless
Method: POST
URL: http://paperless:8000/api/documents/post_document/
Headers:
  Authorization: Token {{$credentials.paperless_token}}
Body: Binary attachment
Additional Fields:
  title: Email from {{$json.from}} - {{$json.subject}}
  correspondent: {{$json.from}}
  tags: email,inbox

// 5. Move email to processed folder
Operation: Move Message
Folder: Processed
```

#### Example 2: Invoice Processing Workflow

```javascript
// Extract data from invoices and create accounting entries

// 1. Paperless Webhook - Document added
// Configure webhook in Paperless settings

// 2. HTTP Request - Get document details
Method: GET
URL: http://paperless:8000/api/documents/{{$json.document_id}}/
Headers:
  Authorization: Token {{$credentials.paperless_token}}

// 3. IF Node - Check if invoice
Condition: {{$json.document_type}} == "Invoice"

// 4. HTTP Request - Get document content
Method: GET  
URL: http://paperless:8000/api/documents/{{$json.id}}/download/
Headers:
  Authorization: Token {{$credentials.paperless_token}}

// 5. OpenAI Node - Extract invoice data
Prompt: |
  Extract the following from this invoice:
  - Invoice number
  - Date
  - Total amount
  - VAT amount
  - Supplier name
  Return as JSON.

// 6. Google Sheets Node - Add to accounting
Operation: Append
Sheet: Invoices 2024
Values: Extracted data

// 7. Send notification
Channel: #accounting
Message: New invoice processed: {{$json.invoice_number}}
```

#### Example 3: Document Retention Policy

```javascript
// Automatically archive old documents

// 1. Schedule Trigger - Monthly
Cron: 0 0 1 * *

// 2. HTTP Request - Get old documents
Method: GET
URL: http://paperless:8000/api/documents/
Query Parameters:
  created__lt: {{$now.minus(7, 'years').format('YYYY-MM-DD')}}
  
// 3. Loop - For each document

// 4. HTTP Request - Add archive tag
Method: PATCH
URL: http://paperless:8000/api/documents/{{$json.id}}/
Body:
  tags: [...existing_tags, "archived"]
  
// 5. Backup to cold storage
// Move to S3/Backblaze/external drive
```

### Mobile Scanning

**Mobile Apps:**
- **iOS:** [Paperless Mobile](https://apps.apple.com/app/paperless-mobile/id1556098941)
- **Android:** [Paperless Mobile](https://play.google.com/store/apps/details?id=de.astubenbord.paperless_mobile)

**App Configuration:**
1. Server URL: `https://docs.yourdomain.com`
2. Username: Your email
3. Password: Your password

**Scanning Workflow:**
1. Open mobile app
2. Tap camera icon
3. Scan document (auto-crop and enhance)
4. Add tags/correspondent (optional)
5. Upload → Automatic OCR processing

### Advanced Features

**Custom Matching Rules:**

Create rules for automatic document processing:

1. **Settings** → **Matching**
2. Add rule:
   - **Pattern:** "Invoice No."
   - **Document Type:** Invoice
   - **Tags:** Add "needs-payment"

**Email Processing Rules:**

Configure email import:

1. **Settings** → **Mail**
2. Add IMAP account
3. Set rules:
   - From `amazon@email.amazon.com` → Tag "Amazon", "Receipt"
   - Subject contains "Invoice" → Document type "Invoice"

### Troubleshooting

**OCR Not Working:**
```bash
# Check if OCR languages are installed
docker exec paperless-ngx ls /usr/share/tesseract-ocr/*/

# Reinstall language packs
docker exec paperless-ngx apt-get update
docker exec paperless-ngx apt-get install tesseract-ocr-deu tesseract-ocr-eng

# Restart service
docker compose restart paperless
```

**Cannot Upload Documents:**
```bash
# Check permissions on consume folder
ls -la ./shared/

# Fix permissions
sudo chown -R 1000:1000 ./shared/

# Check Paperless logs
docker logs paperless-ngx --tail 100 | grep ERROR
```

**Database Issues:**
```bash
# Check PostgreSQL status
docker ps | grep paperless-postgres

# Check database logs
docker logs paperless-postgres --tail 50

# Run database migrations
docker exec paperless-ngx python manage.py migrate
```

**Search Not Working:**
```bash
# Rebuild search index
docker exec paperless-ngx python manage.py document_index reindex

# Check Redis connection
docker exec paperless-ngx python manage.py shell
>>> from django.core.cache import cache
>>> cache.set('test', 'value')
>>> cache.get('test')
```

### Backup & Migration

**Backup Documents:**
```bash
# Export all documents with metadata
docker exec paperless-ngx python manage.py document_exporter ../export

# Backup location: ./export/
# Includes: Documents, metadata, database dump
```

**Restore Documents:**
```bash
# Import from backup
docker exec paperless-ngx python manage.py document_importer ../export
```

### Performance Tips

- **OCR Settings:** Use `skip` mode for already-OCR'd PDFs
- **Parallel Processing:** Increase `PAPERLESS_TASK_WORKERS` for faster processing
- **Thumbnail Generation:** Disable for text-only documents
- **Database:** PostgreSQL performs better than SQLite for large archives
- **Storage:** Use SSD for media directory for better performance

### GDPR Compliance

Paperless-ngx helps with GDPR compliance:

- **Retention Policies:** Automatic document deletion after X years
- **Access Logs:** Track who accessed which documents
- **Encryption:** Optional GPG encryption for sensitive documents
- **Data Export:** Export all data for data portability
- **Right to Delete:** Bulk delete by correspondent

### Resources

- **Official Documentation:** https://docs.paperless-ngx.com/
- **API Documentation:** https://docs.paperless-ngx.com/api/
- **GitHub:** https://github.com/paperless-ngx/paperless-ngx
- **Community Forum:** https://github.com/paperless-ngx/paperless-ngx/discussions
- **Mobile Apps:** https://github.com/astubenbord/paperless-mobile
- **Backup Strategy:** https://docs.paperless-ngx.com/administration/#backup
