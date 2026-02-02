### What is TTS Chatterbox?

TTS Chatterbox is a state-of-the-art text-to-speech service that offers emotion control, voice cloning, and multi-language support. Based on Resemble AI's Chatterbox model, it achieved a 63.75% preference rate over ElevenLabs in blind tests, making it one of the highest-quality open-source TTS solutions available.

### Features

- **State-of-the-Art Quality**: 63.75% preference over ElevenLabs in blind tests
- **Emotion Control**: Adjust emotional intensity with exaggeration parameter (0.25-2.0)
- **Voice Cloning**: Clone any voice with just 10-30 seconds of audio sample
- **22+ Languages**: Language-aware synthesis for natural-sounding speech
- **OpenAI-Compatible API**: Drop-in replacement for OpenAI TTS API
- **Built-in Watermarking**: PerTh neural watermarking for audio traceability
- **GPU Acceleration**: <1 second per sentence with GPU support

### Initial Setup

**First Login to Chatterbox:**

1. Navigate to `https://chatterbox.yourdomain.com`
2. **Web Interface**: Simple UI for testing voices and generating audio
3. **API Key**: Generated during installation and stored in `.env`
4. Default voice available immediately

**Access Methods:**
- **Web UI**: `https://chatterbox.yourdomain.com` (for testing)
- **Internal API**: `http://chatterbox-tts:4123` (for n8n automation)
- **Swagger Docs**: `http://chatterbox-tts:4123/docs` (API documentation)

### n8n Integration Setup

**Credentials needed:**

1. Go to n8n: `https://n8n.yourdomain.com`
2. Settings → Credentials → Create New
3. Type: HTTP Header Auth
4. Add header:
   - **Name**: `X-API-Key`
   - **Value**: `${CHATTERBOX_API_KEY}` (from your `.env` file)

**Internal URL:** `http://chatterbox-tts:4123`

### Example Workflows

#### Example 1: Basic Text-to-Speech with Emotion

```javascript
// Generate speech with emotional control

// 1. Trigger Node (Webhook, Schedule, etc.)
// Input: { "text": "I'm so excited about this!", "emotion": "happy" }

// 2. Set Node - Map emotion to exaggeration value
const emotionMap = {
  "calm": 0.25,      // Very subdued
  "neutral": 0.5,    // Balanced
  "normal": 1.0,     // Standard emotion
  "happy": 1.5,      // Upbeat, energetic
  "excited": 2.0,    // Very enthusiastic
  "sad": 0.3,        // Melancholic
  "angry": 1.8       // Intense
};

return {
  text: $json.text,
  exaggeration: emotionMap[$json.emotion] || 1.0
};

// 3. HTTP Request Node - Generate Speech with Chatterbox
Method: POST
URL: http://chatterbox-tts:4123/v1/audio/speech

Headers:
  - Name: X-API-Key
    Value: {{ $credentials.CHATTERBOX_API_KEY }}
  - Name: Content-Type
    Value: application/json

Send Body: JSON
{
  "model": "chatterbox",
  "voice": "default",
  "input": "{{ $json.text }}",
  "response_format": "mp3",
  "exaggeration": {{ $json.exaggeration }},
  "language_id": "en"
}

Response Format: File
Put Output in Field: data

// 4. Action Node - Use the audio
// Save, send via email, upload to storage, etc.
```

#### Example 2: Multi-Language Dynamic Storytelling

