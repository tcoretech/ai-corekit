### What is Prometheus?

Prometheus is an open-source systems monitoring and alerting toolkit that collects and stores metrics as time-series data. Originally built at SoundCloud, it's now a graduated CNCF project and the de-facto standard for cloud-native monitoring. Prometheus uses a pull-based model to scrape metrics from targets at regular intervals, stores them efficiently, and provides a powerful query language (PromQL) for analysis.

### Features

- **Pull-Based Metrics Collection** - Scrapes HTTP endpoints at configured intervals instead of requiring applications to push data
- **Powerful Query Language (PromQL)** - Flexible queries for filtering, aggregating, and analyzing time-series data in real-time
- **Multi-Dimensional Data Model** - Metrics identified by name and key-value labels for flexible querying and aggregation
- **Service Discovery** - Automatically discovers targets via Kubernetes, Consul, DNS, file-based configs, and more
- **Built-in Alerting** - Define alert rules in PromQL that trigger when conditions are met, integrated with Alertmanager
- **Local Storage & Optional Remote Write** - Efficient on-disk storage with optional integration to remote systems like Grafana Mimir

### Initial Setup

**Access Prometheus Web UI:**

1. Navigate to `http://prometheus.yourdomain.com` (if exposed externally)
   - Or internally: `http://prometheus:9090`
2. No authentication required by default (internal service)
3. Explore the interface:
   - **Graph** - Execute PromQL queries and visualize results
   - **Alerts** - View active alerts and their states
   - **Status** → **Targets** - See all scrape targets and their health
   - **Status** → **Configuration** - View current Prometheus config

**Verify Prometheus is Scraping Metrics:**

1. Go to **Status** → **Targets**
2. Check that targets show as **UP** (green)
3. Common targets in AI CoreKit:
   - `prometheus` - Prometheus itself
   - `node-exporter` - System metrics (if installed)
   - `cadvisor` - Container metrics (if installed)
   - `n8n` - n8n metrics (if enabled with `N8N_METRICS=true`)

**Execute Your First PromQL Query:**

1. Go to **Graph** tab
2. Try these example queries:
   ```promql
   # Current CPU usage
   100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
   # Memory usage percentage
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   
   # HTTP request rate
   rate(http_requests_total[5m])
   
   # n8n workflow executions (if N8N_METRICS enabled)
   sum(n8n_workflow_executions_total)
   ```
3. Click **Execute** and view results in table or graph format

**Configure Alertmanager (Optional but Recommended):**

Alertmanager handles alerts sent by Prometheus, including deduplication, grouping, and routing to receivers like email, Slack, PagerDuty, or n8n webhooks.

1. Edit `prometheus.yml` to add alert rules:
   ```yaml
   rule_files:
     - /etc/prometheus/alert.rules.yml
   
   alerting:
     alertmanagers:
       - static_configs:
           - targets:
               - alertmanager:9093
   ```

2. Create `/etc/prometheus/alert.rules.yml`:
   ```yaml
   groups:
     - name: system_alerts
       interval: 30s
       rules:
         - alert: HighCPUUsage
           expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
           for: 5m
           labels:
             severity: warning
           annotations:
             summary: "High CPU usage detected on {{ $labels.instance }}"
             description: "CPU usage is {{ $value }}%"
   ```

3. Reload Prometheus config:
   ```bash
   docker exec prometheus kill -HUP 1
   # Or restart container
   docker restart prometheus
   ```

### n8n Integration Setup

**Internal URL for n8n:** `http://prometheus:9090`

Prometheus doesn't have traditional "credentials" - it's typically accessed internally without authentication. Integration with n8n is done via:
1. **HTTP Request Node** - Query Prometheus API for metrics
2. **Webhook Trigger** - Receive alerts from Alertmanager

#### Method 1: Query Prometheus API from n8n

**HTTP Request Node Configuration:**

```javascript
// No credentials needed for internal access
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: up{job="prometheus"}  // Your PromQL query
  time: {{ $now.toUnixInteger() }}  // Optional: specific timestamp

// Alternative: Range query for time-series data
Method: GET
URL: http://prometheus:9090/api/v1/query_range
Query Parameters:
  query: rate(http_requests_total[5m])
  start: {{ $now.minus(1, 'hour').toUnixInteger() }}
  end: {{ $now.toUnixInteger() }}
  step: 60  // Resolution in seconds
```

