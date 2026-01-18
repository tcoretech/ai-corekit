# ✅ Vikunja - Task Management

### What is Vikunja?

Vikunja is a modern, open-source task management platform that provides powerful project organization with multiple view types (Kanban, Gantt, Calendar, Table). It's perfect for automating project workflows and task management in n8n, with full CalDAV support and mobile apps.

### Features

- **Multiple Views:** Kanban boards, Gantt charts, Calendar view, Table view
- **Real-time Collaboration:** Team workspaces, task assignments, comments, file attachments (up to 20MB)
- **Import/Export:** Import from Todoist, Trello, Microsoft To-Do; Export to CSV/JSON
- **CalDAV Support:** Full calendar sync at `https://vikunja.yourdomain.com/dav`
- **Mobile Apps:** Native iOS (App Store - "Vikunja Cloud") and Android (Play Store - "Vikunja") apps
- **API-First:** Comprehensive REST API for automation and integration

### Initial Setup

**First Login to Vikunja:**

1. Navigate to `https://vikunja.yourdomain.com`
2. Click "Register" to create your first account
   - The first registered user automatically becomes admin
3. Create your first project and lists
4. Configure your workspace settings
5. Generate API token:
   - Go to User Settings → API Tokens
   - Click "Create New Token"
   - Name it "n8n Integration"
   - Copy the token for use in n8n

### n8n Integration Setup

**Option 1: Community Node (Recommended)**

1. In n8n, go to Settings → Community Nodes
2. Install `n8n-nodes-vikunja`
3. Create Vikunja credentials:
   - **URL:** `http://vikunja:3456` (internal) or `https://vikunja.yourdomain.com` (external)
   - **API Token:** Your token from Vikunja settings

**Option 2: HTTP Request Node**

```javascript
// HTTP Request Credentials
Base URL: http://vikunja:3456/api/v1
Authentication: Bearer Token
Token: [Your API token from Vikunja]
```

**Internal URL for n8n:** `http://vikunja:3456`

### Example Workflows

#### Example 1: Create Task from Email

```javascript
// Automatically create tasks from incoming emails

// 1. Email Trigger (IMAP) or Webhook
// Monitors inbox for emails with [TASK] in subject

// 2. Code Node - Parse email
const subject = $json.subject.replace('[TASK]', '').trim();
const description = $json.textPlain || $json.textHtml;

return {
  title: subject,
  description: description,
  projectId: 1 // Your default project ID
};

// 3. HTTP Request Node - Create task in Vikunja
Method: POST
URL: http://vikunja:3456/api/v1/projects/{{$json.projectId}}/tasks
Headers:
  Authorization: Bearer {{$credentials.vikunjaToken}}
Body: {
  "title": "{{$json.title}}",
  "description": "{{$json.description}}"
}

// 4. Send Email Node - Confirmation
To: {{$('Email Trigger').json.from}}
Subject: Task Created: {{$('HTTP Request').json.title}}
Message: |
  Your task has been created in Vikunja:
  
  Title: {{$('HTTP Request').json.title}}
  Link: https://vikunja.yourdomain.com/tasks/{{$('HTTP Request').json.id}}
```

#### Example 2: Daily Task Summary

```javascript
// Send daily summary of tasks due today

// 1. Schedule Trigger - Every day at 8 AM

// 2. HTTP Request - Get tasks due today
Method: GET
URL: http://vikunja:3456/api/v1/tasks/all
Query Parameters:
  filter_by: due_date
  filter_value: {{$now.toISODate()}}

// 3. Code Node - Format task list
const tasks = $json;
let message = `📋 Tasks Due Today (${tasks.length})\n\n`;

tasks.forEach((task, index) => {
  message += `${index + 1}. ${task.title}\n`;
  message += `   Project: ${task.project.title}\n`;
  message += `   Assignee: ${task.assignees[0]?.username || 'Unassigned'}\n\n`;
});

return { message };

// 4. Slack/Email Node - Send summary
Message: {{$json.message}}
```

#### Example 3: Task Automation Pipeline

```javascript
// Create tasks from webhooks (e.g., from forms, other tools)

// 1. Webhook Trigger
// Receives JSON data from external sources

// 2. Switch Node - Route based on task type
// Branch by task priority or category

// Branch 1: High Priority
// 3a. HTTP Request - Create urgent task
Method: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "URGENT: {{$json.title}}",
  "priority": 5,
  "due_date": "{{$now.plus(1, 'days').toISO()}}"
}

// 4a. Slack Node - Notify team immediately
Channel: #urgent-tasks
Message: 🚨 Urgent task created: {{$json.title}}

// Branch 2: Normal Priority
// 3b. HTTP Request - Create normal task
Priority: 3
Due Date: {{$now.plus(7, 'days').toISO()}}

// 4b. Email Node - Daily digest (batched)
```

