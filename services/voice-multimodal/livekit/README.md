# 🎙️ LiveKit - Voice Agents

### What is LiveKit?

LiveKit is professional WebRTC infrastructure for building real-time voice and video applications. It's specifically designed for AI voice agents, live streaming, and video conferencing - used by ChatGPT's Advanced Voice Mode and thousands of production applications. Unlike traditional video conferencing tools with web interfaces, LiveKit is an **API-first platform** that requires you to build clients using SDKs.

### ⚠️ CRITICAL Requirements

**UDP Ports 50000-50100 are MANDATORY for audio/video:**

- ❌ Without UDP: Only signaling works, **NO media streaming!**
- ⚠️ Many VPS providers **block UDP traffic** by default
- ✅ TCP Port 7882 required as fallback
- 🧪 **Test UDP connectivity BEFORE building voice agents**

**Pre-Installation UDP Test:**

```bash
# 1. Open UDP port range in firewall
sudo ufw allow 50000:50100/udp
sudo ufw allow 7882/tcp

# 2. Test UDP connectivity (requires two terminals)

# Terminal 1 (on your VPS):
nc -u -l 50000

# Terminal 2 (from external network, e.g., your laptop):
nc -u YOUR_VPS_IP 50000
# Type text and press Enter - should appear in Terminal 1

# 3. If text doesn't appear, UDP is BLOCKED by your provider
```

### VPS Provider Compatibility

| Provider | UDP Status | Recommendation |
|----------|------------|----------------|
| **Hetzner Cloud** | ✅ Works well | ⭐ Recommended for LiveKit |
| **DigitalOcean** | ✅ Good UDP | ⭐ Recommended |
| **Contabo** | ✅ Works (game server support) | Good choice |
| **OVH** | ❌ Often blocks UDP | ⚠️ Not recommended |
| **Scaleway** | ⚠️ Firewall restrictions | May require configuration |
| **AWS/GCP** | ⚠️ Requires NAT setup | Complex setup |

### Key Differences: LiveKit vs Jitsi Meet

| Feature | LiveKit | Jitsi Meet |
|---------|---------|------------|
| **Primary Use** | AI voice agents, SDKs | Video conferencing |
| **Authentication** | JWT tokens (backend required) | No auth required |
| **Web UI** | ❌ None (API only) | ✅ Full meeting interface |
| **Integration** | SDK-first (developers) | Browser-first (end users) |
| **UDP Ports** | 50000-50100 | 10000 only |
| **Best For** | Voice AI, custom apps | Quick meetings, Cal.com |

### Features

- **JWT-Based Authentication** - Secure token-based client access
- **SFU Architecture** - Scalable Selective Forwarding Unit for low latency
- **AI Agent Ready** - Built for voice AI applications
- **Multi-Platform SDKs** - JavaScript, React, Flutter, Swift, Kotlin, Go
- **Low Latency** - <100ms glass-to-glass latency
- **Simulcast Support** - Multiple quality streams per participant
- **E2E Encryption** - Optional end-to-end encryption
- **Server-Side Recording** - Egress service for recordings
- **WebRTC Standards** - Full WebRTC compliance

### Architecture

```
┌─────────────┐      WebSocket      ┌──────────────┐
│   Client    │ ←─────────────────→ │   LiveKit    │
│   (Browser) │      JWT Token      │   Server     │
└─────────────┘                     └──────────────┘
                                           │
                 ┌─────────────────────────┼─────────────────────────┐
                 │                         │                         │
           ┌─────▼──────┐           ┌─────▼──────┐           ┌─────▼──────┐
           │  WebRTC    │           │  WebRTC    │           │  WebRTC    │
           │  Media     │           │  Media     │           │  Media     │
           │ UDP 50000+ │           │ UDP 50000+ │           │ UDP 50000+ │
           └────────────┘           └────────────┘           └────────────┘
           Client A                 Client B                 Client C
```

### Initial Setup

**After Installation:**

1. **API Credentials** (automatically generated in `.env`):
   - API Key: `${LIVEKIT_API_KEY}`
   - API Secret: `${LIVEKIT_API_SECRET}`
   - WebSocket URL: `wss://livekit.yourdomain.com`

