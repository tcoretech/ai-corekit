### What is Uptime Kuma?

Uptime Kuma is a self-hosted uptime monitoring tool with a beautiful, modern UI. Often described as "the most beautiful monitoring tool ever," it's like a combination of UptimeRobot and StatusPage.io, but completely open source and self-hosted. Monitor everything from websites to databases, get notified through 90+ channels, and create public status pages for your customers.

### Features

- **Multi-Protocol Monitoring** - HTTP(S), TCP, Ping, DNS, Docker containers, databases (PostgreSQL, MySQL, MongoDB), gRPC, Steam servers
- **Public Status Pages** - Create branded status pages for customers with uptime history and incident timeline
- **90+ Notification Channels** - Email, Discord, Slack, Telegram, Mattermost, Pushover, SMS, webhooks, n8n, and many more
- **Keyword Monitoring** - Check if specific text exists on your web pages
- **SSL Certificate Monitoring** - Get warned before certificates expire (30, 14, 7 days)
- **Response Time Tracking** - Monitor how fast services respond with historical graphs
- **Maintenance Windows** - Schedule maintenance to pause alerts temporarily
- **2FA Support** - Secure your monitoring instance with two-factor authentication
- **Multi-User Management** - Admin, viewer, and custom roles for team collaboration
- **API & Webhooks** - Full REST API for automation and webhook support for real-time notifications
- **Docker Health Checks** - Monitor if Docker containers are running and healthy
- **Prometheus Metrics** - Export uptime metrics to Prometheus for Grafana dashboards

### Initial Setup

**First Login to Uptime Kuma:**

1. Navigate to `https://status.yourdomain.com`
2. **Create Admin Account** - First user becomes admin:
```
   Username: admin (or your choice)
   Password: [Choose a strong password]
```
3. You're immediately taken to the dashboard

**Optional: Enable Two-Factor Authentication:**

1. Click your profile icon → **Settings**
2. Go to **Security** tab
3. Click **Enable 2FA**
4. Scan QR code with authenticator app (Google Authenticator, Authy)
5. Enter verification code to confirm

**Create Your First Monitor:**

1. Click **+ Add New Monitor** button
2. Choose monitor type (e.g., **HTTP(s)**)
3. Configure:
```
   Friendly Name: My Website
   URL: https://mywebsite.com
   Heartbeat Interval: 60 seconds
   Retries: 1
   Accepted Status Codes: 200-299
```
4. **Save** - Monitor starts immediately!

**Set Up Your First Notification:**

1. Go to **Settings** → **Notifications**
2. Click **Setup Notification**
3. Choose a notification type (e.g., **Discord**, **Slack**, **Email**)
4. Configure credentials/webhook URL
5. **Test** to verify it works
6. **Save** and apply to monitors

### n8n Integration Setup

**Internal URL for n8n:** `http://uptime-kuma:3001`

**Authentication Methods:**

Uptime Kuma offers multiple ways to integrate with n8n:

**Method 1: Webhook Notifications (Easiest)**

1. **In n8n - Create Webhook:**
   - Add **Webhook Trigger** node to workflow
   - Set method to `POST`
   - Copy webhook URL: `https://n8n.yourdomain.com/webhook/uptime-alert`

2. **In Uptime Kuma - Add Webhook Notification:**
   - Go to **Settings** → **Notifications**
   - Click **Setup Notification**
   - Select **Webhook** type
   - Configure:
```
     Notification Name: n8n Alert Handler
     POST URL: https://n8n.yourdomain.com/webhook/uptime-alert
     Content Type: application/json
     Additional Headers: (optional, for authentication)
       X-Custom-Auth: your-secret-token
```
   - Click **Test** - Check n8n workflow executions
   - **Save**

3. **Apply to Monitors:**
   - Edit any monitor
   - Scroll to **Notifications**
   - Select your webhook notification
   - Save monitor

**Method 2: API Integration (Advanced)**

