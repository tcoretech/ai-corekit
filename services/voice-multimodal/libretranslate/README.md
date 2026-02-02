# 🌍 LibreTranslate - Translation API

### What is LibreTranslate?

LibreTranslate is a free, open-source, self-hosted translation API that provides machine translation for 50+ languages. It offers complete privacy as all translations happen on your server, with no data sent to external services, and includes automatic language detection.

### Features

- **50+ Languages**: Translate between major world languages
- **Automatic Language Detection**: No need to specify source language
- **Privacy-First**: All translations happen locally on your server
- **Unlimited Translations**: No API rate limits or costs
- **Format Preservation**: HTML formatting preserved in translations
- **Document Translation**: Translate TXT, DOCX, PDF files directly
- **OpenAPI/Swagger**: Full API documentation with interactive testing

### Initial Setup

**First Login to LibreTranslate:**

1. Navigate to `https://translate.yourdomain.com`
2. **Web Interface Available**: Simple UI for testing translations
3. **No Authentication Required**: Internal access from n8n doesn't need auth
4. **External Access**: Protected by Basic Auth (credentials in `.env`)

**Access Methods:**
- **Web UI**: `https://translate.yourdomain.com` (for testing)
- **Internal API**: `http://libretranslate:5000` (for n8n automation)
- **External API**: `https://translate.yourdomain.com` (requires Basic Auth)

### n8n Integration Setup

**No credentials needed for internal access** - LibreTranslate is accessed via HTTP Request Node from n8n without authentication.

**Internal URL:** `http://libretranslate:5000`

### Example Workflows

#### Example 1: Basic Text Translation

```javascript
// Simple text translation

// 1. Trigger Node (Webhook, Database, etc.)
// Input: { "text": "Hello, how are you?", "target_lang": "de" }

// 2. HTTP Request Node - Translate Text
Method: POST
URL: http://libretranslate:5000/translate

Headers:
  - Name: Content-Type
    Value: application/json

Send Body: JSON
{
  "q": "{{ $json.text }}",
  "source": "auto",
  "target": "{{ $json.target_lang }}",
  "format": "text"
}

// Response:
{
  "translatedText": "Hallo, wie geht es dir?"
}

// 3. Set Node - Extract translation
return {
  original: $json.text,
  translated: $('HTTP Request').json.translatedText,
  language: $json.target_lang
};
```

#### Example 2: Multi-Language Customer Support

```javascript
// Automated customer support with language detection

// 1. Webhook Trigger - Customer inquiry received
// Input: { "customer_id": "12345", "message": "Hola, necesito ayuda" }

// 2. HTTP Request - Detect Language
Method: POST
URL: http://libretranslate:5000/detect

Headers:
  Content-Type: application/json

Body: {
  "q": "{{ $json.message }}"
}

// Response:
[
  {
    "confidence": 0.95,
    "language": "es"
  }
]

// 3. IF Node - Check if translation needed
If: {{ $json[0].language }} !== 'en'

// 4. HTTP Request - Translate to English
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Webhook').json.message }}",
  "source": "{{ $('Detect Language').json[0].language }}",
  "target": "en",
  "format": "text"
}

// 5. OpenAI Node - Generate response in English
Model: gpt-4o-mini
Prompt: Respond to this customer inquiry: {{ $json.translatedText }}

// 6. HTTP Request - Translate response back to customer's language
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $json.response }}",
  "source": "en",
  "target": "{{ $('Detect Language').json[0].language }}",
  "format": "text"
}

// 7. Send Response - Return in customer's language
To: {{ $('Webhook').json.customer_id }}
Message: {{ $json.translatedText }}
```

#### Example 3: Automated Document Translation

```javascript
// Translate documents uploaded to Google Drive

// 1. Google Drive Trigger - New file uploaded
Folder: "/Documents/To Translate"
File Type: TXT, DOCX, PDF

// 2. HTTP Request - Detect document language
Method: POST
URL: http://libretranslate:5000/detect
Body: {
  "q": "{{ $json.content_preview }}"
}

// 3. Loop Node - Translate to multiple languages
Items: ["de", "fr", "es", "it", "pt"]  // Target languages

// 4. HTTP Request - Translate document
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Google Drive').json.content }}",
  "source": "{{ $('Detect Language').json[0].language }}",
  "target": "{{ $json }}",
  "format": "text"
}

// 5. Google Docs - Create translated document
Title: {{ $('Google Drive').json.name }}_{{ $json }}
Content: {{ $json.translatedText }}

// 6. Move to Folder - Organize by language
Source: Translated document
Destination: /Documents/Translated/{{ $json }}
```