2. **No Web Interface** - LiveKit is API-only, you must build clients using SDKs

3. **Test Connection:**
   ```bash
   # Generate a test token
   bash scripts/generate_livekit_token.sh
   
   # Use token at LiveKit Playground:
   # https://agents-playground.livekit.io
   ```

### Generating Access Tokens

LiveKit requires JWT tokens for client authentication. Generate them in your backend (n8n, Node.js, Python):

#### Option 1: CLI Helper Script (Quickest for Testing)

```bash
# Generate token with default values
bash scripts/generate_livekit_token.sh

# Specify room and user
bash scripts/generate_livekit_token.sh my-room my-user

# Output:
# Token generated successfully!
# Access token: eyJhbGc...
# Use this token in LiveKit Playground:
# https://agents-playground.livekit.io
```

**Parameters:**
- `room-name` (optional): Room to join, defaults to `voice-test`
- `user-id` (optional): User identity, defaults to `user-<timestamp>`

#### Option 2: Node.js (for n8n)

```javascript
// Install in n8n Code Node or Function
// npm install livekit-server-sdk

const { AccessToken } = require('livekit-server-sdk');

// Create token for a participant
const token = new AccessToken(
  process.env.LIVEKIT_API_KEY,
  process.env.LIVEKIT_API_SECRET,
  {
    identity: 'user-' + Date.now(),
    name: 'User Name'
  }
);

// Grant room permissions
token.addGrant({
  roomJoin: true,
  room: 'my-voice-room',
  canPublish: true,    // Can speak/send video
  canSubscribe: true   // Can hear/see others
});

const jwt = token.toJwt();
return { token: jwt, wsUrl: 'wss://livekit.yourdomain.com' };
```

#### Option 3: Python

```python
from livekit import AccessToken, VideoGrants
import os
import time

# Create token
token = AccessToken(
    api_key=os.getenv('LIVEKIT_API_KEY'),
    api_secret=os.getenv('LIVEKIT_API_SECRET')
)

# Set identity and grants
token.identity = f"user-{int(time.time())}"
token.name = "User Name"
token.add_grant(VideoGrants(
    room_join=True,
    room="my-voice-room",
    can_publish=True,
    can_subscribe=True
))

jwt_token = token.to_jwt()
print(f"Access Token: {jwt_token}")
```

### n8n Integration

**Complete AI Voice Agent Workflow:**

```javascript
// 1. Webhook Trigger - User requests voice call
// Input: { "userId": "123", "userName": "Alice" }

// 2. Code Node - Generate LiveKit Token
const { AccessToken } = require('livekit-server-sdk');

const roomName = `room-${Date.now()}`;
const token = new AccessToken(
  process.env.LIVEKIT_API_KEY,
  process.env.LIVEKIT_API_SECRET,
  {
    identity: $json.userId,
    name: $json.userName
  }
);

token.addGrant({
  roomJoin: true,
  room: roomName,
  canPublish: true,
  canSubscribe: true
});

return {
  token: token.toJwt(),
  wsUrl: 'wss://livekit.yourdomain.com',
  roomName: roomName
};

// 3. HTTP Response Node - Return credentials to client
Body:
{
  "token": "{{$json.token}}",
  "wsUrl": "{{$json.wsUrl}}",
  "room": "{{$json.roomName}}"
}

// Client connects to LiveKit using these credentials
// Audio streams: User → LiveKit → n8n → AI → LiveKit → User
```

### Example Workflows

#### Example 1: AI Voice Assistant Pipeline

```javascript
// Full voice agent flow: Speech → AI → Speech

// 1. LiveKit Webhook - track.published (user speaks)
// LiveKit sends webhook when participant starts speaking

// 2. HTTP Request - Download audio segment
Method: GET
URL: http://livekit-server:7881/recordings/{{$json.trackId}}
Headers:
  Authorization: Bearer {{$env.LIVEKIT_API_KEY}}

// 3. HTTP Request - Transcribe with Whisper
Method: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body (Form Data):
  file: {{$binary.data}}
  model: Systran/faster-whisper-large-v3

// 4. HTTP Request - Get AI response (OpenAI/Claude/Ollama)
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [
    {"role": "system", "content": "You are a helpful voice assistant."},
    {"role": "user", "content": "{{$json.text}}"}
  ]
}

// 5. HTTP Request - Generate speech with TTS
Method: POST
URL: http://openedai-speech:8000/v1/audio/speech
Body: {
  "model": "tts-1",
  "input": "{{$json.choices[0].message.content}}",
  "voice": "alloy"
}

// 6. LiveKit Publish Audio - Send response back to room
// Use LiveKit API to publish audio track to room
```