1. **In Uptime Kuma - Generate API Token:**
   - Go to **Settings** → **API Keys**
   - Click **Generate API Key**
   - Set:
```
     Name: n8n Integration
     Expiry: Never (or set expiry date)
     Active: ✓
```
   - **Copy the API key** (shown only once!)

2. **Store API Key in n8n:**
   - Go to **Credentials** → **Create New**
   - Search for **Header Auth**
   - Configure:
```
     Name: Uptime Kuma API
     Header Name: Authorization
     Header Value: Bearer YOUR_API_KEY_HERE
```
   - Test and save

**Webhook Payload Structure:**

When Uptime Kuma sends webhook notifications, you receive:
```json
{
  "monitor": {
    "id": 1,
    "name": "My Website",
    "url": "https://mywebsite.com",
    "type": "http"
  },
  "heartbeat": {
    "status": 0,           // 0=down, 1=up, 2=pending
    "time": "2025-01-15T10:30:00.000Z",
    "msg": "Connection refused",
    "ping": null,
    "duration": 5023
  },
  "msg": "🔴 Down: My Website is down"
}
```

### Example Workflows

#### Example 1: Alert Team When Service Goes Down

Smart alerting with escalation based on service priority:
```javascript
// n8n Workflow: Uptime Kuma Alert Handler with Escalation

// 1. Webhook Trigger - Receive Uptime Kuma notifications
// URL: https://n8n.yourdomain.com/webhook/uptime-alert
// Method: POST
// Authentication: (Optional) Header X-Custom-Auth

// 2. Code Node - Parse and enrich alert data
const alert = $json;
const monitor = alert.monitor;
const heartbeat = alert.heartbeat;

// Determine severity based on monitor name or tags
const criticalServices = ['Production API', 'Payment Gateway', 'Database'];
const isCritical = criticalServices.some(svc => monitor.name.includes(svc));

// Calculate downtime duration
const downtime = heartbeat.duration ? Math.round(heartbeat.duration / 1000) : 0;

return {
  json: {
    serviceName: monitor.name,
    serviceUrl: monitor.url,
    status: heartbeat.status === 1 ? 'UP' : 'DOWN',
    statusIcon: heartbeat.status === 1 ? '✅' : '🔴',
    isCritical: isCritical,
    errorMessage: heartbeat.msg,
    downtime: `${downtime} seconds`,
    timestamp: heartbeat.time,
    alertMessage: `${heartbeat.status === 1 ? '✅' : '🔴'} ${monitor.name} is ${heartbeat.status === 1 ? 'UP' : 'DOWN'}`
  }
};

// 3. IF Node - Check if service is DOWN
Expression: {{ $json.status }} === 'DOWN'

// 4. Switch Node - Route by severity (only if DOWN)
Mode: Expression
Output: {{ $json.isCritical ? 'critical' : 'normal' }}

// 5a. Critical Path - Immediate PagerDuty + Slack
// PagerDuty Node (or HTTP Request to PagerDuty API)
Summary: CRITICAL: {{ $json.serviceName }} is DOWN
Description: |
  Service: {{ $json.serviceName }}
  URL: {{ $json.serviceUrl }}
  Error: {{ $json.errorMessage }}
  Downtime: {{ $json.downtime }}
Severity: critical

// Slack Critical Alert
Channel: #incidents
Message: |
  🚨 **CRITICAL SERVICE DOWN** @channel
  
  **Service:** {{ $json.serviceName }}
  **URL:** {{ $json.serviceUrl }}
  **Error:** {{ $json.errorMessage }}
  **Downtime:** {{ $json.downtime }}
  
  Immediate action required!

// 5b. Normal Path - Slack notification only
Channel: #monitoring
Message: |
  🔴 **Service Down Alert**
  
  **Service:** {{ $json.serviceName }}
  **URL:** {{ $json.serviceUrl }}
  **Error:** {{ $json.errorMessage }}
  **Downtime:** {{ $json.downtime }}
  
  Please investigate when available.

// 6. IF Node - Check if service came back UP
Expression: {{ $json.status }} === 'UP'

// 7. Slack Recovery Notification
Channel: #monitoring (or #incidents for critical)
Message: |
  ✅ **Service Recovered**
  
  **Service:** {{ $json.serviceName }}
  **URL:** {{ $json.serviceUrl }}
  **Recovery Time:** {{ $now.format('HH:mm:ss') }}
  
  All systems operational.

// 8. HTTP Request - Update Status Page (if using external status page)
Method: POST
URL: https://your-status-page.com/api/incidents
Body: {
  "component": "{{ $json.serviceName }}",
  "status": "{{ $json.status }}",
  "message": "{{ $json.alertMessage }}"
}
```

