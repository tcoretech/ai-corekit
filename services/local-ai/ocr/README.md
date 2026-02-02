# 👁️ OCR Bundle - Text Extraction

### What is the OCR Bundle?

The OCR Bundle provides two complementary OCR (Optical Character Recognition) engines that work together to extract text from images and PDFs: **Tesseract** for speed and clean documents, and **EasyOCR** for quality on photos and complex documents. This dual-engine approach ensures you have the right tool for every document type.

### Features

- **Dual Engine Approach**: Tesseract (fast) + EasyOCR (quality) for optimal results
- **90+ Languages**: Tesseract supports 90+ languages, EasyOCR supports 80+
- **Multiple Document Types**: Images (JPG, PNG, TIFF), PDFs, scanned documents
- **Handwriting Support**: EasyOCR handles handwritten text better than Tesseract
- **PSM Modes**: Tesseract's Page Segmentation Modes for different document layouts
- **REST APIs**: Both engines accessible via HTTP for easy n8n integration
- **Automatic Language Detection**: EasyOCR can detect language automatically

### Initial Setup

**Both services are deployed internally (no direct web access):**

- **Tesseract URL**: `http://tesseract-ocr:8884`
- **EasyOCR URL**: `http://easyocr:2000`
- **Authentication**: EasyOCR requires secret key (from `.env`)
- **No Web UI**: API-only services for automation

**Performance:**
- **Tesseract**: ~3-4 seconds per image (consistent speed)
- **EasyOCR**: ~7-8 seconds per image (first request ~30s for model loading)

### n8n Integration Setup

**Tesseract: No credentials needed** - Simple HTTP Request Node

**EasyOCR: Requires API Key:**
1. Find key in `.env` file: `EASYOCR_SECRET_KEY`
2. Use in HTTP Request Node body

**Internal URLs:**
- **Tesseract**: `http://tesseract-ocr:8884`
- **EasyOCR**: `http://easyocr:2000`

### Example Workflows

#### Example 1: Smart OCR Engine Selection

```javascript
// Automatically choose the best OCR engine based on document type

// 1. Trigger Node (Webhook, Email, Google Drive, etc.)
// Receives document/image

// 2. Code Node - Analyze Document and Choose Engine
const fileType = $binary.data.mimeType;
const fileName = $binary.data.fileName || '';
const fileSize = $binary.data.fileSize;

let ocrEngine = 'tesseract'; // Default: fast engine
let reasoning = '';

// Decision logic
if (fileType.includes('jpeg') || fileType.includes('png')) {
  // Photos typically need better quality
  if (fileName.toLowerCase().includes('receipt') || 
      fileName.toLowerCase().includes('invoice') ||
      fileName.toLowerCase().includes('photo')) {
    ocrEngine = 'easyocr';
    reasoning = 'Photo/receipt detected - using EasyOCR for better quality';
  } else {
    ocrEngine = 'tesseract';
    reasoning = 'Clean image - using Tesseract for speed';
  }
} else if (fileType.includes('pdf')) {
  // PDFs are usually scanned documents (clean)
  ocrEngine = 'tesseract';
  reasoning = 'PDF document - using Tesseract for speed';
} else if (fileSize > 5000000) {
  // Large files (>5MB) benefit from speed
  ocrEngine = 'tesseract';
  reasoning = 'Large file - using Tesseract for faster processing';
}

return {
  ocrEngine,
  endpoint: ocrEngine === 'easyocr' 
    ? 'http://easyocr:2000/ocr'
    : 'http://tesseract-ocr:8884/tesseract',
  reasoning
};

// 3. Switch Node - Route to correct OCR engine
Mode: Rules
Output: {{ $json.ocrEngine }}

// 4a. Branch: Tesseract OCR
// HTTP Request Node
Method: POST
URL: http://tesseract-ocr:8884/tesseract

Send Body: Form Data Multipart
Body Parameters:
  1. Binary File:
     - Parameter Type: n8n Binary File
     - Name: file
     - Input Data Field Name: data
  
  2. OCR Options:
     - Parameter Type: Form Data
     - Name: options
     - Value: {"languages":["eng","deu"],"psm":3}

// Response:
{
  "text": "Extracted text appears here..."
}

// 4b. Branch: EasyOCR
// HTTP Request Node
Method: POST
URL: http://easyocr:2000/ocr

Headers:
  - Name: Content-Type
    Value: application/json

Send Body: JSON
{
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de"],
  "detail": 1,
  "paragraph": true
}

// Response:
{
  "text": "Extracted text...",
  "confidence": 0.95,
  "language": "en"
}

// 5. Merge - Combine branches
Mode: Combine
Output: All

// 6. Set Node - Standardize output
return {
  text: $json.text,
  engine: $('Code Node').json.ocrEngine,
  reasoning: $('Code Node').json.reasoning,
  original_file: $('Trigger').json.fileName
};
```

