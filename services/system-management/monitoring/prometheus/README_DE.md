# 📈 Prometheus - Zeitreihen-Metriken & Monitoring-System

### Was ist Prometheus?

Prometheus ist ein Open-Source-System zur Überwachung und Alarmierung, das Metriken als Zeitreihendaten sammelt und speichert. Ursprünglich bei SoundCloud entwickelt, ist es jetzt ein graduiertes CNCF-Projekt und der De-facto-Standard für Cloud-natives Monitoring. Prometheus verwendet ein Pull-basiertes Modell, um Metriken von Zielen in regelmäßigen Intervallen zu sammeln, speichert sie effizient und bietet eine leistungsstarke Abfragesprache (PromQL) für die Analyse.

### Features

- **Pull-basierte Metriken-Sammlung** - Scraped HTTP-Endpoints in konfigurierten Intervallen, anstatt dass Anwendungen Daten pushen müssen
- **Leistungsstarke Abfragesprache (PromQL)** - Flexible Abfragen zum Filtern, Aggregieren und Analysieren von Zeitreihendaten in Echtzeit
- **Multidimensionales Datenmodell** - Metriken identifiziert durch Namen und Schlüssel-Wert-Labels für flexible Abfragen und Aggregation
- **Service Discovery** - Entdeckt automatisch Ziele über Kubernetes, Consul, DNS, dateibasierte Configs und mehr
- **Eingebaute Alarmierung** - Definiere Alarm-Regeln in PromQL, die bei erfüllten Bedingungen auslösen, integriert mit Alertmanager
- **Lokaler Speicher & optionales Remote Write** - Effizienter Disk-Speicher mit optionaler Integration zu Remote-Systemen wie Grafana Mimir

### Erste Einrichtung

**Auf Prometheus Web UI zugreifen:**

1. Navigiere zu `http://prometheus.deinedomain.com` (falls extern exponiert)
   - Oder intern: `http://prometheus:9090`
2. Keine Authentifizierung standardmäßig erforderlich (interner Service)
3. Erkunde die Oberfläche:
   - **Graph** - Führe PromQL-Abfragen aus und visualisiere Ergebnisse
   - **Alerts** - Zeige aktive Alarme und deren Status an
   - **Status** → **Targets** - Siehe alle Scrape-Ziele und deren Gesundheitsstatus
   - **Status** → **Configuration** - Zeige aktuelle Prometheus-Konfiguration an

**Prüfen ob Prometheus Metriken scraped:**

1. Gehe zu **Status** → **Targets**
2. Prüfe dass Ziele als **UP** (grün) angezeigt werden
3. Häufige Ziele im AI CoreKit:
   - `prometheus` - Prometheus selbst
   - `node-exporter` - System-Metriken (falls installiert)
   - `cadvisor` - Container-Metriken (falls installiert)
   - `n8n` - n8n-Metriken (falls aktiviert mit `N8N_METRICS=true`)

**Deine erste PromQL-Abfrage ausführen:**

1. Gehe zum **Graph**-Tab
2. Probiere diese Beispiel-Abfragen:
   ```promql
   # Aktuelle CPU-Auslastung
   100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
   # Speicher-Auslastung in Prozent
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   
   # HTTP-Request-Rate
   rate(http_requests_total[5m])
   
   # n8n-Workflow-Ausführungen (falls N8N_METRICS aktiviert)
   sum(n8n_workflow_executions_total)
   ```
3. Klicke **Execute** und zeige Ergebnisse in Tabellen- oder Graphen-Format an

**Alertmanager konfigurieren (Optional aber empfohlen):**

Alertmanager verarbeitet Alarme, die von Prometheus gesendet werden, einschließlich Deduplizierung, Gruppierung und Routing zu Empfängern wie E-Mail, Slack, PagerDuty oder n8n-Webhooks.

