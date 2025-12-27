# 📧 Mautic - Marketing Automation

### What is Mautic?

Mautic is a powerful open-source marketing automation platform that enables sophisticated lead nurturing, email campaigns, landing pages, and multi-channel marketing. With comprehensive API support and native n8n community node, Mautic allows you to create advanced marketing workflows that connect seamlessly with your entire tech stack for data-driven marketing campaigns.

### Features

- **Email Marketing** - Campaign builder, templates, A/B testing, personalization, dynamic content
- **Lead Management** - Lead scoring, segmentation, lifecycle stages, progressive profiling
- **Campaign Workflows** - Visual campaign builder with triggers, actions, and conditions
- **Landing Pages & Forms** - Drag-and-drop builder, custom fields, progressive profiling
- **Multi-Channel Marketing** - Email, SMS, web notifications, social media integration
- **Marketing Attribution** - Track customer journey, multi-touch attribution, ROI analytics
- **Advanced Segmentation** - Dynamic segments based on behavior, demographics, engagement
- **Webhooks & API** - RESTful API, OAuth 2.0, real-time webhooks for integrations
- **Lead Nurturing** - Automated drip campaigns, behavioral triggers, lead scoring rules
- **Analytics & Reporting** - Campaign performance, email metrics, conversion tracking
- **GDPR Compliance** - Consent management, data privacy controls, opt-in/opt-out tracking
- **Integration Ready** - 50+ native integrations plus n8n for unlimited connectivity

### Initial Setup

**First Login to Mautic:**

1. Navigate to `https://mautic.yourdomain.com`
2. Complete the installation wizard:
   - Admin username and email
   - Strong password (minimum 8 characters)
   - Site URL (pre-configured)
   - Complete setup wizard
3. Configure email settings:
   - Settings → Configuration → Email Settings
   - Mailpit is pre-configured (SMTP: `mailpit:1025`)
   - For production: Configure Docker-Mailserver or external SMTP
4. Enable API access:
   - Settings → Configuration → API Settings
   - Enable API: Yes
   - Enable HTTP basic auth: Yes (for simpler n8n integration)
   - Enable OAuth 2: Yes (for advanced security)
5. Generate API credentials:
   - Settings → API Credentials
   - Click "New" to create credentials
   - Choose OAuth 2 or Basic Auth
   - Save Client ID and Secret securely

**Post-Setup Configuration:**

```bash
# Access Mautic container for advanced configuration
docker exec -it mautic_web bash

# Clear cache after configuration changes
php bin/console cache:clear

# Warm up cache for better performance
php bin/console cache:warmup

# Process scheduled campaigns (cron job)
php bin/console mautic:campaigns:trigger
```

### n8n Integration Setup

**Method 1: Community Mautic Node (Recommended)**

1. In n8n, go to Settings → Community Nodes
2. Install: `@digital-boss/n8n-nodes-mautic`
3. Restart n8n (docker compose restart n8n)
4. Create Mautic credentials:
   - Type: Mautic OAuth2 API
   - Authorization URL: `http://mautic_web/oauth/v2/authorize`
   - Access Token URL: `http://mautic_web/oauth/v2/token`
   - Client ID: From Mautic API Credentials
   - Client Secret: From Mautic API Credentials
   - Scope: Leave empty for full access

**Method 2: HTTP Request with Basic Auth**

For simpler workflows without community node:

1. In n8n, create credentials:
   - Type: Header Auth
   - Header Name: `Authorization`
   - Header Value: `Basic BASE64(username:password)`
   
Or use built-in Basic Auth:
- Username: Your Mautic username
- Password: Your Mautic password

**Internal URL for n8n:** `http://mautic_web`

**API Base URL:** `http://mautic_web/api`

### Example Workflows

#### Example 1: Advanced Lead Scoring & Nurturing

Automatically score leads based on behavior and engagement:

```javascript
// AI-powered lead scoring with behavioral analysis

// 1. Webhook Trigger - Form submission from website
// Configure webhook URL in website: https://n8n.yourdomain.com/webhook/lead-capture

// 2. Code Node - Enrich lead data
const email = $json.email;
const domain = email.split('@')[1];

const leadData = {
  email: email,
  firstname: $json.firstname || '',
  lastname: $json.lastname || '',
  company: $json.company || domain,
  website: $json.website || `https://${domain}`,
  phone: $json.phone || '',
  formSource: $json.form_id || 'unknown',
  ipAddress: $json.ip_address || '',
  tags: ['website-form', $json.form_id || 'general'],
  customFields: {
    lead_source: $json.utm_source || 'direct',
    campaign: $json.utm_campaign || 'none',
    medium: $json.utm_medium || 'organic'
  }
};