**Response Structure:**
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "up",
          "job": "prometheus",
          "instance": "localhost:9090"
        },
        "value": [1634567890, "1"]
      }
    ]
  }
}
```

#### Method 2: Receive Alerts via Alertmanager Webhook

**Configure Alertmanager to Send to n8n:**

1. **In n8n - Create Webhook Trigger:**
   - Add Webhook node to new workflow
   - Set HTTP Method: `POST`
   - Copy webhook URL: `https://n8n.yourdomain.com/webhook/prometheus-alerts`

2. **In Alertmanager - Edit `/etc/alertmanager/alertmanager.yml`:**
   ```yaml
   global:
     resolve_timeout: 5m
   
   route:
     receiver: 'n8n-webhook'
     group_by: ['alertname', 'instance']
     group_wait: 30s
     group_interval: 1m
     repeat_interval: 30m
     routes:
       - match:
           severity: critical
         receiver: 'n8n-critical'
         continue: true
       - match:
           severity: warning
         receiver: 'n8n-webhook'
   
   receivers:
     - name: 'n8n-webhook'
       webhook_configs:
         - url: 'http://n8n:5678/webhook/prometheus-alerts'
           send_resolved: true
           http_config:
             follow_redirects: true
   
     - name: 'n8n-critical'
       webhook_configs:
         - url: 'http://n8n:5678/webhook/prometheus-critical'
           send_resolved: true
   ```

3. **Reload Alertmanager:**
   ```bash
   docker exec alertmanager kill -HUP 1
   ```

**Webhook Payload Structure:**
```json
{
  "receiver": "n8n-webhook",
  "status": "firing",  // or "resolved"
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighCPUUsage",
        "instance": "server-01",
        "severity": "warning"
      },
      "annotations": {
        "summary": "High CPU usage detected",
        "description": "CPU usage is 85%"
      },
      "startsAt": "2024-10-19T10:30:00Z",
      "endsAt": "0001-01-01T00:00:00Z",
      "generatorURL": "http://prometheus:9090/graph?..."
    }
  ],
  "groupLabels": {
    "alertname": "HighCPUUsage"
  },
  "commonLabels": {
    "severity": "warning"
  },
  "externalURL": "http://alertmanager:9093"
}
```

### Example Workflows

#### Example 1: Automated Incident Response System

Receive Prometheus alerts via Alertmanager and auto-remediate or escalate:

```javascript
// n8n Workflow: Intelligent Alert Handler

// 1. Webhook Trigger - Receive alert from Alertmanager
// Webhook URL: /webhook/prometheus-alerts
// HTTP Method: POST

// 2. Code Node - Parse and analyze alert
const alert = $input.first().json.alerts[0];
const isBusinessHours = () => {
  const now = new Date();
  const hour = now.getHours();
  const day = now.getDay();
  return day >= 1 && day <= 5 && hour >= 9 && hour < 17;
};

const severity = alert.labels.severity || 'info';
const alertName = alert.labels.alertname;
const instance = alert.labels.instance;
const status = alert.status;  // 'firing' or 'resolved'

// Calculate alert duration if firing
let duration = null;
if (status === 'firing') {
  const startTime = new Date(alert.startsAt);
  const now = new Date();
  duration = Math.floor((now - startTime) / 1000 / 60);  // minutes
}

return {
  json: {
    severity: severity,
    alertName: alertName,
    instance: instance,
    status: status,
    duration: duration,
    isBusinessHours: isBusinessHours(),
    description: alert.annotations.description || alert.annotations.summary,
    dashboardUrl: alert.generatorURL,
    canAutoRemediate: ['HighMemoryUsage', 'ContainerRestart'].includes(alertName)
  }
};

// 3. Switch Node - Route based on severity and status
// Mode: Expression
// Output 0: {{ $json.status === 'resolved' }}
// Output 1: {{ $json.severity === 'critical' }}
// Output 2: {{ $json.severity === 'warning' && $json.canAutoRemediate }}
// Output 3: {{ $json.severity === 'warning' }}

// 4a. Resolved Alert - Log and notify
// Code Node - Log resolution
const alert = $input.first().json;
return {
  json: {
    message: `✅ RESOLVED: ${alert.alertName} on ${alert.instance}`,
    slackMessage: {
      text: "Alert Resolved",
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*✅ Alert Resolved*\n*Alert:* ${alert.alertName}\n*Instance:* ${alert.instance}\n*Description:* ${alert.description}`
          }
        }
      ]
    }
  }
};

