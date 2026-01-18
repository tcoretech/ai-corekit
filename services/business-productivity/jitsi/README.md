# 📹 Jitsi Meet - Video Conferencing

### What is Jitsi Meet?

Jitsi Meet is a professional, self-hosted video conferencing platform that provides secure, feature-rich meetings without external dependencies. It integrates seamlessly with Cal.com for automated meeting room generation, making it perfect for client calls, team meetings, webinars, and remote collaboration.

### ⚠️ CRITICAL Requirements

**UDP Port 10000 is MANDATORY for audio/video:**
- Without UDP 10000: Only chat works, NO audio/video!
- Many VPS providers block UDP traffic by default
- Test UDP connectivity BEFORE relying on Jitsi for production
- Alternative: Use external services (Zoom, Google Meet) with Cal.com

### Pre-Installation UDP Test

**Before installing Jitsi, verify UDP works on your VPS:**

```bash
# 1. Open UDP port in firewall
sudo ufw allow 10000/udp

# 2. Test UDP connectivity (requires two terminals)
# Terminal 1 (on your VPS):
nc -u -l 10000

# Terminal 2 (from external network, e.g., your laptop):
nc -u YOUR_VPS_IP 10000
# Type some text and press Enter
# If text appears in Terminal 1, UDP works! ✅
# If nothing appears, UDP is blocked by your provider ❌
```

### VPS Provider Compatibility

**Known to work well with Jitsi:**
- ✅ **Hetzner Cloud** - WebRTC-friendly, recommended
- ✅ **DigitalOcean** - Good WebRTC performance
- ✅ **Contabo** - Game server support = UDP OK
- ✅ **Vultr** - Good for real-time applications

**Often problematic:**
- ❌ **OVH** - Frequently blocks UDP traffic
- ❌ **Scaleway** - Strict firewall restrictions
- ⚠️ **AWS/GCP** - Requires NAT configuration (advanced)

### Features

- **No Authentication Required** - Guest-friendly for meeting participants
- **Lobby Mode** - Control who enters your meetings
- **HD Video** - Up to 1280x720 resolution
- **Screen Sharing** - Share desktop or specific applications
- **Recording** - Optional local recording (requires extra setup)
- **Mobile Apps** - iOS and Android native apps
- **Cal.com Integration** - Automatic meeting room generation
- **End-to-End Encryption** - Optional E2EE for sensitive meetings
- **Chat & Reactions** - In-meeting text chat and emoji reactions

### Initial Setup

**Test Jitsi After Installation:**

1. Navigate to `https://meet.yourdomain.com`
2. Create a test room: `https://meet.yourdomain.com/test123`
3. Allow camera/microphone permissions
4. Verify:
   - ✅ You can see yourself on video
   - ✅ Audio is working
   - ✅ Screen sharing works
5. Test from different network (mobile phone with 4G)

**Architecture:**

Jitsi consists of multiple components:
- **jitsi-web** - Web interface
- **jitsi-prosody** - XMPP server for signaling
- **jitsi-jicofo** - Focus component (manages sessions)
- **jitsi-jvb** - Video bridge (handles media streams via UDP 10000)

### Cal.com Integration

**Automatic Video Conferencing for Bookings:**

#### 1. Install Jitsi App in Cal.com

1. Open Cal.com: `https://cal.yourdomain.com`
2. Go to **Settings** → **Apps**
3. Find **Jitsi Video**
4. Click **Install App**
5. Configure:
   - **Server URL:** `https://meet.yourdomain.com`
   - No trailing slash!
6. Click **Save**

#### 2. Configure Event Types

1. Go to **Event Types**
2. Edit any event type (or create new)
3. Under **Location**, select **Jitsi Video**
4. Save changes

**Meeting links are now auto-generated!**

#### 3. Meeting URL Format

When someone books a meeting:
- **Automatic format:** `https://meet.yourdomain.com/cal/[booking-reference]`
- **Example:** `https://meet.yourdomain.com/cal/abc123def456`

Both you and the attendee receive this link in confirmation emails.

### n8n Integration

**Automated Meeting Workflows:**

#### Example 1: Meeting Reminders

```javascript
// 1. Cal.com Webhook Trigger - booking.created
// Fires when someone books a meeting

// 2. Code Node - Calculate reminder time
const booking = $json;
const meetingTime = new Date(booking.startTime);
const reminderTime = new Date(meetingTime.getTime() - 3600000); // 1 hour before

return {
  attendeeEmail: booking.attendees[0].email,
  meetingTitle: booking.title,
  meetingUrl: `https://meet.yourdomain.com/cal/${booking.uid}`,
  reminderTime: reminderTime.toISOString(),
  attendeeName: booking.attendees[0].name,
  hostName: booking.user.name
};

