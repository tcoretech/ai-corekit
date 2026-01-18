# 📱 Postiz - Social Media Management

### What is Postiz?

Postiz is a powerful, open-source social media management platform that centralizes content planning, scheduling, and analytics across 20+ platforms. It's a self-hosted alternative to Buffer, Hootsuite, and similar tools, offering AI-powered content creation, team collaboration, and comprehensive analytics—all while maintaining complete control over your data.

### Features

- **Multi-Platform Support** - Schedule to 20+ platforms: X, Facebook, Instagram, LinkedIn, YouTube, TikTok, Threads, Bluesky, Reddit, Mastodon, Pinterest, Dribbble, Slack, Discord
- **AI Content Generation** - OpenAI-powered post creation with hashtags, emojis, and CTAs
- **Visual Calendar** - Drag-and-drop scheduling with clear overview of all content
- **Design Studio** - Canva-like interface for creating graphics, infographics, and videos
- **Analytics & Insights** - Track engagement, reach, impressions, and audience demographics
- **Team Collaboration** - Multi-user support with roles, permissions, and comment system

### Initial Setup

**First Login to Postiz:**

1. Navigate to `https://postiz.yourdomain.com`
2. **First user becomes admin** - Create your account
3. Complete organization setup
4. Connect your first social media account

**Connect Social Media Accounts:**

1. Click **Integrations** in sidebar
2. Select platform (X, Facebook, LinkedIn, etc.)
3. Authorize via OAuth
4. Account appears in your channels list

### Generate API Key

**For n8n integration and automation:**

1. Click **Settings** (gear icon, top right)
2. Go to **Public API** section
3. Click **Generate API Key**
4. Copy and save securely

**API Limits:**
- 30 requests per hour
- Applies to API calls, not post count
- Plan ahead to maximize efficiency

### n8n Integration Setup

**Option 1: Custom Postiz Node (Recommended)**

Postiz has a custom n8n community node:

1. n8n → Settings → **Community Nodes**
2. Search: `n8n-nodes-postiz`
3. Click **Install**
4. Restart n8n: `docker compose restart n8n`

**Create Postiz Credentials in n8n:**
```javascript
// Postiz API Credentials
API URL: https://postiz.yourdomain.com
API Key: [Your API key from Postiz settings]
```

**Option 2: HTTP Request Node**

```javascript
// HTTP Request Node Configuration
Method: POST
URL: https://postiz.yourdomain.com/api/public/v1/posts
Authentication: Header Auth
  Header: Authorization
  Value: {{$env.POSTIZ_API_KEY}}
  
Headers:
  Content-Type: application/json
```

**Internal URL:** `http://postiz:3000`

### Example Workflows

#### Example 1: Auto-Post Blog to Social Media

```javascript
// 1. RSS Feed Trigger - Monitor blog for new posts
URL: https://yourblog.com/feed.xml
Check every: 1 hour

// 2. Code Node - Extract post data
const item = $json;
return {
  title: item.title,
  url: item.link,
  summary: item.contentSnippet,
  published: item.pubDate
};

// 3. OpenAI Node - Generate social post
Model: gpt-4o-mini
Prompt: |
  Create an engaging social media post for this blog article:
  Title: {{$json.title}}
  Summary: {{$json.summary}}
  
  Make it catchy with emojis and hashtags. Keep it under 280 characters.
  Include a call-to-action to read the full article.

// 4. Postiz Node (or HTTP Request) - Schedule post
Operation: Create Post
Channels: ["twitter", "linkedin", "facebook"]
Content: {{$json.ai_generated_post}}
Link: {{$('Extract Data').json.url}}
Scheduled Time: Now + 30 minutes

// 5. Slack Node - Notify team
Channel: #marketing
Message: |
  📝 New blog post auto-scheduled to social media!
  
  Title: {{$('Extract Data').json.title}}
  Platforms: Twitter, LinkedIn, Facebook
  Goes live in 30 minutes
```

#### Example 2: AI-Powered Content Calendar

