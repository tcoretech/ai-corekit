# 📅 Cal.com - Scheduling Platform

### What is Cal.com?

Cal.com is a powerful open-source scheduling platform that provides a self-hosted alternative to Calendly. It offers automated booking workflows, team scheduling, payment integration, and seamless n8n integration for comprehensive automation. Perfect for managing client meetings, consultations, and team calendars.

### Features

- **Event Types** - Multiple meeting types: 15min, 30min, 1-on-1, team meetings, recurring events
- **Team Scheduling** - Round-robin assignment, collective availability, team event types
- **Video Integration** - Auto-generated links for Jitsi, Zoom, Google Meet, Teams
- **Payment Processing** - Stripe and PayPal for paid consultations
- **Custom Fields** - Collect additional information during booking
- **Native n8n Integration** - Built-in Cal.com trigger and action nodes
- **Webhooks** - Real-time events for booking.created, cancelled, rescheduled, completed

### Initial Setup

**First Login to Cal.com:**

1. Navigate to `https://cal.yourdomain.com`
2. **First user becomes admin** - Register your account
3. Complete onboarding wizard:
   - Set your availability schedule (working hours)
   - Connect calendar services (Google Calendar, Office 365 - optional)
   - Create event types (15min call, 30min meeting, etc.)
4. Your booking link: `https://cal.yourdomain.com/[username]`

**Generate API Key for n8n:**

1. Go to **Settings** → **Developer** → **API Keys**
2. Click **Create new API key**
3. Name it `n8n Integration`
4. Copy and save securely

### n8n Integration Setup

Cal.com has **native n8n nodes** - no manual configuration needed!

#### Cal.com Trigger Node

**Listen for booking events in real-time:**

1. Add **Cal.com Trigger** node to workflow
2. Create Cal.com credentials:
   - Click **Create New Credential**
   - **API Key:** Paste your Cal.com API key
   - **Base URL:** `http://calcom:3000` (internal) or `https://cal.yourdomain.com` (external)
   - Save
3. Select trigger events:
   - `booking.created` - New booking made
   - `booking.rescheduled` - Booking time changed
   - `booking.cancelled` - Booking cancelled
   - `booking.completed` - Meeting finished
   - `booking.rejected` - Booking rejected (if approval required)
   - `booking.requested` - Booking awaits approval
4. Activate workflow

**The trigger fires automatically when events occur!**

#### Cal.com Node (Actions)

**Perform actions in Cal.com:**

Available operations:
- **Event Types** - List, get, create, update, delete event types
- **Bookings** - List, get, cancel, confirm bookings
- **Availability** - Get/set availability schedules
- **Users** - Get user information
- **Webhooks** - Manage webhooks programmatically

### Jitsi Meet Integration

**Automatic Video Conferencing:**

1. Settings → **Apps**
2. Find **Jitsi Video**
3. Click **Install App**
4. Configure:
   - **Server URL:** `https://meet.yourdomain.com`
   - No trailing slash!
5. Save

**Configure Event Types:**
1. Edit any event type
2. Under **Location**, select **Jitsi Video**
3. Save

**Meeting URLs are auto-generated:**
- Format: `https://meet.yourdomain.com/cal/[booking-reference]`
- Included in confirmation emails automatically

### Example Workflows

#### Example 1: Automated Booking Confirmation

```javascript
// Complete workflow for new bookings

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Extract booking data
const booking = $json;
return {
  attendeeName: booking.attendees[0].name,
  attendeeEmail: booking.attendees[0].email,
  meetingTitle: booking.title,
  startTime: new Date(booking.startTime).toLocaleString('de-DE'),
  endTime: new Date(booking.endTime).toLocaleString('de-DE'),
  meetingUrl: `https://meet.yourdomain.com/cal/${booking.uid}`,
  eventType: booking.eventType.title,
  organizerName: booking.organizer.name
};

// 3. Slack Node - Notify team
Channel: #sales
Message: |
  📅 New Booking!
  
  Customer: {{$json.attendeeName}}
  Meeting: {{$json.meetingTitle}}
  Time: {{$json.startTime}}
  Link: {{$json.meetingUrl}}