1. Bearbeite `prometheus.yml` um Alarm-Regeln hinzuzufügen:
   ```yaml
   rule_files:
     - /etc/prometheus/alert.rules.yml
   
   alerting:
     alertmanagers:
       - static_configs:
           - targets:
               - alertmanager:9093
   ```

2. Erstelle `/etc/prometheus/alert.rules.yml`:
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
             summary: "Hohe CPU-Auslastung erkannt auf {{ $labels.instance }}"
             description: "CPU-Auslastung ist {{ $value }}%"
   ```

3. Prometheus-Konfiguration neu laden:
   ```bash
   docker exec prometheus kill -HUP 1
   # Oder Container neu starten
   docker restart prometheus
   ```

### n8n Integrations-Setup

**Interne URL für n8n:** `http://prometheus:9090`

Prometheus hat keine traditionellen "Credentials" - es wird typischerweise intern ohne Authentifizierung aufgerufen. Integration mit n8n erfolgt über:
1. **HTTP Request Node** - Frage Prometheus-API für Metriken ab
2. **Webhook Trigger** - Empfange Alarme von Alertmanager

#### Methode 1: Prometheus-API von n8n aus abfragen

**HTTP Request Node Konfiguration:**

```javascript
// Keine Credentials für internen Zugriff benötigt
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: up{job="prometheus"}  // Deine PromQL-Abfrage
  time: {{ $now.toUnixInteger() }}  // Optional: spezifischer Zeitstempel

// Alternative: Range-Query für Zeitreihendaten
Methode: GET
URL: http://prometheus:9090/api/v1/query_range
Query Parameter:
  query: rate(http_requests_total[5m])
  start: {{ $now.minus(1, 'hour').toUnixInteger() }}
  end: {{ $now.toUnixInteger() }}
  step: 60  // Auflösung in Sekunden
```

**Antwort-Struktur:**
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

#### Methode 2: Alarme über Alertmanager-Webhook empfangen

**Alertmanager konfigurieren um an n8n zu senden:**

1. **In n8n - Webhook Trigger erstellen:**
   - Webhook-Node zu neuem Workflow hinzufügen
   - HTTP-Methode auf `POST` setzen
   - Webhook-URL kopieren: `https://n8n.deinedomain.com/webhook/prometheus-alerts`

2. **In Alertmanager - `/etc/alertmanager/alertmanager.yml` bearbeiten:**
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

3. **Alertmanager neu laden:**
   ```bash
   docker exec alertmanager kill -HUP 1
   ```

**Webhook-Payload-Struktur:**
```json
{
  "receiver": "n8n-webhook",
  "status": "firing",  // oder "resolved"
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighCPUUsage",
        "instance": "server-01",
        "severity": "warning"
      },
      "annotations": {
        "summary": "Hohe CPU-Auslastung erkannt",
        "description": "CPU-Auslastung ist 85%"
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

### Beispiel-Workflows

#### Beispiel 1: Automatisiertes Incident-Response-System

Empfange Prometheus-Alarme über Alertmanager und automatische Problembehebung oder Eskalation:

```javascript
// n8n Workflow: Intelligent Alert Handler

