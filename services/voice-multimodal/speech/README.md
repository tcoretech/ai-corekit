# 🔊 OpenedAI-Speech - Text-to-Speech

### What is OpenedAI-Speech?

OpenedAI-Speech is a self-hosted text-to-speech service that provides OpenAI-compatible API endpoints powered by Piper TTS. It offers high-quality, natural-sounding voices in multiple languages with complete privacy - all audio generation happens on your server without sending data to external services.

### Features

- **OpenAI-Compatible API**: Drop-in replacement for OpenAI's TTS API (`/v1/audio/speech`)
- **Multiple Voice Models**: Pre-configured English voices (alloy, echo, fable, onyx, nova, shimmer)
- **Multi-Language Support**: Add voices in 50+ languages including German, French, Spanish, Italian, and more
- **Fast Generation**: ~2-5 seconds per sentence on CPU, <1 second with GPU
- **Privacy-First**: All audio generation happens locally on your server
- **Automatic Model Download**: Voice models download automatically on first use

### Initial Setup

**OpenedAI-Speech is deployed internally (no direct web access):**

- **Internal URL**: `http://openedai-speech:8000`
- **API Endpoint**: `/v1/audio/speech`
- **Authentication**: Bearer token (dummy token accepted: `sk-dummy`)
- **Voice Models**: Downloaded automatically on first use

**Pre-configured English voices:**
- `alloy` - Neutral, balanced voice
- `echo` - Male, confident voice
- `fable` - British, narrative voice
- `onyx` - Deep, authoritative voice
- `nova` - Female, energetic voice
- `shimmer` - Soft, warm voice

### n8n Integration Setup

**No credentials needed** - OpenedAI-Speech is accessed via HTTP Request Node with dummy authentication.

**Internal URL:** `http://openedai-speech:8000`

### Example Workflows

#### Example 1: Basic Text-to-Speech

```javascript
// 1. Trigger Node (Webhook, Schedule, etc.)
// Input text to convert to speech

// 2. HTTP Request Node - Generate Speech
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech

Headers:
  - Name: Content-Type
    Value: application/json
  - Name: Authorization
    Value: Bearer sk-dummy

Send Body: JSON
{
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "alloy",
  "response_format": "mp3"
}

Response Format: File
Put Output in Field: data

// 3. Action Node - Use the audio
// Save to file, send via email, upload to cloud, etc.
```

#### Example 2: Multi-Language Voice Response

```javascript
// Text-to-speech in German or English

// 1. Webhook Trigger - Receive text + language
// Input: { "text": "Hallo Welt", "language": "de" }

// 2. IF Node - Check language
If: {{ $json.language }} === 'de'

// 3a. HTTP Request - German Voice
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Headers:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "thorsten"  // German male voice
}

// 3b. HTTP Request - English Voice
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "alloy"
}

// 4. HTTP Response - Return audio file
Response: Binary
Binary Property: data
```

#### Example 3: Automated Podcast Generation

```javascript
// Generate audio podcast from blog posts

// 1. RSS Feed Trigger - New blog post published
// Or Schedule Trigger + fetch RSS

// 2. HTTP Request - Fetch article content
Method: GET
URL: {{ $json.link }}

// 3. HTML Extract Node - Get main text
Selector: article, .post-content, main
Output: text

// 4. Code Node - Clean and format text
const text = $input.item.json.text;

// Remove extra whitespace
const cleaned = text.replace(/\s+/g, ' ').trim();

// Split into chunks (Piper has ~500 char limit per request)
const chunks = [];
const sentences = cleaned.match(/[^.!?]+[.!?]+/g) || [cleaned];
let currentChunk = '';

for (const sentence of sentences) {
  if ((currentChunk + sentence).length < 450) {
    currentChunk += sentence;
  } else {
    if (currentChunk) chunks.push(currentChunk);
    currentChunk = sentence;
  }
}
if (currentChunk) chunks.push(currentChunk);

return chunks.map(chunk => ({ text: chunk }));

// 5. Loop Node - Process each chunk
Items: {{ $json }}

// 6. HTTP Request - Generate speech for chunk
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Headers:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "fable"  // British narrator voice
}

// 7. Code Node - Concatenate audio files
// Use FFmpeg to merge all audio chunks

// 8. Upload to Cloud Storage - Final podcast audio
// Google Drive, S3, Dropbox, etc.

// 9. Update WordPress/Ghost - Add audio player to post
```

#### Example 4: Voice-Enabled Customer Notifications

