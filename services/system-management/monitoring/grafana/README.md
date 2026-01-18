### What is Grafana?

Grafana is an open-source analytics and visualization platform that allows you to query, visualize, alert on, and understand your metrics regardless of where they are stored. It transforms complex data from multiple sources into beautiful, interactive dashboards that make monitoring simple and efficient.

### Features

- **Multi-Source Dashboards** - Combine data from Prometheus, PostgreSQL, InfluxDB, and 60+ other data sources in a single view
- **Real-Time Visualization** - Time series, graphs, heatmaps, histograms, and 30+ visualization types with live data updates
- **Alerting & Notifications** - Define alert rules with thresholds and get notified via email, Slack, PagerDuty, webhooks, and more
- **Template Variables** - Create dynamic, reusable dashboards with dropdown filters for different environments, servers, or metrics
- **Plugin Ecosystem** - Extend functionality with 150+ community and official plugins for data sources, panels, and apps
- **Team Collaboration** - Share dashboards, set up role-based access control (RBAC), organize with folders and playlists

### Initial Setup

**First Login to Grafana:**

1. Navigate to `https://grafana.yourdomain.com`
2. Login with default credentials (from installation report):
   ```
   Username: admin
   Password: [Check your installation report or .env file: GRAFANA_ADMIN_PASSWORD]
   ```
3. **Change Default Password** - You'll be prompted immediately
4. Skip the "Welcome" tour or complete it to learn basics

**Connect Your First Data Source (Prometheus):**

1. Go to **Configuration** (⚙️ gear icon) → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   ```
   Name: Prometheus
   URL: http://prometheus:9090
   Access: Server (default)
   ```
5. Click **Save & Test** - should show "Data source is working"

**Import a Pre-Built Dashboard:**