// 1. Webhook Trigger - Receive alert from Alertmanager
// Webhook URL: /webhook/prometheus-alerts
// HTTP Methode: POST

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
    slackNachricht: {
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
Kanal: #monitoring
Nachricht: {{ $json.slackMessage }}

// 4b. Critical Alert - Immediate escalation
// Code Node - Prepare critical notification
const alert = $input.first().json;
const oncallTeam = alert.isBusinessHours ? '@devops-team' : '@oncall-sre';

return {
  json: {
    subject: `🚨 CRITICAL: ${alert.alertName}`,
    message: `Critical alert requires immediate attention!\n\nAlert: ${alert.alertName}\nInstance: ${alert.instance}\nDescription: ${alert.description}\nDuration: ${alert.duration} minutes\n\nDashboard: ${alert.dashboardUrl}`,
    slackNachricht: {
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
Kanal: #incidents
Nachricht: {{ $json.slackMessage }}

// HTTP Request Node - Trigger PagerDuty
Methode: POST
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
Bedingung: {{ $json.shouldExecute }} === true

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
Betrag: 2
Unit: minutes

// HTTP Request Node - Check if alert still firing
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
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
Bedingung: {{ $json.remediationSucceeded }} === false
// If failed, route to critical alert path (4b)

// Slack Node - Notify remediation result
Kanal: #monitoring
Nachricht: {{ $json.message }}

// 4d. Warning Alert - Standard notification
// Slack Node
Kanal: #alerts
Nachricht: |
  ⚠️ *Warning Alert*
  
  *Alert:* {{ $('Code Node').first().json.alertName }}
  *Instance:* {{ $('Code Node').first().json.instance }}
  *Description:* {{ $('Code Node').first().json.description }}
  *Duration:* {{ $('Code Node').first().json.duration }} minutes
  
  <{{ $('Code Node').first().json.dashboardUrl }}|View Dashboard>

// 5. PostgreSQL Node - Log all alerts to database
Operation: Einfügen
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

#### Beispiel 2: Proaktive System-Gesundheitsüberwachung

Frage Prometheus-Metriken nach Zeitplan ab, um Probleme zu erkennen, bevor sie kritisch werden:

```javascript
// n8n Workflow: Proactive Health Checks

// 1. Schedule Trigger - Every 5 minutes

// 2. HTTP Request Node - Query CPU usage
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

// 3. HTTP Request Node - Query memory usage
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

// 4. HTTP Request Node - Query disk usage
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: (node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100

// 5. HTTP Request Node - Query container health
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
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
Bedingung: {{ $json.overall_health }} === 'degraded'

// 8a. Slack Node (if issues) - Send warning
Kanal: #monitoring
Nachricht: |
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
Operation: Einfügen
Table: system_health_snapshots
Daten: {{ $json }}
```

#### Beispiel 3: Benutzerdefinierte Metriken-Sammlung aus n8n-Workflows

Pushe benutzerdefinierte Metriken zu Prometheus aus deinen n8n-Workflows:

```javascript
// n8n Workflow: Business Metrics to Prometheus

// Enable Prometheus Pushgateway in docker-compose.yml first!

// 1. Schedule Trigger or Webhook - Dein business process

// 2. Code Node - Calculate business metrics
// Beispiel: Calculate daily order metrics

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
Methode: POST
URL: http://pushgateway:9091/metrics/job/n8n_business_metrics/instance/workflow_{{ $workflow.id }}
Header:
  Content-Type: text/plain
Body (Raw): {{ $json.metrics }}

// 5. Slack Node - Confirm metrics pushed
Kanal: #metrics
Nachricht: |
  📊 Business metrics updated in Prometheus
  
  • Total Orders: {{ $('Code Node').first().json.total_orders }}
  • Total Revenue: ${{ $('Code Node').first().json.total_revenue.toFixed(2) }}
  • Avg Order Wert: ${{ $('Code Node').first().json.avg_order_value.toFixed(2) }}
```

#### Beispiel 4: SLA-Überwachung & Reporting

Überwache Service-Level-Agreements und erstelle Compliance-Reports:

```javascript
// n8n Workflow: SLA Compliance Monitoring

// 1. Schedule Trigger - Daily at 8 AM

// 2. Set Variable - Define SLA thresholds
Name: sla_targets
Wert:
{
  "uptime_percentage": 99.9,
  "response_time_ms": 200,
  "error_rate_percentage": 0.1
}

// 3. HTTP Request - Query uptime (last 24h)
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: avg_over_time(up{job="production"}[24h]) * 100

// 4. HTTP Request - Query response time (p95)
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
  query: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[24h])) * 1000

// 5. HTTP Request - Query error rate
Methode: GET
URL: http://prometheus:9090/api/v1/query
Query Parameter:
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
Daten: {{ $json }}

// 8. IF Node - Check compliance
Bedingung: {{ $json.compliant }} === false

// 9a. Email (if violated) - Alert stakeholders
To: management@yourdomain.com, sre@yourdomain.com
Subject: ⚠️ SLA Violation - {{ $json.date }}
Body: |
  SLA Violation Detected
  
  Datum: {{ $json.date }}
  
  Metrics:
  • Uptime: {{ $json.metrics.uptime.actual }} (Target: {{ $json.metrics.uptime.target }}) {{ $json.metrics.uptime.compliant ? '✅' : '❌' }}
  • Response Time: {{ $json.metrics.response_time.actual }} (Target: {{ $json.metrics.response_time.target }}) {{ $json.metrics.response_time.compliant ? '✅' : '❌' }}
  • Error Rate: {{ $json.metrics.error_rate.actual }} (Target: {{ $json.metrics.error_rate.target }}) {{ $json.metrics.error_rate.compliant ? '✅' : '❌' }}
  
  Please review the metrics in Prometheus and Grafana.

// 9b. Slack (if compliant) - Post success
Kanal: #sre
Nachricht: |
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

1. **Scrape-Intervalle** - Halte Scrape-Intervalle angemessen (10-60s). Kürzere Intervalle erhöhen Last und Speicher
2. **Label-Kardinalität** - Vermeide hochkardinalische Labels (z.B. User-IDs, Zeitstempel), da sie Speicher und RAM sprengen
3. **Retention-Policy** - Setze angemessene Retention (Standard 15 Tage). Nutze Remote-Storage für langfristige Metriken
4. **Alarm-Fatigue** - Verwende `for` Dauer in Alarmen um transientes Rauschen zu vermeiden (z.B. `for: 5m`)
5. **Recording Rules** - Berechne teure Abfragen vorab als Recording Rules für Dashboard-Performance
6. **Service Discovery** - Nutze Service Discovery statt statischer Configs für dynamische Umgebungen
7. **Exporters** - Verwende offizielle Exporters (node_exporter, blackbox_exporter) für Standard-Metriken
8. **Alertmanager-Gruppierung** - Gruppiere verwandte Alarme um Benachrichtigungs-Stürme zu vermeiden
9. **Interner Zugriff** - Halte Prometheus nur intern; exponiere über Grafana für Benutzer
10. **n8n-Metriken** - Aktiviere n8n-Metriken (`N8N_METRICS=true`) um Workflow-Performance zu überwachen

### Fehlerbehebung

#### Prometheus-Container startet nicht

```bash
# Logs prüfen
docker logs prometheus --tail 100

# Häufiges Problem: Ungültige Config-Syntax
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Berechtigungen auf Data-Verzeichnis korrigieren
docker exec -u root prometheus chown -R nobody:nobody /prometheus

# Container neu starten
docker restart prometheus
```

#### Targets werden als DOWN angezeigt

```bash
# Target-Status in Prometheus UI prüfen
# Gehe zu: http://prometheus:9090/targets

# Konnektivität vom Prometheus-Container testen
docker exec prometheus wget -O- http://node-exporter:9100/metrics
docker exec prometheus wget -O- http://cadvisor:8080/metrics

# Häufige Probleme:
# 1. Target nicht im selben Docker-Netzwerk
docker network inspect ai-corekit_default

# 2. Target-Port nicht intern exponiert
docker ps | grep node-exporter

# 3. Falsche Job-Konfiguration in prometheus.yml
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

#### Hohe Speicherauslastung

```bash
# Prometheus-Speichernutzung prüfen
docker stats prometheus

# Retention-Zeit in docker-compose.yml reduzieren:
command:
  - '--storage.tsdb.retention.time=7d'  # Von 15d reduzieren

# Scrape-Frequenz für nicht-kritische Targets reduzieren
# In prometheus.yml, längeres scrape_interval setzen

# Hochkardinalische Metriken identifizieren
# In Prometheus UI, query:
topk(10, count by (__name__)({__name__=~".+"}))

# Erwäge Recording Rules für teure Abfragen
```

#### Alarme erreichen n8n nicht

```bash
# 1. Testen ob Alertmanager Alarme empfängt
docker exec prometheus curl http://alertmanager:9093/api/v2/alerts

# 2. Alertmanager-Routing prüfen
docker exec alertmanager cat /etc/alertmanager/alertmanager.yml

# 3. Webhook manuell testen
docker exec alertmanager curl -X POST http://n8n:5678/webhook/prometheus-alerts \
  -H "Content-Type: application/json" \
  -d '{"status":"firing","alerts":[{"labels":{"alertname":"test"}}]}'

# 4. Alertmanager-Logs prüfen
docker logs alertmanager --tail 50

# 5. n8n-Webhook als aktiv verifizieren
# In n8n UI: Prüfen dass Workflow aktiv ist und Webhook lauscht
```

#### PromQL-Abfrage gibt keine Daten zurück

```bash
# 1. Prüfen ob Metrik existiert
# In Prometheus UI: http://prometheus:9090/graph
# Metrik-Namen eingeben und Autocomplete sollte sie anzeigen

# 2. Label-Matcher prüfen
# Labels-Existenz verifizieren:
up{job="nonexistent"}  # Gibt nichts zurück
up{job="prometheus"}   # Sollte Daten zurückgeben

# 3. Zeitbereich prüfen
# Daten könnten außerhalb der Retention-Periode sein

# 4. Prüfen ob Target gescraped wird
# Status → Targets → "Last Scrape" Zeitstempel prüfen

# 5. Auf Tippfehler in Metrik-Namen prüfen
# Prometheus-Autocomplete-Feature verwenden
```

#### n8n HTTP Request zu Prometheus schlägt fehl

```bash
# 1. Interne URL auf Korrektheit prüfen
# Von n8n aus sollte verwendet werden: http://prometheus:9090
# NICHT: https://prometheus.deinedomain.com

# 2. Konnektivität vom n8n-Container testen
docker exec n8n curl http://prometheus:9090/api/v1/query?query=up

# 3. Prüfen ob Services im selben Netzwerk sind
docker network inspect ai-corekit_default | grep -E "n8n|prometheus"

# 4. PromQL-Syntax verifizieren
# Query zuerst in Prometheus UI testen bevor in n8n verwendet

# 5. n8n HTTP Request Node Response-Format prüfen
# "Response Format" auf "JSON" für API-Endpoints setzen
```

### Ressourcen

- **Dokumentation:** [https://prometheus.io/docs/](https://prometheus.io/docs/)
- **Getting Started:** [https://prometheus.io/docs/prometheus/latest/getting_started/](https://prometheus.io/docs/prometheus/latest/getting_started/)
- **PromQL-Leitfaden:** [https://prometheus.io/docs/prometheus/latest/querying/basics/](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- **Alarm-Regeln:** [https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- **Exporters-Liste:** [https://prometheus.io/docs/instrumenting/exporters/](https://prometheus.io/docs/instrumenting/exporters/)
- **Alertmanager-Config:** [https://prometheus.io/docs/alerting/latest/configuration/](https://prometheus.io/docs/alerting/latest/configuration/)
- **Best Practices:** [https://prometheus.io/docs/practices/naming/](https://prometheus.io/docs/practices/naming/)
- **GitHub:** [https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)
- **Community-Forum:** [https://prometheus.io/community/](https://prometheus.io/community/)
- **n8n + Prometheus Integration:** [https://medium.com/@b0ld8/automated-incident-response-workflows-with-n8n-and-prometheus-0fbffdabc92f](https://medium.com/@b0ld8/automated-incident-response-workflows-with-n8n-and-prometheus-0fbffdabc92f)