return [{ json: leadData }];

// 3. Mautic Node - Create/Update Contact
Operation: Create or Update Contact
Email: {{$json.email}}
Fields:
  firstname: {{$json.firstname}}
  lastname: {{$json.lastname}}
  company: {{$json.company}}
  website: {{$json.website}}
  phone: {{$json.phone}}
  last_active: {{$now.toISO()}}
Tags: {{$json.tags.join(',')}}

// 4. HTTP Request - Check email deliverability (optional)
Method: GET
URL: https://api.zerobounce.net/v2/validate
Query Parameters:
  api_key: {{$env.ZEROBOUNCE_API_KEY}}
  email: {{$json.email}}

// 5. Code Node - Calculate lead score
const baseScore = 10; // Starting score
let score = baseScore;
let scoreFactors = [];

// Email quality scoring
const emailQuality = $('Email Validation').item.json.status;
if (emailQuality === 'valid') {
  score += 20;
  scoreFactors.push('Valid email: +20');
} else if (emailQuality === 'catch-all') {
  score += 10;
  scoreFactors.push('Catch-all email: +10');
} else if (emailQuality === 'unknown') {
  score += 5;
  scoreFactors.push('Unknown email: +5');
} else {
  score -= 10;
  scoreFactors.push('Invalid email: -10');
}

// Form source scoring
const formId = $('Enrich Data').item.json.formSource;
if (formId === 'demo-request') {
  score += 40;
  scoreFactors.push('Demo request: +40');
} else if (formId === 'contact-sales') {
  score += 35;
  scoreFactors.push('Contact sales: +35');
} else if (formId === 'whitepaper-download') {
  score += 20;
  scoreFactors.push('Whitepaper download: +20');
} else if (formId === 'newsletter') {
  score += 10;
  scoreFactors.push('Newsletter signup: +10');
}

// Company domain scoring
const domain = $('Enrich Data').item.json.email.split('@')[1];
const freeEmailDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
if (!freeEmailDomains.includes(domain)) {
  score += 15;
  scoreFactors.push('Business email: +15');
}

// Calculate segment
let segment = 'cold-leads';
if (score >= 70) segment = 'hot-leads';
else if (score >= 40) segment = 'warm-leads';

return [{
  json: {
    contactId: $('Create Contact').item.json.contact.id,
    email: $('Enrich Data').item.json.email,
    score: score,
    scoreFactors: scoreFactors,
    segment: segment,
    reasoning: scoreFactors.join(', ')
  }
}];

// 6. Mautic Node - Update lead score
Operation: Edit Contact Points
Contact ID: {{$json.contactId}}
Points: {{$json.score}}
Operator: plus

// 7. Mautic Node - Add to segment
Operation: Add Contact to Segment
Contact ID: {{$json.contactId}}
Segment ID: Get segment ID based on {{$json.segment}}

// 8. Mautic Node - Trigger campaign
Operation: Add Contact to Campaign
Contact ID: {{$json.contactId}}
Campaign ID: {{$json.score >= 70 ? 'sales-outreach-campaign-id' : 'nurture-campaign-id'}}

// 9. IF Node - High-value lead alert
Condition: {{$json.score}} >= 80

// Branch: High-Value Leads
// 10a. Slack Node - Alert sales team
Channel: #sales-hot-leads
Message: |
  🔥 **High-Value Lead Alert!**
  
  Name: {{$('Create Contact').item.json.contact.fields.all.firstname}} {{$('Create Contact').item.json.contact.fields.all.lastname}}
  Email: {{$json.email}}
  Company: {{$('Create Contact').item.json.contact.fields.all.company}}
  Score: {{$json.score}}/100
  
  Scoring: {{$json.reasoning}}
  
  👉 Immediate follow-up recommended!

// 11a. Twenty CRM HTTP Request - Create opportunity
Method: POST
URL: http://twenty-crm:3000/rest/opportunities
Body (JSON):
{
  "name": "Hot Lead: {{$('Create Contact').item.json.contact.fields.all.company}}",
  "amount": 0,
  "stage": "New",
  "companyId": "lookup-or-create-company",
  "customFields": {
    "leadScore": {{$json.score}},
    "source": "mautic",
    "mauticContactId": "{{$json.contactId}}"
  }
}