// 4. Google Calendar Node - Create calendar event
Operation: Create Event
Calendar: Sales Team Calendar
Summary: {{$('Code').json.meetingTitle}}
Description: |
  Meeting with {{$('Code').json.attendeeName}}
  Join: {{$('Code').json.meetingUrl}}
Start: {{$json.startTime}}
End: {{$json.endTime}}

// 5. Send Email Node - Custom confirmation
To: {{$('Code').json.attendeeEmail}}
Subject: Meeting Confirmed - {{$('Code').json.meetingTitle}}
Message: |
  Hi {{$('Code').json.attendeeName}},
  
  Your meeting with {{$('Code').json.organizerName}} is confirmed!
  
  📅 Date & Time: {{$('Code').json.startTime}}
  🔗 Join meeting: {{$('Code').json.meetingUrl}}
  
  Looking forward to speaking with you!

// 6. Baserow/NocoDB Node - Add to CRM
Table: bookings
Fields: {
  customer_name: {{$('Code').json.attendeeName}},
  customer_email: {{$('Code').json.attendeeEmail}},
  meeting_type: {{$('Code').json.eventType}},
  scheduled_time: {{$json.startTime}},
  status: "confirmed"
}
```

#### Example 2: Meeting Reminder System

```javascript
// Automated reminders 1 hour before meeting

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Calculate reminder time
const meetingTime = new Date($json.startTime);
const reminderTime = new Date(meetingTime.getTime() - 3600000); // 1 hour before

return {
  attendeeEmail: $json.attendees[0].email,
  attendeeName: $json.attendees[0].name,
  meetingTitle: $json.title,
  meetingUrl: `https://meet.yourdomain.com/cal/${$json.uid}`,
  reminderTime: reminderTime.toISOString(),
  hostName: $json.user.name
};

// 3. Wait Node
Wait Until: {{$json.reminderTime}}

// 4. Send Email Node - Reminder
To: {{$('Code Node').json.attendeeEmail}}
Subject: Meeting Reminder - Starts in 1 hour!
Message: |
  Hi {{$('Code Node').json.attendeeName}},
  
  Your meeting with {{$('Code Node').json.hostName}} starts in 1 hour!
  
  📅 Meeting: {{$('Code Node').json.meetingTitle}}
  🕐 Time: In 1 hour
  🔗 Join here: {{$('Code Node').json.meetingUrl}}
  
  See you soon!

// 5. SMS Node (optional - via Twilio)
// Send SMS reminder for mobile notification
```

#### Example 3: AI-Enhanced Meeting Preparation

```javascript
// Research and prepare briefing before meeting

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Extract company domain
const attendeeEmail = $json.attendees[0].email;
const companyDomain = attendeeEmail.split('@')[1];

return {
  attendeeName: $json.attendees[0].name,
  attendeeEmail: attendeeEmail,
  companyDomain: companyDomain,
  meetingTitle: $json.title,
  meetingTime: $json.startTime,
  bookingId: $json.id
};

// 3. HTTP Request - Research company (via Perplexica)
Method: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{$json.companyDomain}} company information, recent news, key people",
  "focusMode": "webSearch"
}

// 4. OpenAI Node - Generate meeting briefing
Model: gpt-4o-mini
System Message: "You are a meeting preparation assistant."
User Message: |
  Create a concise meeting briefing for:
  
  Meeting: {{$('Code Node').json.meetingTitle}}
  Attendee: {{$('Code Node').json.attendeeName}}
  Company: {{$('Code Node').json.companyDomain}}
  
  Research findings:
  {{$json.results}}
  
  Include:
  1. Company background (2-3 sentences)
  2. Recent news or developments
  3. Key talking points
  4. Questions to ask

// 5. Wait Node
Wait until: 30 minutes before meeting

// 6. Slack Node - Send briefing to host
Channel: @{{$('Code Node').json.hostName}}
Message: |
  📋 Meeting Briefing
  
  Meeting in 30 minutes with {{$('Code Node').json.attendeeName}}
  
  {{$('OpenAI').json.briefing}}