// 3. Wait Node - Until reminder time
Wait Until: {{$json.reminderTime}}

// 4. Send Email Node - Reminder to attendee
To: {{$('Code Node').json.attendeeEmail}}
Subject: Meeting reminder - {{$('Code Node').json.meetingTitle}}
Message: |
  Hi {{$('Code Node').json.attendeeName}},
  
  Your meeting with {{$('Code Node').json.hostName}} starts in 1 hour!
  
  📅 Meeting: {{$('Code Node').json.meetingTitle}}
  🔗 Join here: {{$('Code Node').json.meetingUrl}}
  
  See you soon!

// 5. Slack Node - Notify team
Channel: #meetings
Message: |
  🔔 Upcoming meeting in 1 hour
  Meeting: {{$('Code Node').json.meetingTitle}}
  Attendee: {{$('Code Node').json.attendeeName}}
  Link: {{$('Code Node').json.meetingUrl}}
```

#### Example 2: Post-Meeting Follow-up

```javascript
// 1. Cal.com Webhook Trigger - booking.completed
// Fires after meeting ends (based on scheduled duration)

// 2. Wait Node - 5 minutes after meeting
Wait: 5 minutes

// 3. Send Email Node - Thank you + feedback
To: {{$json.attendees[0].email}}
Subject: Thanks for the meeting!
Message: |
  Hi {{$json.attendees[0].name}},
  
  Thanks for meeting with us today!
  
  We'd love your feedback:
  [Feedback Form Link]
  
  Next steps:
  - We'll send the summary by EOD
  - Follow-up meeting in 2 weeks
  
  Best regards,
  {{$json.user.name}}

// 4. HTTP Request - Create task in project management
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Body: {
  "title": "Follow up with {{$json.attendees[0].name}}",
  "description": "Meeting: {{$json.title}}\nDate: {{$json.startTime}}",
  "due_date": "{{$now.plus(2, 'weeks').toISO()}}"
}
```

#### Example 3: AI Meeting Transcription

```javascript
// Requires Whisper service

// 1. Cal.com Webhook - booking.created
// 2. Wait Until - Meeting time
// 3. Wait - Meeting duration + 5 minutes
// 4. Check if recording exists (manual recording required)
// 5. If recording exists:
//    - Transcribe with Whisper
//    - Summarize with OpenAI
//    - Email summary to participants
```

### Security & Access Control

**Why No Basic Auth?**
- Meeting participants need direct URL access
- Mobile apps expect direct connection
- Cal.com integration requires open access
- Security is handled at room level, not site level

**Room-Level Security Options:**

1. **Lobby Mode** (Recommended)
   - Host must approve participants before entry
   - Prevents unwanted guests
   - Enable in meeting settings

2. **Meeting Passwords**
   - Add password to room URL
   - Format: `https://meet.yourdomain.com/SecureRoom123?jwt=password`
   - Share password separately from link

3. **Unique Room Names**
   - Use long, random room names
   - Avoid predictable names like "sales-call"
   - Example: `https://meet.yourdomain.com/xK9mP2nQ4vL7`

4. **Time-Limited Meetings**
   - Configure max meeting duration
   - Automatically end after timeout
   - Set in Jitsi configuration

### Troubleshooting

**No Audio/Video (Most Common Issue):**

```bash
# 1. Verify UDP port is open in firewall
sudo ufw status | grep 10000

# Should show:
# 10000/udp                  ALLOW       Anywhere

# 2. Check if JVB (Video Bridge) is running
docker ps | grep jitsi-jvb

# Should show container with "Up" status

# 3. Check JVB logs for errors
docker logs jitsi-jvb --tail 100

# Look for:
# - "Failed to bind" → Port conflict
# - "No candidates" → UDP blocked
# - "ICE failed" → Network issues

# 4. Test UDP from external network
# (See Pre-Installation UDP Test above)

# 5. Verify JVB host address is set correctly
grep JVB_DOCKER_HOST_ADDRESS .env

# Should show your public IP:
# JVB_DOCKER_HOST_ADDRESS=YOUR_PUBLIC_IP
```

**Participants Can't Join:**

```bash
# 1. Check all Jitsi components are running
docker ps | grep jitsi

# Should see 4 containers:
# - jitsi-web
# - jitsi-prosody
# - jitsi-jicofo
# - jitsi-jvb

# 2. Check Caddy routing
docker logs caddy | grep jitsi

# 3. Test from external browser (incognito)
# Open: https://meet.yourdomain.com

# 4. Check browser console for errors (F12)
```