```javascript
// Send voice messages to customers

// 1. Webhook Trigger - Order status update
// Input: { "customer_phone": "+491234567890", "status": "shipped", "order_id": "12345" }

// 2. Set Node - Create notification message
const messages = {
  shipped: `Your order ${$json.order_id} has been shipped! Track your package at our website.`,
  delivered: `Great news! Your order ${$json.order_id} has been delivered. Enjoy your purchase!`,
  delayed: `We apologize, but order ${$json.order_id} is delayed. We'll update you soon.`
};

return {
  phone: $json.customer_phone,
  message: messages[$json.status] || 'Order update available'
};

// 3. HTTP Request - Generate voice message
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Headers:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.message }}",
  "voice": "nova"  // Friendly female voice
}

// 4. Twilio Node - Send voice call
Action: Make Call
To: {{ $json.phone }}
URL: [URL to hosted audio file]

// Or WhatsApp/Telegram with audio message
```

### Adding German Voices (or Other Languages)

OpenedAI-Speech uses Piper TTS which supports 50+ languages. Here's how to add German voices:

**Step 1: Edit Voice Configuration**

```bash
# Access your server
ssh user@yourdomain.com

# Navigate to AI CoreKit
cd ~/ai-corekit

# Edit voice configuration
nano openedai-config/voice_to_speaker.yaml
```

**Step 2: Add German Voices**

Find the `tts-1` section and add German voices:

```yaml
tts-1:
  # Existing English voices...
  alloy:
    model: en_US-amy-medium
    speaker: # default speaker
  
  # Add German voices below:
  thorsten:
    model: de_DE-thorsten-medium
    speaker: # default speaker
  eva:
    model: de_DE-eva_k-x_low
    speaker: # default speaker
  kerstin:
    model: de_DE-kerstin-low
    speaker: # default speaker
```

**Step 3: Restart Service**

```bash
docker compose restart openedai-speech
```

**Step 4: Use German Voices in n8n**

```javascript
// HTTP Request Node
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Headers:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "Hallo, dies ist ein Test der deutschen Sprachausgabe.",
  "voice": "thorsten"  // High-quality German male voice
}
```

**Available German Voices:**

| Voice | Gender | Quality | Speed | Best For |
|-------|--------|---------|-------|----------|
| `thorsten` | Male | Medium | Balanced | General use, professional |
| `eva` | Female | X-Low | Very Fast | Quick notifications |
| `kerstin` | Female | Low | Fast | Casual content |

**More voices available at:** https://rhasspy.github.io/piper-samples/

### Adding Other Languages

The same process works for any Piper-supported language:

**Popular Language Codes:**
- German: `de_DE`
- French: `fr_FR`
- Spanish: `es_ES`
- Italian: `it_IT`
- Portuguese: `pt_BR`
- Dutch: `nl_NL`
- Polish: `pl_PL`
- Russian: `ru_RU`

**Example: Add French voice**

```yaml
tts-1:
  # French voice
  marie:
    model: fr_FR-siwis-medium
    speaker: # default speaker
```

Restart service and use: `"voice": "marie"`

### Voice Model Download

**Models download automatically on first use:**

1. First request with a new voice triggers download
2. Download time: ~30-90 seconds per voice
3. Models cached permanently (~20-100MB per voice)
4. Subsequent requests are instant

**Check download progress:**

```bash
docker logs openedai-speech -f
```

### Response Formats

OpenedAI-Speech supports multiple audio formats:

**Available formats:**
- `mp3` - Compressed, small file size (default)
- `opus` - High quality, efficient compression
- `aac` - Good quality, wide compatibility
- `flac` - Lossless, large file size
- `wav` - Uncompressed, best quality, very large
- `pcm` - Raw audio data

**Specify format in request:**

```json
{
  "model": "tts-1",
  "input": "Hello world",
  "voice": "alloy",
  "response_format": "opus"
}
```

### Troubleshooting

**Issue 1: Service Not Responding**

```bash
# Check service status
docker ps | grep openedai-speech

# Should show: STATUS = Up

# Check logs
docker logs openedai-speech --tail 50

# Restart if needed
docker compose restart openedai-speech
```

**Solution:**
- Ensure service is running: `docker ps | grep openedai-speech`
- Check for port conflicts (port 8000 is used by Supabase Kong)
- OpenedAI-Speech uses port 8000 internally (accessible via service name)

**Issue 2: Voice Not Found Error**

```bash
# Check available voices
docker exec openedai-speech cat /app/config/voice_to_speaker.yaml