// 12a. Cal.com HTTP Request - Offer priority booking
Method: POST
URL: http://cal:3000/api/booking-links
Body (JSON):
{
  "eventTypeId": 123, // Sales demo event type
  "name": "{{$('Create Contact').item.json.contact.fields.all.firstname}} {{$('Create Contact').item.json.contact.fields.all.lastname}}",
  "email": "{{$json.email}}",
  "customNote": "High-value lead (Score: {{$json.score}})"
}

// 13a. Email Node - Send priority booking link
To: {{$json.email}}
Subject: Quick question about {{$('Create Contact').item.json.contact.fields.all.company}}
Body: |
  Hi {{$('Create Contact').item.json.contact.fields.all.firstname}},
  
  Thank you for your interest! Based on your company profile,
  I'd love to show you how we can help.
  
  Book a priority demo slot: {{$('Cal.com Booking').json.bookingLink}}
  
  Looking forward to speaking with you!
  
  Best regards,
  Sales Team
```

#### Example 2: Multi-Channel Campaign Orchestration

Coordinate campaigns across email, SMS, and social media:

```javascript
// Intelligent multi-channel marketing automation

// 1. Schedule Trigger - Daily at 9 AM

// 2. Mautic Node - Get campaign contacts
Operation: Get Contacts
Segment ID: active-campaign-recipients-segment-id
Filters:
  - isPublished: true
  - dnc: 0  // Do Not Contact = false
Limit: 100

// 3. Loop Over Items - Process each contact

// 4. Mautic Node - Get contact activity
Operation: Get Contact Activity
Contact ID: {{$json.id}}
Date From: {{$now.minus(7, 'days').toISO()}}
Include Events: true

// 5. Code Node - Determine next best action
const activity = $input.first().json.events || [];
const contact = $('Loop Over Items').item.json;

// Analyze engagement patterns
const lastEmail = activity.filter(a => a.type === 'email.read').sort((a,b) => 
  new Date(b.timestamp) - new Date(a.timestamp))[0];
const lastClick = activity.filter(a => a.type === 'page.hit').sort((a,b) => 
  new Date(b.timestamp) - new Date(a.timestamp))[0];

const daysSinceEmail = lastEmail ? 
  Math.floor((new Date() - new Date(lastEmail.timestamp)) / (1000 * 60 * 60 * 24)) : 999;
const daysSinceClick = lastClick ?
  Math.floor((new Date() - new Date(lastClick.timestamp)) / (1000 * 60 * 60 * 24)) : 999;

// Engagement scoring
const engagementScore = activity.length;
let nextAction = 'email';
let content = 'standard';
let channel = 'email';

if (lastClick && daysSinceClick < 2) {
  // High recent engagement - be aggressive
  nextAction = 'sms';
  content = 'urgent-offer';
  channel = 'sms';
} else if (lastEmail && !lastClick && daysSinceEmail < 7) {
  // Email opened but no action - try different content
  nextAction = 'email';
  content = 'alternative-content';
  channel = 'email';
} else if (daysSinceEmail > 14) {
  // Inactive - reactivation campaign
  nextAction = 'reactivation';
  content = 'win-back';
  channel = 'email';
} else if (engagementScore > 10 && daysSinceEmail < 3) {
  // Very engaged - personal outreach
  nextAction = 'personal-outreach';
  content = 'direct-call';
  channel = 'phone';
}

return [{
  json: {
    contactId: contact.id,
    email: contact.fields.all.email,
    firstname: contact.fields.all.firstname,
    phone: contact.fields.all.phone,
    nextAction,
    content,
    channel,
    engagementScore,
    daysSinceEmail
  }
}];

// 6. Switch Node - Route by channel

// Branch: Email
// 7a. Mautic Node - Send email
Operation: Send Email to Contact
Email ID: {{$json.content === 'urgent-offer' ? 'email-15' : 
           $json.content === 'alternative-content' ? 'email-12' :
           $json.content === 'win-back' ? 'email-20' : 'email-10'}}
Contact ID: {{$json.contactId}}

