# 📋 Stirling-PDF - PDF-Toolkit

### Was ist Stirling-PDF?

Stirling-PDF ist ein umfassendes, lokal gehostetes webbasiertes PDF-Manipulations-Toolkit mit über 100 Funktionen. Es bietet eine vollständige Lösung für alle deine PDF-Anforderungen, von grundlegenden Operationen wie Zusammenführen und Aufteilen bis hin zu erweiterten Funktionen wie OCR, digitalen Signaturen, Formularverarbeitung und Sicherheitsfunktionen. Mit Fokus auf Datenschutz erfolgt die gesamte Verarbeitung auf deinem Server - keine Daten werden an externe Dienste gesendet. Mit integrierter Benutzerverwaltung und REST-API ist es ideal für manuelle Operationen über die Web-UI und automatisierte Workflows via n8n-Integration.

### Features

- **100+ PDF-Operationen** - Zusammenführen, Aufteilen, Drehen, Komprimieren, Konvertieren, Signieren, Wasserzeichen und mehr
- **OCR-Unterstützung** - Extrahiere Text aus gescannten Dokumenten mit Tesseract OCR in 50+ Sprachen
- **Dokumentenkonvertierung** - PDF ↔ Word/Excel/PowerPoint, Bilder zu PDF, HTML zu PDF
- **Sicherheit & Compliance** - Passwortschutz, Verschlüsselung, digitale Signaturen, Metadatenentfernung, Schwärzung
- **Formularverarbeitung** - Extrahiere Formulardaten, fülle Formulare programmatisch, flache Formulare
- **PDF/A-Archivierung** - Konvertiere in Langzeitarchivformate für Compliance
- **Batch-Verarbeitung** - Verarbeite mehrere Dateien gleichzeitig
- **API-First Design** - Vollständige REST-API für Automatisierung und Integration
- **Benutzerverwaltung** - Multi-User-Unterstützung mit Authentifizierung und Berechtigungen
- **Keine externen Abhängigkeiten** - Alle Verarbeitung erfolgt lokal, vollständiger Datenschutz
- **Web-UI** - Benutzerfreundliche Oberfläche für manuelle Operationen
- **Open Source** - Kostenlos, transparent und anpassbar

### Ersteinrichtung

**Erstes Login bei Stirling-PDF:**

1. Navigiere zu `https://pdf.yourdomain.com`
2. **Login mit Zugangsdaten aus Installation:**
   - Benutzername: Deine E-Mail-Adresse (während Installation festgelegt)
   - Passwort: Prüfe `.env`-Datei für `STIRLING_PASSWORD`
3. Erkunde die Web-Oberfläche für manuelle Operationen
4. **API-Dokumentation verfügbar unter:** `https://pdf.yourdomain.com/swagger-ui/index.html`

**Standard-Passwort ändern:**

```bash
# .env-Datei bearbeiten
nano .env

# Finde und aktualisiere:
STIRLING_PASSWORD=your-new-secure-password

# Starte Stirling-PDF neu
docker compose restart stirling-pdf
```

**Installation verifizieren:**

```bash
# Prüfe ob Stirling-PDF läuft
docker ps | grep stirling-pdf

# Teste API-Endpunkt
curl http://localhost:8080/api/v1/info/status

# Logs anzeigen
docker logs stirling-pdf --tail 50
```

### n8n Integration Setup

**Keine Zugangsdaten benötigt!** Die Stirling-PDF API kann direkt von n8n mit HTTP Request Nodes aufgerufen werden.

**Interne URL:** `http://stirling-pdf:8080`

**API-Basispfad:** `/api/v1/`

**Authentifizierung:** Session Cookie oder API-Schlüssel (falls in Stirling-PDF Einstellungen konfiguriert)

**Grundlegendes Integrationsmuster:**

1. Füge in n8n einen **HTTP Request** Node hinzu
2. Konfiguriere:
   - **Methode:** POST (die meisten Operationen)
   - **URL:** `http://stirling-pdf:8080/api/v1/[operation]`
   - **Body Content Type:** Multipart-Form Data
   - **Body-Parameter:** Füge deine PDF-Dateien und Operations-Parameter hinzu