```javascript
// Create audiobook with emotion-aware narration

// 1. Google Docs Trigger - New chapter added
// Or fetch from CMS/database

// 2. Code Node - Parse text and detect emotions
const text = $json.chapter_text;

// Split by dialogue and narration
const segments = [];
const dialogueRegex = /"([^"]+)"/g;
let lastIndex = 0;
let match;

while ((match = dialogueRegex.exec(text)) !== null) {
  // Add narration before dialogue
  if (match.index > lastIndex) {
    segments.push({
      text: text.substring(lastIndex, match.index),
      type: 'narration',
      exaggeration: 0.5
    });
  }
  
  // Add dialogue
  segments.push({
    text: match[1],
    type: 'dialogue',
    exaggeration: 1.5  // More expressive for dialogue
  });
  
  lastIndex = match.index + match[0].length;
}

// Add remaining narration
if (lastIndex < text.length) {
  segments.push({
    text: text.substring(lastIndex),
    type: 'narration',
    exaggeration: 0.5
  });
}

return segments;

// 3. Loop Node - Process each segment
Items: {{ $json }}

// 4. HTTP Request - Generate audio for segment
Method: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Headers:
  X-API-Key: {{ $credentials.CHATTERBOX_API_KEY }}
Body: {
  "model": "chatterbox",
  "voice": "default",
  "input": "{{ $json.text }}",
  "exaggeration": {{ $json.exaggeration }},
  "language_id": "en"
}

// 5. Code Node - Concatenate audio segments
// Use FFmpeg to merge all audio files

// 6. Google Drive - Upload complete audiobook chapter
File Name: Chapter_{{ $json.chapter_number }}.mp3
```

#### Example 3: Customer Service with Cloned Brand Voice

```javascript
// Use cloned company spokesperson voice for automated responses

// 1. Webhook Trigger - Customer inquiry received
// Input: { "customer_name": "Alice", "question": "What are your hours?" }

// 2. HTTP Request - Get answer from knowledge base
// Or use LLM to generate response

// 3. Set Node - Format personalized response
return {
  response: `Hi ${$json.customer_name}, ${$json.answer}. Is there anything else I can help you with?`
};

// 4. HTTP Request - Generate speech with cloned voice
Method: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Headers:
  X-API-Key: {{ $credentials.CHATTERBOX_API_KEY }}
Body: {
  "model": "chatterbox",
  "voice": "company_spokesperson",  // Previously cloned voice
  "input": "{{ $json.response }}",
  "exaggeration": 1.0,
  "language_id": "en"
}

// 5. Twilio Node - Send voice response
// Or return audio in webhook response
```

#### Example 4: Podcast Auto-Generation with Multiple Speakers

```javascript
// Create podcast with different voices for hosts and guests

// 1. RSS Feed Trigger - New blog post published

// 2. HTTP Request - Send to LLM for podcast script
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o",
  "messages": [{
    "role": "system",
    "content": "Convert this blog post into a podcast script with Host and Guest dialogue."
  }, {
    "role": "user",
    "content": "{{ $json.blog_content }}"
  }]
}

// 3. Code Node - Parse script into segments
const script = $json.response;
const segments = [];

// Parse "Host: text" and "Guest: text" format
const lines = script.split('\n');
for (const line of lines) {
  if (line.startsWith('Host:')) {
    segments.push({
      speaker: 'host',
      text: line.replace('Host:', '').trim(),
      voice: 'host_voice',
      exaggeration: 1.2
    });
  } else if (line.startsWith('Guest:')) {
    segments.push({
      speaker: 'guest',
      text: line.replace('Guest:', '').trim(),
      voice: 'guest_voice',
      exaggeration: 1.0
    });
  }
}

return segments;

// 4. Loop Node - Generate audio for each segment
Items: {{ $json }}

// 5. HTTP Request - Chatterbox TTS
Method: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Body: {
  "model": "chatterbox",
  "voice": "{{ $json.voice }}",
  "input": "{{ $json.text }}",
  "exaggeration": {{ $json.exaggeration }}
}

// 6. Code Node - Merge audio segments with FFmpeg
// 7. Upload to podcast hosting platform
```

### Voice Cloning Setup

One of Chatterbox's most powerful features is the ability to clone voices with minimal audio samples.

**Step 1: Prepare Voice Sample**

```bash
# SSH into your server
ssh user@yourdomain.com

# Create voice directory
mkdir -p ~/ai-corekit/shared/tts/voices

# Upload your voice sample (10-30 seconds recommended)
# Upload via SCP or save directly:
# scp voice_sample.wav user@yourdomain.com:~/ai-corekit/shared/tts/voices/
```

**Requirements for best results:**
- **Duration**: 10-30 seconds (more is better, up to 60 seconds)
- **Format**: WAV or MP3 (WAV preferred)
- **Quality**: Clear audio, minimal background noise
- **Content**: Natural speech with varied intonation
- **Single speaker**: One person only in the recording

**Step 2: Clone Voice via API (n8n)**