// Branch: SMS
// 7b. HTTP Request - Send SMS via Twilio
Method: POST
URL: https://api.twilio.com/2010-04-01/Accounts/{{$env.TWILIO_ACCOUNT_SID}}/Messages.json
Authentication: Basic Auth
Username: {{$env.TWILIO_ACCOUNT_SID}}
Password: {{$env.TWILIO_AUTH_TOKEN}}
Body (Form):
  To: {{$json.phone}}
  From: {{$env.TWILIO_PHONE_NUMBER}}
  Body: "Exclusive offer ending soon! Check your email for details. - {{$env.COMPANY_NAME}}"

// Branch: Personal Outreach
// 7c. Create task for sales rep
// HTTP Request - Create task in Vikunja
Method: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body (JSON):
{
  "title": "Call {{$json.firstname}} - High Engagement",
  "description": "Contact has {{$json.engagementScore}} recent interactions. Follow up personally.",
  "priority": 3,
  "dueDate": "{{$now.plus(1, 'day').toISO()}}",
  "labels": ["hot-lead", "personal-outreach"]
}

// Branch: Reactivation
// 7d. Mautic Node - Remove from current campaign
Operation: Remove Contact from Campaign
Contact ID: {{$json.contactId}}
Campaign ID: current-campaign-id

// 7e. Mautic Node - Add to win-back campaign
Operation: Add Contact to Campaign
Contact ID: {{$json.contactId}}
Campaign ID: win-back-campaign-id

// 8. Mautic Node - Log custom activity
Operation: Add Contact Note
Contact ID: {{$json.contactId}}
Note: |
  Multi-channel action triggered: {{$json.nextAction}}
  Channel: {{$json.channel}}
  Engagement score: {{$json.engagementScore}}
  Last email: {{$json.daysSinceEmail}} days ago

// 9. HTTP Request - Update analytics dashboard
Method: POST
URL: http://metabase:3000/api/card/campaign-performance/refresh
Headers:
  X-Metabase-Session: {{$env.METABASE_SESSION}}
```

#### Example 3: Dynamic Content Personalization with AI

Create personalized content based on lead behavior and AI analysis:

```javascript
// AI-powered content personalization engine

// 1. Mautic Webhook - Email opened
// Configure in Mautic: Webhooks → Create webhook for "Email Opened" event

// 2. HTTP Request - Get contact full profile
Method: GET
URL: http://mautic_web/api/contacts/{{$json.contact.id}}
Authentication: Use Mautic credentials

// 3. Code Node - Prepare personalization context
const contact = $input.first().json.contact;
const fields = contact.fields.all;

const personalizationContext = {
  firstname: fields.firstname || 'there',
  company: fields.company || 'your company',
  industry: fields.industry || 'your industry',
  leadScore: contact.points || 0,
  tags: contact.tags.map(t => t.tag).join(', '),
  utmSource: fields.utm_source || 'direct',
  lastActive: fields.last_active || 'recently',
  customFields: {
    jobTitle: fields.job_title || '',
    companySize: fields.company_size || '',
    interests: fields.interests || ''
  }
};

return [{ json: personalizationContext }];

// 4. OpenAI Node - Generate personalized content
Operation: Message a Model
Model: gpt-4o-mini
Messages:
  System: "You are a marketing content specialist creating personalized email content."
  User: |
    Create a personalized email follow-up for:
    - Name: {{$json.firstname}}
    - Company: {{$json.company}}
    - Industry: {{$json.industry}}
    - Job Title: {{$json.customFields.jobTitle}}
    - Lead Score: {{$json.leadScore}}
    - Interests: {{$json.customFields.interests}}
    - Previous interactions: {{$json.tags}}
    - Traffic source: {{$json.utmSource}}
    
    Focus on their pain points and our solution benefits.
    Include a clear CTA appropriate for their lead score.
    Keep it under 150 words.
    Use a friendly, professional tone.

// 5. Code Node - Build dynamic email template
const aiContent = $input.first().json.message.content;
const context = $('Prepare Context').item.json;

