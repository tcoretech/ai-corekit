# 📝 Formbricks - Survey Platform

### What is Formbricks?

Formbricks is an open-source, privacy-first survey platform that enables you to collect user feedback, measure satisfaction, and gather insights without compromising data privacy. It's GDPR-compliant, self-hosted, and designed for product teams who need powerful survey capabilities with complete data control. Unlike cloud services like Typeform or SurveyMonkey, Formbricks gives you full ownership of your data while providing advanced features like multi-language support, logic branching, and webhook integrations.

### Features

- **Privacy-First:** GDPR-compliant, self-hosted, complete data ownership
- **Multi-Language Support:** Create surveys in 20+ languages
- **Logic Branching:** Dynamic survey flows based on responses
- **Rich Question Types:** NPS, CSAT, multiple choice, text, rating, and more
- **In-App Surveys:** JavaScript SDK for seamless integration
- **Email Surveys:** Send surveys via email with tracking
- **Link Surveys:** Share standalone survey links
- **Webhooks:** Real-time notifications to n8n for automation
- **Team Collaboration:** Multi-user access with role-based permissions
- **Custom Branding:** White-label surveys with your brand identity
- **Advanced Analytics:** Response rates, completion times, sentiment analysis

### Initial Setup

**First Login to Formbricks:**

1. Navigate to `https://forms.yourdomain.com`
2. Click "Sign up" to create the first admin account
3. First user automatically becomes organization owner
4. Complete organization setup (name, branding)
5. Generate API key:
   - Go to Settings → API Keys
   - Click "Create New API Key"
   - Name it "n8n Integration"
   - Copy the key for use in n8n

**Create Your First Survey:**

1. Click "Create Survey" in the dashboard
2. Choose survey type:
   - **NPS Survey:** Net Promoter Score (0-10 scale)
   - **CSAT Survey:** Customer Satisfaction
   - **Product Feedback:** Custom questions
   - **Lead Qualification:** Form with scoring
3. Add questions and configure logic
4. Set up triggers (on page load, on exit, after time)
5. Configure webhook for n8n integration
6. Publish and get embed code or link

### n8n Integration Setup

**Method 1: Webhooks (Recommended)**

Configure webhooks directly in Formbricks for real-time response processing:

1. In Formbricks: Survey → Settings → Webhooks
2. Add webhook URL: `https://n8n.yourdomain.com/webhook/formbricks-response`
3. Select triggers:
   - Response Created
   - Response Updated
   - Response Completed
4. Save webhook configuration

**Create Webhook Trigger in n8n:**

```javascript
// Webhook Trigger Node in n8n
Webhook Path: /formbricks-response
HTTP Method: POST
Response Mode: On Received
Authentication: None (or add custom header for security)

// Formbricks sends data in this format:
{
  "event": "responseCreated",
  "data": {
    "surveyId": "clxxx123",
    "responseId": "clyyy456",
    "userId": "user@example.com",
    "responses": {
      "q1": 8,  // NPS score
      "q2": "Great product!",  // Text feedback
      "q3": ["feature1", "feature2"]  // Multi-select
    },
    "metadata": {
      "userAgent": "Mozilla/5.0...",
      "language": "en",
      "url": "https://example.com/product"
    },
    "createdAt": "2025-10-18T10:30:00Z"
  }
}
```

**Method 2: API Integration**

For programmatic survey management and response retrieval:

```javascript
// HTTP Request Node - Get Survey Responses
Method: GET
URL: https://forms.yourdomain.com/api/v1/surveys/{surveyId}/responses
Authentication: Header Auth
  Header: x-api-key
  Value: YOUR_FORMBRICKS_API_KEY
Query Parameters:
  limit: 100
  offset: 0
```

**Internal URL for n8n:** `http://formbricks:3000`

### Example Workflows

#### Example 1: NPS Score Automation

React to customer feedback immediately:

```javascript
// Automate follow-up based on NPS scores

// 1. Webhook Trigger - Formbricks survey response
// Configured in Formbricks: Survey → Settings → Webhooks
// URL: https://n8n.yourdomain.com/webhook/nps-response

// 2. Code Node - Parse and categorize response
const npsScore = $json.data.responses.nps_score;
const feedback = $json.data.responses.feedback || '';
const email = $json.data.userId;

// Categorize based on NPS methodology
let category, priority, action;

if (npsScore >= 9) {
  category = 'Promoter';
  priority = 'Medium';
  action = 'Request testimonial/referral';
} else if (npsScore >= 7) {
  category = 'Passive';
  priority = 'Low';
  action = 'Monitor for improvement opportunities';
} else {
  category = 'Detractor';
  priority = 'High';
  action = 'Immediate follow-up required';
}

return [{
  json: {
    score: npsScore,
    category: category,
    priority: priority,
    action: action,
    feedback: feedback,
    email: email,
    timestamp: $json.data.createdAt
  }
}];

// 3. Switch Node - Route based on category

// Branch 1 - Detractors (Score 0-6)
// → Create urgent support ticket
// → Alert customer success team
// → Send personalized apology email

// HTTP Request - Create ticket in support system
Method: POST
URL: http://baserow:80/api/database/rows/table/SUPPORT_TICKETS/
Body (JSON):
{
  "Customer Email": "{{$json.email}}",
  "Priority": "Urgent",
  "Type": "NPS Detractor",
  "Score": {{$json.score}},
  "Feedback": "{{$json.feedback}}",
  "Status": "Open",
  "Created": "{{$now.toISO()}}"
}

// Slack Alert
Channel: #customer-success
Message: |
  ⚠️ **URGENT: NPS Detractor Alert**
  
  Score: {{$json.score}}/10
  Customer: {{$json.email}}
  Feedback: {{$json.feedback}}
  
  Action required within 24 hours!

// Send Email - Personal follow-up
To: {{$json.email}}
Subject: We're sorry - Your feedback matters to us
Body: |
  Hi there,
  
  We noticed you gave us a {{$json.score}}/10 in our recent survey.
  We're truly sorry we didn't meet your expectations.
  
  Your feedback: "{{$json.feedback}}"
  
  A member of our team will reach out within 24 hours to make this right.

// Branch 2 - Passives (Score 7-8)
// → Add to nurture campaign
// → Log in CRM

// HTTP Request - Update CRM
Method: PATCH
URL: http://nocodb:8080/api/v2/tables/CUSTOMERS/records
Body (JSON):
{
  "Email": "{{$json.email}}",
  "NPS Score": {{$json.score}},
  "Last Survey": "{{$now.toISO()}}",
  "Segment": "Passive",
  "Notes": "{{$json.feedback}}"
}

// Branch 3 - Promoters (Score 9-10)
// → Request testimonial/review
// → Referral program invite

// Send Email - Request testimonial
To: {{$json.email}}
Subject: Thank you! Would you share your experience?
Body: |
  Hi there,
  
  Thank you for the amazing {{$json.score}}/10 rating! 🎉
  
  Your feedback: "{{$json.feedback}}"
  
  Would you be willing to:
  • Leave a review on G2/Capterra?
  • Share your experience as a testimonial?
  • Refer a colleague (get 20% off)?
  
  Click here: [Testimonial Form]

// 4. Baserow/NocoDB Node - Log all responses
Operation: Create
Table: NPS_History
Fields:
  Email: {{$json.email}}
  Score: {{$json.score}}
  Category: {{$json.category}}
  Feedback: {{$json.feedback}}
  Action Taken: {{$json.action}}
  Timestamp: {{$now.toISO()}}
```

#### Example 2: Form to CRM Pipeline

Convert survey responses into qualified leads:

```javascript
// Automate lead qualification and CRM updates

// 1. Webhook Trigger - Formbricks lead form submission

// 2. Code Node - Parse and score lead
const formData = $json.data.responses;

// Calculate lead score based on responses
let leadScore = 0;

// Company size scoring
const companySize = formData.company_size;
if (companySize === '50-200') leadScore += 20;
if (companySize === '200-1000') leadScore += 30;
if (companySize === '1000+') leadScore += 40;

// Budget scoring
const budget = formData.annual_budget;
if (budget === '10k-50k') leadScore += 15;
if (budget === '50k-100k') leadScore += 25;
if (budget === '100k+') leadScore += 35;

// Timeline scoring
const timeline = formData.implementation_timeline;
if (timeline === 'Immediate') leadScore += 30;
if (timeline === '1-3 months') leadScore += 20;
if (timeline === '3-6 months') leadScore += 10;

// Interest level
const interest = formData.interest_level;
if (interest === 'Very interested') leadScore += 25;
if (interest === 'Interested') leadScore += 15;

// Determine lead quality
let leadQuality;
if (leadScore >= 80) leadQuality = 'Hot';
else if (leadScore >= 50) leadQuality = 'Warm';
else leadQuality = 'Cold';

return [{
  json: {
    name: formData.name,
    email: formData.email,
    company: formData.company,
    phone: formData.phone || '',
    companySize: companySize,
    budget: budget,
    timeline: timeline,
    interests: formData.interested_features || [],
    leadScore: leadScore,
    leadQuality: leadQuality,
    source: 'Formbricks Lead Form',
    submittedAt: $json.data.createdAt
  }
}];

// 3. Switch Node - Route based on lead quality

// Branch 1 - Hot Leads (Score >= 80)
// → Create in CRM immediately
// → Alert sales team
// → Schedule follow-up call

// HTTP Request - Create in CRM (Odoo/Twenty/EspoCRM)
Method: POST
URL: http://odoo:8069/api/v1/leads
Body (JSON):
{
  "name": "{{$json.name}}",
  "email": "{{$json.email}}",
  "company": "{{$json.company}}",
  "phone": "{{$json.phone}}",
  "priority": "3",  // High priority
  "tag_ids": ["Hot Lead", "Formbricks"],
  "description": |
    Lead Score: {{$json.leadScore}}
    Company Size: {{$json.companySize}}
    Budget: {{$json.budget}}
    Timeline: {{$json.timeline}}
    Interests: {{$json.interests.join(', ')}}
}

// Slack Notification - Immediate alert
Channel: #sales
Message: |
  🔥 **HOT LEAD ALERT** 🔥
  
  Name: {{$json.name}}
  Company: {{$json.company}}
  Email: {{$json.email}}
  Score: {{$json.leadScore}}/100
  
  Timeline: {{$json.timeline}}
  Budget: {{$json.budget}}
  
  [View in CRM](https://odoo.yourdomain.com/leads/{{$json.id}})

// Cal.com Node - Auto-schedule discovery call
// (If Cal.com is installed)
Method: POST
URL: http://calcom:3000/api/v1/bookings
Body (JSON):
{
  "eventTypeId": YOUR_EVENT_TYPE_ID,
  "name": "{{$json.name}}",
  "email": "{{$json.email}}",
  "notes": "Hot lead from Formbricks - Score: {{$json.leadScore}}",
  "rescheduleUid": null
}

// Branch 2 - Warm Leads (Score 50-79)
// → Add to nurture campaign
// → Send info package

// HTTP Request - Add to email campaign (Mautic)
Method: POST
URL: http://mautic_web/api/contacts/new
Body (JSON):
{
  "firstname": "{{$json.name.split(' ')[0]}}",
  "lastname": "{{$json.name.split(' ')[1]}}",
  "email": "{{$json.email}}",
  "company": "{{$json.company}}",
  "tags": ["Warm Lead", "Formbricks", "Nurture Campaign"]
}

// Send Email - Info package
To: {{$json.email}}
Subject: Here's the information you requested
Body: |
  Hi {{$json.name}},
  
  Thanks for your interest! Based on your responses, here are some resources:
  
  • [Product Demo Video]
  • [Case Study: Similar Company]
  • [Pricing Guide]
  • [Implementation Timeline]
  
  I'll follow up in a few days. In the meantime, feel free to book a call:
  [Schedule Demo]

// Branch 3 - Cold Leads (Score < 50)
// → Add to long-term nurture
// → Send educational content

// HTTP Request - Add to database for future nurture
Method: POST
URL: http://baserow:80/api/database/rows/table/LEADS_DATABASE/
Body (JSON):
{
  "Name": "{{$json.name}}",
  "Email": "{{$json.email}}",
  "Company": "{{$json.company}}",
  "Score": {{$json.leadScore}},
  "Quality": "Cold",
  "Source": "Formbricks",
  "Status": "Nurture",
  "Created": "{{$now.toISO()}}"
}

// 4. Final Node - Log to analytics
// Track conversion rates and lead quality metrics
```

#### Example 3: Customer Feedback Loop

Collect, analyze, and act on product feedback:

