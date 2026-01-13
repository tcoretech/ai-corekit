# 📊 Grafana - Metriken-Visualisierung & Monitoring-Plattform

### Was ist Grafana?

Grafana ist eine Open-Source-Analyse- und Visualisierungsplattform, mit der du Metriken abfragen, visualisieren, Alarme setzen und verstehen kannst, unabhängig davon, wo sie gespeichert sind. Sie verwandelt komplexe Daten aus mehreren Quellen in schöne, interaktive Dashboards, die das Monitoring einfach und effizient machen.

### Features

- **Multi-Source-Dashboards** - Kombiniere Daten von Prometheus, PostgreSQL, InfluxDB und über 60 weiteren Datenquellen in einer einzigen Ansicht
- **Echtzeit-Visualisierung** - Zeitreihen, Graphen, Heatmaps, Histogramme und über 30 Visualisierungstypen mit Live-Daten-Updates
- **Alarme & Benachrichtigungen** - Definiere Alarm-Regeln mit Schwellenwerten und lasse dich per E-Mail, Slack, PagerDuty, Webhooks und mehr benachrichtigen
- **Template-Variablen** - Erstelle dynamische, wiederverwendbare Dashboards mit Dropdown-Filtern für verschiedene Umgebungen, Server oder Metriken
- **Plugin-Ökosystem** - Erweitere Funktionalität mit über 150 Community- und offiziellen Plugins für Datenquellen, Panels und Apps
- **Team-Zusammenarbeit** - Teile Dashboards, richte rollenbasierte Zugriffskontrolle (RBAC) ein, organisiere mit Ordnern und Playlists

### Erste Einrichtung

**Erster Login in Grafana:**

1. Navigiere zu `https://grafana.deinedomain.com`
2. Melde dich mit Standard-Anmeldedaten an (aus Installations-Report):
   ```
   Benutzername: admin
   Passwort: [Prüfe deinen Installations-Report oder .env-Datei: GRAFANA_ADMIN_PASSWORD]
   ```
3. **Standard-Passwort ändern** - Du wirst sofort dazu aufgefordert
4. Überspringe die "Willkommens"-Tour oder durchlaufe sie, um die Grundlagen zu lernen

**Erste Datenquelle verbinden (Prometheus):**

1. Gehe zu **Configuration** (⚙️ Zahnrad-Symbol) → **Data Sources**
2. Klicke **Add data source**
3. Wähle **Prometheus**
4. Konfiguriere:
   ```
   Name: Prometheus
   URL: http://prometheus:9090
   Access: Server (Standard)
   ```
5. Klicke **Save & Test** - sollte "Data source is working" anzeigen

**Vorgefertigtes Dashboard importieren:**