#### Example 2: Monitor SSL Certificates & Auto-Renew

Track SSL certificate expiry and trigger renewal workflows:
```javascript
// n8n Workflow: SSL Certificate Monitoring & Renewal

// 1. Webhook Trigger - SSL certificate warning from Uptime Kuma
// Uptime Kuma sends notifications 30, 14, 7 days before expiry

// 2. Code Node - Parse certificate data
const alert = $json;
const monitor = alert.monitor;

// Extract domain from monitor name or URL
const domain = monitor.url.replace(/^https?:\/\//, '').split('/')[0];

// Determine urgency
const message = alert.msg || '';
const daysUntilExpiry = parseInt(message.match(/(\d+)\s+days?/i)?.[1] || '0');

return {
  json: {
    domain: domain,
    monitorName: monitor.name,
    daysUntilExpiry: daysUntilExpiry,
    isUrgent: daysUntilExpiry <= 7,
    message: message
  }
};

// 3. IF Node - Check urgency
Expression: {{ $json.isUrgent }} === true

// 4a. Urgent Path (<7 days) - Auto-renew certificate
// HTTP Request - Trigger Caddy certificate renewal
Method: POST
URL: http://caddy:2019/reload
// Caddy automatically renews certificates when reloaded

// Wait 30 seconds for renewal
// Wait Node: 30 seconds

// Check if certificate was renewed
// HTTP Request - Check SSL certificate
Method: GET
URL: https://{{ $json.domain }}
Options:
  - Ignore SSL Issues: false
  - Full Response: true

// Code Node - Verify certificate is valid
const response = $input.first().binary;
const certValid = response !== null;

return {
  json: {
    renewed: certValid,
    message: certValid 
      ? `✅ Certificate for ${$('Code Node').first().json.domain} renewed successfully`
      : `❌ Certificate renewal failed for ${$('Code Node').first().json.domain}`
  }
};

// Slack Notification
Channel: #infrastructure
Message: {{ $json.message }}

// 4b. Normal Path (>7 days) - Just notify
// Email or Slack
Message: |
  ⚠️ **SSL Certificate Expiring Soon**
  
  **Domain:** {{ $json.domain }}
  **Days Until Expiry:** {{ $json.daysUntilExpiry }}
  **Monitor:** {{ $json.monitorName }}
  
  Certificate will auto-renew, but please monitor.
```

#### Example 3: Create Monitors from Service Registry