# Verify voice name spelling
# Voice names are case-sensitive!
```

**Solution:**
- Voice names must match exactly (case-sensitive)
- Check `voice_to_speaker.yaml` for configured voices
- Default voices: alloy, echo, fable, onyx, nova, shimmer
- Custom voices: Must be added to config file

**Issue 3: First Request is Very Slow**

```bash
# Monitor model download
docker logs openedai-speech -f

# You'll see:
# Downloading voice model: en_US-amy-medium
# Progress: [████████████████████] 100%
```

**Solution:**
- First request downloads voice model (~30-90 seconds)
- Subsequent requests complete in 2-5 seconds
- Models are cached permanently
- Pre-download models by testing each voice after setup

**Issue 4: German Voice Sounds Wrong**

```bash
# Check voice configuration
docker exec openedai-speech cat /app/config/voice_to_speaker.yaml | grep -A 2 thorsten

# Should show:
# thorsten:
#   model: de_DE-thorsten-medium
#   speaker:
```

**Solution:**
- Ensure correct model code: `de_DE-thorsten-medium` (not `en_US`)
- Voice must be added to `voice_to_speaker.yaml`
- Restart service after config changes
- Verify language code matches voice model

**Issue 5: Audio Quality is Poor**

**Solution:**
- Use higher quality voice models:
  - `*-low` → `*-medium` → `*-high`
- Switch to uncompressed format: `"response_format": "wav"`
- Try different voices (some are higher quality)
- For best quality: Use medium or high quality models
- Example: `en_US-libritts-high` (best English quality)

**Issue 6: Cannot Access from n8n**

```bash
# Test connection from n8n container
docker exec n8n curl http://openedai-speech:8000/

# Should return health check or error page

# Test actual TTS endpoint
docker exec n8n curl -X POST http://openedai-speech:8000/v1/audio/speech \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{"model":"tts-1","input":"test","voice":"alloy"}'
```

**Solution:**
- Use internal URL: `http://openedai-speech:8000` (not localhost or IP)
- Ensure both services in same Docker network
- Add dummy Authorization header: `Bearer sk-dummy`
- Check service is running: `docker ps | grep openedai-speech`

### Resources

- **GitHub**: https://github.com/matatonic/openedai-speech
- **Piper TTS**: https://github.com/rhasspy/piper
- **Voice Samples**: https://rhasspy.github.io/piper-samples/
- **OpenAI TTS API Reference**: https://platform.openai.com/docs/api-reference/audio/createSpeech
- **Available Languages**: 50+ languages supported

### Best Practices

**For Best Audio Quality:**

1. **Choose Right Voice Quality:**
   - Development/testing: low quality (fast, small)
   - Production: medium quality (balanced)
   - Premium: high quality (slow, large)

2. **Optimize Text Input:**
   - Keep sentences under 500 characters
   - Use proper punctuation for natural pauses
   - Split long text into chunks
   - Add commas for natural pacing

3. **Handle Errors Gracefully:**
   - Retry on network failures
   - Validate text length before sending
   - Cache generated audio to avoid regeneration
   - Set reasonable timeout (10-30 seconds)

4. **Performance Optimization:**
   - Pre-download commonly used voice models
   - Use lower quality voices for real-time apps
   - Batch process multiple requests
   - Cache results for repeated phrases

5. **Multi-Language Support:**
   - Pre-configure voices for all needed languages
   - Test each voice before production
   - Consider regional accents (US vs UK English)
   - Use language-specific voices for best quality

**When to Use OpenedAI-Speech:**

- ✅ Voice notifications and alerts
- ✅ Audiobook and podcast generation
- ✅ Voice assistants and chatbots
- ✅ Accessibility features (text-to-speech)
- ✅ Multi-language content
- ✅ Phone system IVR messages
- ✅ Educational content
- ❌ Real-time low-latency (<100ms) - use Chatterbox instead
- ❌ Emotional expression control - use Chatterbox instead
- ❌ Voice cloning - use Chatterbox instead

### Integration with Other Services

**Voice-to-Voice Pipeline:**

```
Faster-Whisper (STT) → LLM (Processing) → OpenedAI-Speech (TTS)
```

**Complete workflow:**
1. User sends voice message
2. Faster-Whisper transcribes to text
3. LLM (GPT/Claude/Ollama) processes request
4. OpenedAI-Speech converts response to audio
5. Send audio back to user

**Example platforms:**
- Telegram voice messages
- WhatsApp audio messages
- Phone systems (Twilio)
- Discord voice bots
- Web apps with audio
