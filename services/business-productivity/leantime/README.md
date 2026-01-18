# 🎯 Leantime - Project Management

### What is Leantime?

Leantime is a goal-oriented project management suite designed specifically for ADHD and neurodiverse teams. It combines traditional PM tools (sprints, timesheets, Gantt charts) with strategic planning frameworks (Lean Canvas, SWOT, Goal Canvas) and ADHD-friendly features like focus mode, break reminders, and gamification elements.

### Features

- **Strategy Tools:** Goal Canvas (OKRs), Lean Canvas, SWOT Analysis, Opportunity Canvas
- **Project Management:** Kanban boards, Gantt charts, milestones, sprints
- **Time Tracking:** Built-in timer, timesheets, estimates vs actual hours
- **ADHD-Friendly UI:** Dopamine-driven design, focus mode, Pomodoro technique support
- **Team Collaboration:** Comments, file attachments, @mentions, real-time updates
- **JSON-RPC API:** Complete automation support via JSON-RPC 2.0 protocol

### Initial Setup

**First Login to Leantime:**

1. Navigate to `https://leantime.yourdomain.com`
2. The installation wizard starts automatically
3. Create your admin account (first user becomes admin)
4. Complete company profile setup
5. Generate API key:
   - Go to User Settings → API Access
   - Click "Create API Key"
   - Name it "n8n Integration"
   - Copy the key for use in n8n

**MySQL 8.4 Auto-Installation:**
- Leantime automatically installs MySQL 8.4 during setup
- This MySQL instance can be reused for other services (WordPress, Ghost, etc.)
- Root password available in `.env` file as `LEANTIME_MYSQL_ROOT_PASSWORD`

### n8n Integration Setup

**IMPORTANT:** Leantime uses JSON-RPC 2.0 API, not REST. All requests go to `/api/jsonrpc` endpoint.

**Create Leantime Credentials in n8n:**

1. Go to Credentials → New → Header Auth
2. Configure:
   - **Name:** `Leantime API`
   - **Header Name:** `x-api-key`
   - **Header Value:** `[Your API key from Leantime settings]`

**HTTP Request Node Configuration:**

```javascript
Method: POST
URL: http://leantime:8080/api/jsonrpc
Authentication: Header Auth (select your Leantime API credential)
Headers:
  Content-Type: application/json
  Accept: application/json
Body Type: JSON
```

**Internal URL for n8n:** `http://leantime:8080`

### JSON-RPC API Reference

**Available Methods:**

**Projects:**
- `leantime.rpc.projects.getAll` - Get all projects
- `leantime.rpc.projects.getProject` - Get specific project
- `leantime.rpc.projects.addProject` - Create new project
- `leantime.rpc.projects.updateProject` - Update project

**Tasks/Tickets:**
- `leantime.rpc.tickets.getAll` - Get all tickets
- `leantime.rpc.tickets.getTicket` - Get specific ticket
- `leantime.rpc.tickets.addTicket` - Create new ticket
- `leantime.rpc.tickets.updateTicket` - Update ticket
- `leantime.rpc.tickets.deleteTicket` - Delete ticket

**Time Tracking:**
- `leantime.rpc.timesheets.getAll` - Get timesheets
- `leantime.rpc.timesheets.addTime` - Log time entry
- `leantime.rpc.timesheets.updateTime` - Update time entry

**Milestones:**
- `leantime.rpc.tickets.getAllMilestones` - Get milestones
- `leantime.rpc.tickets.addMilestone` - Create milestone

### Status & Type Codes

```javascript
// Task Status Codes
const STATUS = {
  NEW: 3,           // Neu
  IN_PROGRESS: 1,   // In Bearbeitung
  DONE: 0,          // Fertig
  BLOCKED: 4,       // Blockiert
  REVIEW: 2         // Review
};

// Task Types
const TYPES = {
  TASK: "task",
  BUG: "bug",
  STORY: "story",
  MILESTONE: "milestone"
};

// Priority Levels
const PRIORITY = {
  HIGH: "1",
  MEDIUM: "2",
  LOW: "3"
};
```

### Example Workflows

#### Example 1: Get All Projects

```javascript
// Simple query to list all projects

// HTTP Request Node
Method: POST
URL: http://leantime:8080/api/jsonrpc
Headers:
  x-api-key: {{$credentials.leantimeApiKey}}
  Content-Type: application/json
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.projects.getAll",
  "id": 1,
  "params": {}
}

// Response format:
{
  "jsonrpc": "2.0",
  "result": [
    {
      "id": 1,
      "name": "AI CoreKit Development",
      "clientId": 1,
      "state": 0
    }
  ],
  "id": 1
}
```

