### What is Faster-Whisper?

Faster-Whisper is an optimized implementation of OpenAI's Whisper speech recognition model that provides OpenAI-compatible API endpoints for speech-to-text transcription. It offers significant performance improvements while maintaining the same accuracy as the original Whisper model, making it perfect for self-hosted transcription workflows.

### Features

- **OpenAI-Compatible API**: Drop-in replacement for OpenAI's Whisper API
- **High Performance**: Up to 4x faster than original Whisper implementation
- **Multi-Language Support**: Transcribe audio in 99 languages including English, German, Spanish, French, Chinese, Japanese, and more
- **Automatic Language Detection**: No need to specify language if unknown
- **Timestamp Support**: Get word-level and sentence-level timestamps
- **Multiple Model Sizes**: Choose between tiny, base, small, medium, and large models based on accuracy vs speed requirements

### Initial Setup

**Faster-Whisper is deployed internally (no direct web access):**

- **Internal URL**: `http://faster-whisper:8000`
- **API Endpoint**: `/v1/audio/transcriptions`
- **Authentication**: None required (internal service)
- **Model Loading**: Models are downloaded automatically on first use

**First transcription will take longer** (~2-5 minutes) as the model downloads. Subsequent transcriptions are much faster.

### n8n Integration Setup

**No credentials needed** - Faster-Whisper is accessed via HTTP Request Node with internal URL.

**Internal URL:** `http://faster-whisper:8000`

### Example Workflows

#### Example 1: Basic Audio Transcription

```javascript
// 1. Trigger Node (Webhook, File Upload, etc.)
// Receives audio file in various formats (mp3, wav, m4a, flac, etc.)

// 2. HTTP Request Node - Transcribe Audio
Method: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Send Body: Form Data Multipart

Body Parameters:
1. Binary File:
   - Parameter Type: n8n Binary File
   - Name: file
   - Input Data Field Name: data

2. Model:
   - Parameter Type: Form Data
   - Name: model
   - Value: Systran/faster-whisper-large-v3

3. Language (optional):
   - Parameter Type: Form Data
   - Name: language
   - Value: en
   // Supported: en, de, es, fr, it, pt, nl, pl, ru, ja, ko, zh, ar, etc.

// Response format:
{
  "text": "Transcribed text appears here..."
}

// 3. Set Node or Code Node - Extract text
// Access transcription: {{ $json.text }}
```

#### Example 2: Voice-to-Voice AI Assistant

```javascript
// Complete voice agent pipeline

// 1. Telegram Trigger - Receive voice message
// Telegram sends audio file automatically

// 2. HTTP Request - Download voice file from Telegram
Method: GET
URL: {{ $json.file_url }}

// 3. HTTP Request - Transcribe with Faster-Whisper
Method: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body: Form Data Multipart
  - file: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  - language: de  // or 'en' for English

// 4. AI Agent Node - Process with LLM
// Use OpenAI, Claude, or Ollama node
Model: gpt-4 / claude-3-5-sonnet / llama3.2
Prompt: You are a helpful voice assistant. Respond to: {{ $json.text }}

// 5. HTTP Request - Generate speech response
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Headers:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.response }}",
  "voice": "alloy"  // or "thorsten" for German
}

// 6. Telegram Node - Send audio response
Action: Send Audio
Audio: {{ $binary.data }}

// User receives AI voice response in seconds!
```

#### Example 3: Meeting Recording Auto-Transcription

```javascript
// Automated meeting transcript workflow

// 1. Schedule Trigger - Check for new recordings
// Or Webhook from video conferencing tool

// 2. Google Drive Node - List recent recordings
Folder: /Recordings
Filter: Created in last 24 hours

// 3. Loop Node - Process each recording
Items: {{ $json.files }}

// 4. Google Drive - Download audio file
File ID: {{ $json.id }}

// 5. HTTP Request - Transcribe with timestamps
Method: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body:
  - file: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  - language: en
  - timestamp_granularities: ["segment"]  // word-level or segment-level

// 6. HTTP Request - Summarize with LLM
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [{
    "role": "system",
    "content": "Summarize this meeting transcript with key points and action items."
  }, {
    "role": "user",
    "content": "{{ $json.text }}"
  }]
}

// 7. Google Docs - Create meeting notes
Title: Meeting Notes - {{ $json.meeting_date }}
Content: 
  ## Meeting Transcript
  {{ $json.transcription }}
  
  ## Summary
  {{ $json.summary }}
  
  ## Action Items
  - [ ] {{ $json.action_items }}

// 8. Gmail - Send to participants
To: {{ $json.participants }}
Subject: Meeting Notes - {{ $now.format('YYYY-MM-DD') }}
```

#### Example 4: Multi-Language Customer Support

```javascript
// Automatic transcription and translation

// 1. Webhook - Receive voicemail from customer
// Audio file in any language

// 2. HTTP Request - Transcribe (auto-detect language)
Method: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body:
  - file: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  // No language specified = auto-detect

// Response includes detected language:
{
  "text": "Transcribed text",
  "language": "de"  // Detected: German
}

// 3. IF Node - Check if translation needed
If: {{ $json.language }} !== 'en'

// 4. HTTP Request - Translate to English
Method: POST
URL: http://translate:5000/translate
Body: {
  "q": "{{ $json.text }}",
  "source": "{{ $json.language }}",
  "target": "en"
}

// 5. Set Node - Combine information
{
  "original_text": "{{ $node.Transcribe.json.text }}",
  "original_language": "{{ $json.language }}",
  "translated_text": "{{ $json.translatedText }}",
  "customer_id": "{{ $json.customer_id }}"
}

// 6. Create ticket in CRM with both versions
// 7. Notify support team
```

