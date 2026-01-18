# 📝 Scriberr - Audio Transcription with Speaker Diarization

### What is Scriberr?

Scriberr is an advanced AI-powered audio transcription service built on WhisperX that provides high-accuracy transcription with speaker diarization (identifying who said what). Perfect for meetings, interviews, podcasts, and call recordings, Scriberr goes beyond basic transcription by automatically identifying and labeling different speakers, making it ideal for multi-speaker content analysis.

### Features

- **WhisperX-Powered Transcription** - High accuracy with precise timestamp alignment
- **Speaker Diarization** - Automatically identifies and labels different speakers (Speaker 1, Speaker 2, etc.)
- **AI Summaries** - Generate meeting summaries using OpenAI or Anthropic models
- **YouTube Support** - Transcribe directly from YouTube URLs without downloading
- **REST API** - Full automation support for n8n and other tools
- **Multiple Model Options** - Choose from tiny to large models based on accuracy needs
- **Multi-Language Support** - Supports 99 languages with auto-detection

### Initial Setup

**First Login to Scriberr:**

1. Navigate to `https://scriberr.yourdomain.com`
2. No authentication required by default (internal network only)
3. Upload a test audio file or paste a YouTube URL
4. Configure speaker detection settings:
   - **Min Speakers**: Minimum number of expected speakers (default: 2)
   - **Max Speakers**: Maximum number of speakers to identify (default: 4)
5. Click "Transcribe" and wait for processing
6. First transcription downloads the model (2-5 minutes initial setup)
7. View results with speaker labels and timestamps

**Model Selection:**
- **tiny** (~1GB RAM): Fast processing, draft quality
- **base** (~1.5GB RAM): Good balance, recommended default
- **small** (~3GB RAM): Better accuracy for accents
- **medium** (~5GB RAM): Professional-grade transcription
- **large** (~10GB RAM): Maximum accuracy, slower processing

### n8n Integration Setup

**Access Scriberr API from n8n:**

Scriberr provides a REST API for complete automation. Use n8n's HTTP Request node to interact with all features.

**Internal URL:** `http://scriberr:8080`

**Available Endpoints:**
- `POST /api/upload` - Upload and transcribe audio file
- `GET /api/transcripts/{id}` - Get transcript by ID
- `POST /api/youtube` - Transcribe from YouTube URL
- `POST /api/summary` - Generate AI summary of transcript
- `GET /api/models` - List available Whisper models

### Example Workflows

#### Example 1: Meeting Recording to Transcript with Speakers

```javascript
// Complete workflow: Upload → Transcribe → Identify Speakers → Email Results

// 1. HTTP Request Node - Upload Audio File
Method: POST
URL: http://scriberr:8080/api/upload
Send Body: Form Data Multipart
Body Parameters:
  - file: {{ $binary.data }}  // n8n Binary File
  - speaker_detection: true
  - min_speakers: 2
  - max_speakers: 4
  - model: base  // or: tiny, small, medium, large

// Response includes transcript_id for next steps

// 2. Wait Node - Processing Time
Time: 30 seconds
// Adjust based on audio length (1:1 ratio typical)

// 3. HTTP Request Node - Get Transcript Results
Method: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// Response format:
{
  "transcript_id": "abc123",
  "status": "completed",
  "text": "Full transcript text...",
  "segments": [
    {
      "start": 0.0,
      "end": 3.5,
      "text": "Hello everyone, welcome to the meeting.",
      "speaker": "SPEAKER_00"
    },
    {
      "start": 3.5,
      "end": 7.2,
      "text": "Thanks for having me.",
      "speaker": "SPEAKER_01"
    }
  ],
  "speakers": {
    "SPEAKER_00": "Speaker 1",
    "SPEAKER_01": "Speaker 2"
  }
}

// 4. Code Node - Format Transcript with Speaker Labels
const segments = $input.item.json.segments;
const speakers = $input.item.json.speakers;

const formatted = segments.map(seg => {
  const speakerLabel = speakers[seg.speaker] || seg.speaker;
  const timestamp = new Date(seg.start * 1000).toISOString().substr(11, 8);
  return `[${timestamp}] ${speakerLabel}: ${seg.text}`;
}).join('\n\n');

return {
  formatted_transcript: formatted,
  full_text: $input.item.json.text
};

// 5. Email Node - Send Transcript to Participants
To: meeting@company.com
Subject: Meeting Transcript - {{ $now.format('YYYY-MM-DD') }}
Body: |
  Meeting Transcript (with speaker identification):
  
  {{ $json.formatted_transcript }}
  
  ---
  Full transcript attached.
```

