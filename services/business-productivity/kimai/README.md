# ⏱️ Kimai - Time Tracking

### What is Kimai?

Kimai is a professional time tracking solution from Austria that's DSGVO/GDPR-compliant, perfect for freelancers and small teams. It provides comprehensive time tracking with invoicing, team management, 2FA support, and a complete REST API for automation.

### Features

- **DSGVO/GDPR Compliant:** Built with European data protection standards
- **Professional Invoicing:** Export to Excel, CSV, PDF with customizable templates
- **Team Management:** Role hierarchy (User → Teamlead → Admin → Super-Admin)
- **Multi-Project Tracking:** Organize time by customers, projects, and activities
- **Mobile Apps:** Native iOS and Android apps for on-the-go tracking
- **REST API:** Complete API for automation and integration

### Initial Setup

**First Login to Kimai:**

1. Navigate to `https://time.yourdomain.com`
2. Login with admin credentials from installation report:
   - **Email:** Your email address (set during installation)
   - **Password:** Check `.env` file for `KIMAI_ADMIN_PASSWORD`
3. Complete initial setup:
   - Configure company details (Settings → System → Settings)
   - Set default currency and timezone
   - Create customers (Customers → Add Customer)
   - Create projects (Projects → Add Project)
   - Create activities (Activities → Add Activity)
   - Add team members (Settings → Users → Add User)

**Generate API Token for n8n:**

1. Click on your profile icon (top right)
2. Go to API Access
3. Click "Create Token"
4. Name it "n8n Integration"
5. Select all permissions
6. Copy the token immediately (shown only once!)

### n8n Integration Setup

**Create Kimai Credentials in n8n:**

```javascript
// HTTP Request Credentials - Header Auth
Authentication: Header Auth

Main Header:
  Name: X-AUTH-USER
  Value: admin@example.com (your Kimai email)

Additional Header:
  Name: X-AUTH-TOKEN
  Value: [Your API token from Kimai]
```

**Base URL for internal access:** `http://kimai:8001/api`

### API Endpoints Reference

**Timesheets:**
- `GET /api/timesheets` - List time entries
- `POST /api/timesheets` - Create time entry
- `PATCH /api/timesheets/{id}` - Update time entry
- `DELETE /api/timesheets/{id}` - Delete time entry

**Projects:**
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create project
- `GET /api/projects/{id}/rates` - Get project statistics

**Customers:**
- `GET /api/customers` - List customers
- `POST /api/customers` - Create customer

**Activities:**
- `GET /api/activities` - List activities
- `POST /api/activities` - Create activity

### Example Workflows

#### Example 1: Automated Time Tracking from Completed Tasks

```javascript
// Track time automatically when tasks are marked complete

// 1. Vikunja/Leantime Trigger - Task marked as complete

// 2. Code Node - Calculate duration
const taskStarted = new Date($json.task_created);
const taskCompleted = new Date($json.task_completed);
const durationSeconds = Math.round((taskCompleted - taskStarted) / 1000);

return {
  projectId: $json.project_id,
  activityId: 1, // Default activity
  description: $json.task_name,
  begin: taskStarted.toISOString(),
  end: taskCompleted.toISOString()
};

// 3. HTTP Request - Create timesheet entry in Kimai
Method: POST
URL: http://kimai:8001/api/timesheets
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
  Content-Type: application/json
Body: {
  "begin": "{{$json.begin}}",
  "end": "{{$json.end}}",
  "project": {{$json.projectId}},
  "activity": {{$json.activityId}},
  "description": "{{$json.description}}"
}

// 4. Notification Node - Confirm time tracked
Slack/Email: |
  ⏱️ Time tracked automatically
  
  Task: {{$json.description}}
  Duration: {{Math.round(durationSeconds/3600, 2)}} hours
  Project: {{$json.projectId}}
```

#### Example 2: Weekly Invoice Generation from Kimai