**One-Way Video (You see them, they don't see you):**

```bash
# Usually indicates UDP issues for outbound traffic

# Check firewall rules
sudo iptables -L -n | grep 10000

# Restart JVB
docker compose restart jitsi-jvb

# Check if your router/firewall allows outbound UDP
# Some corporate networks block UDP
```

**Jitsi Services Not Starting:**

```bash
# Check logs for each component
docker logs jitsi-web --tail 50
docker logs jitsi-prosody --tail 50
docker logs jitsi-jicofo --tail 50
docker logs jitsi-jvb --tail 50

# Verify all passwords are generated in .env
grep JICOFO_COMPONENT_SECRET .env
grep JICOFO_AUTH_PASSWORD .env
grep JVB_AUTH_PASSWORD .env

# If any are missing, regenerate secrets:
cd ai-corekit
sudo bash ./scripts/03_generate_secrets.sh

# Restart all Jitsi services
docker compose down
docker compose up -d jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb
```

**Cal.com Integration Not Working:**

```bash
# 1. Verify Jitsi server URL in Cal.com
# Settings → Apps → Jitsi Video
# Must be: https://meet.yourdomain.com (no trailing slash)

# 2. Test manual meeting creation
# Create event in Cal.com
# Book a test meeting
# Check if Jitsi link is generated

# 3. Check Cal.com logs
docker logs calcom --tail 100 | grep -i jitsi

# 4. Verify Jitsi is accessible from Cal.com container
docker exec calcom curl https://meet.yourdomain.com
# Should return HTML, not error
```

**UDP Blocked by VPS Provider (No Solution):**

If UDP test fails and provider won't enable it:

**Alternative Solutions:**
1. **Use External Services**
   - Configure Cal.com with Zoom instead
   - Or Google Meet integration
   - Both work well with Cal.com

2. **Change VPS Provider**
   - Migrate to Hetzner, DigitalOcean, or Contabo
   - All support UDP for WebRTC

3. **Set up TURN Server** (Advanced)
   - Falls back to TURN when UDP fails
   - Requires additional VPS with UDP
   - More complex configuration

4. **Use Jitsi as a Service**
   - Free: https://meet.jit.si
   - Paid: https://8x8.vc
   - Configure in Cal.com instead

### Performance Tips

**Bandwidth Requirements:**
- **Video:** 2-4 Mbps per participant (HD)
- **Audio only:** 50-100 Kbps per participant
- **Screen share:** +1-2 Mbps

**Server Resources:**
- **CPU:** ~1 core per 10 participants
- **RAM:** 1-2GB for Jitsi services
- **Tested:** Up to 35 participants on 4-core VPS

**Best Practices:**
- Use **lobby mode** for meetings >10 people
- Disable video for large meetings (audio only)
- Use **720p** instead of 1080p (better performance)
- Limit screen sharing to one person at a time
- Consider external service for >30 participants

### Advanced Configuration

**Enable Recording:**

Requires additional setup:
1. Install Jibri (Jitsi recording service)
2. Configure storage location
3. Enable in meeting settings

**Custom Branding:**

Edit Jitsi config to customize:
- Logo and colors
- Welcome page text
- Room name format
- Default settings

**Integration with Other Tools:**

- **Matrix/Element** - Bridge Jitsi to Matrix rooms
- **Slack/Discord** - Start Jitsi calls from chat
- **WordPress** - Embed Jitsi on website

### Resources

- **Official Documentation:** https://jitsi.github.io/handbook/
- **Community Forum:** https://community.jitsi.org/
- **GitHub:** https://github.com/jitsi/jitsi-meet
- **Docker Setup:** https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker
- **Mobile Apps:**
  - iOS: https://apps.apple.com/app/jitsi-meet/id1165103905
  - Android: https://play.google.com/store/apps/details?id=org.jitsi.meet

### Best Practices

**For Hosts:**
- Test meeting room before important calls
- Use lobby mode for client meetings
- Share meeting link 24h before call
- Keep room names professional
- Have backup plan (phone number, Zoom link)

**For Participants:**
- Join 2-3 minutes early to test audio/video
- Use headphones to avoid echo
- Mute when not speaking
- Use "Raise hand" feature for questions
- Stable internet connection (wired > WiFi)

**For Organizations:**
- Create naming convention for meeting rooms
- Set up automated reminders (n8n)
- Monitor server resources during large meetings
- Have IT support contact ready
- Document setup for team members