Automatically add monitors when new services are deployed:
```javascript
// n8n Workflow: Auto-Create Monitors from Docker Compose

// 1. Webhook Trigger - Receives service deployment notification
// Or Schedule Trigger - Runs hourly to sync

// 2. Execute Command Node - Get running Docker services
Command: launchkit ps --format json

// 3. Code Node - Parse services and prepare monitor configs
const services = JSON.parse($input.first().json.stdout);

// Define which services should be monitored
const monitorsToCreate = [];

services.forEach(service => {
  const serviceName = service.Service;
  
  // Skip internal services
  if (['postgres', 'redis', 'caddy'].includes(serviceName)) return;
  
  // Determine monitoring config based on service type
  let monitorConfig = {
    type: 'http',
    name: `${serviceName} Health Check`,
    interval: 60,
    retries: 1,
    tags: ['auto-generated', 'production']
  };
  
  // Web services
  if (['n8n', 'open-webui', 'grafana'].includes(serviceName)) {
    monitorConfig.url = `http://${serviceName}:${service.Ports.split(':')[0]}`;
  }
  
  // API services
  if (serviceName === 'ollama') {
    monitorConfig.url = 'http://ollama:11434/api/tags';
    monitorConfig.acceptedStatusCodes = ['200'];
  }
  
  // Database health checks
  if (serviceName === 'qdrant') {
    monitorConfig.url = 'http://qdrant:6333/health';
  }
  
  if (monitorConfig.url) {
    monitorsToCreate.push(monitorConfig);
  }
});

return monitorsToCreate.map(m => ({ json: m }));

// 4. HTTP Request Node - Get existing monitors from Uptime Kuma
Method: GET
URL: http://uptime-kuma:3001/api/monitors
Authentication: Use Uptime Kuma API credentials

// 5. Code Node - Filter out monitors that already exist
const existingMonitors = $input.first().json.monitors || [];
const newMonitors = $('Code Node').all();

const monitorsToAdd = newMonitors.filter(newMon => {
  return !existingMonitors.some(existing => 
    existing.name === newMon.json.name
  );
});

return monitorsToAdd;

// 6. Loop Over Items Node - For each new monitor

// 7. HTTP Request Node - Create monitor in Uptime Kuma
Method: POST
URL: http://uptime-kuma:3001/api/monitors
Authentication: Use Uptime Kuma API credentials
Body (JSON): {{ $json }}

// 8. Code Node - Collect results
const results = $input.all();
const created = results.filter(r => r.json.ok);
const failed = results.filter(r => !r.json.ok);

return {
  json: {
    totalAttempted: results.length,
    successfullyCreated: created.length,
    failed: failed.length,
    createdMonitors: created.map(c => c.json.monitor?.name)
  }
};

// 9. Slack Node - Report results
Channel: #automation
Message: |
  📊 **Monitor Sync Complete**
  
  ✅ Created: {{ $json.successfullyCreated }} new monitors
  ❌ Failed: {{ $json.failed }}
  
  New monitors: {{ $json.createdMonitors.join(', ') }}
```

#### Example 4: Aggregate Multi-Service Health Report

Generate daily health reports combining multiple monitors:
```javascript
// n8n Workflow: Daily Service Health Report

// 1. Schedule Trigger - Every day at 8 AM

// 2. HTTP Request Node - Get all monitors
Method: GET
URL: http://uptime-kuma:3001/api/monitors
Authentication: Use Uptime Kuma API credentials

// 3. Code Node - Calculate uptime statistics
const monitors = $input.first().json.monitors || [];

// Group by tags or categories
const categories = {
  'Critical Services': [],
  'AI Services': [],
  'Business Tools': [],
  'Monitoring': []
};

monitors.forEach(monitor => {
  const tags = monitor.tags || [];
  const status = monitor.active ? (monitor.stats?.uptime24h || 0) : 0;
  
  const monitorInfo = {
    name: monitor.name,
    uptime24h: (status * 100).toFixed(2),
    uptime7d: ((monitor.stats?.uptime7d || 0) * 100).toFixed(2),
    uptime30d: ((monitor.stats?.uptime30d || 0) * 100).toFixed(2),
    avgPing: monitor.stats?.avgPing || 'N/A',
    status: monitor.active ? '✅' : '❌'
  };
  
  // Categorize based on tags or name
  if (tags.includes('critical') || monitor.name.includes('Production')) {
    categories['Critical Services'].push(monitorInfo);
  } else if (tags.includes('ai') || ['ollama', 'n8n', 'flowise'].some(s => monitor.name.toLowerCase().includes(s))) {
    categories['AI Services'].push(monitorInfo);
  } else if (tags.includes('business')) {
    categories['Business Tools'].push(monitorInfo);
  } else {
    categories['Monitoring'].push(monitorInfo);
  }
});