```javascript
// Automated product feedback workflow

// 1. Webhook Trigger - Product feedback survey response

// 2. Code Node - Analyze feedback sentiment
const feedback = $json.data.responses.feedback_text;
const satisfaction = $json.data.responses.satisfaction_score;
const feature = $json.data.responses.requested_feature;

// Simple sentiment analysis (in production, use AI)
const negativekeywords = ['bug', 'broken', 'problem', 'issue', 'frustrated', 'slow'];
const positiveKeywords = ['love', 'great', 'awesome', 'excellent', 'perfect', 'helpful'];

let sentiment = 'neutral';
const lowerFeedback = feedback.toLowerCase();

if (negativeKeywords.some(word => lowerFeedback.includes(word))) {
  sentiment = 'negative';
} else if (positiveKeywords.some(word => lowerFeedback.includes(word))) {
  sentiment = 'positive';
}

return [{
  json: {
    email: $json.data.userId,
    feedback: feedback,
    satisfaction: satisfaction,
    requestedFeature: feature || 'None',
    sentiment: sentiment,
    needsResponse: sentiment === 'negative' || satisfaction <= 2,
    timestamp: $json.data.createdAt
  }
}];

// 3. IF Node - Check if response needed
Condition: {{$json.needsResponse}} === true

// IF YES - Negative feedback or low satisfaction:

// HTTP Request - Create ticket in Vikunja/Leantime
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "Customer Feedback Response: {{$json.email}}",
  "description": |
    Satisfaction: {{$json.satisfaction}}/5
    Sentiment: {{$json.sentiment}}
    Feedback: {{$json.feedback}}
    Requested Feature: {{$json.requestedFeature}}
  "priority": 3,
  "labels": ["customer-feedback", "urgent"],
  "due_date": "{{$now.plus({days: 2}).toISO()}}"
}

// Send Email - Personal response
To: {{$json.email}}
Subject: Thank you for your feedback
Body: |
  Hi there,
  
  Thank you for taking the time to share your feedback with us.
  
  Your feedback: "{{$json.feedback}}"
  
  We take all feedback seriously and are working to address your concerns.
  A team member will reach out within 48 hours.

// IF NO - Positive feedback or high satisfaction:

// HTTP Request - Store in feature requests database
Method: POST
URL: http://nocodb:8080/api/v2/tables/FEATURE_REQUESTS/records
Body (JSON):
{
  "Customer Email": "{{$json.email}}",
  "Feedback": "{{$json.feedback}}",
  "Satisfaction": {{$json.satisfaction}},
  "Requested Feature": "{{$json.requestedFeature}}",
  "Sentiment": "{{$json.sentiment}}",
  "Status": "Reviewed",
  "Created": "{{$now.toISO()}}"
}

// 4. Always - Store in analytics database
Method: POST
URL: http://baserow:80/api/database/rows/table/FEEDBACK_ANALYTICS/
Body (JSON):
{
  "Date": "{{$now.toISODate()}}",
  "Email": "{{$json.email}}",
  "Score": {{$json.satisfaction}},
  "Sentiment": "{{$json.sentiment}}",
  "Feedback": "{{$json.feedback}}",
  "Feature Request": "{{$json.requestedFeature}}",
  "Response Required": {{$json.needsResponse}},
  "Timestamp": "{{$now.toISO()}}"
}
```

### Survey Types & Use Cases

**NPS Surveys (Net Promoter Score):**
- Measure customer satisfaction and loyalty
- Identify promoters, passives, and detractors
- Track satisfaction trends over time
- Automate follow-up based on score

**CSAT Surveys (Customer Satisfaction):**
- Post-interaction feedback (support, sales)
- Product/feature satisfaction
- Service quality measurement
- Immediate issue detection

**Lead Qualification Forms:**
- Capture contact information
- Score leads based on responses
- Route to appropriate sales rep
- Trigger nurture campaigns

**Product Feedback:**
- Feature requests and suggestions
- Bug reports and issues
- User experience insights
- Beta testing feedback

**Employee Pulse Surveys:**
- Team satisfaction monitoring
- Workplace culture assessment
- Anonymous feedback collection
- Engagement tracking

**Market Research:**
- Customer preference studies
- Product-market fit validation
- Competitive analysis
- Pricing research

### Formbricks Features for Automation

**Survey Triggers:**
- **On Page Load:** Show survey when specific page loads
- **On Exit Intent:** Catch users before they leave
- **After Time:** Display after X seconds on page
- **On Scroll:** Trigger at specific scroll depth
- **On Click:** Show when user clicks element
- **On Custom Event:** JavaScript-triggered surveys

**Logic Branching:**
- Skip questions based on previous answers
- Show/hide questions conditionally
- Multi-path survey flows
- Personalized survey experiences

**Multi-Language:**
- Create surveys in 20+ languages
- Auto-detect user language
- Manual language selection
- Translated response data