#### Example 2: Create Task from Email

```javascript
// Automatically create Leantime tasks from emails

// 1. Email Trigger (IMAP)
// Monitors inbox for emails with [TASK] in subject

// 2. Code Node - Parse email
const subject = $json.subject.replace('[TASK]', '').trim();
const description = $json.textPlain || $json.textHtml;

return {
  headline: subject,
  description: description,
  projectId: 1
};

// 3. HTTP Request - Create task in Leantime
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "description": "{{$json.description}}",
      "type": "task",
      "projectId": {{$json.projectId}},
      "status": 3,
      "priority": "2"
    }
  }
}

// 4. Send Email Node - Confirmation
To: {{$('Email Trigger').json.from}}
Subject: Task Created in Leantime
Message: |
  Your task has been created:
  
  Title: {{$json.headline}}
  Project: AI CoreKit Development
  Status: New
  
  View in Leantime: https://leantime.yourdomain.com
```

#### Example 3: Weekly Sprint Planning Automation

```javascript
// Automatically create sprint tasks every Monday

// 1. Schedule Trigger - Every Monday at 9 AM

// 2. Code Node - Generate weekly tasks
const weekNumber = Math.ceil((new Date() - new Date(new Date().getFullYear(), 0, 1)) / 604800000);

const weeklyTasks = [
  {
    headline: `Week ${weekNumber} - Sprint Planning`,
    type: "task",
    priority: "1"
  },
  {
    headline: `Week ${weekNumber} - Daily Standups`,
    type: "task",
    priority: "2"
  },
  {
    headline: `Week ${weekNumber} - Sprint Review`,
    type: "task",
    priority: "2"
  },
  {
    headline: `Week ${weekNumber} - Sprint Retrospective`,
    type: "task",
    priority: "2"
  }
];

return weeklyTasks;

// 3. Loop Over Items

// 4. HTTP Request - Create each task
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "type": "{{$json.type}}",
      "projectId": 1,
      "status": 3,
      "priority": "{{$json.priority}}",
      "tags": "weekly,automated"
    }
  }
}

// 5. Slack Notification
Channel: #project-updates
Message: |
  📋 Weekly sprint tasks created for Week {{$('Code Node').json.weekNumber}}
  
  ✅ Sprint Planning
  ✅ Daily Standups
  ✅ Sprint Review
  ✅ Sprint Retrospective
```

#### Example 4: Time Tracking Report Automation

```javascript
// Generate weekly time reports

// 1. Schedule Trigger - Every Friday at 5 PM

// 2. HTTP Request - Get all tickets with time entries
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.getAll",
  "id": 1,
  "params": {}
}

// 3. Code Node - Calculate time summaries
const tickets = $json.result;

const timeReport = tickets
  .filter(t => t.bookedHours > 0)
  .map(ticket => ({
    task: ticket.headline,
    project: ticket.projectName,
    plannedHours: ticket.planHours || 0,
    actualHours: ticket.bookedHours,
    remaining: ticket.hourRemaining || 0,
    status: ticket.statusLabel
  }));

const totalBooked = timeReport.reduce((sum, t) => sum + t.actualHours, 0);
const totalPlanned = timeReport.reduce((sum, t) => sum + t.plannedHours, 0);
const efficiency = totalPlanned > 0 ? (totalBooked / totalPlanned * 100).toFixed(2) : 0;

return {
  report: timeReport,
  summary: {
    totalBookedHours: totalBooked,
    totalPlannedHours: totalPlanned,
    efficiency: efficiency + '%',
    weekEnding: new Date().toISOString()
  }
};

// 4. Send Email - Weekly report
To: team@company.com
Subject: Weekly Time Report - Week Ending {{$json.summary.weekEnding}}
Message: |
  📊 Weekly Time Tracking Report
  
  Total Hours Booked: {{$json.summary.totalBookedHours}}h
  Total Hours Planned: {{$json.summary.totalPlannedHours}}h
  Efficiency: {{$json.summary.efficiency}}
  
  Detailed breakdown attached.
```

#### Example 5: AI Idea to Task Pipeline