```javascript
// Automatically generate invoices from tracked time

// 1. Schedule Trigger - Every Friday at 5 PM

// 2. HTTP Request - Get week's timesheet entries
Method: GET
URL: http://kimai:8001/api/timesheets
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Query Parameters:
  begin: {{$now.startOf('week').toISO()}}
  end: {{$now.endOf('week').toISO()}}

// 3. Code Node - Group by customer and calculate totals
const timesheets = $json;
const byCustomer = {};

timesheets.forEach(ts => {
  const customerName = ts.project.customer.name;
  const customerId = ts.project.customer.id;
  
  if (!byCustomer[customerName]) {
    byCustomer[customerName] = {
      id: customerId,
      name: customerName,
      entries: [],
      totalHours: 0,
      totalAmount: 0
    };
  }
  
  const hours = ts.duration / 3600; // Convert seconds to hours
  const amount = ts.rate || 0;
  
  byCustomer[customerName].entries.push({
    date: new Date(ts.begin).toLocaleDateString(),
    project: ts.project.name,
    activity: ts.activity.name,
    description: ts.description,
    hours: hours.toFixed(2),
    rate: (amount / hours).toFixed(2),
    amount: amount.toFixed(2)
  });
  
  byCustomer[customerName].totalHours += hours;
  byCustomer[customerName].totalAmount += amount;
});

return Object.values(byCustomer);

// 4. Loop Over Customers

// 5. Generate Invoice PDF (using Gotenberg)
Method: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body (HTML template):
<html>
  <h1>Invoice for {{$json.name}}</h1>
  <p>Week: {{$now.startOf('week').toFormat('MMM dd')}} - {{$now.endOf('week').toFormat('MMM dd, yyyy')}}</p>
  
  <table>
    <tr>
      <th>Date</th>
      <th>Project</th>
      <th>Description</th>
      <th>Hours</th>
      <th>Rate</th>
      <th>Amount</th>
    </tr>
    {{#each $json.entries}}
    <tr>
      <td>{{this.date}}</td>
      <td>{{this.project}}</td>
      <td>{{this.description}}</td>
      <td>{{this.hours}}</td>
      <td>€{{this.rate}}/h</td>
      <td>€{{this.amount}}</td>
    </tr>
    {{/each}}
    <tr class="total">
      <td colspan="3"><strong>Total</strong></td>
      <td><strong>{{$json.totalHours.toFixed(2)}}h</strong></td>
      <td></td>
      <td><strong>€{{$json.totalAmount.toFixed(2)}}</strong></td>
    </tr>
  </table>
</html>

// 6. Send Email - Invoice to customer
To: {{$json.name}}@example.com
Subject: Invoice - Week {{$now.week()}}
Attachments: invoice-{{$json.name}}.pdf
Message: |
  Dear {{$json.name}},
  
  Please find attached your invoice for this week.
  
  Total Hours: {{$json.totalHours.toFixed(2)}}
  Total Amount: €{{$json.totalAmount.toFixed(2)}}
  
  Best regards
```

#### Example 3: Project Budget Monitoring

```javascript
// Alert when projects approach budget limits

// 1. Schedule Trigger - Daily at 9 AM

// 2. HTTP Request - Get all projects
Method: GET
URL: http://kimai:8001/api/projects
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}

// 3. Loop Over Projects

// 4. HTTP Request - Get project statistics
Method: GET
URL: http://kimai:8001/api/projects/{{$json.id}}/rates
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}

// 5. Code Node - Calculate budget usage
const budget = $json.budget || 0;
const spent = $json.totalRate || 0;
const percentage = budget > 0 ? (spent / budget * 100).toFixed(1) : 0;

return {
  projectName: $json.name,
  budget: budget,
  spent: spent,
  remaining: budget - spent,
  percentage: percentage,
  alertNeeded: percentage >= 80
};

// 6. IF Node - Check if alert needed
Condition: {{$json.alertNeeded}} is true

// 7. Send Alert - Project Manager
Channel: #project-alerts
Message: |
  ⚠️ Budget Alert: {{$json.projectName}}
  
  Budget: €{{$json.budget}}
  Spent: €{{$json.spent}} ({{$json.percentage}}%)
  Remaining: €{{$json.remaining}}
  
  Action needed: Review project scope or request budget increase.
```

#### Example 4: Cal.com Meeting Time Tracking

```javascript
// Automatically track time for completed meetings

// 1. Cal.com Webhook Trigger - booking.completed

// 2. HTTP Request - Find or create customer in Kimai
Method: GET
URL: http://kimai:8001/api/customers
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Query: name={{$json.attendees[0].email.split('@')[1]}}

// 3. IF Node - Customer doesn't exist
Branch: {{$json.length === 0}}

// 4a. HTTP Request - Create new customer
Method: POST
URL: http://kimai:8001/api/customers
Body: {
  "name": "{{$json.attendees[0].email.split('@')[1]}}",
  "contact": "{{$json.attendees[0].name}}",
  "email": "{{$json.attendees[0].email}}"
}

// 5. Merge - Combine branches

// 6. HTTP Request - Create timesheet for meeting
Method: POST
URL: http://kimai:8001/api/timesheets
Body: {
  "begin": "{{$('Cal.com Trigger').json.startTime}}",
  "end": "{{$('Cal.com Trigger').json.endTime}}",
  "project": 1, // Default meeting project ID
  "activity": 2, // Meeting activity ID
  "description": "Meeting: {{$('Cal.com Trigger').json.title}} with {{$('Cal.com Trigger').json.attendees[0].name}}",
  "tags": "cal.com,meeting,{{$('Cal.com Trigger').json.eventType.slug}}"
}

// 7. Notification
Message: |
  ✅ Meeting time tracked:
  {{$('Cal.com Trigger').json.title}}
  Duration: {{Math.round(($('Cal.com Trigger').json.endTime - $('Cal.com Trigger').json.startTime) / 3600000, 2)}}h
```

#### Example 5: Daily Time Tracking Reminder