#### Example 2: Meeting Recording & Transcription

```javascript
// Automatic meeting processing

// 1. LiveKit Webhook - recording.finished
// Triggered when LiveKit finishes recording

// 2. HTTP Request - Download recording
Method: GET
URL: http://livekit-server:7881/recordings/{{$json.recordingId}}
Headers:
  Authorization: Bearer {{$env.LIVEKIT_API_SECRET}}

// 3. HTTP Request - Transcribe with Whisper
// (Same as Example 1, step 3)

// 4. HTTP Request - Summarize with LLM
Method: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": "Summarize this meeting transcript:\n\n{{$json.text}}"
    }
  ]
}

// 5. Email Node - Send summary to participants
To: {{$json.participantEmails}}
Subject: Meeting Summary - {{$json.roomName}}
Body: 
  Meeting: {{$json.roomName}}
  Date: {{$json.startTime}}
  Duration: {{$json.duration}}
  
  Summary:
  {{$json.summary}}
  
  Full Transcript:
  {{$json.transcript}}

// 6. Google Drive - Save transcript
File Name: Meeting_{{$json.roomName}}_{{$now}}.txt
Content: {{$json.transcript}}
```

#### Example 3: Voice-Controlled Automation

```javascript
// "Hey assistant, turn on the lights"

// 1. LiveKit audio stream → Whisper transcription

// 2. Code Node - Intent detection
const text = $json.text.toLowerCase();
const intent = {
  action: null,
  device: null
};

if (text.includes('turn on')) {
  intent.action = 'on';
} else if (text.includes('turn off')) {
  intent.action = 'off';
}

if (text.includes('lights') || text.includes('light')) {
  intent.device = 'lights';
} else if (text.includes('thermostat') || text.includes('temperature')) {
  intent.device = 'thermostat';
}

return intent;

// 3. IF Node - Check if valid command
If: {{$json.action}} !== null AND {{$json.device}} !== null

// 4. HTTP Request - Control home automation
Method: POST
URL: http://homeassistant:8123/api/services/light/turn_{{$json.action}}
Headers:
  Authorization: Bearer {{$env.HOMEASSISTANT_TOKEN}}
Body: {
  "entity_id": "light.living_room"
}

// 5. TTS Response - Confirm action
"Okay, turning {{$json.action}} the {{$json.device}}"
→ LiveKit audio publish
```

### Client SDK Integration

#### JavaScript/TypeScript (Web)

```javascript
import { Room, RoomEvent } from 'livekit-client';

// Get token from your backend (n8n webhook)
const response = await fetch('/api/get-livekit-token');
const { token, wsUrl } = await response.json();

// Connect to room
const room = new Room();
await room.connect(wsUrl, token);

// Enable microphone
await room.localParticipant.setMicrophoneEnabled(true);

// Listen for AI agent's audio response
room.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
  if (track.kind === 'audio') {
    const audioElement = track.attach();
    document.body.appendChild(audioElement);
  }
});

// Disconnect
await room.disconnect();
```

#### React Example

```jsx
import { LiveKitRoom, AudioTrack, useParticipants } from '@livekit/components-react';
import { useState, useEffect } from 'react';

function VoiceAgent() {
  const [token, setToken] = useState('');

  useEffect(() => {
    // Fetch token from n8n webhook
    fetch('/api/livekit-token')
      .then(r => r.json())
      .then(data => setToken(data.token));
  }, []);

  return (
    <LiveKitRoom
      serverUrl="wss://livekit.yourdomain.com"
      token={token}
      connect={true}
      audio={true}
      video={false}
    >
      <AudioTrack />
      <ParticipantList />
    </LiveKitRoom>
  );
}

function ParticipantList() {
  const participants = useParticipants();
  
  return (
    <div>
      <h3>In Room: {participants.length}</h3>
      {participants.map(p => (
        <div key={p.identity}>{p.name}</div>
      ))}
    </div>
  );
}
```