// 7. Cal.com Node - Add notes to booking
Operation: Update Booking
Booking ID: {{$('Code Node').json.bookingId}}
Notes: {{$('OpenAI').json.briefing}}
```

#### Example 4: Post-Meeting Follow-up

```javascript
// Automated follow-up after meeting completes

// 1. Cal.com Trigger Node
Event: booking.completed

// 2. Wait Node
Wait: 1 hour after meeting end

// 3. Send Email Node - Thank you & feedback
To: {{$json.attendees[0].email}}
Subject: Thanks for the meeting!
Message: |
  Hi {{$json.attendees[0].name}},
  
  Thanks for meeting with us today!
  
  📝 We'd love your feedback:
  https://forms.yourdomain.com/meeting-feedback?id={{$json.id}}
  
  Next Steps:
  - Summary will be sent by EOD
  - Follow-up meeting in 2 weeks
  
  Questions? Just reply to this email.
  
  Best regards,
  {{$json.user.name}}

// 4. HTTP Request - Create follow-up task (via Vikunja)
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Headers:
  Authorization: Bearer {{$env.VIKUNJA_API_TOKEN}}
Body: {
  "title": "Follow up with {{$json.attendees[0].name}}",
  "description": "Meeting: {{$json.title}}\nDate: {{$json.startTime}}",
  "due_date": "{{$now.plus(2, 'weeks').toISO()}}",
  "project_id": 1
}

// 5. Cal.com Node - Schedule follow-up meeting (optional)
Operation: Create Booking
Event Type: Follow-up Call
Date: {{$now.plus(2, 'weeks')}}
```

#### Example 5: Smart Scheduling with AI

```javascript
// AI-powered scheduling from natural language

// 1. Webhook Trigger - Receive scheduling request
// Example: Customer fills form or sends chat message

// 2. OpenAI Node - Parse scheduling request
Model: gpt-4o-mini
Prompt: |
  Extract scheduling preferences from this request:
  "{{$json.message}}"
  
  Return JSON:
  {
    "preferredDays": ["Monday", "Wednesday"],
    "preferredTimes": ["morning", "afternoon"],
    "duration": 30,
    "topic": "product demo",
    "urgency": "high"
  }

// 3. Cal.com Node - Get availability
Operation: Get Available Slots
Event Type: Consultation
Date Range: Next 7 days

// 4. Code Node - Rank slots by AI preferences
const slots = $json.slots;
const preferences = $('OpenAI').json;

// Score each slot based on preferences
const rankedSlots = slots.map(slot => {
  let score = 0;
  
  // Preferred day match
  const slotDay = new Date(slot.time).toLocaleDateString('en-US', {weekday: 'long'});
  if (preferences.preferredDays.includes(slotDay)) score += 10;
  
  // Preferred time match
  const slotHour = new Date(slot.time).getHours();
  if (preferences.preferredTimes.includes('morning') && slotHour < 12) score += 5;
  if (preferences.preferredTimes.includes('afternoon') && slotHour >= 12) score += 5;
  
  // Urgency (prefer sooner)
  if (preferences.urgency === 'high') {
    const daysUntil = Math.floor((new Date(slot.time) - new Date()) / (1000 * 60 * 60 * 24));
    score += (7 - daysUntil);
  }
  
  return { ...slot, score };
}).sort((a, b) => b.score - a.score);

return rankedSlots[0]; // Best match

// 5. Cal.com Node - Create booking
Operation: Create Booking
Event Type ID: 1
Start Time: {{$json.time}}
Attendee Name: {{$('Webhook').json.name}}
Attendee Email: {{$('Webhook').json.email}}

// 6. Send Confirmation
To: {{$('Webhook').json.email}}
Subject: Meeting Scheduled!
Message: |
  Great news! Your meeting is scheduled:
  
  📅 {{$json.startTime}}
  🔗 {{$json.conferenceUrl}}
  
  This time was selected based on your preferences.
```

### Advanced API Usage

**For operations not available in the native node, use HTTP Request:**

```javascript
// Get all event types with full details
Method: GET
URL: http://calcom:3000/api/v2/event-types
Headers:
  Authorization: Bearer {{$env.CAL_API_KEY}}
  Content-Type: application/json