### Model Selection Guide

Choose the right model based on your requirements:

| Model | RAM | Speed | Quality | Best For |
|-------|-----|-------|---------|----------|
| **tiny** | ~1GB | Fastest | Good | Real-time, development, testing |
| **base** | ~1.5GB | Fast | Better | Default choice, balanced performance |
| **small** | ~3GB | Medium | Good | Accents, professional use |
| **medium** | ~5GB | Slow | Great | High accuracy requirements |
| **large-v3** | ~10GB | Slowest | Best | Maximum quality, complex audio |

**Model Download Times (first use only):**
- tiny: ~40MB (~30 seconds)
- base: ~145MB (~1 minute)
- small: ~466MB (~3 minutes)
- medium: ~1.5GB (~8 minutes)
- large-v3: ~6GB (~30 minutes)

**Recommended Settings:**
- **English-only**: `large-v3` for best accuracy
- **Multi-language**: `large-v3` with language detection
- **Real-time apps**: `base` or `small` for speed
- **Development/testing**: `tiny` for fast iteration

### Troubleshooting

**Issue 1: First Transcription is Very Slow**

```bash
# Model downloads on first use - this is normal
# Check download progress
docker logs faster-whisper

# You'll see:
# Downloading model: Systran/faster-whisper-large-v3
# Progress: [████████████████████] 100%

# Subsequent transcriptions are fast
```

**Solution:**
- First request takes 2-30 minutes depending on model size
- Subsequent requests complete in seconds
- Pre-download models by running a test transcription after installation

**Issue 2: German Audio Transcribed as English Gibberish**

```bash
# Problem: Using wrong model or no language specified
```

**Solution:**
- Use full model: `Systran/faster-whisper-large-v3` (not distil version)
- Add language parameter: `"language": "de"`
- Distil models have poor non-English support

**Issue 3: Transcription Quality is Poor**

```bash
# Check audio quality
ffmpeg -i input.mp3 -af "volumedetect" -f null -

# Check for:
# - Low volume (< -20dB)
# - Heavy background noise
# - Multiple speakers talking simultaneously
```

**Solution:**
- Use larger model (medium or large-v3)
- Pre-process audio to remove noise
- Split multi-speaker audio before transcription
- Ensure audio is at least 16kHz sample rate
- Convert to mono if stereo (Whisper uses mono)

**Issue 4: Service Not Responding / Timeout**

```bash
# Check service status
docker ps | grep faster-whisper

# Check logs
docker logs faster-whisper --tail 50

# Restart service
docker compose restart faster-whisper

# Check memory usage (models need RAM)
free -h
```

**Solution:**
- Ensure server has enough RAM for model (see table above)
- First transcription triggers model download (wait 5-30 mins)
- Check logs for out-of-memory errors
- Reduce to smaller model if insufficient RAM

**Issue 5: Cannot Access from n8n**

```bash
# Test API endpoint
docker exec n8n curl http://faster-whisper:8000/

# Should return: {"detail":"Not Found"}
# This confirms service is accessible

# Test actual transcription endpoint
docker exec n8n curl -X POST http://faster-whisper:8000/v1/audio/transcriptions
```

**Solution:**
- Use internal URL: `http://faster-whisper:8000` (not localhost)
- Ensure both services are in same Docker network
- Check service is running: `docker ps | grep faster-whisper`

### Language Support

Faster-Whisper supports 99 languages:

**Common Languages:**
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

**Auto-Detection:**
- Omit `language` parameter to auto-detect
- Whisper will identify language automatically
- Slightly slower than specifying language
- Very accurate for most languages

### Resources

- **GitHub**: https://github.com/SYSTRAN/faster-whisper
- **Original Whisper**: https://github.com/openai/whisper
- **Model Card**: https://huggingface.co/Systran/faster-whisper-large-v3
- **Language Support**: https://github.com/openai/whisper#available-models-and-languages
- **API Documentation**: OpenAI-compatible endpoints

### Best Practices

**For Best Transcription Results:**

1. **Audio Quality Matters:**
   - Use lossless formats when possible (WAV, FLAC)
   - Minimum 16kHz sample rate (higher is better)
   - Clear, front-facing microphone recordings
   - Minimize background noise

2. **Choose Right Model:**
   - Development: tiny/base for speed
   - Production: medium/large-v3 for accuracy
   - Real-time: base/small with streaming

3. **Specify Language When Known:**
   - Faster processing (skips detection)
   - Slightly better accuracy
   - Required for best non-English results

4. **Pre-process Audio:**
   - Normalize volume levels
   - Remove long silences
   - Split files >30 minutes for better processing
   - Convert to mono (Whisper doesn't use stereo)

5. **Handle Errors Gracefully:**
   - Add retry logic for network issues
   - Validate audio format before sending
   - Set reasonable timeout (5-10 minutes for long files)
   - Cache results to avoid re-processing

6. **Optimize Performance:**
   - Batch process multiple files with queue
   - Use smaller models for preview/draft
   - Pre-download models during off-hours
   - Monitor server RAM usage

**When to Use Faster-Whisper:**

- ✅ Voice messages, voicemail transcription
- ✅ Meeting and interview recordings
- ✅ Podcast and video subtitles
- ✅ Voice command interfaces
- ✅ Multi-language customer support
- ✅ Accessibility features (closed captions)
- ✅ Voice-driven workflows and automation
- ❌ Real-time live transcription (use Scriberr/Vexa instead)
- ❌ Speaker diarization (use Scriberr instead)