#### Example 2: Invoice Processing Pipeline

```javascript
// Extract data from invoice images and create accounting records

// 1. Email IMAP Trigger - Monitor invoice inbox
Host: mailserver
Port: 993
Mailbox: INBOX/Invoices
Check for new emails every: 5 minutes

// 2. Loop Node - Process each email attachment

// 3. IF Node - Check if image/PDF
Condition: {{ $json.mimeType }} contains "image" OR "pdf"

// 4. HTTP Request - Extract text with Tesseract
Method: POST
URL: http://tesseract-ocr:8884/tesseract
Body (Form Data):
  file: {{ $binary.data }}
  options: {"languages":["eng","deu"],"psm":6}

// 5. Code Node - Parse invoice data
const text = $json.text;

// Extract invoice details using regex
const invoiceNumber = text.match(/Invoice\s*#?\s*:?\s*(\w+-?\d+)/i)?.[1] || '';
const invoiceDate = text.match(/Date\s*:?\s*([\d\/\-]+)/i)?.[1] || '';
const vendor = text.match(/From\s*:?\s*(.+?)\n/i)?.[1]?.trim() || '';

// Extract amount (multiple patterns)
const amountPatterns = [
  /Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Amount\s*Due\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Grand\s*Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i
];

let amount = '';
for (const pattern of amountPatterns) {
  const match = text.match(pattern);
  if (match) {
    amount = match[1].replace(',', '');
    break;
  }
}

// Parse date to YYYY-MM-DD format
let parsedDate = '';
if (invoiceDate) {
  const dateParts = invoiceDate.split(/[\/\-]/);
  if (dateParts.length === 3) {
    // Assume MM/DD/YYYY or DD/MM/YYYY format
    parsedDate = `20${dateParts[2]}-${dateParts[0].padStart(2, '0')}-${dateParts[1].padStart(2, '0')}`;
  }
}

return {
  invoiceNumber,
  vendor,
  amount: parseFloat(amount) || 0,
  date: parsedDate || new Date().toISOString().split('T')[0],
  originalText: text,
  fileName: $('Loop').json.filename
};

// 6. IF Node - Validate required fields
Condition: {{ $json.invoiceNumber }} AND {{ $json.amount }} > 0

// 7. HTTP Request - Create record in accounting system
Method: POST
URL: http://odoo:8069/api/v1/invoices
Headers:
  Content-Type: application/json
  Authorization: Bearer {{ $env.ODOO_API_KEY }}
Body: {
  "vendor": "{{ $json.vendor }}",
  "invoice_number": "{{ $json.invoiceNumber }}",
  "amount": {{ $json.amount }},
  "date": "{{ $json.date }}",
  "status": "pending_review"
}

// 8. Send Email - Confirmation
To: accounting@yourdomain.com
Subject: Invoice Processed: {{ $json.invoiceNumber }}
Body: |
  Invoice automatically processed:
  
  Vendor: {{ $json.vendor }}
  Invoice #: {{ $json.invoiceNumber }}
  Amount: ${{ $json.amount }}
  Date: {{ $json.date }}
  
  Please review in accounting system.

// 9. Move Email - Archive processed invoice
Mailbox: INBOX/Invoices/Processed
```

#### Example 3: Receipt Scanner for Expense Tracking