```javascript
// Convert ideas into actionable tasks using AI

// 1. Webhook Trigger
// Receives idea submissions from forms/chat

// 2. OpenAI Node - Analyze and break down idea
Model: gpt-4o-mini
Prompt: |
  Break down this idea into 3-5 concrete, actionable tasks:
  
  "{{$json.idea}}"
  
  For each task, provide:
  - Title (short, actionable)
  - Description (2-3 sentences)
  - Estimated hours (realistic)
  
  Return as JSON array.

// 3. Code Node - Parse AI response
const tasks = JSON.parse($json.choices[0].message.content);

return tasks.map(task => ({
  headline: task.title,
  description: task.description,
  storypoints: task.estimatedHours
}));

// 4. Loop Over Items

// 5. HTTP Request - Create each task
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "description": "{{$json.description}}",
      "type": "task",
      "projectId": 1,
      "status": 3,
      "storypoints": "{{$json.storypoints}}",
      "tags": "idea-generated,ai-enhanced"
    }
  }
}

// 6. Final Notification
Message: |
  🤖 AI processed your idea and created {{$('Loop Over Items').itemsLength}} tasks!
  
  View in Leantime: https://leantime.yourdomain.com
```

#### Example 6: Update Task Status

```javascript
// Update task status when conditions are met

// 1. Webhook or Schedule Trigger

// 2. HTTP Request - Get specific task
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.getTicket",
  "id": 1,
  "params": {
    "id": 10
  }
}

// 3. Code Node - Check conditions
const task = $json.result;
let newStatus = task.status;

if (task.progress >= 100) {
  newStatus = 0; // DONE
} else if (task.progress > 0) {
  newStatus = 1; // IN_PROGRESS
}

return { taskId: task.id, newStatus };

// 4. HTTP Request - Update task
Method: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.updateTicket",
  "id": 1,
  "params": {
    "id": {{$json.taskId}},
    "values": {
      "status": {{$json.newStatus}}
    }
  }
}
```

### Troubleshooting

**"Method not found" error:**

```bash
# 1. Check method name spelling and case
# Format must be: leantime.rpc.resource.method

# 2. Verify API access in Leantime
# User Settings → API Access → Verify key is active

# 3. Test API endpoint
docker exec n8n curl -X POST http://leantime:8080/api/jsonrpc \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"leantime.rpc.projects.getAll","id":1,"params":{}}'
```

**Authentication failed:**

```bash
# 1. Check API key format
# Header must be exactly: x-api-key (not X-API-KEY or x-api-token)

# 2. Regenerate API key
# Leantime → User Settings → API Access → Create New Key

# 3. Verify header in n8n
# Credentials → Header Auth → Header Name: x-api-key

# 4. Test from n8n container
docker exec n8n curl -H "x-api-key: YOUR_KEY" http://leantime:8080/api/jsonrpc
```

**Invalid parameters error:**

```bash
# 1. Parameters must be wrapped in "params" object
# Correct:
{
  "jsonrpc": "2.0",
  "method": "...",
  "id": 1,
  "params": {
    "values": {...}
  }
}

# 2. For updates, ID must be separate
{
  "params": {
    "id": 10,
    "values": {
      "headline": "Updated"
    }
  }
}
```

**Connection refused:**

```bash
# 1. Use internal Docker hostname
# FROM n8n: http://leantime:8080
# NOT: http://localhost:8080

# 2. Check Leantime container status
docker ps | grep leantime
# Should show: STATUS = Up

# 3. Check network connectivity
docker exec n8n ping leantime
# Should return: packets transmitted and received

# 4. Verify port is 8080
grep LEANTIME_PORT .env
# Should show: LEANTIME_PORT=8080
```

### Tips for Leantime + n8n Integration

**Best Practices:**

1. **Always use JSON-RPC format:** All API calls must be POST to `/api/jsonrpc`
2. **Internal URLs:** Use `http://leantime:8080` from n8n (faster, no SSL)
3. **Error Handling:** Check for `error` field in JSON-RPC responses
4. **Response Format:** Results are always in `result` field
5. **Batch Operations:** Can send array of requests for efficiency
6. **ID Parameter:** Most update/delete operations need ID in params
7. **Time Format:** Use ISO 8601 for dates

**ADHD-Friendly Automation:**

- Automate recurring task creation to reduce mental load
- Set up reminders for break times using Schedule Triggers
- Create visual progress dashboards with n8n → Slack/Email
- Generate daily focus lists based on priority and deadlines

**Strategy Integration:**

- Automate goal tracking from Goal Canvas
- Generate insights from Lean Canvas data
- Create feedback loops between execution (tasks) and strategy
- Sync strategic objectives with team task assignments

### Resources

- **Documentation:** https://docs.leantime.io/
- **API Reference:** https://docs.leantime.io/api/
- **GitHub:** https://github.com/Leantime/leantime
- **Community Forum:** https://community.leantime.io/
- **Philosophy:** "Start with WHY" approach for ADHD-friendly project management