```javascript
// HTTP Request Node - Clone Voice
Method: POST
URL: http://chatterbox-tts:4123/v1/voice/clone

Headers:
  - Name: X-API-Key
    Value: {{ $credentials.CHATTERBOX_API_KEY }}

Send Body: Form Data Multipart
Body Parameters:
  1. Audio File:
     - Parameter Type: n8n Binary File
     - Name: audio_file
     - Input Data Field Name: data
  
  2. Voice Name:
     - Parameter Type: Form Data
     - Name: voice_name
     - Value: my_cloned_voice

// Response:
{
  "success": true,
  "voice_id": "my_cloned_voice",
  "message": "Voice cloned successfully"
}
```

**Step 3: Use Cloned Voice**

```javascript
// HTTP Request Node - Generate with Cloned Voice
Method: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Body: {
  "model": "chatterbox",
  "voice": "my_cloned_voice",  // Your cloned voice ID
  "input": "This is spoken in my cloned voice!",
  "exaggeration": 1.0
}
```

**Managing Cloned Voices:**

```bash
# List all cloned voices
curl -X GET http://chatterbox-tts:4123/v1/voices \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}"

# Delete a cloned voice
curl -X DELETE http://chatterbox-tts:4123/v1/voices/my_cloned_voice \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}"
```

### Emotion Control Guide

The `exaggeration` parameter controls emotional intensity:

| Value | Effect | Best For |
|-------|--------|----------|
| **0.25** | Very calm, subdued | Meditation, ASMR, relaxation |
| **0.5** | Balanced, neutral | Narration, audiobooks, formal |
| **1.0** | Normal emotion | General use, natural speech |
| **1.5** | Upbeat, energetic | Marketing, enthusiasm, happy |
| **2.0** | Very emotional | Excitement, dramatic reading |

**Example scenarios:**

```javascript
// News reading (neutral)
{ "exaggeration": 0.5, "text": "Today's headlines..." }

// Sales pitch (enthusiastic)
{ "exaggeration": 1.8, "text": "This amazing product..." }

// Bedtime story (calm)
{ "exaggeration": 0.3, "text": "Once upon a time..." }

// Sports commentary (excited)
{ "exaggeration": 2.0, "text": "GOAL! What an incredible play!" }
```

### Supported Languages

Chatterbox supports 22+ languages with language-aware synthesis:

**Major Languages:**
- English: `en`
- German: `de`
- Spanish: `es`
- French: `fr`
- Italian: `it`
- Portuguese: `pt`
- Dutch: `nl`
- Polish: `pl`
- Russian: `ru`
- Japanese: `ja`
- Korean: `ko`
- Chinese: `zh`
- Arabic: `ar`
- Turkish: `tr`
- Hindi: `hi`
- Hebrew: `he`
- Danish: `da`
- Finnish: `fi`
- Greek: `el`
- Norwegian: `no`
- Swedish: `sv`
- Swahili: `sw`

**Specify language in request:**

```json
{
  "model": "chatterbox",
  "voice": "default",
  "input": "Hallo, wie geht es dir?",
  "language_id": "de"
}
```

### Performance Tips

**CPU Mode** (Default):
- Speed: ~5-10 seconds per sentence
- RAM: 2-4GB
- Best for: Low-volume use, development

**GPU Mode** (If available):
- Speed: <1 second per sentence
- VRAM: 4GB+
- Best for: Production, high volume

**Enable GPU** (if your server has NVIDIA GPU):

```bash
# Edit docker-compose.yml
nano ~/ai-corekit/docker-compose.yml

# Find chatterbox-tts service, add:
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]

# Add environment variable:
environment:
  - CHATTERBOX_DEVICE=cuda

# Restart service
docker compose restart chatterbox-tts
```

**Optimization Tips:**
- Cache generated audio to avoid regeneration
- Split long texts into sentences for faster processing
- Use lower exaggeration values for faster generation
- Models are cached after first load
- Batch process multiple requests if possible

### Troubleshooting

**Issue 1: Service Not Responding**

```bash
# Check service status
docker ps | grep chatterbox

# Should show: STATUS = Up

# Check logs
docker logs chatterbox-tts --tail 50

# Restart if needed
docker compose restart chatterbox-tts
```

**Issue 2: First Request is Very Slow**