// Calculate overall health score
const allServices = Object.values(categories).flat();
const avgUptime = allServices.reduce((sum, s) => sum + parseFloat(s.uptime24h), 0) / allServices.length;

return {
  json: {
    categories: categories,
    summary: {
      totalServices: allServices.length,
      avgUptime24h: avgUptime.toFixed(2),
      healthScore: avgUptime >= 99 ? 'Excellent' : avgUptime >= 95 ? 'Good' : 'Needs Attention'
    },
    timestamp: new Date().toISOString()
  }
};

// 4. Code Node - Generate HTML report
const data = $input.first().json;
const categories = data.categories;
const summary = data.summary;

let html = `
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .header { background: #1e88e5; color: white; padding: 20px; }
    .summary { background: #f5f5f5; padding: 15px; margin: 20px 0; }
    .category { margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; }
    th { background: #424242; color: white; padding: 10px; text-align: left; }
    td { padding: 8px; border-bottom: 1px solid #ddd; }
    .excellent { color: #4caf50; }
    .good { color: #ff9800; }
    .poor { color: #f44336; }
  </style>
</head>
<body>
  <div class="header">
    <h1>📊 Daily Service Health Report</h1>
    <p>${new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
  </div>
  
  <div class="summary">
    <h2>Summary</h2>
    <p><strong>Total Services Monitored:</strong> ${summary.totalServices}</p>
    <p><strong>Average Uptime (24h):</strong> <span class="${summary.healthScore === 'Excellent' ? 'excellent' : summary.healthScore === 'Good' ? 'good' : 'poor'}">${summary.avgUptime24h}%</span></p>
    <p><strong>Health Score:</strong> ${summary.healthScore}</p>
  </div>
`;

Object.keys(categories).forEach(categoryName => {
  const services = categories[categoryName];
  if (services.length === 0) return;
  
  html += `
  <div class="category">
    <h2>${categoryName}</h2>
    <table>
      <thead>
        <tr>
          <th>Service</th>
          <th>Status</th>
          <th>24h Uptime</th>
          <th>7d Uptime</th>
          <th>30d Uptime</th>
          <th>Avg Response</th>
        </tr>
      </thead>
      <tbody>
  `;
  
  services.forEach(service => {
    const uptimeClass = parseFloat(service.uptime24h) >= 99 ? 'excellent' : 
                        parseFloat(service.uptime24h) >= 95 ? 'good' : 'poor';
    html += `
      <tr>
        <td><strong>${service.name}</strong></td>
        <td>${service.status}</td>
        <td class="${uptimeClass}">${service.uptime24h}%</td>
        <td>${service.uptime7d}%</td>
        <td>${service.uptime30d}%</td>
        <td>${service.avgPing}ms</td>
      </tr>
    `;
  });
  
  html += `
      </tbody>
    </table>
  </div>
  `;
});

html += `
  <div style="margin-top: 30px; padding: 15px; background: #e3f2fd; border-left: 4px solid #1e88e5;">
    <p><strong>📍 View Live Status:</strong> <a href="https://status.yourdomain.com">https://status.yourdomain.com</a></p>
  </div>
</body>
</html>
`;

return {
  json: {
    html: html,
    subject: `📊 Daily Health Report - ${summary.healthScore} (${summary.avgUptime24h}% uptime)`
  }
};

// 5. Send Email Node
To: team@yourdomain.com, management@yourdomain.com
Subject: {{ $json.subject }}
Body (HTML): {{ $json.html }}