// Create custom availability schedule
Method: POST
URL: http://calcom:3000/api/v2/schedules
Body: {
  "name": "Summer Hours",
  "timeZone": "Europe/Berlin",
  "availability": [
    {
      "days": [1, 2, 3, 4, 5],
      "startTime": "09:00",
      "endTime": "17:00"
    }
  ]
}

// Bulk cancel bookings
Method: POST
URL: http://calcom:3000/api/v2/bookings/cancel
Body: {
  "bookingIds": [123, 124, 125],
  "reason": "Holiday closure"
}
```

### Common Webhook Payload

**booking.created event:**
```json
{
  "triggerEvent": "booking.created",
  "payload": {
    "id": 12345,
    "uid": "abc123def456",
    "title": "30 Min Meeting",
    "description": "Let's discuss the project",
    "startTime": "2025-01-20T10:00:00.000Z",
    "endTime": "2025-01-20T10:30:00.000Z",
    "organizer": {
      "name": "John Host",
      "email": "john@example.com",
      "username": "john"
    },
    "attendees": [{
      "name": "Jane Guest",
      "email": "jane@example.com"
    }],
    "eventType": {
      "id": 1,
      "title": "30 Min Meeting",
      "slug": "30min"
    },
    "location": "Jitsi Video",
    "conferenceUrl": "https://meet.yourdomain.com/cal/abc123",
    "status": "ACCEPTED"
  }
}
```

### Email Notifications

Cal.com automatically sends emails for:
- **Booking Confirmations** - To organizer and attendee
- **Reminders** - Configurable timing (15min, 1h, 1day before)
- **Cancellations** - Notification to all parties
- **Rescheduling** - Update emails with new time

All emails use your configured mail system (Mailpit for development, Docker-Mailserver for production).

### Troubleshooting

**Webhook not firing:**

```bash
# Check Cal.com logs
docker logs calcom --tail 100 | grep -i webhook

# Verify webhook is registered
# Cal.com → Settings → Webhooks
# Should show n8n webhook URL

# Test webhook manually
curl -X POST https://n8n.yourdomain.com/webhook/cal-com-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Restart Cal.com if needed
docker compose restart calcom
```

**API authentication failed:**

```bash
# Verify API key is valid
# Cal.com → Settings → Developer → API Keys
# Check key hasn't expired

# Test API key
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://cal.yourdomain.com/api/v2/me

# Should return your user info, not 401
```

**Calendar sync not working:**

```bash
# Check Cal.com can reach external calendars
docker exec calcom curl https://www.googleapis.com

# Reconnect calendar integration
# Cal.com → Settings → Apps → Google Calendar → Reconnect

# Check logs for OAuth errors
docker logs calcom | grep -i oauth
```

**Slow booking page load:**

```bash
# Check database performance
docker exec calcom-db pg_stat_activity

# Restart Cal.com services
docker compose restart calcom calcom-db

# Check server resources
docker stats calcom
```

### Resources

- **Official Documentation:** https://cal.com/docs
- **API Reference:** https://cal.com/docs/api-reference
- **GitHub:** https://github.com/calcom/cal.com
- **n8n Integration:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.calcom/
- **Community Forum:** https://github.com/calcom/cal.com/discussions

### Best Practices

**Event Type Setup:**
- Create specific types for different use cases (sales, support, consultation)
- Set appropriate buffer times between meetings
- Use location-specific event types (office vs. remote)
- Configure custom fields to collect required information

**Availability Management:**
- Set realistic working hours
- Block personal time in connected calendars
- Use multiple schedules for different seasons
- Enable "minimum notice" to avoid last-minute bookings

**n8n Integration:**
- Use internal URL (`http://calcom:3000`) for performance
- Implement error handling for failed bookings
- Add deduplication logic for webhook events
- Store API key in n8n credentials, not hardcoded

**Team Coordination:**
- Use round-robin for sales leads
- Set up collective events for panel interviews
- Configure team routing rules
- Monitor team booking metrics

**Customer Experience:**
- Customize confirmation emails with branding
- Provide clear meeting preparation instructions
- Set up automatic reminders
- Collect feedback after meetings