3. Führe aus um verarbeitete PDF-Binärausgabe zu erhalten

**API-Dokumentation:**

- Swagger UI: `https://pdf.yourdomain.com/swagger-ui/index.html`
- Alle verfügbaren Endpunkte und Parameter dokumentiert
- Teste Operationen direkt in Swagger UI vor dem Erstellen von Workflows

### Beispiel-Workflows

#### Beispiel 1: Rechnungsverarbeitungs-Pipeline

Extrahiere automatisch Text aus Rechnungen und parse Daten.

```javascript
// 1. Email Trigger Node
Trigger: Bei neuer E-Mail empfangen
Filter: Betreff enthält "Rechnung"
Anhänge herunterladen: Ja

// 2. Filter Node - Only Process PDFs
Bedingung: {{ $binary.data.mimeType }} === 'application/pdf'

// 3. HTTP Request Node - Extract Text with OCR
Methode: POST
URL: http://stirling-pdf:8080/api/v1/convert/pdf-to-text
Body Content Type: Multipart-Form Data

Body Parameter:
  Datei: {{ $binary.data }}  // PDF-Anhang
  outputFormat: txt
  ocrLanguages: eng  // oder "deu" für Deutsch

// 4. Code Node - Parse Invoice Data
const text = $json.text;

// Extrahiere Rechnungsdetails mit Regex
const invoiceNumber = text.match(/Rechnung #:?\s*(\d+)/i)?.[1];
const invoiceDate = text.match(/Datum:?\s*([\d-/]+)/i)?.[1];
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

// 5. IF Node - Daten validieren
Bedingung: {{ $json.invoice_number }} && {{ $json.total > 0 }}

// 6. Supabase/Baserow Node - Rechnungsdaten speichern
Tabelle: invoices
Operation: Einfügen
Daten: {{ $json }}

// 7. Slack-Benachrichtigung
Kanal: #finance
Nachricht: |
  💰 **Neue Rechnung verarbeitet**
  
  Rechnung #: {{ $json.invoice_number }}
  Lieferant: {{ $json.vendor }}
  Betrag: ${{ $json.total }}
  Datum: {{ $json.date }}

// 8. Error Branch - Manual Review Needed
Slack: #finance-errors
Nachricht: |
  ⚠️ Invoice processing failed - manual review needed
  Attachment: {{ $('Email Trigger').json.subject }}
```

#### Example 2: Document Watermarking Workflow

Add watermarks and password protection to sensitive documents.

```javascript
// 1. Webhook Trigger
Methode: POST
Pfad: /protect-document
Authentication: Header Auth

// 2. HTTP Request Node - Add Watermark
Methode: POST
URL: http://stirling-pdf:8080/api/v1/security/add-watermark
Body Content Type: Multipart-Form Data

Body Parameter:
  Datei: {{ $binary.data }}
  watermarkText: CONFIDENTIAL - {{ $now.format('YYYY-MM-DD') }}
  fontSize: 48
  opacity: 0.3
  rotation: 45
  watermarkType: text
  alphabet: roman  // or "arabic", "japanese", etc.

// 3. HTTP Request Node - Add Password Protection
Methode: POST
URL: http://stirling-pdf:8080/api/v1/security/add-password
Body Content Type: Multipart-Form Data

Body Parameter:
  Datei: {{ $json.data }}  // Watermarked PDF from previous step
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
Nachricht: |
  You have received a confidential document.
  
  Password: {{ $json.password }}
  
  Please keep this password secure and do not share.

Anhänge: {{ $binary.protected_pdf }}

// 6. Supabase Storage - Archive Protected Document
Bucket: confidential-documents
Pfad: {{ $now.format('YYYY/MM') }}/{{ $('Webhook').json.filename }}
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
Methode: GET
URL: {{ $json.url }}
Response Format: File

// 5. Aggregate to Array Node
// Collect all downloaded PDFs

// 6. HTTP Request Node - Merge PDFs
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/merge-pdfs
Body Content Type: Multipart-Form Data

Body Parameter:
  files: {{ $binary.data0 }}  // Erstes PDF
  files: {{ $binary.data1 }}  // Zweites PDF
  files: {{ $binary.data2 }}  // Third PDF
  sortType: alphabetical

// Hinweis: Add all PDFs as separate "files" parameters with same name

// 7. HTTP Request Node - Add Table of Contents
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/add-page-numbers
Body Parameter:
  Datei: {{ $binary.data }}
  position: footer-center
  startingNumber: 1
  customMargins: {"top": 10, "bottom": 10, "left": 10, "right": 10}

// 8. HTTP Request Node - Split by Page Numbers (Optional)
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/split-pdfs
Body Parameter:
  Datei: {{ $binary.data }}
  pageNumbers: 1-10,11-20,21-30  // Split into 3 sections

// 9. Google Drive Upload Node
Folder: /Reports/Daily/{{ $now.format('YYYY-MM-DD') }}
File Name: daily-report-{{ $now.format('YYYY-MM-DD') }}.pdf
Binary Daten: {{ $binary.data }}

// 10. Slack Notification
Kanal: #reports
Nachricht: |
  📊 **Daily Report Generated**
  
  Datum: {{ $now.format('YYYY-MM-DD') }}
  Sections: Sales, Finance, Operations
  
  [View Report](https://drive.google.com/...)
```