```javascript
// OCR receipts from Telegram and track expenses

// 1. Telegram Trigger - Receive photo messages
Bot Token: {{ $env.TELEGRAM_BOT_TOKEN }}
Updates: Message with photo

// 2. Telegram Node - Get Photo
Operation: Get File
File ID: {{ $json.message.photo[0].file_id }}

// 3. HTTP Request - OCR with EasyOCR (better for photos)
Method: POST
URL: http://easyocr:2000/ocr
Headers:
  Content-Type: application/json
Body: {
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de"],
  "detail": 2,
  "paragraph": true
}

// 4. Code Node - Extract expense data
const text = $json.text;
const userId = $('Telegram Trigger').json.message.from.id;

// Extract merchant name (usually at top)
const lines = text.split('\n');
const merchant = lines[0]?.trim() || 'Unknown Merchant';

// Extract total amount
const amountMatch = text.match(/Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i) ||
                   text.match(/Sum\s*:?\s*\$?\s?([\d,]+\.?\d*)/i) ||
                   text.match(/EUR\s*([\d,]+\.?\d*)/i);
const amount = amountMatch ? parseFloat(amountMatch[1].replace(',', '')) : 0;

// Extract date
const dateMatch = text.match(/(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/);
const date = dateMatch ? dateMatch[1] : new Date().toISOString().split('T')[0];

// Detect category from text
let category = 'Other';
if (/restaurant|café|coffee|food|pizza/i.test(text)) {
  category = 'Food & Dining';
} else if (/taxi|uber|transport|fuel|gas/i.test(text)) {
  category = 'Transportation';
} else if (/hotel|airbnb|accommodation/i.test(text)) {
  category = 'Lodging';
} else if (/supermarket|grocery|aldi|rewe/i.test(text)) {
  category = 'Groceries';
}

return {
  userId,
  merchant,
  amount,
  date,
  category,
  fullText: text
};

// 5. HTTP Request - Save to expense database
Method: POST
URL: http://supabase-kong:8000/rest/v1/expenses
Headers:
  apikey: {{ $env.SUPABASE_ANON_KEY }}
  Content-Type: application/json
Body: {
  "user_id": "{{ $json.userId }}",
  "merchant": "{{ $json.merchant }}",
  "amount": {{ $json.amount }},
  "date": "{{ $json.date }}",
  "category": "{{ $json.category }}",
  "receipt_text": "{{ $json.fullText }}"
}

// 6. Telegram Node - Send confirmation
Operation: Send Message
Chat ID: {{ $('Telegram Trigger').json.message.chat.id }}
Message: |
  ✅ Receipt processed!
  
  🏪 Merchant: {{ $json.merchant }}
  💰 Amount: ${{ $json.amount }}
  📅 Date: {{ $json.date }}
  📂 Category: {{ $json.category }}
  
  Expense saved to your tracker!
```

#### Example 4: Multi-Language Document Digitization

```javascript
// Scan and digitize documents in multiple languages

// 1. Google Drive Trigger - New file in folder
Folder: /Documents/To Scan
File Types: PDF, Image

// 2. HTTP Request - Detect language with EasyOCR
Method: POST
URL: http://easyocr:2000/ocr
Body: {
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de", "fr", "es"],
  "detail": 0,
  "paragraph": false
}

// 3. Code Node - Determine primary language
const text = $json.text;
const confidence = $json.confidence || 0;

// Simple language detection based on common words
let detectedLang = 'eng';
if (/der|die|das|und|ich|Sie|werden/i.test(text)) {
  detectedLang = 'deu';
} else if (/le|la|les|et|je|vous|sont/i.test(text)) {
  detectedLang = 'fra';
} else if (/el|la|los|las|y|yo|usted|son/i.test(text)) {
  detectedLang = 'spa';
}

return {
  detectedLang,
  confidence,
  fileName: $('Google Drive Trigger').json.name
};

// 4. HTTP Request - Full OCR with correct language
Method: POST
URL: http://tesseract-ocr:8884/tesseract
Body (Form Data):
  file: {{ $('Google Drive Trigger').binary.data }}
  options: {
    "languages": ["{{ $json.detectedLang }}"],
    "psm": 3
  }

// 5. HTTP Request - Translate to English (if needed)
IF: {{ $('Code Node').json.detectedLang }} !== 'eng'
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $json.text }}",
  "source": "{{ $('Code Node').json.detectedLang.substring(0,2) }}",
  "target": "en"
}

// 6. Google Docs - Create searchable document
Title: {{ $('Code Node').json.fileName }}_text
Content: |
  Original Language: {{ $('Code Node').json.detectedLang }}
  
  OCR Text:
  {{ $('Full OCR').json.text }}
  
  English Translation:
  {{ $json.translatedText }}

// 7. Google Drive - Move to processed folder
Source: {{ $('Google Drive Trigger').json.id }}
Destination: /Documents/Processed/{{ $('Code Node').json.detectedLang }}
```