1. Go to **Dashboards** → **Import**
2. Enter dashboard ID from [Grafana.com](https://grafana.com/grafana/dashboards/):
   - `1860` - Node Exporter Full (system metrics)
   - `3662` - Prometheus 2.0 Overview
   - `12708` - Docker and system monitoring
3. Select **Prometheus** as data source
4. Click **Import**
5. Your dashboard is ready with live metrics!

### n8n Integration Setup

**Internal URL for n8n:** `http://grafana:3000`

**Authentication Options:**

n8n can interact with Grafana using two methods:

**Method 1: API Token (Recommended)**

1. In Grafana, go to **Configuration** → **API Keys**
2. Click **Add API key**:
   ```
   Key name: n8n-integration
   Role: Editor (or Viewer for read-only)
   Time to live: Never expire (or set expiry)
   ```
3. Click **Add** and **copy the API key** immediately (shown only once!)
4. Store in n8n credentials or `.env` file

**Method 2: Service Account Token (Grafana 9+)**

1. Go to **Administration** → **Service accounts**
2. Click **Add service account**:
   ```
   Display name: n8n-automation
   Role: Editor
   ```
3. Click **Add**, then **Add service account token**
4. Copy the token and store securely

**Create HTTP Request Credentials in n8n:**

1. In n8n, go to **Credentials** → **Create New**
2. Search for **Header Auth**
3. Configure:
   ```
   Name: Grafana API
   Header Name: Authorization
   Header Value: Bearer YOUR_API_TOKEN_HERE
   ```
4. Test and save

### Example Workflows

#### Example 1: Alert on High Error Rates

Monitor application errors and notify team when thresholds are exceeded:

```javascript
// n8n Workflow: Grafana Alert to Slack

// 1. Schedule Trigger - Every 5 minutes

// 2. HTTP Request Node - Query Grafana API for panel data
Method: GET
URL: http://grafana:3000/api/datasources/proxy/1/api/v1/query
Authentication: Use Grafana API credentials
Query Parameters:
  query: sum(rate(http_errors_total[5m]))

// 3. Code Node - Evaluate threshold
const errorRate = $input.first().json.data.result[0]?.value[1];
const threshold = 100; // errors per second

if (parseFloat(errorRate) > threshold) {
  return {
    json: {
      alert: true,
      errorRate: errorRate,
      message: `⚠️ High error rate detected: ${errorRate} errors/sec (threshold: ${threshold})`
    }
  };
} else {
  return {
    json: {
      alert: false,
      errorRate: errorRate,
      message: `✅ Error rate normal: ${errorRate} errors/sec`
    }
  };
}

// 4. IF Node - Check if alert condition met
Expression: {{ $json.alert }} === true

// 5a. Slack Node (if true) - Send alert
Channel: #alerts
Message: {{ $json.message }}

// 5b. Do Nothing (if false)

// 6. HTTP Request Node - Create annotation in Grafana
Method: POST
URL: http://grafana:3000/api/annotations
Authentication: Use Grafana API credentials
Body (JSON):
{
  "dashboardId": 1,
  "time": {{ $now.toUnixInteger() * 1000 }},
  "tags": ["alert", "automated"],
  "text": "{{ $json.message }}"
}
```

#### Example 2: Automated Dashboard Snapshot & Report

Generate weekly dashboard snapshots and email to stakeholders:

```javascript
// n8n Workflow: Weekly Grafana Report

// 1. Schedule Trigger - Every Monday at 9 AM

// 2. HTTP Request Node - Create dashboard snapshot
Method: POST
URL: http://grafana:3000/api/snapshots
Authentication: Use Grafana API credentials
Body (JSON):
{
  "dashboard": {
    "getDashboardId": 1  // Your main dashboard ID
  },
  "name": "Weekly Report - {{ $now.format('YYYY-MM-DD') }}",
  "expires": 604800  // 7 days in seconds
}

// Store snapshot URL
// Response contains: {"url": "https://grafana.yourdomain.com/dashboard/snapshot/..."}

// 3. HTTP Request Node - Render dashboard as image
Method: GET
URL: http://grafana:3000/render/d-solo/DASHBOARD_UID/dashboard-name
Authentication: Use Grafana API credentials
Query Parameters:
  orgId: 1
  from: now-7d
  to: now
  panelId: 2
  width: 1000
  height: 500
  theme: light
Options:
  Response Format: File

// 4. Code Node - Prepare email content
const snapshotUrl = $('HTTP Request').json.url;
const dashboardUrl = 'https://grafana.yourdomain.com/d/YOUR_DASHBOARD_UID';

return {
  json: {
    subject: `📊 Weekly Dashboard Report - ${new Date().toLocaleDateString()}`,
    body: `
      <h2>Weekly Dashboard Snapshot</h2>
      <p>Here's your automated weekly report from Grafana:</p>
      <p><strong>Report Period:</strong> Last 7 days</p>
      <p><strong>Live Dashboard:</strong> <a href="${dashboardUrl}">View in Grafana</a></p>
      <p><strong>Snapshot Link:</strong> <a href="${snapshotUrl}">View Snapshot (expires in 7 days)</a></p>
      <h3>Key Metrics Overview:</h3>
      <p>See attached dashboard image for full details.</p>
    `
  }
};

// 5. Send Email Node
To: team@yourdomain.com, executives@yourdomain.com
Subject: {{ $json.subject }}
Body (HTML): {{ $json.body }}
Attachments: Use file from HTTP Request (step 3)

// 6. Slack Node - Post notification
Channel: #reports
Message: |
  📊 *Weekly Grafana Report Published*
  
  📅 Report Date: {{ $now.format('MMMM D, YYYY') }}
  🔗 Dashboard: {{ dashboardUrl }}
  📸 Snapshot: {{ snapshotUrl }}
  
  Full report sent via email.
```

#### Example 3: Dynamic Dashboard Creation from Workflow Data

Automatically create Grafana dashboards from n8n workflow execution metrics:

```javascript
// n8n Workflow: Create Custom Workflow Performance Dashboard

// 1. Webhook Trigger - Receive workflow completion event

// 2. Code Node - Aggregate last 30 days of workflow data
// Query your n8n database or use n8n API to get execution stats

const workflowMetrics = {
  workflow_id: $json.workflowId,
  workflow_name: $json.workflowName,
  total_executions: 1250,
  success_rate: 94.5,
  avg_duration: 2.3,
  error_count: 69
};

// Define dashboard JSON
const dashboard = {
  "dashboard": {
    "title": `Workflow Performance: ${workflowMetrics.workflow_name}`,
    "tags": ["workflow", "automation", "performance"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Execution Count (Last 30 Days)",
        "type": "stat",
        "targets": [
          {
            "datasource": "Prometheus",
            "expr": `sum(n8n_workflow_executions_total{workflow_id="${workflowMetrics.workflow_id}"})`
          }
        ],
        "gridPos": { "h": 8, "w": 6, "x": 0, "y": 0 }
      },
      {
        "id": 2,
        "title": "Success Rate",
        "type": "gauge",
        "targets": [
          {
            "datasource": "Prometheus",
            "expr": `(sum(n8n_workflow_executions_total{status="success"}) / sum(n8n_workflow_executions_total)) * 100`
          }
        ],
        "gridPos": { "h": 8, "w": 6, "x": 6, "y": 0 }
      },
      {
        "id": 3,
        "title": "Average Duration",
        "type": "graph",
        "targets": [
          {
            "datasource": "Prometheus",
            "expr": `avg(n8n_workflow_execution_duration_seconds{workflow_id="${workflowMetrics.workflow_id}"})`
          }
        ],
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 }
      }
    ]
  },
  "folderId": 0,
  "overwrite": true
};

return { json: dashboard };

// 3. HTTP Request Node - Create dashboard in Grafana
Method: POST
URL: http://grafana:3000/api/dashboards/db
Authentication: Use Grafana API credentials
Body (JSON): {{ $json }}

// 4. Code Node - Extract dashboard URL
const response = $input.first().json;
const dashboardUrl = `https://grafana.yourdomain.com${response.url}`;

return {
  json: {
    dashboardUrl: dashboardUrl,
    dashboardId: response.id,
    message: `Dashboard created successfully for workflow: ${workflowMetrics.workflow_name}`
  }
};

// 5. Slack Node - Notify team
Channel: #automation
Message: |
  ✅ *New Grafana Dashboard Created*
  
  📊 Workflow: {{ $('Code Node').first().json.workflow_name }}
  🔗 Dashboard: {{ $json.dashboardUrl }}
  
  Automated performance tracking is now live!
```

#### Example 4: Monitor & Auto-Scale Based on Metrics

Query Grafana metrics and trigger scaling actions:

```javascript
// n8n Workflow: Auto-Scale Based on CPU Metrics

// 1. Schedule Trigger - Every 2 minutes

// 2. HTTP Request Node - Query current CPU usage from Prometheus
Method: GET
URL: http://grafana:3000/api/datasources/proxy/1/api/v1/query
Authentication: Use Grafana API credentials
Query Parameters:
  query: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

// 3. Code Node - Evaluate scaling decision
const cpuData = $input.first().json.data.result;

// Calculate average CPU across all instances
let totalCpu = 0;
let instanceCount = 0;

cpuData.forEach(instance => {
  totalCpu += parseFloat(instance.value[1]);
  instanceCount++;
});

const avgCpu = totalCpu / instanceCount;
const scaleUpThreshold = 80;
const scaleDownThreshold = 30;

let action = 'none';
if (avgCpu > scaleUpThreshold) {
  action = 'scale_up';
} else if (avgCpu < scaleDownThreshold) {
  action = 'scale_down';
}

return {
  json: {
    avgCpu: avgCpu.toFixed(2),
    action: action,
    instanceCount: instanceCount,
    timestamp: new Date().toISOString()
  }
};

// 4. Switch Node - Route based on action
// Mode: Expression
// Output: {{ $json.action }}

// 5a. HTTP Request (Scale Up) - Call your infrastructure API
Method: POST
URL: https://your-cloud-provider.com/api/scale
Body: { "action": "scale_up", "instances": 1 }

// 5b. HTTP Request (Scale Down) - Call your infrastructure API
Method: POST
URL: https://your-cloud-provider.com/api/scale
Body: { "action": "scale_down", "instances": 1 }

// 5c. Do Nothing

// 6. HTTP Request Node - Create annotation in Grafana
Method: POST
URL: http://grafana:3000/api/annotations
Authentication: Use Grafana API credentials
Body (JSON):
{
  "dashboardId": 1,
  "time": {{ $now.toUnixInteger() * 1000 }},
  "tags": ["autoscaling", "{{ $json.action }}"],
  "text": "Auto-scaling action: {{ $json.action }} (CPU: {{ $json.avgCpu }}%)"
}

// 7. Send Email (if scaled)
IF Node: {{ $json.action }} !== 'none'
To: devops@yourdomain.com
Subject: Auto-scaling event triggered
Body: |
  CPU Utilization: {{ $json.avgCpu }}%
  Action Taken: {{ $json.action }}
  Instance Count: {{ $json.instanceCount }}
```

### Alerting with Grafana & n8n

**Set up Grafana Alerts to trigger n8n webhooks:**

1. **In n8n - Create Webhook:**
   - Add Webhook node to new workflow
   - Set to `GET` or `POST`
   - Copy webhook URL: `https://n8n.yourdomain.com/webhook/grafana-alert`

2. **In Grafana - Configure Contact Point:**
   - Go to **Alerting** → **Contact points**
   - Click **New contact point**
   - Select **Webhook** as type
   - Enter n8n webhook URL
   - Add custom headers if needed (for authentication)

3. **Create Alert Rule:**
   - Go to **Alerting** → **Alert rules**
   - Click **Create alert rule**
   - Select data source and write PromQL query
   - Define threshold conditions
   - Set evaluation interval
   - Select your n8n contact point

4. **Process in n8n:**
   ```javascript
   // n8n Webhook receives alert payload
   const alert = $json;
   
   // Alert payload structure:
   {
     "state": "alerting",  // or "ok"
     "evalMatches": [...],
     "message": "Alert message",
     "ruleId": 1,
     "ruleName": "High CPU Alert",
     "tags": {...}
   }
   
   // Take action based on alert state
   if (alert.state === 'alerting') {
     // Send to Slack, PagerDuty, create ticket, etc.
   }
   ```

### Advanced Grafana Features for n8n Integration

#### Variables & Templating

Create dynamic dashboards that n8n can manipulate:

```javascript
// HTTP Request - Update dashboard variable
Method: POST
URL: http://grafana:3000/api/dashboards/db
Body (JSON):
{
  "dashboard": {
    "title": "Dynamic Dashboard",
    "templating": {
      "list": [
        {
          "type": "query",
          "name": "server",
          "query": "label_values(up, instance)",
          "current": {
            "text": "{{ $json.selectedServer }}",
            "value": "{{ $json.selectedServer }}"
          }
        }
      ]
    }
  }
}
```

#### Annotations

Add context to your dashboards programmatically:

```javascript
// Mark deployments, incidents, or events
Method: POST
URL: http://grafana:3000/api/annotations
Body (JSON):
{
  "dashboardId": 1,
  "panelId": 2,  // Optional: specific panel
  "time": {{ $now.toUnixInteger() * 1000 }},
  "timeEnd": {{ $now.plus(1, 'hour').toUnixInteger() * 1000 }},  // Optional: for range
  "tags": ["deployment", "production", "v2.1.0"],
  "text": "Deployed version 2.1.0 to production",
  "dashboardUID": "dashboard-uid"  // Alternative to dashboardId
}
```

#### Playlist Automation

Control dashboard playlists for display screens:

```javascript
// Create a playlist
Method: POST
URL: http://grafana:3000/api/playlists
Body (JSON):
{
  "name": "Office Dashboard Rotation",
  "interval": "30s",
  "items": [
    {"type": "dashboard_by_id", "value": "1"},
    {"type": "dashboard_by_id", "value": "2"},
    {"type": "dashboard_by_id", "value": "5"}
  ]
}

// Start a playlist
Method: GET
URL: http://grafana:3000/api/playlists/1/start
```

### Best Practices

1. **Use Service Accounts** - Create dedicated service accounts with minimal permissions for n8n integrations
2. **Internal URLs** - From n8n, always use `http://grafana:3000`, never the external domain
3. **Cache Queries** - Store frequently queried data in n8n variables to reduce API calls
4. **Error Handling** - Always wrap Grafana API calls in try-catch blocks and handle rate limits
5. **Dashboard as Code** - Export dashboard JSON and version control it alongside your workflows
6. **Annotations for Audit** - Create Grafana annotations when n8n workflows make infrastructure changes
7. **Alert De-duplication** - Implement cooldown periods in n8n to prevent alert spam
8. **Secure API Keys** - Rotate API tokens regularly and use short-lived tokens when possible
9. **Testing Dashboards** - Create test dashboards in separate folders before promoting to production
10. **Monitor Grafana Itself** - Set up self-monitoring dashboards to track Grafana's own performance

### Troubleshooting

#### Grafana Container Won't Start

```bash
# Check logs
docker logs grafana --tail 100

# Common issue: Permissions on grafana data volume
docker exec grafana ls -la /var/lib/grafana
# Should be owned by user 472 (grafana user)

# Fix permissions if needed
docker exec -u root grafana chown -R 472:472 /var/lib/grafana

# Restart container
docker restart grafana
```

#### Cannot Connect to Data Sources

```bash
# Test internal connectivity from Grafana container
docker exec grafana curl -v http://prometheus:9090
docker exec grafana curl -v http://postgres:5432

# If connection fails, check Docker network
docker network inspect ai-corekit_default

# Ensure services are on same network
docker inspect grafana | grep NetworkMode
docker inspect prometheus | grep NetworkMode
```

#### n8n Cannot Authenticate with Grafana

```bash
# 1. Verify API token is valid
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://grafana:3000/api/org

# Should return organization info, not 401

# 2. Check token permissions
# In Grafana UI: Configuration → API Keys
# Ensure role is Editor or Admin

# 3. For service accounts (Grafana 9+)
# Administration → Service accounts → Check token expiry
```

#### Slow Dashboard Performance

```bash
# 1. Check query performance in Grafana UI
# Open panel → Query Inspector → Check query execution time

# 2. Optimize Prometheus queries
# Use recording rules for frequently computed metrics

# 3. Increase Grafana resources in docker-compose.yml
environment:
  - GF_SERVER_ROOT_URL=https://grafana.yourdomain.com
  - GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/home.json
  - GF_DATABASE_MAX_OPEN_CONN=300  # Increase from default 0
  - GF_DATABASE_MAX_IDLE_CONN=100  # Increase from default 2

# 4. Enable query caching
# Settings → Data Sources → Your data source → Cache Settings
# Set cache timeout: 60s for frequently changing data
```

#### Alerts Not Triggering n8n Webhooks

```bash
# 1. Check Grafana alert state
# Alerting → Alert rules → View rule state

# 2. Test contact point manually
# Alerting → Contact points → Select your webhook → Test

# 3. Check n8n webhook logs
# In n8n: Workflow → Executions → Find webhook trigger

# 4. Verify webhook URL is accessible from Grafana
docker exec grafana curl -v https://n8n.yourdomain.com/webhook/test

# 5. Check Grafana logs for delivery errors
docker logs grafana --tail 50 | grep -i "webhook\|alert"
```

#### Dashboard Not Saving via API

```bash
# Check if dashboard JSON is valid
# Test with curl:
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {...}, "folderId": 0, "overwrite": true}' \
  --verbose

# Common errors:
# - Missing "dashboard" wrapper object
# - Invalid panel ID references
# - Duplicate dashboard UID (set "overwrite": true)
# - Insufficient token permissions (use Editor or Admin role)
```

### Resources

- **Documentation:** [https://grafana.com/docs/grafana/latest/](https://grafana.com/docs/grafana/latest/)
- **Dashboard Library:** [https://grafana.com/grafana/dashboards/](https://grafana.com/grafana/dashboards/) (1000+ pre-built dashboards)
- **API Reference:** [https://grafana.com/docs/grafana/latest/developers/http_api/](https://grafana.com/docs/grafana/latest/developers/http_api/)
- **Plugin Catalog:** [https://grafana.com/grafana/plugins/](https://grafana.com/grafana/plugins/)
- **GitHub:** [https://github.com/grafana/grafana](https://github.com/grafana/grafana)
- **Community Forum:** [https://community.grafana.com/](https://community.grafana.com/)
- **Grafana University:** [https://grafana.com/tutorials/](https://grafana.com/tutorials/) (Free tutorials and courses)
- **n8n Grafana Node:** [https://n8n.io/integrations/grafana/](https://n8n.io/integrations/grafana/)