// 6. Slack Node - Post summary
Channel: #daily-reports
Message: |
  📊 **Daily Service Health Report**
  
  **Health Score:** {{ $('Code Node').first().json.summary.healthScore }}
  **Average Uptime:** {{ $('Code Node').first().json.summary.avgUptime24h }}%
  **Services Monitored:** {{ $('Code Node').first().json.summary.totalServices }}
  
  📧 Full report sent via email
  🌐 Live status: https://status.yourdomain.com
```

### Creating Public Status Pages

**Set Up a Customer-Facing Status Page:**

1. **In Uptime Kuma:**
   - Go to **Status Pages**
   - Click **+ New Status Page**

2. **Configure Status Page:**
```
   Title: Service Status
   Description: Real-time status of our services
   Theme: Auto/Light/Dark
   Show Tags: Yes
   Domain Names: status.yourdomain.com (optional custom domain)
```

3. **Add Monitors to Status Page:**
   - Click **+ Add a Group**
   - Group name: "Core Services"
   - Select monitors to display
   - Drag to reorder

4. **Customize Appearance:**
   - Upload logo/favicon
   - Choose color scheme
   - Add footer text (links to support)

5. **Publish:**
   - Toggle **Published** to ON
   - Status page is now public at: `https://status.yourdomain.com/status/page-slug`

**Embed Status Badge in Your Website:**
```html
<!-- Add to your website/docs -->
<img src="https://status.yourdomain.com/api/badge/1/status" alt="Service Status">

<!-- Or with more detail -->
<img src="https://status.yourdomain.com/api/badge/1/uptime/24" alt="24h Uptime">
```

### Best Practices

1. **Logical Monitor Naming** - Use clear, descriptive names like "Production API" instead of "Monitor 1"
2. **Use Tags** - Organize monitors with tags (critical, production, ai-services, customer-facing)
3. **Set Appropriate Intervals** - Critical services: 60s, Normal services: 120-300s to reduce load
4. **Maintenance Windows** - Always schedule maintenance windows to prevent false alerts
5. **Notification Groups** - Create notification groups for different teams/severity levels
6. **Status Page Groups** - Group related services on status pages for better customer UX
7. **Certificate Monitoring** - Monitor all SSL certificates at least 30 days before expiry
8. **Internal Services** - Monitor internal Docker services to catch container crashes
9. **Database Health** - Use dedicated monitor types for databases, not just HTTP checks
10. **Regular Audits** - Review and update monitors monthly, remove obsolete ones
11. **API Rate Limits** - Be mindful of API rate limits when monitoring external services
12. **Backup Notifications** - Configure at least 2 notification channels for critical monitors
13. **Test Notifications** - Regularly test notification channels to ensure they work
14. **Monitor Uptime Kuma** - Set up external monitoring to watch Uptime Kuma itself

### Troubleshooting

#### Uptime Kuma Container Won't Start
```bash
# Check logs
docker logs uptime-kuma --tail 100

# Common issue: Database corruption
docker exec uptime-kuma ls -la /app/data
# Should see kuma.db file

# If database corrupted, restore from backup
docker cp /path/to/backup/kuma.db uptime-kuma:/app/data/kuma.db
docker restart uptime-kuma

# Or start fresh (WARNING: Deletes all monitors!)
launchkit down uptime-kuma
docker volume rm ai-launchkit_uptime-kuma_data
launchkit up -d uptime-kuma
```

#### Monitors Showing False "Down" Alerts
```bash
# 1. Check monitor configuration
# In Uptime Kuma UI: Edit monitor → Check URL, status codes, timeout

# 2. Test connectivity from container
docker exec uptime-kuma curl -v https://example.com
docker exec uptime-kuma ping -c 4 example.com

# 3. DNS resolution issues
docker exec uptime-kuma nslookup example.com
# If fails, check Docker DNS settings

# 4. SSL certificate issues
docker exec uptime-kuma curl -v https://example.com
# Look for certificate errors

# 5. Increase retry count
# In monitor settings: Set Retries to 2-3
# Set Retry Interval to 30-60 seconds
```