### Tesseract Configuration

**Page Segmentation Modes (PSM):**

| PSM | Description | Best For |
|-----|-------------|----------|
| `0` | Orientation and script detection only | Initial analysis |
| `1` | Automatic page segmentation with OSD | Mixed layouts |
| `3` | Fully automatic (default) | General documents |
| `4` | Single column of variable sizes | Newspaper |
| `5` | Single uniform block of vertical text | Vertical text |
| `6` | Single uniform block | Clean documents |
| `7` | Single line of text | Short text |
| `8` | Single word | Individual words |
| `11` | Sparse text, find as much as possible | Receipts, forms |
| `13` | Raw line, treat as single text line | Business cards |

**Choose PSM based on document:**
```javascript
// Clean business letter
{"psm": 6}

// Receipt or form
{"psm": 11}

// Business card
{"psm": 13}

// Mixed document layout
{"psm": 1}
```

### Language Support

**Common Language Codes:**

**Tesseract:**

| Language | Code | Language | Code |
|----------|------|----------|------|
| English | `eng` | German | `deu` |
| Spanish | `spa` | French | `fra` |
| Italian | `ita` | Portuguese | `por` |
| Dutch | `nld` | Polish | `pol` |
| Russian | `rus` | Chinese (Simplified) | `chi_sim` |
| Chinese (Traditional) | `chi_tra` | Japanese | `jpn` |
| Korean | `kor` | Arabic | `ara` |
| Turkish | `tur` | Hindi | `hin` |

**EasyOCR:**

| Language | Code | Language | Code |
|----------|------|----------|------|
| English | `en` | German | `de` |
| Spanish | `es` | French | `fr` |
| Italian | `it` | Portuguese | `pt` |
| Dutch | `nl` | Polish | `pl` |
| Russian | `ru` | Chinese (Simplified) | `ch_sim` |
| Chinese (Traditional) | `ch_tra` | Japanese | `ja` |
| Korean | `ko` | Arabic | `ar` |
| Turkish | `tr` | Hindi | `hi` |

**Multi-Language OCR:**
```javascript
// Tesseract - multiple languages
{"languages": ["eng", "deu", "fra"], "psm": 3}

// EasyOCR - multiple languages
{"languages": ["en", "de", "fr"], "detail": 1}
```

### Troubleshooting

**Issue 1: Services Not Responding**

```bash
# Check service status
docker ps | grep "tesseract\|easyocr"

# Should show both services running

# Check Tesseract logs
docker logs tesseract-ocr --tail 50

# Check EasyOCR logs
docker logs easyocr --tail 50

# Restart if needed
docker compose restart tesseract-ocr easyocr
```

**Issue 2: EasyOCR First Request Very Slow**

```bash
# Monitor model loading
docker logs easyocr -f

# You'll see:
# Downloading detection model...
# Downloading recognition model...
# Models loaded successfully
```

**Solution:**
- First request loads models (~30-90 seconds)
- Subsequent requests are fast (7-8 seconds)
- Models cached permanently after first load
- Increase HTTP timeout to 120 seconds for first request

**Issue 3: Poor OCR Quality**

```bash
# Check image quality
file input_image.jpg

# Verify image is not too small
identify -format "%wx%h" input_image.jpg
# Should be at least 1000x1000 pixels for good results
```

**Solution:**
- **For Tesseract:** Use PSM mode appropriate for layout
- **For EasyOCR:** Try with `detail: 2` for better accuracy
- **Preprocessing:** Convert to grayscale, increase contrast
- **Resolution:** Ensure minimum 300 DPI for scanned documents
- **Switch engines:** Try EasyOCR if Tesseract fails (or vice versa)

**Issue 4: Wrong Language Detected**

**Solution:**
- Specify language explicitly instead of auto-detection
- Use multiple languages if document is multilingual
- Ensure correct language packs installed
- For mixed scripts (English + Chinese), specify both languages