// Slack Node - Notify resolution
Channel: #monitoring
Message: {{ $json.slackMessage }}

// 4b. Critical Alert - Immediate escalation
// Code Node - Prepare critical notification
const alert = $input.first().json;
const oncallTeam = alert.isBusinessHours ? '@devops-team' : '@oncall-sre';

return {
  json: {
    subject: `🚨 CRITICAL: ${alert.alertName}`,
    message: `Critical alert requires immediate attention!\n\nAlert: ${alert.alertName}\nInstance: ${alert.instance}\nDescription: ${alert.description}\nDuration: ${alert.duration} minutes\n\nDashboard: ${alert.dashboardUrl}`,
    slackMessage: {
      text: "🚨 CRITICAL ALERT",
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: "🚨 CRITICAL ALERT"
          }
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: `*Alert:*\n${alert.alertName}`
            },
            {
              type: "mrkdwn",
              text: `*Instance:*\n${alert.instance}`
            },
            {
              type: "mrkdwn",
              text: `*Duration:*\n${alert.duration} minutes`
            },
            {
              type: "mrkdwn",
              text: `*Oncall:*\n${oncallTeam}`
            }
          ]
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*Description:*\n${alert.description}`
          }
        },
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: {
                type: "plain_text",
                text: "View Dashboard"
              },
              url: alert.dashboardUrl
            }
          ]
        }
      ]
    },
    pagerdutyPayload: {
      routing_key: "YOUR_PAGERDUTY_KEY",
      event_action: "trigger",
      payload: {
        summary: `${alert.alertName} on ${alert.instance}`,
        severity: "critical",
        source: alert.instance,
        custom_details: {
          description: alert.description,
          duration: `${alert.duration} minutes`
        }
      }
    }
  }
};

// Slack Node - Post to emergency channel
Channel: #incidents
Message: {{ $json.slackMessage }}

// HTTP Request Node - Trigger PagerDuty
Method: POST
URL: https://events.pagerduty.com/v2/enqueue
Body (JSON): {{ $json.pagerdutyPayload }}

// Send Email Node - Email oncall team
To: oncall@yourdomain.com
Subject: {{ $json.subject }}
Priority: High
Body: {{ $json.message }}

// 4c. Auto-Remediation Path - Attempt automated fix
// Code Node - Determine remediation action
const alert = $input.first().json;

const remediationActions = {
  'HighMemoryUsage': {
    action: 'restart_container',
    container: alert.instance,
    command: `docker restart ${alert.instance}`
  },
  'ContainerRestart': {
    action: 'check_logs',
    container: alert.instance,
    command: `docker logs --tail 100 ${alert.instance}`
  }
};

const remediation = remediationActions[alert.alertName];

return {
  json: {
    ...alert,
    remediation: remediation,
    shouldExecute: remediation !== undefined
  }
};

// IF Node - Check if remediation available
Condition: {{ $json.shouldExecute }} === true

// SSH Node - Execute remediation command
Host: server.yourdomain.com
Command: {{ $json.remediation.command }}

// Code Node - Evaluate remediation result
const sshOutput = $input.first().json;
const alert = $('Code Node1').first().json;

// Wait 2 minutes and query Prometheus to check if alert cleared
return {
  json: {
    alert: alert,
    remediationExecuted: true,
    willVerify: true
  }
};

// Wait Node - 2 minutes
Amount: 2
Unit: minutes

// HTTP Request Node - Check if alert still firing
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: ALERTS{alertname="{{ $('Code Node1').first().json.alertName }}",alertstate="firing"}

// Code Node - Check if remediation worked
const prometheusResult = $input.first().json.data.result;
const remediationSucceeded = prometheusResult.length === 0;

return {
  json: {
    remediationSucceeded: remediationSucceeded,
    message: remediationSucceeded 
      ? `✅ Auto-remediation successful for ${$('Code Node1').first().json.alertName}`
      : `⚠️ Auto-remediation failed, escalating ${$('Code Node1').first().json.alertName}`
  }
};

// IF Node - Escalate if remediation failed
Condition: {{ $json.remediationSucceeded }} === false
// If failed, route to critical alert path (4b)

// Slack Node - Notify remediation result
Channel: #monitoring
Message: {{ $json.message }}

// 4d. Warning Alert - Standard notification
// Slack Node
Channel: #alerts
Message: |
  ⚠️ *Warning Alert*
  
  *Alert:* {{ $('Code Node').first().json.alertName }}
  *Instance:* {{ $('Code Node').first().json.instance }}
  *Description:* {{ $('Code Node').first().json.description }}
  *Duration:* {{ $('Code Node').first().json.duration }} minutes
  
  <{{ $('Code Node').first().json.dashboardUrl }}|View Dashboard>

// 5. PostgreSQL Node - Log all alerts to database
Operation: Insert
Table: prometheus_alerts
Columns:
  alert_name: {{ $('Code Node').first().json.alertName }}
  instance: {{ $('Code Node').first().json.instance }}
  severity: {{ $('Code Node').first().json.severity }}
  status: {{ $('Code Node').first().json.status }}
  description: {{ $('Code Node').first().json.description }}
  duration_minutes: {{ $('Code Node').first().json.duration }}
  timestamp: {{ $now.toISO() }}
  remediation_attempted: {{ $json.remediationExecuted || false }}
```