#### Example 4: Real-Time Chat Translation

```javascript
// Translate chat messages in real-time

// 1. Webhook Trigger - New chat message
// Input: { "user_id": "123", "message": "Bonjour!", "room_id": "general" }

// 2. HTTP Request - Detect message language
Method: POST
URL: http://libretranslate:5000/detect
Body: {
  "q": "{{ $json.message }}"
}

// 3. Code Node - Store original language
return {
  user_id: $json.user_id,
  message: $json.message,
  original_lang: $('Detect Language').json[0].language,
  room_id: $json.room_id
};

// 4. HTTP Request - Get room members' languages
// Query database for user language preferences

// 5. Loop Node - Translate for each user
Items: {{ $json.room_members }}

// 6. IF Node - Skip if same language
If: {{ $json.preferred_lang }} !== {{ $('Code').json.original_lang }}

// 7. HTTP Request - Translate message
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Code').json.message }}",
  "source": "{{ $('Code').json.original_lang }}",
  "target": "{{ $json.preferred_lang }}",
  "format": "text"
}

// 8. Slack/Discord/Matrix - Send translated message
Channel: {{ $('Code').json.room_id }}
User: @{{ $json.username }}
Message: [🌍 {{ $json.preferred_lang }}] {{ $json.translatedText }}
```

### Supported Languages

LibreTranslate supports 50+ languages:

**Major Languages:**

| Code | Language | Code | Language | Code | Language |
|------|----------|------|----------|------|----------|
| `en` | English | `de` | German | `zh` | Chinese |
| `es` | Spanish | `fr` | French | `ja` | Japanese |
| `it` | Italian | `pt` | Portuguese | `ar` | Arabic |
| `ru` | Russian | `nl` | Dutch | `ko` | Korean |
| `pl` | Polish | `tr` | Turkish | `hi` | Hindi |
| `sv` | Swedish | `fi` | Finnish | `th` | Thai |
| `da` | Danish | `no` | Norwegian | `vi` | Vietnamese |
| `cs` | Czech | `el` | Greek | `id` | Indonesian |
| `ro` | Romanian | `he` | Hebrew | `ms` | Malay |
| `hu` | Hungarian | `uk` | Ukrainian | `fa` | Persian |

**Get full list via API:**

```bash
# List all available languages
curl http://libretranslate:5000/languages

# Response:
[
  {"code": "en", "name": "English"},
  {"code": "de", "name": "German"},
  ...
]
```

### API Endpoints Reference

#### Translate Text

```javascript
POST http://libretranslate:5000/translate
Content-Type: application/json

{
  "q": "Text to translate",
  "source": "auto",  // or specific language code
  "target": "de",
  "format": "text"  // or "html"
}
```

#### Detect Language

```javascript
POST http://libretranslate:5000/detect
Content-Type: application/json

{
  "q": "Text to detect"
}

// Response:
[
  {
    "confidence": 0.95,
    "language": "en"
  }
]
```

#### Get Available Languages

```javascript
GET http://libretranslate:5000/languages

// Response:
[
  {"code": "en", "name": "English", "targets": ["de", "es", "fr", ...]},
  {"code": "de", "name": "German", "targets": ["en", "es", "fr", ...]},
  ...
]
```

#### Translate File

```javascript
POST http://libretranslate:5000/translate_file
Content-Type: multipart/form-data

file: [binary file data]
source: auto
target: de
```

### Format Preservation

LibreTranslate can preserve HTML formatting during translation:

**HTML Translation:**

```javascript
// HTTP Request Node
Method: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "<h1>Hello World</h1><p>This is a <strong>test</strong>.</p>",
  "source": "en",
  "target": "de",
  "format": "html"  // Preserves HTML tags
}

// Response:
{
  "translatedText": "<h1>Hallo Welt</h1><p>Dies ist ein <strong>Test</strong>.</p>"
}
```

### Troubleshooting

**Issue 1: Service Not Responding**

```bash
# Check service status
docker ps | grep libretranslate

# Should show: STATUS = Up

# Check logs
docker logs libretranslate --tail 50

# Restart if needed
docker compose restart libretranslate
```

**Issue 2: First Translation is Slow**

```bash
# Monitor model loading
docker logs libretranslate -f

# You'll see:
# Loading language models...
# Models loaded successfully
```

**Solution:**
- First translation triggers model download (1-3 minutes per language pair)
- Subsequent translations are fast (<1 second)
- Models are cached permanently
- Pre-load common languages by testing translations after installation