**Issue 5: Cannot Access from n8n**

```bash
# Test Tesseract connection
docker exec n8n curl -I http://tesseract-ocr:8884/

# Should return HTTP headers

# Test EasyOCR connection
docker exec n8n curl -I http://easyocr:2000/

# Test actual OCR endpoint
docker exec n8n curl -X POST http://tesseract-ocr:8884/tesseract \
  -F "file=@test.jpg" \
  -F 'options={"languages":["eng"],"psm":3}'
```

**Solution:**
- Use internal URLs: `http://tesseract-ocr:8884` and `http://easyocr:2000`
- Ensure services in same Docker network
- EasyOCR requires secret_key in request body
- Check services are running: `docker ps | grep ocr`

**Issue 6: Empty or Garbled Text Output**

**Solution:**
- Try the other OCR engine (switch between Tesseract/EasyOCR)
- Check image is not corrupted: `identify input.jpg`
- Ensure image has sufficient contrast
- Verify language settings are correct
- For photos: Always use EasyOCR
- For scans: Always use Tesseract

### Resources

**Tesseract:**
- **GitHub**: https://github.com/tesseract-ocr/tesseract
- **Documentation**: https://tesseract-ocr.github.io/
- **Language Data**: https://github.com/tesseract-ocr/tessdata
- **PSM Modes**: https://tesseract-ocr.github.io/tessdoc/ImproveQuality.html

**EasyOCR:**
- **GitHub**: https://github.com/JaidedAI/EasyOCR
- **Documentation**: https://www.jaided.ai/easyocr/documentation/
- **Supported Languages**: https://www.jaided.ai/easyocr/
- **API Reference**: https://github.com/JaidedAI/EasyOCR#api

### Best Practices

**Choosing the Right Engine:**

| Document Type | Recommended Engine | Reason |
|---------------|-------------------|---------|
| **Scanned PDFs** | Tesseract | Fast, optimized for clean scans |
| **Business documents** | Tesseract | Consistent formatting, high speed |
| **Photos of receipts** | EasyOCR | Better quality on photos |
| **Handwritten text** | EasyOCR | Superior handwriting recognition |
| **Low-quality images** | EasyOCR | Better noise handling |
| **Mixed languages** | EasyOCR | Better multi-language support |
| **Bulk processing** | Tesseract | Consistent fast speed |
| **Street signs/photos** | EasyOCR | Optimized for real-world images |

**Image Preprocessing:**

```javascript
// Code Node - Preprocess image before OCR
const sharp = require('sharp');

// Get image from previous node
const imageBuffer = Buffer.from($binary.data.data, 'base64');

// Preprocess: grayscale, increase contrast, sharpen
const processedImage = await sharp(imageBuffer)
  .grayscale()
  .normalize()
  .sharpen()
  .toBuffer();

return {
  binary: {
    data: {
      ...$ $binary.data,
      data: processedImage.toString('base64')
    }
  }
};

// Then send to OCR engine
```

**Performance Optimization:**

1. **Batch Processing:**
   - Process multiple files in parallel with Loop Node
   - Use Queue node to control concurrency
   - Tesseract handles 5-10 simultaneous requests well

2. **Caching:**
   - Store OCR results in database to avoid re-processing
   - Check if document already processed before OCR

3. **Smart Routing:**
   - Analyze document first (size, type, quality)
   - Route to appropriate engine based on analysis
   - Use Tesseract by default, EasyOCR for edge cases

4. **Error Handling:**
   - Always add Try/Catch nodes
   - Retry with other engine if first fails
   - Log failed documents for manual review

**Document Types:**

- ✅ **Tesseract**: Books, newspapers, business letters, forms, clean PDFs
- ✅ **EasyOCR**: Receipts, invoices, photos, street signs, screenshots, handwriting
- ❌ **Neither**: Very low quality images, heavily distorted text, artistic fonts

**When to Use Both:**

1. **Quality Check:** Run both engines and compare results
2. **Confidence:** Use engine with higher confidence score
3. **Mixed Documents:** Tesseract for main text, EasyOCR for photos
4. **Fallback:** Try Tesseract first (fast), use EasyOCR if confidence <80%