#### Example 2: Proactive System Health Monitoring

Query Prometheus metrics on schedule to detect issues before they become critical:

```javascript
// n8n Workflow: Proactive Health Checks

// 1. Schedule Trigger - Every 5 minutes

// 2. HTTP Request Node - Query CPU usage
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

// 3. HTTP Request Node - Query memory usage
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

// 4. HTTP Request Node - Query disk usage
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: (node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100

// 5. HTTP Request Node - Query container health
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: up{job=~".*"}

// 6. Code Node - Aggregate and analyze health metrics
const cpuData = $('HTTP Request').all()[0].json.data.result;
const memoryData = $('HTTP Request1').all()[0].json.data.result;
const diskData = $('HTTP Request2').all()[0].json.data.result;
const containerData = $('HTTP Request3').all()[0].json.data.result;

// Analyze CPU
const cpuIssues = cpuData.filter(m => parseFloat(m.value[1]) > 70);

// Analyze Memory
const memoryIssues = memoryData.filter(m => parseFloat(m.value[1]) > 80);

// Analyze Disk
const diskIssues = diskData.filter(m => parseFloat(m.value[1]) > 85);

// Analyze Container Health
const downContainers = containerData.filter(m => m.value[1] !== "1");

// Create health report
const healthReport = {
  timestamp: new Date().toISOString(),
  overall_health: cpuIssues.length === 0 && memoryIssues.length === 0 && 
                  diskIssues.length === 0 && downContainers.length === 0 ? 'healthy' : 'degraded',
  cpu: {
    total_instances: cpuData.length,
    high_usage_count: cpuIssues.length,
    details: cpuIssues.map(m => ({
      instance: m.metric.instance,
      usage: parseFloat(m.value[1]).toFixed(2) + '%'
    }))
  },
  memory: {
    total_instances: memoryData.length,
    high_usage_count: memoryIssues.length,
    details: memoryIssues.map(m => ({
      instance: m.metric.instance,
      usage: parseFloat(m.value[1]).toFixed(2) + '%'
    }))
  },
  disk: {
    total_instances: diskData.length,
    high_usage_count: diskIssues.length,
    details: diskIssues.map(m => ({
      instance: m.metric.instance,
      mountpoint: m.metric.mountpoint,
      usage: parseFloat(m.value[1]).toFixed(2) + '%'
    }))
  },
  containers: {
    total: containerData.length,
    down: downContainers.length,
    details: downContainers.map(m => ({
      job: m.metric.job,
      instance: m.metric.instance
    }))
  }
};

return { json: healthReport };

// 7. IF Node - Check if issues detected
Condition: {{ $json.overall_health }} === 'degraded'

// 8a. Slack Node (if issues) - Send warning
Channel: #monitoring
Message: |
  ⚠️ *System Health Degraded*
  
  *CPU Issues:* {{ $json.cpu.high_usage_count }} instance(s)
  {{ $json.cpu.details.map(d => `  • ${d.instance}: ${d.usage}`).join('\n') }}
  
  *Memory Issues:* {{ $json.memory.high_usage_count }} instance(s)
  {{ $json.memory.details.map(d => `  • ${d.instance}: ${d.usage}`).join('\n') }}
  
  *Disk Issues:* {{ $json.disk.high_usage_count }} instance(s)
  {{ $json.disk.details.map(d => `  • ${d.instance} (${d.mountpoint}): ${d.usage}`).join('\n') }}
  
  *Containers Down:* {{ $json.containers.down }}
  {{ $json.containers.details.map(d => `  • ${d.job} on ${d.instance}`).join('\n') }}

// 8b. Do Nothing (if healthy)

// 9. PostgreSQL Node - Store health snapshot
Operation: Insert
Table: system_health_snapshots
Data: {{ $json }}
```