```bash
# Monitor model loading
docker logs chatterbox-tts -f

# You'll see:
# Loading Chatterbox model...
# Model loaded successfully (takes 30-60 seconds first time)
```

**Solution:**
- First request loads model into memory (~2GB, 30-60 seconds)
- Subsequent requests are much faster (5-10 seconds CPU, <1s GPU)
- Model stays in memory while service runs

**Issue 3: Voice Quality is Poor**

**Solution:**
- Check exaggeration value (too high = distorted, too low = flat)
- Optimal range: 0.5-1.5 for most use cases
- For voice cloning: Use high-quality source audio (clear, no noise)
- Ensure correct language_id matches input text
- Try different voices or clone a custom voice

**Issue 4: Voice Cloning Failed**

```bash
# Check audio file format
file voice_sample.wav
# Should show: RIFF (little-endian) data, WAVE audio

# Check logs during cloning
docker logs chatterbox-tts -f
```

**Solution:**
- Audio must be clear, single speaker, 10+ seconds
- Convert to WAV if needed: `ffmpeg -i input.mp3 -ar 22050 output.wav`
- Remove background noise before cloning
- Minimum 10 seconds, recommended 20-30 seconds
- Check API key is correct in request headers

**Issue 5: Cannot Access from n8n**

```bash
# Test connection from n8n container
docker exec n8n curl -I http://chatterbox-tts:4123/

# Should return HTTP headers

# Test API endpoint
docker exec n8n curl -X POST http://chatterbox-tts:4123/v1/audio/speech \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"chatterbox","input":"test","voice":"default"}'
```

**Solution:**
- Use internal URL: `http://chatterbox-tts:4123` (not localhost)
- Ensure both services in same Docker network
- API Key must be in header: `X-API-Key: YOUR_KEY`
- Check service is running: `docker ps | grep chatterbox`

**Issue 6: Audio Sounds Robotic**

**Solution:**
- Increase exaggeration (try 1.2-1.5)
- Use voice cloning for more natural results
- Check input text has proper punctuation
- Avoid all-caps text (sounds shouted)
- Add commas for natural pauses

### Resources

- **GitHub**: https://github.com/travisvn/chatterbox-tts-api
- **Model Info**: https://www.resemble.ai/chatterbox/
- **API Docs**: `http://chatterbox-tts:4123/docs` (after installation)
- **Paper**: https://www.resemble.ai/papers/chatterbox
- **Voice Samples**: Available in web UI

### Best Practices

**For Best Audio Quality:**

1. **Input Text Optimization:**
   - Use proper punctuation (commas = pauses, periods = stops)
   - Avoid abbreviations (write "Doctor" not "Dr.")
   - Spell out numbers ("twenty-five" not "25")
   - Use natural sentence structure

2. **Emotion Control:**
   - Start with 1.0 and adjust incrementally
   - Test different values for your use case
   - Lower for formal content, higher for energetic
   - Consistent values within same context

3. **Voice Cloning Tips:**
   - Record in quiet environment
   - Use external microphone if possible
   - Natural, conversational tone in sample
   - Varied intonation (not monotone)
   - 20-30 seconds is sweet spot

4. **Performance:**
   - Cache frequently used audio
   - Batch generate overnight for large projects
   - Use GPU if available for production
   - Pre-generate common phrases

5. **Multi-Language:**
   - Always specify language_id for best results
   - Test with native speakers if possible
   - Some languages work better than others
   - English has best quality overall

**When to Use Chatterbox vs OpenedAI-Speech:**

**Use Chatterbox when you need:**
- ✅ Emotion control and expression
- ✅ Voice cloning capability
- ✅ Highest quality natural speech
- ✅ Marketing, brand voice, podcasts
- ✅ Audiobooks with emotion
- ✅ Multi-speaker content

**Use OpenedAI-Speech when you need:**
- ✅ Faster generation (lower latency)
- ✅ More voice variety (60+ voices)
- ✅ Lower resource usage
- ✅ Simple notifications
- ✅ Quick prototyping

**Best of both worlds:**
- Use OpenedAI-Speech for development/testing
- Use Chatterbox for final production audio
- Clone your brand voice with Chatterbox
- Use OpenedAI for quick notifications