### AI Voice Agent Use Cases

**Customer Support Bot:**
- User calls in via browser
- LiveKit streams audio to n8n
- Whisper transcribes in real-time
- LLM generates contextual responses
- TTS synthesizes natural voice
- Bot responds conversationally

**Language Learning Assistant:**
- Student practices conversation
- AI analyzes pronunciation
- Provides instant feedback
- Tracks progress over time

**Voice-Controlled Smart Home:**
- "Turn on the lights"
- LiveKit → Whisper → Intent detection
- n8n triggers home automation
- TTS confirms action

**Live Translation Service:**
- Multi-language conference
- Real-time transcription
- Translation via LibreTranslate
- TTS in target language

### Security & Token Permissions

**Why JWT Authentication:**
- ✅ Tokens expire automatically
- ✅ Granular permissions per room
- ✅ Backend controls access
- ✅ No shared passwords
- ✅ Revocable per session

**Token Permission Levels:**

```javascript
// Minimal permissions (listen only)
token.addGrant({
  roomJoin: true,
  room: 'room-name',
  canPublish: false,    // Cannot speak
  canSubscribe: true    // Can hear others
});

// Full permissions (speak and listen)
token.addGrant({
  roomJoin: true,
  room: 'room-name',
  canPublish: true,     // Can speak
  canSubscribe: true    // Can hear others
});

// Admin permissions
token.addGrant({
  roomJoin: true,
  room: 'room-name',
  canPublish: true,
  canSubscribe: true,
  roomAdmin: true       // Can kick users, end room
});
```

### Troubleshooting

**No Audio/Video (Most Common):**

```bash
# 1. Check if LiveKit server is running
docker ps | grep livekit

# Should show:
# livekit-server (Up)
# livekit-sfu (Up)

# 2. Check server logs
docker logs livekit-server --tail 100
docker logs livekit-sfu --tail 100

# Look for:
# - "Started SFU" ✅
# - "Failed to bind" ❌ Port conflict
# - "ICE failed" ❌ Network issues

# 3. Verify UDP ports are open
sudo netstat -ulnp | grep 50000

# Should show listening ports 50000-50100

# 4. Test UDP connectivity
# (Use Pre-Installation UDP Test from above)

# 5. Check public IP configuration
grep JVB_DOCKER_HOST_ADDRESS .env

# Should show your public IP
```

**Token Authentication Errors:**

```bash
# 1. Check API Key/Secret in .env
cat .env | grep LIVEKIT

# Should show:
# LIVEKIT_API_KEY=...
# LIVEKIT_API_SECRET=...

# 2. Verify token generation
# Invalid tokens fail with "401 Unauthorized"
bash scripts/generate_livekit_token.sh

# 3. Test token at LiveKit Playground
# https://agents-playground.livekit.io

# 4. Check token expiration
# Tokens expire - generate new ones for each session
```

**WebSocket Connection Failed:**

```bash
# 1. Check Caddy reverse proxy
docker logs caddy | grep livekit

# Should show successful proxy routes

# 2. Test WebSocket connection
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test123" \
  https://livekit.yourdomain.com

# Should return: 101 Switching Protocols

# 3. Verify DNS resolution
nslookup livekit.yourdomain.com

# 4. Check SSL certificate
curl -v https://livekit.yourdomain.com 2>&1 | grep SSL
```

**Media Stream Issues:**

```bash
# 1. Check SFU (Selective Forwarding Unit) logs
docker logs livekit-sfu --tail 100

# Look for ICE negotiation errors

# 2. Verify public IP is correct
# LiveKit needs to know your public IP for ICE candidates
curl ifconfig.me
# Compare with JVB_DOCKER_HOST_ADDRESS in .env

# 3. Test from different networks
# Try connecting from mobile data vs WiFi
# Helps identify firewall/NAT issues

# 4. Enable detailed logging
# In docker-compose.yml, set:
# LIVEKIT_LOG_LEVEL=debug

# 5. Monitor bandwidth
docker stats livekit-server livekit-sfu
# High CPU/network? May indicate media routing issues
```