```javascript
// Generate a week of social media posts with AI

// 1. Schedule Trigger - Monday at 9 AM

// 2. OpenAI Node - Generate content ideas
Model: gpt-4o
Prompt: |
  Generate 7 engaging social media post ideas for this week.
  Topics: AI, automation, productivity, tech tips
  
  Return as JSON array:
  [
    {
      "day": "Monday",
      "topic": "...",
      "content": "...",
      "hashtags": "..."
    }
  ]

// 3. Split in Batches - Process each day

// 4. Code Node - Format for Postiz
const post = $json;
const dayOffset = {
  "Monday": 0,
  "Tuesday": 1,
  "Wednesday": 2,
  "Thursday": 3,
  "Friday": 4,
  "Saturday": 5,
  "Sunday": 6
};

const scheduleDate = new Date();
scheduleDate.setDate(scheduleDate.getDate() + dayOffset[post.day]);
scheduleDate.setHours(10, 0, 0, 0); // 10 AM each day

return {
  content: `${post.content}\n\n${post.hashtags}`,
  scheduledTime: scheduleDate.toISOString(),
  platforms: ["twitter", "linkedin"]
};

// 5. Loop Over Posts
// 6. HTTP Request - Create scheduled posts
Method: POST
URL: http://postiz:3000/api/public/v1/posts
Headers:
  Authorization: {{$env.POSTIZ_API_KEY}}
Body: {
  "content": "{{$json.content}}",
  "scheduledTime": "{{$json.scheduledTime}}",
  "integrations": ["twitter_id", "linkedin_id"]
}

// 7. Aggregate - Collect all created posts
// 8. Email Node - Send confirmation
To: marketing@company.com
Subject: Week's social media scheduled!
Message: |
  ✅ Successfully scheduled 7 posts across Twitter & LinkedIn
  
  Posts go live at 10 AM daily starting Monday.
```

#### Example 3: Performance Analytics Report

```javascript
// Weekly social media analytics digest

// 1. Schedule Trigger - Friday at 5 PM

// 2. HTTP Request - Get posts from last 7 days
Method: GET
URL: http://postiz:3000/api/public/v1/posts
Headers:
  Authorization: {{$env.POSTIZ_API_KEY}}
Query Parameters:
  startDate: {{$now.minus(7, 'days').toISO()}}
  endDate: {{$now.toISO()}}

// 3. Code Node - Calculate metrics
const posts = $json.posts;

const stats = {
  totalPosts: posts.length,
  platforms: {},
  topPerformer: null,
  totalEngagement: 0
};

posts.forEach(post => {
  // Group by platform
  const platform = post.integration.name;
  if (!stats.platforms[platform]) {
    stats.platforms[platform] = {
      count: 0,
      engagement: 0
    };
  }
  
  stats.platforms[platform].count++;
  stats.platforms[platform].engagement += post.engagement || 0;
  stats.totalEngagement += post.engagement || 0;
  
  // Track top performer
  if (!stats.topPerformer || post.engagement > stats.topPerformer.engagement) {
    stats.topPerformer = post;
  }
});

return stats;

// 4. OpenAI Node - Generate insights
Model: gpt-4o-mini
Prompt: |
  Analyze this week's social media performance and provide insights:
  
  {{JSON.stringify($json)}}
  
  Provide:
  1. Overall performance summary
  2. Best performing platform
  3. Recommendations for next week

// 5. Google Docs Node - Create report
Document: Weekly Social Media Report
Content: |
  # Social Media Report - Week of {{$now.toFormat('MMM dd')}}
  
  ## 📊 Overview
  - Total Posts: {{$('Calculate').json.totalPosts}}
  - Total Engagement: {{$('Calculate').json.totalEngagement}}
  
  ## 🏆 Top Post
  {{$('Calculate').json.topPerformer.content}}
  Engagement: {{$('Calculate').json.topPerformer.engagement}}
  
  ## 🤖 AI Insights
  {{$json.insights}}

// 6. Slack Node - Share report
Channel: #marketing
Message: |
  📈 Weekly Social Media Report is ready!
  
  [Link to Google Doc]
```

#### Example 4: User-Generated Content Workflow

```javascript
// Monitor brand mentions and repost with permission

// 1. HTTP Request - Search for brand mentions
// (Use Twitter API, Instagram API, or web scraping)

// 2. Code Node - Filter quality content
const mentions = $json;
return mentions.filter(m => 
  m.engagement > 100 && 
  m.sentiment === 'positive' &&
  !m.author.isSpam
);

// 3. Send Email - Request permission
To: {{$json.author.email}}
Subject: Love to feature your content!
Message: |
  Hi {{$json.author.name}},
  
  We noticed your awesome post about our product!
  May we share it on our channels with credit?
  
  Reply YES to approve.

// 4. Wait for Webhook - User approval
// Email reply triggers webhook

// 5. IF Node - Check approval
Condition: {{$json.response}} === "YES"

// 6. Postiz Node - Schedule repost
Content: |
  Amazing content from @{{$json.author.username}}! 🎉
  
  {{$json.original_content}}
  
  #UserFeature #Community
Channels: ["twitter", "instagram", "linkedin"]
Media: {{$json.media_url}}
```