**Response Actions:**
- Webhooks to n8n (real-time)
- Email notifications
- Slack/Discord alerts
- Custom JavaScript callbacks

### Tips for Formbricks + n8n Integration

1. **Use Webhooks:** Configure "Response Completed" webhooks for real-time processing
2. **Internal URL:** Use `http://formbricks:3000` from n8n for API calls
3. **Secure Webhooks:** Add custom headers for webhook authentication
4. **Response Filtering:** Use n8n IF nodes to filter responses before processing
5. **Error Handling:** Add Try/Catch nodes for resilient workflows
6. **Rate Limiting:** Be mindful of API rate limits (100 requests/minute)
7. **Data Privacy:** Ensure GDPR compliance in data processing workflows
8. **Testing:** Use Formbricks preview mode to test webhooks before going live
9. **Analytics:** Store all responses in a database for long-term analysis
10. **Multi-Survey:** Use survey IDs to route different surveys to different workflows

### Troubleshooting

#### Webhooks Not Triggering

```bash
# 1. Check Formbricks webhook configuration
# Survey → Settings → Webhooks → Verify URL and status

# 2. Test webhook manually
curl -X POST https://n8n.yourdomain.com/webhook/formbricks-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# 3. Check Formbricks logs
docker logs formbricks --tail 100 | grep webhook

# 4. Verify n8n webhook is active
# n8n UI → Workflows → Check webhook trigger is enabled
```

#### Survey Not Displaying

```bash
# 1. Check JavaScript SDK installation
# Verify SDK loaded in browser console:
# window.formbricks

# 2. Check survey triggers
# Formbricks UI → Survey → Triggers → Verify conditions

# 3. Test with direct link
# Use the direct survey link to test functionality

# 4. Clear browser cache
# Survey code may be cached
```

#### API Authentication Errors

```bash
# 1. Verify API key is correct
grep FORMBRICKS_API_KEY .env

# 2. Test API key
curl -H "x-api-key: YOUR_KEY" \
  https://forms.yourdomain.com/api/v1/surveys

# 3. Regenerate API key if needed
# Formbricks UI → Settings → API Keys → Create New

# 4. Check API key permissions
# Ensure key has required scopes
```

#### Database Connection Issues

```bash
# 1. Check Formbricks container status
docker ps | grep formbricks

# 2. Check database connection
docker logs formbricks --tail 50 | grep database

# 3. Verify PostgreSQL is running
docker ps | grep postgres

# 4. Test database connection
docker exec formbricks npm run db:migrate
```

#### Survey Responses Not Saving

```bash
# 1. Check database migrations
docker exec formbricks npm run db:migrate

# 2. Check disk space
df -h

# 3. Check PostgreSQL logs
docker logs postgres --tail 100

# 4. Verify database permissions
docker exec postgres psql -U postgres -c "\du"
```

### Resources

- **Documentation:** https://formbricks.com/docs
- **API Reference:** https://formbricks.com/docs/api/overview
- **JavaScript SDK:** https://formbricks.com/docs/developer-docs/js-library
- **GitHub:** https://github.com/formbricks/formbricks
- **Community:** https://formbricks.com/discord
- **Templates:** https://formbricks.com/templates
- **Examples:** https://github.com/formbricks/formbricks/tree/main/examples

### Best Practices

**Survey Design:**
- Keep surveys short (5-7 questions max)
- Use clear, simple language
- Avoid leading questions
- Test on mobile devices
- A/B test survey designs
- Use progress indicators

**Timing & Triggers:**
- Don't show immediately on page load (wait 3-5 seconds)
- Limit survey frequency (max once per 30 days)
- Use exit intent for non-intrusive feedback
- Time surveys based on user engagement
- Respect "Don't show again" preferences

**Data Privacy:**
- Be transparent about data usage
- Provide opt-out mechanisms
- Anonymize PII when possible
- Comply with GDPR/CCPA
- Secure API keys properly
- Regular data retention cleanup

**Automation:**
- Set up real-time webhooks for urgent feedback
- Create escalation rules for detractors
- Automate thank-you messages
- Track response rates and completion
- Close the feedback loop (follow up with users)
- Monitor survey performance metrics

**Integration:**
- Connect to CRM for lead qualification
- Sync with support systems for issues
- Feed into product roadmap tools
- Update customer profiles automatically
- Trigger marketing campaigns
- Generate analytics dashboards