#### Example 4: Form Processing Pipeline

Extract and validate PDF form data automatically.

```javascript
// 1. Webhook Trigger
Pfad: /process-form
Methode: POST
Content Type: multipart/form-data

// 2. HTTP Request Node - Extract Form Data
Methode: POST
URL: http://stirling-pdf:8080/api/v1/convert/pdf-to-json
Body Content Type: Multipart-Form Data

Body Parameter:
  Datei: {{ $binary.formPdf }}

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
Operation: Einfügen
Daten: {{ $json }}

// 5. HTTP Request Node - Flatten Form (Remove Bearbeiteability)
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/flatten
Body Parameter:
  Datei: {{ $('Webhook').binary.formPdf }}

// 6. Google Drive Upload - Archive Flattened Form
Folder: /Forms/Submissions/{{ $now.format('YYYY-MM') }}
File Name: {{ $json.full_name }}-{{ $now.format('YYYY-MM-DD-HHmmss') }}.pdf
Binary Daten: {{ $binary.data }}

// 7. Email Node - Confirmation to Submitter
To: {{ $json.email }}
Subject: Form Submission Received
Nachricht: |
  Dear {{ $json.full_name }},
  
  Thank you for your submission. We have received your application form.
  
  Reference ID: {{ $json.id }}
  Submitted: {{ $json.submitted_at }}
  
  We will review your application and contact you within 3-5 business days.

// 8. Slack Notification - Internal Team
Kanal: #new-submissions
Nachricht: |
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
Dateityp: PDF

// 2. Google Drive Download
File: {{ $json.id }}

// 3. HTTP Request Node - Auto-Redact SSNs and Credit Cards
Methode: POST
URL: http://stirling-pdf:8080/api/v1/security/auto-redact
Body Content Type: Multipart-Form Data

Body Parameter:
  Datei: {{ $binary.data }}
  redactPattern: (?:\d{3}-\d{2}-\d{4})|(?:\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4})
  // Regex for SSN (###-##-####) and Credit Card numbers
  color: black
  wholeWordSearchOnly: false
  redactType: regex

// 4. HTTP Request Node - Redact Email Addresses
Methode: POST
URL: http://stirling-pdf:8080/api/v1/security/auto-redact
Body Parameter:
  Datei: {{ $binary.data }}
  redactPattern: [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
  color: black

// 5. HTTP Request Node - Remove Metadata
Methode: POST
URL: http://stirling-pdf:8080/api/v1/security/sanitize-pdf
Body Parameter:
  Datei: {{ $binary.data }}
  removeMetadata: true
  removeLinks: false
  removeJavaScript: true
  removeEmbeddedFiles: true
  removeFormFields: false

// 6. HTTP Request Node - Compress Redacted PDF
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/compress-pdf
Body Parameter:
  Datei: {{ $binary.data }}
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
Binary Daten: {{ $binary.redacted_pdf }}

// 9. Slack Notification
Kanal: #legal
Nachricht: |
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

**Sicherheit:**
- Add/remove passwords
- Add watermarks (text/image)
- Digital signatures
- Certificate signing
- Redact content (manual or auto with regex)
- Remove metadata
- Sanitize PDFs (remove scripts, links, embedded files)
- Encrypt/decrypt PDFs

**Forms & Daten:**
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

### Fehlerbehebung

**PDF Processing Fails:**
```bash
# Prüfe Stirling-PDF Logs
docker logs stirling-pdf --tail 100