#### Example 2: YouTube Video to Meeting Minutes

```javascript
// Transcribe YouTube video and generate AI summary

// 1. Webhook Trigger - Receive YouTube URL
// Input: { "youtube_url": "https://youtube.com/watch?v=..." }

// 2. HTTP Request Node - Transcribe YouTube Video
Method: POST
URL: http://scriberr:8080/api/youtube
Send Body: JSON
{
  "url": "{{ $json.youtube_url }}",
  "speaker_detection": true,
  "min_speakers": 1,
  "max_speakers": 5,
  "model": "small"  // Better for online videos
}

// Response: { "transcript_id": "xyz789", "status": "processing" }

// 3. Wait Node - YouTube Processing
Time: 2 minutes
// YouTube downloads take longer

// 4. HTTP Request Node - Check Transcript Status
Method: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// 5. HTTP Request Node - Generate AI Summary
Method: POST
URL: http://scriberr:8080/api/summary
Send Body: JSON
{
  "transcript_id": "{{$json.transcript_id}}",
  "prompt": "Create detailed meeting minutes with:\n- Main discussion points\n- Key decisions\n- Action items with assigned owners\n- Follow-up items",
  "model": "gpt-4o-mini"  // or: gpt-4, claude-3-5-sonnet
}

// Response:
{
  "summary": "# Meeting Minutes\n\n## Main Points...",
  "action_items": ["Task 1", "Task 2"]
}

// 6. Google Docs Node - Create Document
Title: Meeting Minutes - {{ $now.format('YYYY-MM-DD') }}
Content: |
  # Video Meeting Minutes
  
  **Video:** {{ $json.youtube_url }}
  **Date:** {{ $now.format('YYYY-MM-DD HH:mm') }}
  
  ## AI-Generated Summary
  {{ $json.summary }}
  
  ## Full Transcript with Speakers
  {{ $json.transcript_text }}
  
  ## Action Items
  {{ $json.action_items.map(item => `- [ ] ${item}`).join('\n') }}

// 7. Slack Node - Notify Team
Channel: #meetings
Message: |
  📝 New meeting minutes available:
  {{ $json.document_url }}
  
  Key action items:
  {{ $json.action_items[0] }}
  {{ $json.action_items[1] }}
```

#### Example 3: Podcast Processing with Speaker Identification

```javascript
// Automated podcast transcription workflow

// 1. Google Drive Trigger - New file in /Podcasts folder
// Monitors for new audio uploads

// 2. Google Drive Node - Download audio file
File ID: {{ $json.id }}
Output: Binary

// 3. HTTP Request Node - Upload to Scriberr
Method: POST
URL: http://scriberr:8080/api/upload
Body: Form Data Multipart
  - file: {{ $binary.data }}
  - speaker_detection: true
  - min_speakers: 2  // Host + Guest
  - max_speakers: 3  // In case of multiple guests
  - model: medium  // Better for production quality

// 4. Wait Node - Processing
Time: {{ Math.ceil($json.duration / 60) }} minutes
// Process time ≈ audio length

// 5. Loop Node - Poll for Completion
// Check every 30 seconds until status = "completed"

// 6. HTTP Request Node - Get Results
Method: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// 7. Code Node - Create Podcast Show Notes
const segments = $input.item.json.segments;
const speakers = $input.item.json.speakers;

// Group by speaker
const speakerSegments = {};
segments.forEach(seg => {
  if (!speakerSegments[seg.speaker]) {
    speakerSegments[seg.speaker] = [];
  }
  speakerSegments[seg.speaker].push(seg);
});

// Generate timestamps for notable moments
const timestamps = [];
segments.forEach((seg, i) => {
  const words = seg.text.split(' ');
  if (words.some(w => ['question', 'important', 'key', 'summary'].includes(w.toLowerCase()))) {
    timestamps.push({
      time: Math.floor(seg.start),
      text: seg.text.substring(0, 100)
    });
  }
});

return {
  full_transcript: $input.item.json.text,
  speaker_count: Object.keys(speakerSegments).length,
  timestamps: timestamps.slice(0, 10),  // Top 10 moments
  duration: segments[segments.length - 1].end
};

// 8. WordPress Node - Publish Show Notes
Title: {{ $json.podcast_title }}
Content: |
  ## Podcast Episode Notes
  
  **Duration:** {{ Math.floor($json.duration / 60) }} minutes
  **Speakers:** {{ $json.speaker_count }}
  
  ### Key Moments
  {{ $json.timestamps.map(t => `[${Math.floor(t.time / 60)}:${t.time % 60}] ${t.text}`).join('\n') }}
  
  ### Full Transcript
  {{ $json.full_transcript }}
  
  ---
  *Transcript generated automatically with Scriberr*

// 9. Social Media Nodes - Promote Episode
// Twitter, LinkedIn, etc. with key quotes
```