#### Example 4: Recurring Task Generator

```javascript
// Automatically create recurring tasks

// 1. Schedule Trigger - Every Monday at 9 AM

// 2. Code Node - Generate weekly tasks
const weeklyTasks = [
  { title: 'Weekly Team Meeting', day: 'monday', time: '10:00' },
  { title: 'Client Report', day: 'friday', time: '16:00' },
  { title: 'Backup Check', day: 'sunday', time: '22:00' }
];

return weeklyTasks.map(task => ({
  title: task.title,
  dueDate: getNextDayOfWeek(task.day, task.time)
}));

// 3. Loop Over Items

// 4. HTTP Request - Create each task
Method: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "{{$json.title}}",
  "due_date": "{{$json.dueDate}}",
  "repeat_after": 604800 // 7 days in seconds
}
```

#### Example 5: Task Import from Trello/Asana/CSV

```javascript
// Migrate tasks from other platforms

// 1. HTTP Request - Fetch from source (Trello API, CSV file, etc.)

// 2. Code Node - Transform data to Vikunja format
const tasks = $json.cards || $json.tasks || [];

return tasks.map(task => ({
  title: task.name || task.title,
  description: task.desc || task.description,
  dueDate: task.due || task.dueDate,
  labels: task.labels?.map(l => l.name).join(',')
}));

// 3. Loop Over Items

// 4. HTTP Request - Create in Vikunja
Method: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "{{$json.title}}",
  "description": "{{$json.description}}",
  "due_date": "{{$json.dueDate}}"
}

// 5. Wait Node - 500ms between requests (rate limiting)

// 6. Final notification when complete
```

### Troubleshooting

**Tasks not appearing:**

```bash
# 1. Check Vikunja status
docker ps | grep vikunja
# Should show: STATUS = Up

# 2. Check Vikunja logs
docker logs vikunja --tail 100

# 3. Verify API token
# Generate new token in Vikunja settings if needed

# 4. Test API connection from n8n
docker exec n8n curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://vikunja:3456/api/v1/projects
# Should return list of projects
```

**API authentication errors:**

```bash
# 1. Verify token format
# Should be: Authorization: Bearer token_here

# 2. Check internal URL is correct
# From n8n: http://vikunja:3456
# Not: https://vikunja.yourdomain.com

# 3. Regenerate API token
# User Settings → API Tokens → Create New Token

# 4. Check Vikunja container network
docker network inspect ai-corekit_default | grep vikunja
```

**CalDAV sync not working:**

```bash
# 1. CalDAV URL format
# https://vikunja.yourdomain.com/dav/projects/[project-id]

# 2. Use Vikunja credentials (not API token)
# Username: your@email.com
# Password: your Vikunja password

# 3. Test CalDAV connection
curl -X PROPFIND https://vikunja.yourdomain.com/dav \
  -u "your@email.com:password"
```

### Tips for Vikunja + n8n Integration

**Best Practices:**

1. **Use Internal URLs:** Always use `http://vikunja:3456` from n8n containers (faster, no SSL overhead)
2. **Dedicated API Tokens:** Create separate tokens for each n8n workflow or integration
3. **Rate Limiting:** Add Wait nodes (200-500ms) between bulk operations to avoid overloading
4. **Error Handling:** Use Try/Catch nodes for resilient workflows
5. **Webhook Setup:** Configure Vikunja webhooks for real-time task updates
6. **Project IDs:** Store project IDs in n8n environment variables for easy reference
7. **Label Management:** Use labels for workflow automation triggers

**Project Organization:**

- Create separate projects for different workflow types
- Use lists within projects to organize by status/category
- Apply consistent labeling for automation triggers
- Set up templates for common task types

**Mobile & Calendar Integration:**

- iOS/Android apps work seamlessly with self-hosted instance
- CalDAV integration syncs with Apple Calendar, Google Calendar, Thunderbird
- Use CalDAV URL: `https://vikunja.yourdomain.com/dav`
- Mobile notifications for task assignments and due dates

### Resources

- **Documentation:** https://vikunja.io/docs/
- **API Reference:** https://try.vikunja.io/api/v1/docs
- **GitHub:** https://github.com/go-vikunja/vikunja
- **Community Forum:** https://community.vikunja.io/
- **Mobile Apps:**
  - iOS: https://apps.apple.com/app/vikunja-cloud/id1660089863
  - Android: https://play.google.com/store/apps/details?id=io.vikunja.app