# Verify service is running
docker ps | grep stirling-pdf

# Teste API-Endpunkt
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

# Starte Stirling-PDF neu after installing languages
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

# Prüfe Docker-Netzwerk
docker network inspect ai-corekit_default
# Verify both stirling-pdf and n8n are on same network

# Starte beide Services neu
docker compose restart stirling-pdf n8n
```

**Conversion Errors:**
```bash
# LibreOffice conversion issues
# Check if LibreOffice is running
docker exec stirling-pdf ps aux | grep soffice

# For corrupted Office files, try repairing first in MS Office

# Prüfe unterstützte Formate
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

### Erweiterte Funktionen

**Pipeline Mode:**

Execute multiple operations in a single API call for complex workflows.

```javascript
// HTTP Request Node - Multi-Step Pipeline
Methode: POST
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

**Performance-Optimierung:**

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
7. **Batch-Verarbeitung** - Nutze Schleifen mit Wait-Nodes um Stirling-PDF nicht zu überlasten

### Ressourcen

- **Offizielle Dokumentation:** https://docs.stirlingpdf.com
- **API-Referenz (Swagger):** `https://pdf.yourdomain.com/swagger-ui/index.html`
- **GitHub Repository:** https://github.com/Stirling-Tools/Stirling-PDF
- **Community-Diskussionen:** https://github.com/Stirling-Tools/Stirling-PDF/discussions
- **Feature-Anfragen:** https://github.com/Stirling-Tools/Stirling-PDF/issues
- **n8n Community-Beispiele:** https://n8n.io/workflows?search=stirling
- **Docker Hub:** https://hub.docker.com/r/stirlingtools/s-pdf

### Integration mit AI CoreKit Services

**Stirling-PDF + Gotenberg:**
- Nutze Gotenberg für HTML → PDF Generierung
- Nutze Stirling-PDF für PDF-Manipulation (zusammenführen, aufteilen, Sicherheit)
- Pipeline: Gotenberg (erstellen) → Stirling-PDF (verbessern)

**Stirling-PDF + Ollama:**
- Extrahiere Text aus PDFs mit Stirling OCR
- Verarbeite Text mit lokalen Ollama LLMs
- Generiere Zusammenfassungen, extrahiere Entitäten, klassifiziere Dokumente

**Stirling-PDF + Supabase:**
- Speichere verarbeitete PDFs in Supabase Storage
- Verfolge Dokument-Metadaten in Supabase-Datenbank
- Triggere Verarbeitung aus Datenbank-Events

**Stirling-PDF + n8n:**
- Vollständige Dokumenten-Automatisierungs-Pipelines
- Rechnungsverarbeitung, Formular-Handling, Vertragsmanagement
- Geplante Batch-Operationen

**Stirling-PDF + Open WebUI:**
- Konvertiere Chat-Transkripte zu PDF-Berichten
- Archiviere KI-Konversationen mit Wasserzeichen
- Generiere formatierte Dokumentation

**Stirling-PDF + Cal.com:**
- Generiere Meeting-Bestätigungs-PDFs
- Erstelle Termin-Dokumentation
- Exportiere Kalender-Zusammenfassungen

**Stirling-PDF + Invoice Ninja:**
- Extrahiere Rechnungsdaten aus PDF-Uploads
- Automatisches Ausfüllen von Rechnungsfeldern
- Archiviere bezahlte Rechnungen mit Wasserzeichen