#### Example 4: Customer Support Call Analysis

```javascript
// Analyze support calls for quality and insights

// 1. FTP Trigger - New call recordings uploaded
// Or webhook from phone system

// 2. HTTP Request - Transcribe Call
Method: POST
URL: http://scriberr:8080/api/upload
Body:
  - file: {{ $binary.data }}
  - speaker_detection: true
  - min_speakers: 2  // Agent + Customer
  - max_speakers: 2

// 3. Wait + Get Transcript (see Example 1)

// 4. Code Node - Analyze Call Quality
const segments = $input.item.json.segments;

// Identify agent vs customer
const agentSpeaker = segments[0].speaker;  // First speaker = agent
const customerSpeaker = segments.find(s => s.speaker !== agentSpeaker)?.speaker;

// Calculate metrics
const agentWords = segments
  .filter(s => s.speaker === agentSpeaker)
  .reduce((sum, s) => sum + s.text.split(' ').length, 0);
  
const customerWords = segments
  .filter(s => s.speaker === customerSpeaker)
  .reduce((sum, s) => sum + s.text.split(' ').length, 0);

const talkRatio = agentWords / customerWords;
const callDuration = segments[segments.length - 1].end;
const avgPause = segments.reduce((sum, s, i, arr) => {
  if (i === 0) return 0;
  return sum + (s.start - arr[i-1].end);
}, 0) / segments.length;

return {
  transcript: $input.item.json.text,
  agent_speaker: agentSpeaker,
  customer_speaker: customerSpeaker,
  talk_ratio: talkRatio.toFixed(2),
  call_duration_seconds: callDuration,
  avg_pause_seconds: avgPause.toFixed(2),
  total_segments: segments.length
};

// 5. HTTP Request - Sentiment Analysis (OpenAI)
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [{
    "role": "system",
    "content": "Analyze this customer support call and rate: Customer Satisfaction (1-10), Issue Resolution (yes/no), Agent Performance (1-10), Key Issues, Recommendations"
  }, {
    "role": "user",
    "content": "{{ $json.transcript }}"
  }]
}

// 6. IF Node - Check if Escalation Needed
If: {{ $json.customer_satisfaction < 5 }} OR {{ $json.issue_resolved === false }}

// 7a. Slack Node - Alert Manager
Channel: #support-escalations
Message: |
  ⚠️ Call Requires Review
  
  **Call Duration:** {{ $json.call_duration_seconds }}s
  **Customer Satisfaction:** {{ $json.customer_satisfaction }}/10
  **Issue Resolved:** {{ $json.issue_resolved }}
  **Key Issues:** {{ $json.key_issues }}
  
  **Recommendations:** {{ $json.recommendations }}

// 7b. Database - Store Call Analytics
// Insert metrics for reporting dashboard
```

### Troubleshooting

**Issue 1: First Transcription Takes Forever**

```bash
# Model downloads on first use - this is normal
docker logs scriberr --tail 100

# You'll see model download progress:
# Downloading WhisperX model: base
# Progress: [████████████] 100%

# Check disk space
df -h

# Models require:
# tiny: ~40MB
# base: ~145MB
# small: ~466MB
# medium: ~1.5GB
# large: ~6GB
```

**Solution:**
- First transcription with a new model takes 2-30 minutes (model download)
- Subsequent transcriptions are fast (model cached)
- Pre-download models by running test transcription after install
- Ensure sufficient disk space for models

**Issue 2: Speaker Diarization Not Working**

```bash
# Check speaker detection settings in API request
# Verify min_speakers and max_speakers are set correctly

# Check Scriberr logs
docker logs scriberr | grep -i "speaker\|diarization"

# Common issues:
# - Audio too short (< 30 seconds)
# - Only one speaker in audio
# - Poor audio quality (background noise)
# - min_speakers > actual speakers
```

**Solution:**
- Audio must be at least 30 seconds for diarization
- Set realistic min/max speaker ranges (2-4 typical)
- Provide clear audio with distinct speakers
- Use mono audio (stereo can confuse diarization)
- Speaker labels are generic (SPEAKER_00, SPEAKER_01) - rename manually if needed

**Issue 3: YouTube Transcription Fails**