```javascript
// Send reminders to track time

// 1. Schedule Trigger - Daily at 5 PM

// 2. HTTP Request - Get today's timesheets per user
Method: GET
URL: http://kimai:8001/api/timesheets
Query: begin={{$now.startOf('day').toISO()}}

// 3. Code Node - Calculate who needs reminders
const users = ['user1@example.com', 'user2@example.com'];
const entries = $json;
const tracked = new Set(entries.map(e => e.user.email));

const needsReminder = users.filter(u => !tracked.has(u));

return needsReminder.map(email => ({ email }));

// 4. Loop Over Users

// 5. Send Email - Reminder
To: {{$json.email}}
Subject: Don't forget to track your time!
Message: |
  Hi there,
  
  Just a friendly reminder to track your time for today.
  
  👉 https://time.yourdomain.com
  
  Thanks!
```

### Mobile Apps Integration

Kimai has official mobile apps for on-the-go time tracking:

**iOS:** [App Store - Kimai Mobile](https://apps.apple.com/app/kimai-mobile/id1463807227)  
**Android:** [Play Store - Kimai Mobile](https://play.google.com/store/apps/details?id=de.cloudrizon.kimai)

**Configure mobile app:**
1. Server URL: `https://time.yourdomain.com`
2. Use API token authentication
3. Enable offline time tracking
4. Sync automatically when online

### Advanced Features

**Team Management:**
- First user is automatically Super Admin
- Role hierarchy: User → Teamlead → Admin → Super-Admin
- Teams can have restricted access to specific customers/projects
- Approval workflow for timesheets (requires plugin)

**Invoice Templates:**
- Customizable invoice templates (Settings → Invoice Templates)
- Supports multiple languages
- Include company logo and custom fields
- Export to PDF, Excel, CSV

**Time Rounding:**
- Configure rounding rules (Settings → Timesheet)
- Options: 1, 5, 10, 15, 30 minutes
- Can round up, down, or to nearest
- Prevents time theft and ensures accurate billing

**API Rate Limits:**
- Default: 1000 requests per hour per user
- Can be adjusted in `local.yaml` configuration
- Monitor usage in Kimai admin panel

### Troubleshooting

**API returns 401 Unauthorized:**

```bash
# 1. Verify API token is active
# Login to Kimai → Profile → API Access → Check token status

# 2. Test authentication
docker exec n8n curl -H "X-AUTH-USER: admin@example.com" \
  -H "X-AUTH-TOKEN: YOUR_TOKEN" \
  http://kimai:8001/api/version
# Should return Kimai version number

# 3. Check if user exists
docker exec kimai bin/console kimai:user:list

# 4. Regenerate token if needed
# Kimai UI → Profile → API Access → Create New Token
```

**Timesheet entries not showing:**

```bash
# 1. Clear Kimai cache
docker exec kimai bin/console cache:clear --env=prod
docker exec kimai bin/console cache:warmup --env=prod

# 2. Check database connection
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} -e "SELECT COUNT(*) FROM kimai2_timesheet;"

# 3. Verify project/activity IDs exist
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} kimai \
  -e "SELECT id, name FROM kimai2_projects;"
```

**Database connection issues:**

```bash
# 1. Check MySQL container status
docker ps | grep kimai_db
# Should show: STATUS = Up

# 2. Test database connection
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} -e "SHOW DATABASES;"

# 3. Check environment variables
docker exec kimai env | grep DATABASE

# 4. Restart both containers
docker compose restart kimai_db kimai
```

**Time entries have wrong timezone:**

```bash
# 1. Check Kimai timezone setting
# Settings → System → Settings → Timezone

# 2. Check server timezone
docker exec kimai date
docker exec kimai cat /etc/timezone

# 3. Set correct timezone in docker-compose.yml
environment:
  - TZ=Europe/Berlin
```

### Tips for Kimai + n8n Integration

**Best Practices:**

1. **Use Internal URLs:** Always use `http://kimai:8001` from n8n (faster, no SSL overhead)
2. **API Authentication:** Both `X-AUTH-USER` and `X-AUTH-TOKEN` headers are required
3. **Time Format:** Use ISO 8601 format for all date/time fields
4. **Rate Calculation:** Kimai automatically calculates rates based on project/customer settings
5. **Bulk Operations:** Use `/api/timesheets` with loop for multiple entries
6. **No Webhooks:** Kimai doesn't have webhooks - use Schedule Triggers for monitoring
7. **Export Formats:** Kimai supports Excel, CSV, PDF exports via API

**Time Tracking Automation Ideas:**

- Auto-track time when starting/stopping tasks in project management tools
- Create timesheets from calendar meetings
- Send daily/weekly time reports to team
- Generate invoices automatically from tracked time
- Alert when team members forget to track time
- Monitor project budgets and send alerts
- Export time data to accounting software

**DSGVO Compliance:**

- All time data stored in EU (your server)
- Built-in data export functionality
- User consent for data processing
- Audit logs for all changes
- Right to be forgotten support

### Resources

- **Documentation:** https://www.kimai.org/documentation/
- **API Reference:** https://www.kimai.org/documentation/rest-api.html
- **Plugin Store:** https://www.kimai.org/store/
- **GitHub:** https://github.com/kimai/kimai
- **Support Forum:** https://github.com/kimai/kimai/discussions
- **Demo:** https://demo.kimai.org (try before installing)