#### Example 3: Custom Metrics Collection from n8n Workflows

Push custom metrics to Prometheus from your n8n workflows:

```javascript
// n8n Workflow: Business Metrics to Prometheus

// Enable Prometheus Pushgateway in docker-compose.yml first!

// 1. Schedule Trigger or Webhook - Your business process

// 2. Code Node - Calculate business metrics
// Example: Calculate daily order metrics

const orders = $json.orders || [];

const metrics = {
  total_orders: orders.length,
  total_revenue: orders.reduce((sum, o) => sum + o.amount, 0),
  avg_order_value: orders.reduce((sum, o) => sum + o.amount, 0) / orders.length,
  orders_by_status: {
    pending: orders.filter(o => o.status === 'pending').length,
    completed: orders.filter(o => o.status === 'completed').length,
    cancelled: orders.filter(o => o.status === 'cancelled').length
  }
};

return { json: metrics };

// 3. Code Node - Format metrics for Pushgateway
const metrics = $input.first().json;

// Prometheus metrics format
const metricsText = `
# HELP business_orders_total Total number of orders
# TYPE business_orders_total counter
business_orders_total ${metrics.total_orders}

# HELP business_revenue_total Total revenue
# TYPE business_revenue_total counter
business_revenue_total ${metrics.total_revenue}

# HELP business_order_value_avg Average order value
# TYPE business_order_value_avg gauge
business_order_value_avg ${metrics.avg_order_value}

# HELP business_orders_by_status Orders by status
# TYPE business_orders_by_status gauge
business_orders_by_status{status="pending"} ${metrics.orders_by_status.pending}
business_orders_by_status{status="completed"} ${metrics.orders_by_status.completed}
business_orders_by_status{status="cancelled"} ${metrics.orders_by_status.cancelled}
`;

return { json: { metrics: metricsText } };

// 4. HTTP Request Node - Push to Pushgateway
Method: POST
URL: http://pushgateway:9091/metrics/job/n8n_business_metrics/instance/workflow_{{ $workflow.id }}
Headers:
  Content-Type: text/plain
Body (Raw): {{ $json.metrics }}

// 5. Slack Node - Confirm metrics pushed
Channel: #metrics
Message: |
  📊 Business metrics updated in Prometheus
  
  • Total Orders: {{ $('Code Node').first().json.total_orders }}
  • Total Revenue: ${{ $('Code Node').first().json.total_revenue.toFixed(2) }}
  • Avg Order Value: ${{ $('Code Node').first().json.avg_order_value.toFixed(2) }}
```

#### Example 4: SLA Monitoring & Reporting

Monitor service level agreements and generate compliance reports:

```javascript
// n8n Workflow: SLA Compliance Monitoring

// 1. Schedule Trigger - Daily at 8 AM

// 2. Set Variable - Define SLA thresholds
Name: sla_targets
Value:
{
  "uptime_percentage": 99.9,
  "response_time_ms": 200,
  "error_rate_percentage": 0.1
}

// 3. HTTP Request - Query uptime (last 24h)
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: avg_over_time(up{job="production"}[24h]) * 100

// 4. HTTP Request - Query response time (p95)
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[24h])) * 1000

// 5. HTTP Request - Query error rate
Method: GET
URL: http://prometheus:9090/api/v1/query
Query Parameters:
  query: sum(rate(http_requests_total{status=~"5.."}[24h])) / sum(rate(http_requests_total[24h])) * 100

// 6. Code Node - Calculate SLA compliance
const slaTargets = $('Set Variable').first().json;
const uptime = parseFloat($('HTTP Request').first().json.data.result[0]?.value[1] || 0);
const responseTime = parseFloat($('HTTP Request1').first().json.data.result[0]?.value[1] || 0);
const errorRate = parseFloat($('HTTP Request2').first().json.data.result[0]?.value[1] || 0);

const uptimeCompliant = uptime >= slaTargets.uptime_percentage;
const responseTimeCompliant = responseTime <= slaTargets.response_time_ms;
const errorRateCompliant = errorRate <= slaTargets.error_rate_percentage;

const overallCompliant = uptimeCompliant && responseTimeCompliant && errorRateCompliant;

return {
  json: {
    date: new Date().toISOString().split('T')[0],
    compliant: overallCompliant,
    metrics: {
      uptime: {
        actual: uptime.toFixed(3) + '%',
        target: slaTargets.uptime_percentage + '%',
        compliant: uptimeCompliant
      },
      response_time: {
        actual: responseTime.toFixed(2) + 'ms',
        target: slaTargets.response_time_ms + 'ms',
        compliant: responseTimeCompliant
      },
      error_rate: {
        actual: errorRate.toFixed(3) + '%',
        target: slaTargets.error_rate_percentage + '%',
        compliant: errorRateCompliant
      }
    },
    summary: overallCompliant ? '✅ SLA Met' : '❌ SLA Violation'
  }
};

// 7. Google Sheets Node - Log to SLA tracking sheet
Operation: Append
Spreadsheet: SLA Compliance Reports
Sheet: Daily Metrics
Data: {{ $json }}

// 8. IF Node - Check compliance
Condition: {{ $json.compliant }} === false

// 9a. Email (if violated) - Alert stakeholders
To: management@yourdomain.com, sre@yourdomain.com
Subject: ⚠️ SLA Violation - {{ $json.date }}
Body: |
  SLA Violation Detected
  
  Date: {{ $json.date }}
  
  Metrics:
  • Uptime: {{ $json.metrics.uptime.actual }} (Target: {{ $json.metrics.uptime.target }}) {{ $json.metrics.uptime.compliant ? '✅' : '❌' }}
  • Response Time: {{ $json.metrics.response_time.actual }} (Target: {{ $json.metrics.response_time.target }}) {{ $json.metrics.response_time.compliant ? '✅' : '❌' }}
  • Error Rate: {{ $json.metrics.error_rate.actual }} (Target: {{ $json.metrics.error_rate.target }}) {{ $json.metrics.error_rate.compliant ? '✅' : '❌' }}
  
  Please review the metrics in Prometheus and Grafana.

// 9b. Slack (if compliant) - Post success
Channel: #sre
Message: |
  ✅ *SLA Compliance - {{ $json.date }}*
  
  All targets met!
  • Uptime: {{ $json.metrics.uptime.actual }}
  • Response Time: {{ $json.metrics.response_time.actual }}
  • Error Rate: {{ $json.metrics.error_rate.actual }}
```

### PromQL Tips for n8n Workflows

**Common Queries for Automation:**

```promql
# Is a service up?
up{job="my-service"}

# Request rate (last 5 minutes)
rate(http_requests_total[5m])

# CPU usage across all instances
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Available memory in GB
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024

# Container restart count
changes(container_last_seen[1h])

# Active alerts (use in workflows to check alert state)
ALERTS{alertstate="firing"}

# Error rate (percentage)
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# P95 response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Instances with high disk usage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100 > 80
```

### Best Practices

1. **Scrape Intervals** - Keep scrape intervals reasonable (10-60s). Shorter intervals increase load and storage
2. **Label Cardinality** - Avoid high-cardinality labels (e.g., user IDs, timestamps) as they explode storage and memory
3. **Retention Policy** - Set appropriate retention (default 15 days). Use remote storage for long-term metrics
4. **Alert Fatigue** - Use `for` duration in alerts to avoid transient noise (e.g., `for: 5m`)
5. **Recording Rules** - Pre-compute expensive queries as recording rules for dashboard performance
6. **Service Discovery** - Use service discovery instead of static configs for dynamic environments
7. **Exporters** - Use official exporters (node_exporter, blackbox_exporter) for standard metrics
8. **Alertmanager Grouping** - Group related alerts to avoid notification storms
9. **Internal Access** - Keep Prometheus internal-only; expose via Grafana for users
10. **n8n Metrics** - Enable n8n metrics (`N8N_METRICS=true`) to monitor workflow performance

### Troubleshooting

#### Prometheus Container Won't Start