```bash
# Check Scriberr logs
docker logs scriberr --tail 50

# Common errors:
# - "Video unavailable" → Private/restricted video
# - "Network timeout" → Video too long
# - "Format not supported" → Age-restricted content
```

**Solution:**
- Use public, non-restricted YouTube videos only
- For long videos (>2 hours), download separately and upload
- Check YouTube URL is correct format: `https://youtube.com/watch?v=...`
- Some corporate networks block YouTube downloads - test on different network

**Issue 4: Out of Memory Error**

```bash
# Check container memory usage
docker stats scriberr --no-stream

# Check server RAM
free -h

# Scriberr memory requirements:
# tiny model: ~1GB RAM
# base model: ~1.5GB RAM
# small model: ~3GB RAM
# medium model: ~5GB RAM
# large model: ~10GB RAM

# Check Docker container limits
docker inspect scriberr | grep -i memory
```

**Solution:**
- Use smaller model (base instead of large)
- Process shorter audio files (<30 minutes)
- Split long files before upload
- Increase Docker memory limits in docker-compose.yml
- Ensure no other heavy services running simultaneously

**Issue 5: AI Summary Generation Fails**

```bash
# Check if OpenAI/Anthropic API key is configured
docker exec scriberr env | grep -i "api_key\|openai\|anthropic"

# Check Scriberr summary endpoint
docker logs scriberr | grep -i "summary\|openai\|anthropic"
```

**Solution:**
- Configure OpenAI or Anthropic API key in Scriberr settings
- Or use local LLM via Open WebUI for summaries
- Summary endpoint requires transcript_id from completed transcription
- Ensure sufficient API credits available
- For privacy, use local LLM instead of external APIs

### Tips for Best Results

**Audio Quality Matters:**
1. **Use high-quality recordings:** WAV or FLAC format preferred
2. **Minimum 16kHz sample rate:** Higher is better (44.1kHz ideal)
3. **Clear, front-facing mics:** Lapel mics or good USB microphones
4. **Minimize background noise:** Quiet room, close doors, turn off fans
5. **Avoid compression:** Upload uncompressed audio when possible

**Speaker Diarization Tips:**
1. **Set realistic speaker count:** Most meetings have 2-6 speakers
2. **Distinct speakers:** Physical separation helps identification
3. **Avoid overlapping speech:** Wait for pauses between speakers
4. **Longer audio = better accuracy:** 5+ minutes recommended
5. **Label speakers manually:** SPEAKER_00 → "John Smith" in post-processing

**Processing Time Optimization:**
1. **Choose right model for task:**
   - Development/testing: tiny or base
   - Production: small or medium
   - Accuracy-critical: large
2. **Pre-process audio:** Remove silence, normalize volume
3. **Split long files:** <30 minutes per file for faster processing
4. **Batch processing:** Queue multiple files during off-hours

**Integration Best Practices:**
1. **Use polling for long transcriptions:** Check status every 30-60 seconds
2. **Handle errors gracefully:** Retry on network failures
3. **Cache results:** Store transcripts in database to avoid re-processing
4. **Webhook support:** Configure callbacks for async processing
5. **Rate limiting:** Don't overwhelm with simultaneous requests

### Resources

- **GitHub:** https://github.com/rishikanthc/Scriberr
- **WhisperX Paper:** https://arxiv.org/abs/2303.00747
- **API Documentation:** Available at `http://scriberr:8080/docs` (when running)
- **Speaker Diarization Guide:** https://github.com/pyannote/pyannote-audio
- **Model Comparison:** https://github.com/openai/whisper#available-models-and-languages
- **Language Support:** 99 languages supported by Whisper

### When to Use Scriberr

**✅ Perfect For:**
- Meeting recordings with multiple speakers
- Podcast episode transcription
- Interview analysis
- Customer support call quality assurance
- Legal depositions and court recordings
- Focus group analysis
- Medical consultations (with proper consent)
- Academic research interviews
- Conference talk transcription

**❌ Not Ideal For:**
- Real-time live transcription (use Vexa instead)
- Single speaker with real-time needs (use Faster-Whisper)
- Very short audio clips (<10 seconds)
- Heavily overlapping speech
- Extremely noisy environments
- Music transcription (not designed for this)

**Scriberr vs Faster-Whisper vs Vexa:**
- **Scriberr:** Best for speaker diarization, async processing, detailed transcripts
- **Faster-Whisper:** Best for speed, real-time apps, single speaker
- **Vexa:** Best for live meeting transcription (Google Meet, Teams)