const template = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Personalized for ${context.firstname}</title>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #007bff; color: white; padding: 20px; }
    .content { padding: 20px; }
    .cta { display: inline-block; padding: 12px 24px; background: #28a745; 
           color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
    .footer { font-size: 12px; color: #666; padding: 20px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Hi ${context.firstname}! 👋</h1>
    </div>
    <div class="content">
      ${aiContent}
      
      <!-- Dynamic CTA based on lead score -->
      ${context.leadScore > 70 ? 
        '<a href="{trackinglink=demo-booking}" class="cta">Schedule Your Demo</a>' :
        context.leadScore > 40 ?
        '<a href="{trackinglink=learn-more}" class="cta">Learn More</a>' :
        '<a href="{trackinglink=resources}" class="cta">View Resources</a>'
      }
      
      <!-- Dynamic product recommendations based on industry -->
      <h3>Recommended for ${context.industry}:</h3>
      ${context.industry === 'SaaS' || context.industry === 'Technology' ? 
        '{dynamiccontent="tech-features"}' :
        context.industry === 'Healthcare' ?
        '{dynamiccontent="healthcare-features"}' :
        '{dynamiccontent="enterprise-features"}'
      }
    </div>
    <div class="footer">
      <p>You're receiving this because you showed interest in our solutions.</p>
      <p><a href="{unsubscribe_url}">Unsubscribe</a> | <a href="{webview_url}">View in browser</a></p>
    </div>
  </div>
</body>
</html>
`;

return [{
  json: {
    template,
    contactId: $('Get Profile').item.json.contact.id,
    subject: `${context.firstname}, quick question about ${context.company}`
  }
}];

// 6. Mautic Node - Create dynamic email
Operation: Create Email
Name: "Personalized Follow-up - {{$now.format('YYYY-MM-DD HH:mm')}}"
Subject: {{$json.subject}}
Custom HTML: {{$json.template}}
Email Type: template

// 7. Mautic Node - Send to contact
Operation: Send Email to Contact
Email ID: {{$('Create Email').item.json.email.id}}
Contact ID: {{$json.contactId}}

// 8. Mautic Node - Log personalization
Operation: Add Contact Note
Contact ID: {{$json.contactId}}
Note: |
  AI-personalized email sent
  Subject: {{$json.subject}}
  Generated: {{$now.toISO()}}
```

#### Example 4: Lead Attribution & ROI Tracking

Track complete customer journey and calculate marketing ROI:

```javascript
// Complete attribution tracking system

// 1. Webhook Trigger - Conversion event (purchase/signup completed)
// Sent from your application when conversion happens

// 2. Mautic Node - Get contact journey
Operation: Get Contact
Contact ID: {{$json.contact_id}}
Include Timeline: true

// 3. Code Node - Analyze attribution path
const contact = $input.first().json.contact;
const timeline = contact.timeline || [];
const touchpoints = [];

// Extract all marketing touchpoints
timeline.forEach(event => {
  const marketingEvents = ['email.read', 'email.sent', 'page.hit', 
                          'form.submitted', 'asset.download', 'campaign.event'];
  
  if (marketingEvents.includes(event.eventType)) {
    touchpoints.push({
      type: event.eventType,
      timestamp: event.timestamp,
      campaign: event.event.campaign?.name || null,
      email: event.event.email?.name || null,
      source: event.event.source || 'direct',
      metadata: event.event
    });
  }
});

// Sort by timestamp
touchpoints.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

// Calculate attribution weights (linear model)
const attribution = {};
const weight = touchpoints.length > 0 ? 1 / touchpoints.length : 0;

touchpoints.forEach(tp => {
  const key = tp.campaign || tp.email || tp.source || 'direct';
  attribution[key] = (attribution[key] || 0) + weight;
});

// Identify first and last touch
const firstTouch = touchpoints[0];
const lastTouch = touchpoints[touchpoints.length - 1];

// Calculate time to conversion
const firstTouchDate = firstTouch ? new Date(firstTouch.timestamp) : new Date();
const conversionDate = new Date();
const daysToConversion = Math.floor((conversionDate - firstTouchDate) / (1000 * 60 * 60 * 24));

return [{
  json: {
    contactId: contact.id,
    email: contact.fields.all.email,
    conversionValue: $('Webhook').item.json.order_value || 0,
    touchpoints: touchpoints,
    touchpointCount: touchpoints.length,
    attribution: attribution,
    firstTouch: firstTouch,
    lastTouch: lastTouch,
    daysToConversion: daysToConversion
  }
}];

// 4. HTTP Request - Update campaign ROI in database
Method: POST
URL: http://nocodb:8080/api/v2/tables/CAMPAIGN_ATTRIBUTION/records
Authentication: Use NocoDB credentials
Body (JSON):
{
  "ContactId": "{{$json.contactId}}",
  "Email": "{{$json.email}}",
  "ConversionValue": {{$json.conversionValue}},
  "TouchpointCount": {{$json.touchpointCount}},
  "FirstTouchCampaign": "{{$json.firstTouch?.campaign || 'Unknown'}}",
  "LastTouchCampaign": "{{$json.lastTouch?.campaign || 'Unknown'}}",
  "DaysToConversion": {{$json.daysToConversion}},
  "AttributionData": "{{JSON.stringify($json.attribution)}}",
  "ConversionDate": "{{$now.toISO()}}"
}

// 5. Mautic Node - Update contact with conversion data
Operation: Edit Contact
Contact ID: {{$json.contactId}}
Custom Fields:
  lifetime_value: {{$json.conversionValue}}
  conversion_date: {{$now.toISODate()}}
  touchpoint_count: {{$json.touchpointCount}}
  days_to_conversion: {{$json.daysToConversion}}

// 6. Mautic Node - Add to customer segment
Operation: Add Contact to Segment
Contact ID: {{$json.contactId}}
Segment ID: customers-segment-id

// 7. Mautic Node - Remove from lead nurture campaigns
Operation: Remove Contact from Campaign
Contact ID: {{$json.contactId}}
Campaign ID: nurture-campaign-id

// 8. Invoice Ninja Node - Create invoice (if applicable)
Operation: Create Invoice
Client: {{$json.email}}
Amount: {{$json.conversionValue}}
Description: Product purchase - Mautic tracking

// 9. Google Sheets Node - Log conversion
Operation: Append
Spreadsheet: Marketing Attribution Report
Sheet: Conversions
Data:
  - Date: {{$now.toISODate()}}
  - Contact: {{$json.email}}
  - Value: {{$json.conversionValue}}
  - First Touch: {{$json.firstTouch?.campaign}}
  - Last Touch: {{$json.lastTouch?.campaign}}
  - Days to Convert: {{$json.daysToConversion}}
  - Touchpoints: {{$json.touchpointCount}}

// 10. Slack Node - Notify team
Channel: #conversions
Message: |
  🎉 **New Conversion!**
  
  Customer: {{$json.email}}
  Value: ${{$json.conversionValue}}
  
  Journey:
  • First Touch: {{$json.firstTouch?.campaign || 'Direct'}}
  • Last Touch: {{$json.lastTouch?.campaign || 'Direct'}}
  • Time to Convert: {{$json.daysToConversion}} days
  • Total Touchpoints: {{$json.touchpointCount}}
  
  Attribution breakdown:
  {{#each $json.attribution}}
  • {{@key}}: {{(this * 100).toFixed(1)}}%
  {{/each}}
```

### Troubleshooting

**Issue 1: Webhook Not Receiving Data**

```bash
# Check Mautic webhook configuration
docker exec mautic_web php bin/console mautic:webhooks:list

# Process pending webhooks manually
docker exec mautic_web php bin/console mautic:webhooks:process

# Test webhook URL accessibility
curl -X POST https://n8n.yourdomain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check Mautic logs for webhook errors
docker logs mautic_web | grep -i webhook
```

**Solution:**
- Verify webhook URL in Mautic (Settings → Webhooks)
- Ensure webhook URL is accessible from Mautic container
- Use internal URL if possible: `http://n8n:5678/webhook/...`
- Check webhook triggers and events are correctly configured
- Enable webhook debugging in Mautic configuration

**Issue 2: API Authentication Failures**

```bash
# Regenerate OAuth2 credentials
docker exec mautic_web php bin/console mautic:integration:synccontacts

# Test API connection
curl -u username:password \
  http://localhost/api/contacts

# Check API settings in Mautic
# Settings → Configuration → API Settings → Enable API
```

**Solution:**
- Regenerate API credentials in Mautic (Settings → API Credentials)
- Verify OAuth2 callback URL matches n8n configuration
- For Basic Auth: Ensure username and password are correct
- Check API is enabled in Mautic Configuration
- Use internal URL: `http://mautic_web/api` from n8n

**Issue 3: Emails Not Sending**

```bash
# Check email queue
docker exec mautic_web php bin/console mautic:emails:send

# Process email queue
docker exec mautic_worker php bin/console messenger:consume email

# Check SMTP configuration
docker logs mautic_web | grep -i smtp

# Test email configuration
docker exec mautic_web php bin/console mautic:email:test your@email.com
```

**Solution:**
- Verify SMTP settings (Settings → Configuration → Email Settings)
- For Mailpit: Host=`mailpit`, Port=`1025`, no authentication
- For Docker-Mailserver: Host=`mailserver`, Port=`587`, TLS enabled
- Check email queue: Settings → System Info → Email Queue
- Process queue manually if stuck
- Verify FROM email address is valid

**Issue 4: Performance Issues / Slow Campaigns**

```bash
# Check campaign queue
docker exec mautic_web php bin/console mautic:campaigns:update
docker exec mautic_web php bin/console mautic:campaigns:trigger

# Monitor Redis cache
docker exec mautic_redis redis-cli INFO stats

# Check segment processing
docker exec mautic_web php bin/console mautic:segments:update

# Optimize database
docker exec mautic_db mysql -u root -p \
  -e "OPTIMIZE TABLE mautic.leads, mautic.lead_event_log, mautic.campaign_lead_event_log;"

# Check container resources
docker stats mautic_web mautic_worker mautic_redis --no-stream
```

**Solution:**
- Ensure mautic_worker container is running for background jobs
- Increase Redis memory limit in docker-compose.yml
- Optimize segments (reduce complexity, use static segments when possible)
- Archive old campaigns and inactive contacts
- Increase PHP memory limit: `memory_limit = 512M` in php.ini
- Enable opcache for better PHP performance
- Run cron jobs regularly for campaign processing

### Resources

- **Official Documentation:** https://docs.mautic.org/
- **API Documentation:** https://developer.mautic.org/
- **Community Mautic Node:** https://www.npmjs.com/package/@digital-boss/n8n-nodes-mautic
- **GitHub:** https://github.com/mautic/mautic
- **Community Forum:** https://forum.mautic.org/
- **Best Practices Guide:** https://docs.mautic.org/en/best-practices
- **Campaign Builder:** https://docs.mautic.org/en/campaigns
- **Email Marketing:** https://docs.mautic.org/en/emails
- **Lead Scoring:** https://docs.mautic.org/en/points

### Best Practices

**Campaign Optimization:**
1. **Segment strategically** - Keep segments under 10,000 contacts for performance
2. **Use dynamic content** - Personalize emails with tokens and dynamic content blocks
3. **Test everything** - A/B test subject lines, content, send times
4. **Monitor engagement** - Track opens, clicks, unsubscribes; adjust campaigns accordingly
5. **Clean your list** - Regularly remove hard bounces and unengaged contacts

**Data Management:**
1. **Progressive profiling** - Gradually collect data through multiple form interactions
2. **Archive old data** - Move inactive contacts (>1 year) to archive segments
3. **Data hygiene** - Regular cleanup of duplicates, invalid emails, test contacts
4. **Monitor API limits** - Implement rate limiting in n8n workflows
5. **Backup regularly** - Database backups before major campaign launches

**Security & Compliance:**
```javascript
// GDPR compliance workflow example

// 1. Track consent in custom fields
custom_field: gdpr_consent
value: true/false
consent_date: timestamp

// 2. Check consent before sending
IF Node: {{$json.gdpr_consent}} === true

// 3. Provide easy unsubscribe
All emails must include {unsubscribe_url}

// 4. Implement data deletion workflow
On request: Delete contact + anonymize activity logs
```

**Integration Patterns:**

**Mautic + CRM (Twenty/EspoCRM):**
- Use Mautic for marketing, CRM for sales
- Bi-directional sync via n8n
- Hand off qualified leads from Mautic to CRM when score > 70

**Mautic + Cal.com:**
- High-value leads get automatic booking links
- Book meetings based on engagement scores
- Sync meeting status back to Mautic

**Mautic + E-commerce:**
- Abandoned cart campaigns
- Post-purchase nurturing
- Win-back campaigns for inactive customers

**API Best Practices:**
1. **Use OAuth2** for production environments (more secure)
2. **Batch operations** - Process contacts in batches of 50-100
3. **Rate limiting** - Respect API limits (typically 100 req/min)
4. **Error handling** - Implement retry logic for failed requests
5. **Webhooks over polling** - Use webhooks for real-time updates instead of polling API
6. **Cache data** - Cache frequently accessed data (segments, campaigns) in n8n
7. **Logging** - Log all API calls for debugging and audit trails