```bash
# Check logs
docker logs prometheus --tail 100

# Common issue: Invalid config syntax
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Fix permissions on data directory
docker exec -u root prometheus chown -R nobody:nobody /prometheus

# Restart container
docker restart prometheus
```

#### Targets Showing as DOWN

```bash
# Check target status in Prometheus UI
# Go to: http://prometheus:9090/targets

# Test connectivity from Prometheus container
docker exec prometheus wget -O- http://node-exporter:9100/metrics
docker exec prometheus wget -O- http://cadvisor:8080/metrics

# Common issues:
# 1. Target not in same Docker network
docker network inspect ai-corekit_default

# 2. Target port not exposed internally
docker ps | grep node-exporter

# 3. Wrong job configuration in prometheus.yml
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

#### High Memory Usage

```bash
# Check Prometheus memory usage
docker stats prometheus

# Reduce retention time in docker-compose.yml:
command:
  - '--storage.tsdb.retention.time=7d'  # Reduce from 15d

# Reduce scrape frequency for non-critical targets
# In prometheus.yml, set longer scrape_interval

# Identify high-cardinality metrics
# In Prometheus UI, query:
topk(10, count by (__name__)({__name__=~".+"}))

# Consider using recording rules for expensive queries
```

#### Alerts Not Reaching n8n

```bash
# 1. Test Alertmanager is receiving alerts
docker exec prometheus curl http://alertmanager:9093/api/v2/alerts

# 2. Check Alertmanager routing
docker exec alertmanager cat /etc/alertmanager/alertmanager.yml

# 3. Test webhook manually
docker exec alertmanager curl -X POST http://n8n:5678/webhook/prometheus-alerts \
  -H "Content-Type: application/json" \
  -d '{"status":"firing","alerts":[{"labels":{"alertname":"test"}}]}'

# 4. Check Alertmanager logs
docker logs alertmanager --tail 50

# 5. Verify n8n webhook is active
# In n8n UI: Check workflow is active and webhook is listening
```

#### PromQL Query Returns No Data

```bash
# 1. Check if metric exists
# In Prometheus UI: http://prometheus:9090/graph
# Type metric name and autocomplete should show it

# 2. Check label matchers
# Verify labels exist:
up{job="nonexistent"}  # Returns nothing
up{job="prometheus"}   # Should return data

# 3. Check time range
# Data may be outside retention period

# 4. Verify target is being scraped
# Status → Targets → Check "Last Scrape" timestamp

# 5. Check for typos in metric names
# Use Prometheus autocomplete feature
```

#### n8n HTTP Request to Prometheus Fails

```bash
# 1. Verify internal URL is correct
# From n8n, should use: http://prometheus:9090
# NOT: https://prometheus.yourdomain.com

# 2. Test connectivity from n8n container
docker exec n8n curl http://prometheus:9090/api/v1/query?query=up

# 3. Check if services are on same network
docker network inspect ai-corekit_default | grep -E "n8n|prometheus"

# 4. Verify PromQL syntax
# Test query in Prometheus UI first before using in n8n

# 5. Check n8n HTTP Request node response format
# Set "Response Format" to "JSON" for API endpoints
```

### Resources

- **Documentation:** [https://prometheus.io/docs/](https://prometheus.io/docs/)
- **Getting Started:** [https://prometheus.io/docs/prometheus/latest/getting_started/](https://prometheus.io/docs/prometheus/latest/getting_started/)
- **PromQL Guide:** [https://prometheus.io/docs/prometheus/latest/querying/basics/](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- **Alerting Rules:** [https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- **Exporters List:** [https://prometheus.io/docs/instrumenting/exporters/](https://prometheus.io/docs/instrumenting/exporters/)
- **Alertmanager Config:** [https://prometheus.io/docs/alerting/latest/configuration/](https://prometheus.io/docs/alerting/latest/configuration/)
- **Best Practices:** [https://prometheus.io/docs/practices/naming/](https://prometheus.io/docs/practices/naming/)
- **GitHub:** [https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)
- **Community Forum:** [https://prometheus.io/community/](https://prometheus.io/community/)
- **n8n + Prometheus Integration:** [https://medium.com/@b0ld8/automated-incident-response-workflows-with-n8n-and-prometheus-0fbffdabc92f](https://medium.com/@b0ld8/automated-incident-response-workflows-with-n8n-and-prometheus-0fbffdabc92f)