**UDP Blocked by Provider:**

If UDP test fails and your provider blocks UDP:

**Option 1: Use TCP Fallback** (higher latency)
```bash
# Configure LiveKit to use TCP port 7882
# Already configured in AI CoreKit
# But expect ~50-100ms additional latency
```

**Option 2: Use TURN Server** (complex)
```bash
# Set up coturn or managed TURN service
# Configure in LiveKit ICE servers
# Requires additional server/service
```

**Option 3: Switch VPS Provider**
```bash
# Recommended: Hetzner Cloud, DigitalOcean
# Test UDP BEFORE migrating
```

**Option 4: Use LiveKit Cloud**
```bash
# Managed LiveKit hosting
# https://livekit.io/cloud
# No UDP configuration needed
```

### Performance & Monitoring

**Resource Requirements:**
- **Bandwidth:** 50-100 kbps per audio stream
- **CPU:** ~0.5 cores per 10 audio participants
- **RAM:** 512MB base + 50MB per active room
- **Participants:** Tested up to 100 audio streams per VPS

**LiveKit Admin API:**

```bash
# List active rooms
curl -X GET http://livekit-server:7881/rooms \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# Get room details
curl -X GET http://livekit-server:7881/rooms/my-room \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# End a room (kick all participants)
curl -X DELETE http://livekit-server:7881/rooms/my-room \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# List participants in room
curl -X GET http://livekit-server:7881/rooms/my-room/participants \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"
```

**Webhook Events for n8n:**

Configure webhooks to receive real-time events:
- `room_started` - Room created
- `room_finished` - Room closed
- `participant_joined` - User joins
- `participant_left` - User leaves
- `track_published` - Audio/video stream starts
- `track_unpublished` - Audio/video stream stops
- `recording_finished` - Recording complete

### Integration with AI CoreKit Services

**LiveKit + Whisper (STT):**
- Stream audio from LiveKit rooms
- Transcribe in real-time with Whisper
- URL: `http://faster-whisper:8000`

**LiveKit + OpenedAI-Speech (TTS):**
- Generate AI voice responses
- Publish audio back to LiveKit room
- URL: `http://openedai-speech:8000`

**LiveKit + Ollama/OpenAI:**
- Process transcribed text with LLM
- Generate intelligent responses
- Complete voice agent pipeline

**LiveKit + n8n:**
- Orchestrate entire voice agent workflow
- Handle webhooks and events
- Manage state and conversation flow

### Resources

- **Official Documentation**: [docs.livekit.io](https://docs.livekit.io/)
- **SDK Examples**: [github.com/livekit/livekit-examples](https://github.com/livekit/livekit-examples)
- **Agents Playground**: [agents-playground.livekit.io](https://agents-playground.livekit.io)
- **Discord Community**: [livekit.io/discord](https://livekit.io/discord)
- **API Reference**: [docs.livekit.io/reference/server/server-apis](https://docs.livekit.io/reference/server/server-apis/)
- **Client SDKs**: JavaScript, React, Flutter, Swift, Kotlin, Go, Python

### Production Checklist

Before deploying LiveKit voice agents to production:

- [ ] UDP ports 50000-50100 verified open and accessible
- [ ] TCP port 7882 accessible as fallback
- [ ] API Key and Secret stored securely in environment variables
- [ ] Token generation tested and working
- [ ] WebSocket connection verified (`wss://livekit.yourdomain.com`)
- [ ] Audio stream flow validated (User → LiveKit → n8n → AI → User)
- [ ] Monitoring webhooks configured in n8n
- [ ] Client SDK integrated and tested
- [ ] Error handling implemented for network failures
- [ ] Latency measured (<100ms target for voice)
- [ ] Bandwidth requirements calculated
- [ ] Scaling plan defined (SFU can handle 100+ streams)
- [ ] Security audit completed (JWT permissions, token expiration)
- [ ] SSL certificate valid and auto-renewing
- [ ] Backup/failover strategy in place