### API Endpoints Reference

**Create Post:**
```bash
POST /api/public/v1/posts
{
  "content": "Your post content",
  "scheduledTime": "2025-01-20T10:00:00Z",
  "integrations": ["twitter_id", "facebook_id"]
}
```

**Get Posts:**
```bash
GET /api/public/v1/posts?startDate=2025-01-01&endDate=2025-01-20
```

**Upload Media:**
```bash
POST /api/public/v1/upload
{
  "file": "base64_encoded_image"
}
```

**Upload from URL:**
```bash
POST /api/public/v1/upload-from-url
{
  "url": "https://example.com/image.jpg"
}
```

### AI Content Generation

**Using built-in AI assistant:**

1. Create new post in Postiz UI
2. Click **AI Generate** button
3. Enter prompt: "Create engaging post about product launch"
4. AI generates content with hashtags and emojis
5. Edit and schedule

**Current limitation:** Only OpenAI supported (no Ollama yet)

**Workaround for local AI:**
Use n8n with Ollama to generate content, then send to Postiz API.

### Team Collaboration

**Invite Team Members:**

1. Settings → **Team**
2. Click **Invite Member**
3. Enter email and select role:
   - **Admin** - Full access
   - **Member** - Create and schedule posts
   - **Viewer** - View-only access

**Comment on Posts:**
- Team members can comment on scheduled posts
- Discuss changes before publishing
- Approval workflow for sensitive content

### Troubleshooting

**Posts not publishing:**

```bash
# Check Postiz workers
docker logs postiz-worker --tail 50

# Verify social account connection
# Postiz UI → Integrations → Check status

# Re-authorize account if needed
# Tokens expire after 60-90 days for most platforms

# Check scheduled time
# Posts must be scheduled at least 5 minutes in future
```

**API rate limit exceeded:**

```bash
# Error: 429 Too Many Requests
# Limit: 30 requests/hour

# Solution: Implement request throttling in n8n
// Add Wait Node between requests
Wait: 2 minutes

// Or batch schedule posts
// Schedule multiple posts in single API call
```

**Media upload failed:**

```bash
# Check file size
# Max: 10MB per file

# Supported formats:
# Images: JPG, PNG, GIF, WEBP
# Videos: MP4, MOV (max 100MB)

# Compress large files before upload
docker exec n8n ffmpeg -i input.mp4 -vcodec libx264 -crf 28 output.mp4
```

**OAuth authentication failed:**

```bash
# Requires public URL for callbacks
# Cannot use localhost

# If using Cloudflare Tunnel:
# Make sure tunnel is active

# Check callback URL in platform settings
# Example Twitter: https://postiz.yourdomain.com/api/integration/twitter/callback
```

### Resources

- **Official Website:** https://postiz.com/
- **Documentation:** https://docs.postiz.com/
- **GitHub:** https://github.com/gitroomhq/postiz-app
- **API Docs:** https://docs.postiz.com/public-api
- **n8n Community Node:** https://www.npmjs.com/package/n8n-nodes-postiz
- **Discord Community:** https://discord.gg/postiz

### Best Practices

**Content Strategy:**
- Plan content 1-2 weeks ahead
- Use visual calendar for overview
- Batch create content on specific days
- Mix promotional and engaging content

**Scheduling:**
- Post during peak engagement times
- Stagger posts across platforms (don't post everywhere simultaneously)
- Use Postiz analytics to find best times
- Schedule at least 5 minutes in advance

**Media:**
- Always include images/videos (higher engagement)
- Use design studio for branded graphics
- Keep videos under 2 minutes for best performance
- Optimize images (compress before upload)

**API Automation:**
- Implement error handling in workflows
- Use webhooks for real-time updates
- Batch operations to respect rate limits
- Monitor API usage to avoid hitting limits

**Team Workflow:**
- Create approval process for sensitive posts
- Use comments for collaboration
- Assign specific platforms to team members
- Regular review meetings using analytics