**Issue 3: Translation Quality is Poor**

**Solution:**
- LibreTranslate uses Argos Translate (neural machine translation)
- Quality varies by language pair
- Best for: English ↔ Major European languages
- Moderate for: Asian languages, Arabic
- For better quality: Consider using OpenAI/Claude API for critical content
- Combine with human review for important documents

**Issue 4: Cannot Access from n8n**

```bash
# Test connection from n8n container
docker exec n8n curl http://libretranslate:5000/languages

# Should return JSON list of languages

# Test translation endpoint
docker exec n8n curl -X POST http://libretranslate:5000/translate \
  -H "Content-Type: application/json" \
  -d '{"q":"test","source":"auto","target":"de"}'
```

**Solution:**
- Use internal URL: `http://libretranslate:5000` (not localhost)
- Ensure both services in same Docker network
- No authentication required for internal access
- Check service is running: `docker ps | grep libretranslate`

**Issue 5: File Translation Fails**

```bash
# Check supported file types
# TXT, DOCX, PDF only

# Verify file size (max 10MB default)
docker logs libretranslate | grep "file size"

# Check file encoding
file uploaded_document.txt
```

**Solution:**
- Ensure file is UTF-8 encoded
- Maximum file size: 10MB (configurable)
- For PDFs: Extract text first with OCR tools
- For large files: Split into chunks and translate separately
- Use text extraction tools before translation

**Issue 6: Language Detection is Incorrect**

**Solution:**
- Detection works best with 50+ characters
- Short text may detect incorrectly
- Specify source language explicitly for better results
- Confidence score <0.5 indicates uncertain detection
- Test with longer text samples

### Resources

- **Official Website**: https://libretranslate.com
- **GitHub**: https://github.com/LibreTranslate/LibreTranslate
- **API Documentation**: `https://translate.yourdomain.com/docs` (Swagger UI)
- **Supported Languages**: https://github.com/argosopentech/argos-translate#supported-languages
- **Community**: https://github.com/LibreTranslate/LibreTranslate/discussions

### Best Practices

**For Best Translation Quality:**

1. **Source Text Quality:**
   - Use proper grammar and spelling
   - Avoid slang and idioms
   - Keep sentences simple and clear
   - Use formal language when possible

2. **Language Detection:**
   - Provide 50+ characters for accurate detection
   - Specify source language if known (faster + more accurate)
   - Use confidence score to validate detection

3. **Performance Optimization:**
   - Cache frequent translations
   - Pre-load commonly used language pairs
   - Batch translate multiple texts together
   - Use async processing for large volumes

4. **Format Handling:**
   - Use `format: "html"` to preserve formatting
   - Clean up text before translation
   - Post-process translations if needed
   - Test with sample content first

5. **Error Handling:**
   - Validate language codes before sending
   - Handle network timeouts gracefully
   - Provide fallback for failed translations
   - Log failed translations for review

**When to Use LibreTranslate:**

- ✅ Privacy-sensitive content
- ✅ High-volume translations (no API costs)
- ✅ Internal tools and automation
- ✅ Basic communication across languages
- ✅ Quick prototyping
- ✅ Educational projects
- ❌ Professional/legal documents (use human translator)
- ❌ Marketing copy (consider paid services)
- ❌ Critical communications

**LibreTranslate vs Commercial Services:**

| Feature | LibreTranslate | Google Translate | DeepL |
|---------|----------------|------------------|-------|
| **Cost** | Free (self-hosted) | Pay per character | Limited free tier |
| **Privacy** | Complete | Data sent to Google | Data sent to DeepL |
| **Quality** | Good | Excellent | Excellent |
| **Languages** | 50+ | 100+ | 30+ |
| **Speed** | Fast (local) | Fast | Fast |
| **Best For** | Privacy, volume | General use | Professional |

### Integration with Other Services

**Translation Pipeline:**

```
Content Creation → LibreTranslate → Review → Publish
```

**Multi-Language Workflow:**

1. Create content in primary language (English)
2. Auto-translate to target languages (LibreTranslate)
3. Store translations in database
4. Human review (optional)
5. Publish to all markets

**Combined with Speech Services:**

```
Speech → Whisper (STT) → LibreTranslate → TTS → Speech
```

**Use case:** Real-time voice translation for meetings

**Document Processing:**

```
Upload → OCR (Tesseract) → LibreTranslate → Format → Save
```

**Use case:** Translate scanned documents