1. Gehe zu **Dashboards** → **Import**
2. Gib Dashboard-ID von [Grafana.com](https://grafana.com/grafana/dashboards/) ein:
   - `1860` - Node Exporter Full (System-Metriken)
   - `3662` - Prometheus 2.0 Overview
   - `12708` - Docker and system monitoring
3. Wähle **Prometheus** als Datenquelle
4. Klicke **Import**
5. Dein Dashboard ist bereit mit Live-Metriken!

### n8n Integrations-Setup

**Interne URL für n8n:** `http://grafana:3000`

**Authentifizierungs-Optionen:**

n8n kann mit Grafana über zwei Methoden interagieren:

**Methode 1: API Token (Empfohlen)**

1. Gehe in Grafana zu **Configuration** → **API Keys**
2. Klicke **Add API key**:
   ```
   Key name: n8n-integration
   Rolle: Bearbeiteor (oder Viewer für nur-lesen)
   Time to live: Never expire (oder setze Ablaufdatum)
   ```
3. Klicke **Add** und **kopiere den API-Key** sofort (wird nur einmal angezeigt!)
4. Speichere in n8n-Credentials oder `.env`-Datei

**Methode 2: Service Account Token (Grafana 9+)**

1. Gehe zu **Administration** → **Service accounts**
2. Klicke **Add service account**:
   ```
   Display name: n8n-automation
   Rolle: Bearbeiteor
   ```
3. Klicke **Add**, dann **Add service account token**
4. Kopiere den Token und speichere ihn sicher

**HTTP Request Credentials in n8n erstellen:**

1. Gehe in n8n zu **Credentials** → **Create New**
2. Suche nach **Header Auth**
3. Konfiguriere:
   ```
   Name: Grafana API
   Header Name: Authorization
   Header Wert: Bearer DEIN_API_TOKEN_HIER
   ```
4. Teste und speichere

### Beispiel-Workflows

#### Beispiel 1: Alarm bei hohen Fehlerraten

Überwache Anwendungsfehler und benachrichtige Team, wenn Schwellenwerte überschritten werden:

```javascript
// n8n Workflow: Grafana-Alarm zu Slack

// 1. Schedule Trigger - Alle 5 Minuten

// 2. HTTP Request Node - Grafana API für Panel-Daten abfragen
Methode: GET
URL: http://grafana:3000/api/datasources/proxy/1/api/v1/query
Authentication: Grafana API Credentials verwenden
Query Parameter:
  query: sum(rate(http_errors_total[5m]))

// 3. Code Node - Schwellenwert auswerten
const errorRate = $input.first().json.data.result[0]?.value[1];
const threshold = 100; // Fehler pro Sekunde

if (parseFloat(errorRate) > threshold) {
  return {
    json: {
      alert: true,
      errorRate: errorRate,
      message: `⚠️ Hohe Fehlerrate erkannt: ${errorRate} Fehler/Sek (Schwellenwert: ${threshold})`
    }
  };
} else {
  return {
    json: {
      alert: false,
      errorRate: errorRate,
      message: `✅ Fehlerrate normal: ${errorRate} Fehler/Sek`
    }
  };
}

// 4. IF Node - Prüfen ob Alarm-Bedingung erfüllt
Expression: {{ $json.alert }} === true

// 5a. Slack Node (wenn true) - Alarm senden
Kanal: #alerts
Nachricht: {{ $json.message }}

// 5b. Do Nothing (wenn false)

// 6. HTTP Request Node - Annotation in Grafana erstellen
Methode: POST
URL: http://grafana:3000/api/annotations
Authentication: Grafana API Credentials verwenden
Body (JSON):
{
  "dashboardId": 1,
  "time": {{ $now.toUnixInteger() * 1000 }},
  "tags": ["alert", "automated"],
  "text": "{{ $json.message }}"
}
```

#### Beispiel 2: Automatischer Dashboard-Snapshot & Report

Erstelle wöchentliche Dashboard-Snapshots und versende sie per E-Mail an Stakeholder:

```javascript
// n8n Workflow: Wöchentlicher Grafana-Report

// 1. Schedule Trigger - Jeden Montag um 9 Uhr

// 2. HTTP Request Node - Dashboard-Snapshot erstellen
Methode: POST
URL: http://grafana:3000/api/snapshots
Authentication: Grafana API Credentials verwenden
Body (JSON):
{
  "dashboard": {
    "getDashboardId": 1  // Deine Haupt-Dashboard-ID
  },
  "name": "Wöchentlicher Report - {{ $now.format('YYYY-MM-DD') }}",
  "expires": 604800  // 7 Tage in Sekunden
}

// Snapshot-URL speichern
// Antwort enthält: {"url": "https://grafana.deinedomain.com/dashboard/snapshot/..."}

// 3. HTTP Request Node - Dashboard als Bild rendern
Methode: GET
URL: http://grafana:3000/render/d-solo/DASHBOARD_UID/dashboard-name
Authentication: Grafana API Credentials verwenden
Query Parameter:
  orgId: 1
  from: now-7d
  to: now
  panelId: 2
  width: 1000
  height: 500
  theme: light
Options:
  Response Format: File

// 4. Code Node - E-Mail-Inhalt vorbereiten
const snapshotUrl = $('HTTP Request').json.url;
const dashboardUrl = 'https://grafana.deinedomain.com/d/DEINE_DASHBOARD_UID';

return {
  json: {
    subject: `📊 Wöchentlicher Dashboard-Report - ${new Date().toLocaleDateString('de-DE')}`,
    body: `
      <h2>Wöchentlicher Dashboard-Snapshot</h2>
      <p>Hier ist dein automatisierter wöchentlicher Report von Grafana:</p>
      <p><strong>Berichtszeitraum:</strong> Letzte 7 Tage</p>
      <p><strong>Live-Dashboard:</strong> <a href="${dashboardUrl}">In Grafana ansehen</a></p>
      <p><strong>Snapshot-Link:</strong> <a href="${snapshotUrl}">Snapshot ansehen (läuft in 7 Tagen ab)</a></p>
      <h3>Übersicht wichtiger Metriken:</h3>
      <p>Siehe angehängtes Dashboard-Bild für vollständige Details.</p>
    `
  }
};

// 5. Send Email Node
To: team@deinedomain.com, executives@deinedomain.com
Subject: {{ $json.subject }}
Body (HTML): {{ $json.body }}
Anhänge: Datei von HTTP Request (Schritt 3) verwenden

// 6. Slack Node - Benachrichtigung posten
Kanal: #reports
Nachricht: |
  📊 *Wöchentlicher Grafana-Report veröffentlicht*
  
  📅 Report-Datum: {{ $now.format('D. MMMM YYYY', 'de') }}
  🔗 Dashboard: {{ dashboardUrl }}
  📸 Snapshot: {{ snapshotUrl }}
  
  Vollständiger Report per E-Mail versendet.
```

#### Beispiel 3: Dynamische Dashboard-Erstellung aus Workflow-Daten

Erstelle automatisch Grafana-Dashboards aus n8n-Workflow-Ausführungs-Metriken:

```javascript
// n8n Workflow: Benutzerdefiniertes Workflow-Performance-Dashboard erstellen

// 1. Webhook Trigger - Workflow-Abschluss-Event empfangen

// 2. Code Node - Letzte 30 Tage Workflow-Daten aggregieren
// Frage deine n8n-Datenbank ab oder nutze n8n API für Ausführungs-Statistiken

const workflowMetrics = {
  workflow_id: $json.workflowId,
  workflow_name: $json.workflowName,
  total_executions: 1250,
  success_rate: 94.5,
  avg_duration: 2.3,
  error_count: 69
};

// Dashboard-JSON definieren
const dashboard = {
  "dashboard": {
    "title": `Workflow-Performance: ${workflowMetrics.workflow_name}`,
    "tags": ["workflow", "automation", "performance"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Ausführungsanzahl (Letzte 30 Tage)",
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
        "title": "Erfolgsrate",
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
        "title": "Durchschnittliche Dauer",
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

// 3. HTTP Request Node - Dashboard in Grafana erstellen
Methode: POST
URL: http://grafana:3000/api/dashboards/db
Authentication: Grafana API Credentials verwenden
Body (JSON): {{ $json }}

// 4. Code Node - Dashboard-URL extrahieren
const response = $input.first().json;
const dashboardUrl = `https://grafana.deinedomain.com${response.url}`;

return {
  json: {
    dashboardUrl: dashboardUrl,
    dashboardId: response.id,
    message: `Dashboard erfolgreich erstellt für Workflow: ${workflowMetrics.workflow_name}`
  }
};

// 5. Slack Node - Team benachrichtigen
Kanal: #automation
Nachricht: |
  ✅ *Neues Grafana-Dashboard erstellt*
  
  📊 Workflow: {{ $('Code Node').first().json.workflow_name }}
  🔗 Dashboard: {{ $json.dashboardUrl }}
  
  Automatisches Performance-Tracking ist jetzt live!
```

#### Beispiel 4: Überwachen & Auto-Skalieren basierend auf Metriken

Frage Grafana-Metriken ab und löse Skalierungsaktionen aus:

```javascript
// n8n Workflow: Auto-Skalierung basierend auf CPU-Metriken

// 1. Schedule Trigger - Alle 2 Minuten

// 2. HTTP Request Node - Aktuelle CPU-Auslastung von Prometheus abfragen
Methode: GET
URL: http://grafana:3000/api/datasources/proxy/1/api/v1/query
Authentication: Grafana API Credentials verwenden
Query Parameter:
  query: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

// 3. Code Node - Skalierungs-Entscheidung evaluieren
const cpuData = $input.first().json.data.result;

// Durchschnittliche CPU über alle Instanzen berechnen
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

// 4. Switch Node - Routing basierend auf Aktion
// Mode: Expression
// Output: {{ $json.action }}

// 5a. HTTP Request (Scale Up) - Infrastruktur-API aufrufen
Methode: POST
URL: https://dein-cloud-provider.com/api/scale
Body: { "action": "scale_up", "instances": 1 }

// 5b. HTTP Request (Scale Down) - Infrastruktur-API aufrufen
Methode: POST
URL: https://dein-cloud-provider.com/api/scale
Body: { "action": "scale_down", "instances": 1 }

// 5c. Do Nothing

// 6. HTTP Request Node - Annotation in Grafana erstellen
Methode: POST
URL: http://grafana:3000/api/annotations
Authentication: Grafana API Credentials verwenden
Body (JSON):
{
  "dashboardId": 1,
  "time": {{ $now.toUnixInteger() * 1000 }},
  "tags": ["autoscaling", "{{ $json.action }}"],
  "text": "Auto-Skalierungs-Aktion: {{ $json.action }} (CPU: {{ $json.avgCpu }}%)"
}

// 7. Send Email (wenn skaliert)
IF Node: {{ $json.action }} !== 'none'
To: devops@deinedomain.com
Subject: Auto-Skalierungs-Event ausgelöst
Body: |
  CPU-Auslastung: {{ $json.avgCpu }}%
  Durchgeführte Aktion: {{ $json.action }}
  Instanz-Anzahl: {{ $json.instanceCount }}
```

### Alarme mit Grafana & n8n

**Grafana-Alarme einrichten, um n8n-Webhooks auszulösen:**

1. **In n8n - Webhook erstellen:**
   - Webhook-Node zu neuem Workflow hinzufügen
   - Auf `GET` oder `POST` setzen
   - Webhook-URL kopieren: `https://n8n.deinedomain.com/webhook/grafana-alert`

2. **In Grafana - Contact Point konfigurieren:**
   - Gehe zu **Alerting** → **Contact points**
   - Klicke **New contact point**
   - Wähle **Webhook** als Typ
   - n8n-Webhook-URL eingeben
   - Benutzerdefinierte Header hinzufügen falls benötigt (für Authentifizierung)

3. **Alarm-Regel erstellen:**
   - Gehe zu **Alerting** → **Alert rules**
   - Klicke **Create alert rule**
   - Datenquelle auswählen und PromQL-Query schreiben
   - Schwellenwert-Bedingungen definieren
   - Auswertungs-Intervall setzen
   - Deinen n8n Contact Point auswählen

4. **In n8n verarbeiten:**
   ```javascript
   // n8n Webhook empfängt Alarm-Payload
   const alert = $json;
   
   // Alarm-Payload-Struktur:
   {
     "state": "alerting",  // oder "ok"
     "evalMatches": [...],
     "message": "Alarm-Nachricht",
     "ruleId": 1,
     "ruleName": "Hohe CPU Alarm",
     "tags": {...}
   }
   
   // Aktion basierend auf Alarm-Status durchführen
   if (alert.state === 'alerting') {
     // An Slack senden, PagerDuty, Ticket erstellen, etc.
   }
   ```

### Erweiterte Grafana-Features für n8n-Integration

#### Variablen & Templating

Erstelle dynamische Dashboards, die n8n manipulieren kann:

```javascript
// HTTP Request - Dashboard-Variable aktualisieren
Methode: POST
URL: http://grafana:3000/api/dashboards/db
Body (JSON):
{
  "dashboard": {
    "title": "Dynamisches Dashboard",
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

Füge programmatisch Kontext zu deinen Dashboards hinzu:

```javascript
// Deployments, Vorfälle oder Events markieren
Methode: POST
URL: http://grafana:3000/api/annotations
Body (JSON):
{
  "dashboardId": 1,
  "panelId": 2,  // Optional: spezifisches Panel
  "time": {{ $now.toUnixInteger() * 1000 }},
  "timeEnd": {{ $now.plus(1, 'hour').toUnixInteger() * 1000 }},  // Optional: für Zeitraum
  "tags": ["deployment", "production", "v2.1.0"],
  "text": "Version 2.1.0 in Produktion deployed",
  "dashboardUID": "dashboard-uid"  // Alternative zu dashboardId
}
```

#### Playlist-Automatisierung

Kontrolliere Dashboard-Playlists für Anzeige-Bildschirme:

```javascript
// Playlist erstellen
Methode: POST
URL: http://grafana:3000/api/playlists
Body (JSON):
{
  "name": "Büro-Dashboard-Rotation",
  "interval": "30s",
  "items": [
    {"type": "dashboard_by_id", "value": "1"},
    {"type": "dashboard_by_id", "value": "2"},
    {"type": "dashboard_by_id", "value": "5"}
  ]
}

// Playlist starten
Methode: GET
URL: http://grafana:3000/api/playlists/1/start
```

### Best Practices

1. **Service Accounts verwenden** - Erstelle dedizierte Service-Accounts mit minimalen Berechtigungen für n8n-Integrationen
2. **Interne URLs** - Von n8n aus immer `http://grafana:3000` verwenden, niemals die externe Domain
3. **Queries cachen** - Speichere häufig abgefragte Daten in n8n-Variablen um API-Aufrufe zu reduzieren
4. **Fehlerbehandlung** - Grafana-API-Aufrufe immer in try-catch-Blöcke einpacken und Rate-Limits behandeln
5. **Dashboard as Code** - Exportiere Dashboard-JSON und versioniere es zusammen mit deinen Workflows
6. **Annotations für Audit** - Erstelle Grafana-Annotations wenn n8n-Workflows Infrastruktur-Änderungen vornehmen
7. **Alarm-Deduplizierung** - Implementiere Cooldown-Perioden in n8n um Alarm-Spam zu verhindern
8. **API-Keys sichern** - Rotiere API-Tokens regelmäßig und verwende kurzlebige Tokens wenn möglich
9. **Dashboards testen** - Erstelle Test-Dashboards in separaten Ordnern bevor du sie in Produktion bringst
10. **Grafana selbst überwachen** - Richte Self-Monitoring-Dashboards ein um Grafanas eigene Performance zu verfolgen

### Fehlerbehebung

#### Grafana-Container startet nicht

```bash
# Logs prüfen
docker logs grafana --tail 100

# Häufiges Problem: Berechtigungen auf Grafana-Data-Volume
docker exec grafana ls -la /var/lib/grafana
# Sollte User 472 gehören (grafana user)

# Berechtigungen korrigieren falls nötig
docker exec -u root grafana chown -R 472:472 /var/lib/grafana

# Container neu starten
docker restart grafana
```

#### Kann nicht zu Datenquellen verbinden

```bash
# Interne Konnektivität vom Grafana-Container testen
docker exec grafana curl -v http://prometheus:9090
docker exec grafana curl -v http://postgres:5432

# Falls Verbindung fehlschlägt, Docker-Netzwerk prüfen
docker network inspect ai-corekit_default

# Sicherstellen, dass Services im selben Netzwerk sind
docker inspect grafana | grep NetworkMode
docker inspect prometheus | grep NetworkMode
```

#### n8n kann sich nicht bei Grafana authentifizieren

```bash
# 1. API-Token Gültigkeit prüfen
curl -H "Authorization: Bearer DEIN_TOKEN" \
  http://grafana:3000/api/org

# Sollte Organisations-Info zurückgeben, nicht 401

# 2. Token-Berechtigungen prüfen
# In Grafana UI: Configuration → API Keys
# Sicherstellen dass Role Bearbeiteor oder Admin ist

# 3. Für Service Accounts (Grafana 9+)
# Administration → Service accounts → Token-Ablauf prüfen
```

#### Langsame Dashboard-Performance

```bash
# 1. Query-Performance in Grafana UI prüfen
# Panel öffnen → Query Inspector → Query-Ausführungszeit prüfen

# 2. Prometheus-Queries optimieren
# Recording Rules für häufig berechnete Metriken verwenden

# 3. Grafana-Ressourcen in docker-compose.yml erhöhen
environment:
  - GF_SERVER_ROOT_URL=https://grafana.deinedomain.com
  - GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/home.json
  - GF_DATABASE_MAX_OPEN_CONN=300  # Von Standard 0 erhöhen
  - GF_DATABASE_MAX_IDLE_CONN=100  # Von Standard 2 erhöhen

# 4. Query-Caching aktivieren
# Settings → Data Sources → Deine Datenquelle → Cache Settings
# Cache-Timeout setzen: 60s für sich häufig ändernde Daten
```

#### Alarme lösen keine n8n-Webhooks aus

```bash
# 1. Grafana-Alarm-Status prüfen
# Alerting → Alert rules → Regel-Status ansehen

# 2. Contact Point manuell testen
# Alerting → Contact points → Deinen Webhook auswählen → Test

# 3. n8n-Webhook-Logs prüfen
# In n8n: Workflow → Executions → Webhook-Trigger finden

# 4. Prüfen ob Webhook-URL von Grafana aus erreichbar ist
docker exec grafana curl -v https://n8n.deinedomain.com/webhook/test

# 5. Grafana-Logs auf Zustellungs-Fehler prüfen
docker logs grafana --tail 50 | grep -i "webhook\|alert"
```

#### Dashboard lässt sich nicht über API speichern

```bash
# Prüfen ob Dashboard-JSON gültig ist
# Mit curl testen:
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Authorization: Bearer DEIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {...}, "folderId": 0, "overwrite": true}' \
  --verbose

# Häufige Fehler:
# - Fehlende "dashboard" Wrapper-Objekt
# - Ungültige Panel-ID-Referenzen
# - Doppelte Dashboard-UID (setze "overwrite": true)
# - Unzureichende Token-Berechtigungen (verwende Bearbeiteor oder Admin Role)
```

### Ressourcen

- **Dokumentation:** [https://grafana.com/docs/grafana/latest/](https://grafana.com/docs/grafana/latest/)
- **Dashboard-Bibliothek:** [https://grafana.com/grafana/dashboards/](https://grafana.com/grafana/dashboards/) (1000+ vorgefertigte Dashboards)
- **API-Referenz:** [https://grafana.com/docs/grafana/latest/developers/http_api/](https://grafana.com/docs/grafana/latest/developers/http_api/)
- **Plugin-Katalog:** [https://grafana.com/grafana/plugins/](https://grafana.com/grafana/plugins/)
- **GitHub:** [https://github.com/grafana/grafana](https://github.com/grafana/grafana)
- **Community-Forum:** [https://community.grafana.com/](https://community.grafana.com/)
- **Grafana University:** [https://grafana.com/tutorials/](https://grafana.com/tutorials/) (Kostenlose Tutorials und Kurse)
- **n8n Grafana Node:** [https://n8n.io/integrations/grafana/](https://n8n.io/integrations/grafana/)