#### n8n Webhook Not Receiving Notifications
```bash
# 1. Test webhook manually from Uptime Kuma
# Settings → Notifications → Your webhook → Test
# Check n8n execution log

# 2. Verify webhook URL is accessible from Uptime Kuma container
docker exec uptime-kuma curl -v https://n8n.yourdomain.com/webhook/test

# 3. Check n8n webhook node configuration
# Must be set to POST and path must match exactly

# 4. Test with internal Docker network
# Change webhook URL to: http://n8n:5678/webhook/test
# This bypasses Caddy and tests internal connectivity

# 5. Check Uptime Kuma logs for webhook errors
docker logs uptime-kuma | grep -i webhook
```

#### SSL Certificate Monitor Not Working
```bash
# 1. Ensure monitor type is HTTP(S), not just HTTP
# Edit monitor → Type: HTTP(s)

# 2. Check certificate expiry monitoring is enabled
# Edit monitor → Certificate Expiry Notification: ON
# Certificate Days: 30,14,7

# 3. Test SSL manually
docker exec uptime-kuma openssl s_client -connect example.com:443 -servername example.com

# 4. Check if certificate is actually expiring
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates

# 5. Verify notification is configured
# Monitor must have at least one notification channel enabled
```

#### Database Growing Too Large
```bash
# Check database size
docker exec uptime-kuma du -h /app/data/kuma.db

# Uptime Kuma stores up to 100 heartbeats per monitor
# For 100 monitors @ 60s intervals = ~200MB typical

# If database >1GB, consider:
# 1. Reduce heartbeat retention (Settings → General)
# 2. Increase monitor intervals for non-critical services
# 3. Remove old/unused monitors

# Compact database (Uptime Kuma 2.0+)
# Settings → Database → Shrink Database
```

#### Status Page Not Loading
```bash
# 1. Check if status page is published
# In Uptime Kuma: Status Pages → Your page → Published: ON

# 2. Verify Caddy routing
docker logs caddy | grep uptime-kuma

# 3. Test internal access
docker exec uptime-kuma curl http://localhost:3001

# 4. Check for custom domain configuration
# Status Pages → Your page → Domain Names must match

# 5. Browser cache issue
# Try accessing in incognito/private mode
# Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
```

#### Notifications Not Being Sent
```bash
# 1. Test notification channel manually
# Settings → Notifications → Your notification → Test
# Check the test result message

# 2. Verify notification is enabled on monitor
# Edit monitor → Notifications → Check your notification is selected

# 3. Check notification cooldown period
# Notifications are rate-limited to prevent spam
# Default: 1 notification per 10 minutes per monitor

# 4. Review notification logs
docker logs uptime-kuma | grep -i notification

# 5. For email notifications, check mail server connectivity
docker exec uptime-kuma telnet mailpit 1025
# Should connect successfully
```

### Resources

- **Documentation:** [https://github.com/louislam/uptime-kuma/wiki](https://github.com/louislam/uptime-kuma/wiki)
- **GitHub:** [https://github.com/louislam/uptime-kuma](https://github.com/louislam/uptime-kuma)
- **API Documentation:** [https://github.com/louislam/uptime-kuma/wiki/API-Documentation](https://github.com/louislam/uptime-kuma/wiki/API-Documentation)
- **Community Forum:** [https://github.com/louislam/uptime-kuma/discussions](https://github.com/louislam/uptime-kuma/discussions)
- **Demo Instance:** [https://demo.uptime.kuma.pet](https://demo.uptime.kuma.pet) (Read-only, data deleted every 10 minutes)
- **Notification Setup Guides:** [https://github.com/louislam/uptime-kuma/wiki/🔔-Notification-Setup](https://github.com/louislam/uptime-kuma/wiki/🔔-Notification-Setup)
- **Docker Hub:** [https://hub.docker.com/r/louislam/uptime-kuma](https://hub.docker.com/r/louislam/uptime-kuma)
