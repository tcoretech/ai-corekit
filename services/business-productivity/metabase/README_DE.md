# 📈 Metabase - Business Intelligence

### Was ist Metabase?

Metabase ist die benutzerfreundlichste Open-Source Business-Intelligence-Plattform, die Rohdaten in umsetzbare Erkenntnisse verwandelt. Im Gegensatz zu komplexen BI-Tools verfügt Metabase über einen No-Code Visual Query Builder, der es jedem in deinem Team ermöglicht, Dashboards zu erstellen und Daten zu analysieren. Es ist perfekt für die Überwachung deines gesamten AI LaunchKit-Stacks, das Tracking von Business-Metriken und datengestützte Entscheidungen, ohne SQL-Kenntnisse zu erfordern (obwohl SQL-Support für Power-User verfügbar ist).

### Funktionen

- **No-Code Query Builder:** Drag-and-Drop-Oberfläche zum Erstellen von Charts und Dashboards
- **Automatische Einblicke (X-Ray):** KI-gestützte Datenexploration mit einem Klick
- **Multi-Datenbank-Support:** Verbindung zu PostgreSQL, MySQL, MongoDB und 20+ Datenbanken
- **Schöne Dashboards:** Anpassbare, teilbare Dashboards mit Echtzeit-Updates
- **Geplante Berichte (Pulses):** Automatisierte E-Mail/Slack-Berichte nach Zeitplan
- **Öffentliches Teilen:** Erstelle öffentliche Links für Dashboards ohne Authentifizierung
- **Einbettbare Charts:** Iframe-Einbettung für externe Websites
- **SQL-Bearbeiteor:** Vollständiger SQL-Support für fortgeschrittene Benutzer
- **Team-Zusammenarbeit:** Multi-User-Zugriff mit rollenbasierten Berechtigungen
- **Mobilfreundlich:** Responsives Design funktioniert auf allen Geräten
- **API-Zugriff:** Vollständige REST-API für Automatisierung und Integration

### Erste Einrichtung

**Erster Login bei Metabase:**

1. Navigiere zu `https://analytics.deinedomain.com`
2. Schließe den Setup-Assistenten ab:
   - Wähle deine Sprache
   - Erstelle Admin-Konto (keine vorkonfigurierten Zugangsdaten erforderlich)
   - Richte deinen Organisationsnamen ein
   - Optional: Füge deine erste Datenquelle hinzu (oder überspringe und füge später hinzu)
   - Lehne die Sammlung von Nutzungsdaten für Datenschutz ab
3. Klicke auf "Take me to Metabase"

**Wichtig:** Metabase hat ein eigenes vollständiges Benutzerverwaltungssystem mit Gruppen und SSO-Support, daher ist keine Basic Auth in Caddy konfiguriert.

### AI LaunchKit Datenbanken verbinden

Metabase kann sich mit allen Datenbanken in deiner AI LaunchKit-Installation verbinden für umfassende Analysen:

#### n8n Workflows-Datenbank (PostgreSQL)

```
Database Type: PostgreSQL
Host: postgres
Port: 5432
Database: n8n
Username: postgres (oder prüfe POSTGRES_USER in .env)
Password: Prüfe POSTGRES_PASSWORD in .env
SSL: Nicht erforderlich (internes Netzwerk)
```

**Anwendungsfälle:**
- Workflow-Ausführungs-Analysen
- Fehler-Tracking und Debugging
- Performance-Monitoring
- Automatisierungs-Effizienz-Metriken

#### Supabase-Datenbank (PostgreSQL) - Falls installiert

```
Database Type: PostgreSQL
Host: supabase-db
Port: 5432
Database: postgres
Username: postgres
Password: Prüfe POSTGRES_PASSWORD in .env
SSL: Nicht erforderlich
```

**Anwendungsfälle:**
- Anwendungsdaten-Analyse
- Benutzerverhalten-Tracking
- Benutzerdefinierte Anwendungs-Metriken

#### Invoice Ninja (MySQL) - Falls installiert

```
Database Type: MySQL
Host: invoiceninja_db
Port: 3306
Database: invoiceninja
Username: invoiceninja
Password: Prüfe INVOICENINJA_DB_PASSWORD in .env
SSL: Nicht erforderlich
```

**Anwendungsfälle:**
- Umsatz-Analysen
- Rechnungs-Fälligkeits-Berichte
- Kunden-Zahlungstrends
- Finanz-Prognosen

#### Kimai Zeiterfassung (MySQL) - Falls installiert

```
Database Type: MySQL
Host: kimai_db
Port: 3306
Database: kimai
Username: kimai
Password: Prüfe KIMAI_DB_PASSWORD in .env
SSL: Nicht erforderlich
```

**Anwendungsfälle:**
- Team-Produktivitäts-Analyse
- Projekt-Rentabilitäts-Tracking
- Zeitzuweisungs-Berichte
- Abrechnungsfähige Stunden-Tracking

#### Baserow/NocoDB - Falls installiert

Über PostgreSQL-Backend verbinden:

```
Database Type: PostgreSQL
Host: postgres
Port: 5432
Database: baserow oder nocodb
Username: postgres
Password: Prüfe POSTGRES_PASSWORD in .env
```

**Anwendungsfälle:**
- Benutzerdefinierte Business-Daten-Analyse
- CRM-Metriken
- Lead-Tracking
- Projektmanagement-Analysen

### n8n Integration einrichten

**Interne URL für n8n:** `http://metabase:3000`

**Methode 1: API-Integration (Empfohlen)**

```javascript
// HTTP Request Node - API-Session erstellen
Methode: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "admin@deinedomain.com",
  "password": "{{$env.METABASE_ADMIN_PASSWORD}}"
}

// Antwort enthält Session-Token:
{
  "id": "session-token-hier"
}

// Verwende diesen Token in nachfolgenden Anfragen:
Header:
  X-Metabase-Session: {{$json.id}}
```

**Methode 2: Datenbank Write-Through**

Schreibe Metriken direkt in eine PostgreSQL-Tabelle, die Metabase überwacht:

```javascript
// HTTP Request Node - Metriken einfügen
Methode: POST
URL: http://postgres:5432
// Nutze PostgreSQL Node oder SQL Execute Node
Abfrage: |
  INSERT INTO metrics_log (metric_name, value, timestamp)
  VALUES ($1, $2, NOW())
Parameter: ['workflow_executions', {{$json.count}}]
```

### Beispiel-Workflows

#### Beispiel 1: n8n Workflow Analytics Dashboard

Überwache deine Automatisierungs-Performance:

```sql
-- Dashboard Query 1: Tägliche Workflow-Ausführungen
-- Zeigt Ausführungstrends über Zeit

SELECT 
  DATE(started_at) as date,
  COUNT(*) as total_executions,
  SUM(CASE WHEN finished = true THEN 1 ELSE 0 END) as successful,
  SUM(CASE WHEN finished = false THEN 1 ELSE 0 END) as failed,
  ROUND(SUM(CASE WHEN finished = true THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) as success_rate
FROM execution_entity
WHERE started_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;

-- Visualisierung: Liniendiagramm mit Datum auf X-Achse, Ausführungen auf Y-Achse

-- Dashboard Query 2: Aktivste Workflows
-- Identifiziert deine meistgenutzten Automatisierungen

SELECT 
  w.name as workflow_name,
  COUNT(e.id) as execution_count,
  ROUND(AVG(EXTRACT(EPOCH FROM (e.stopped_at - e.started_at))), 2) as avg_duration_seconds,
  ROUND(SUM(CASE WHEN e.finished = true THEN 1 ELSE 0 END)::float / COUNT(*) * 100, 2) as success_rate
FROM execution_entity e
JOIN workflow_entity w ON e.workflow_id = w.id
WHERE e.started_at > NOW() - INTERVAL '7 days'
GROUP BY w.name
ORDER BY execution_count DESC
LIMIT 10;

-- Visualisierung: Balkendiagramm sortiert nach Ausführungsanzahl

-- Dashboard Query 3: Fehleranalyse
-- Hilft wiederkehrende Probleme zu identifizieren und zu beheben

SELECT 
  w.name as workflow_name,
  e.execution_error->>'message' as error_message,
  COUNT(*) as error_count,
  MAX(e.started_at) as last_occurrence
FROM execution_entity e
JOIN workflow_entity w ON e.workflow_id = w.id
WHERE e.finished = false
  AND e.started_at > NOW() - INTERVAL '24 hours'
  AND e.execution_error IS NOT NULL
GROUP BY w.name, e.execution_error->>'message'
ORDER BY error_count DESC;

-- Visualisierung: Tabelle mit Drill-Down-Fähigkeit

-- Dashboard Query 4: Performance über Zeit
-- Verfolge Automatisierungs-Performance-Trends

SELECT 
  DATE_TRUNC('hour', started_at) as hour,
  COUNT(*) as executions,
  ROUND(AVG(EXTRACT(EPOCH FROM (stopped_at - started_at))), 2) as avg_duration,
  MAX(EXTRACT(EPOCH FROM (stopped_at - started_at))) as max_duration
FROM execution_entity
WHERE started_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', started_at)
ORDER BY hour;

-- Visualisierung: Multi-Serien-Liniendiagramm

-- Dashboard erstellen:
-- 1. Erstelle jede Query als "Question" in Metabase
-- 2. Füge alle Questions zu einem neuen Dashboard hinzu
-- 3. Ordne und skaliere Visualisierungen
-- 4. Füge Filter hinzu (Datumsbereich, Workflow-Name)
-- 5. Setze Auto-Refresh-Intervall (z.B. alle 5 Minuten)
```

#### Beispiel 2: Service-übergreifendes Business Dashboard

Einheitliche Ansicht deines gesamten Geschäfts:

```sql
-- Umsatz-Analysen (Invoice Ninja)

-- Query 1: Monatlicher wiederkehrender Umsatz-Trend
SELECT 
  DATE_FORMAT(date, '%Y-%m') as month,
  SUM(amount) as revenue,
  COUNT(DISTINCT client_id) as active_customers,
  ROUND(SUM(amount) / COUNT(DISTINCT client_id), 2) as arpu
FROM invoices
WHERE status_id = 4 -- Bezahlt-Status
  AND is_recurring = 1
  AND date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY month;

-- Query 2: Umsatz nach Kunde
SELECT 
  c.name as customer_name,
  SUM(i.amount) as total_revenue,
  COUNT(i.id) as invoice_count,
  MAX(i.date) as last_invoice_date
FROM invoices i
JOIN clients c ON i.client_id = c.id
WHERE i.status_id = 4
  AND i.date > DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY c.name
ORDER BY total_revenue DESC
LIMIT 20;

-- Query 3: Ausstehende Rechnungen (Fälligkeitsbericht)
SELECT 
  CASE 
    WHEN DATEDIFF(NOW(), due_date) <= 0 THEN 'Nicht fällig'
    WHEN DATEDIFF(NOW(), due_date) <= 30 THEN '1-30 Tage'
    WHEN DATEDIFF(NOW(), due_date) <= 60 THEN '31-60 Tage'
    WHEN DATEDIFF(NOW(), due_date) <= 90 THEN '61-90 Tage'
    ELSE '90+ Tage'
  END as aging_bucket,
  COUNT(*) as invoice_count,
  SUM(balance) as total_amount
FROM invoices
WHERE status_id IN (2, 3) -- Versendet oder Teilweise
GROUP BY aging_bucket
ORDER BY 
  CASE aging_bucket
    WHEN 'Nicht fällig' THEN 1
    WHEN '1-30 Tage' THEN 2
    WHEN '31-60 Tage' THEN 3
    WHEN '61-90 Tage' THEN 4
    ELSE 5
  END;

-- Zeiterfassungs-Analysen (Kimai)

-- Query 4: Team-Produktivität
SELECT 
  u.username,
  COUNT(DISTINCT t.project_id) as projects_worked,
  ROUND(SUM(t.duration) / 3600, 2) as total_hours,
  ROUND(SUM(t.rate * t.duration / 3600), 2) as billable_amount
FROM timesheet t
JOIN kimai2_users u ON t.user = u.id
WHERE t.end_time > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.username
ORDER BY total_hours DESC;

-- Query 5: Projekt-Rentabilität
SELECT 
  p.name as project_name,
  ROUND(SUM(t.duration) / 3600, 2) as hours_spent,
  ROUND(SUM(t.rate * t.duration / 3600), 2) as cost,
  -- Vergleiche mit Umsatz aus Invoice Ninja (erfordert JOIN)
  ROUND((SELECT SUM(amount) FROM invoices WHERE project_id = p.id), 2) as revenue,
  ROUND((SELECT SUM(amount) FROM invoices WHERE project_id = p.id) - 
        SUM(t.rate * t.duration / 3600), 2) as profit
FROM timesheet t
JOIN kimai2_projects p ON t.project_id = p.id
WHERE t.end_time > DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY p.name
ORDER BY profit DESC;

-- Kombiniertes Dashboard erstellen:
-- 1. Füge Umsatz-Charts hinzu (Liniendiagramm für Trends)
-- 2. Füge Kunden-Tabelle hinzu (sortierbar)
-- 3. Füge Fälligkeitsbericht hinzu (Kreisdiagramm)
-- 4. Füge Team-Produktivität hinzu (Balkendiagramm)
-- 5. Füge Projekt-Rentabilität hinzu (Kombi-Diagramm)
-- 6. Füge Filter hinzu: Datumsbereich, Kunde, Projekt
-- 7. Verknüpfe Questions miteinander (Drill-Through)
```

#### Beispiel 3: Automatisierte Berichtsverteilung

Sende wöchentliche Analysen an Stakeholder:

```javascript
// n8n Workflow: Wöchentlicher Metabase-Bericht

// 1. Schedule Trigger - Jeden Montag um 9 Uhr

// 2. HTTP Request Node - Metabase-Session erstellen
Methode: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "{{$env.METABASE_USER}}",
  "password": "{{$env.METABASE_PASSWORD}}"
}

// 3. Set Variable Node - Session-Token speichern
Name: metabase_session
Wert: {{$json.id}}

// 4. HTTP Request Node - Dashboard-Daten abrufen
Methode: GET
URL: http://metabase:3000/api/dashboard/1
Header:
  X-Metabase-Session: {{$vars.metabase_session}}

// 5. Code Node - Bericht formatieren
const dashboard = $input.first().json;
const cards = dashboard.ordered_cards;

let reportHtml = `
<html>
<body>
  <h1>Wöchentlicher Analytics-Bericht</h1>
  <p>Generiert: ${new Date().toLocaleString()}</p>
  <h2>Wichtige Metriken:</h2>
`;

// Metriken aus Dashboard-Karten extrahieren
for (const card of cards) {
  const cardData = card.card;
  reportHtml += `
    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ddd;">
      <h3>${cardData.name}</h3>
      <p>${cardData.description || ''}</p>
      <img src="https://analytics.deinedomain.com/api/card/${cardData.id}/query/png?session=${metabase_session}" width="600" />
    </div>
  `;
}

reportHtml += `
</body>
</html>
`;

return [{
  json: {
    subject: `Wöchentlicher Analytics-Bericht - ${new Date().toLocaleDateString()}`,
    html: reportHtml
  }
}];

// 6. Send Email Node
To: team@deinedomain.com, executives@deinedomain.com
Subject: {{$json.subject}}
Body (HTML): {{$json.html}}
Anhänge: Optionaler PDF-Export

// 7. Slack Node - Zusammenfassung posten
Kanal: #analytics
Nachricht: |
  📊 **Wöchentlicher Analytics-Bericht bereit**
  
  Dashboard: https://analytics.deinedomain.com/dashboard/1
  
  Highlights:
  • Gesamt-Ausführungen: [Metrik]
  • Umsatz: [Metrik]
  • Team-Stunden: [Metrik]
  
  Vollständiger Bericht an Team-E-Mail gesendet.

// 8. HTTP Request Node - Von Metabase abmelden
Methode: DELETE
URL: http://metabase:3000/api/session
Header:
  X-Metabase-Session: {{$vars.metabase_session}}
```

#### Beispiel 4: Alarm bei Anomalien

Automatisierte Alarme für ungewöhnliche Muster:

```javascript
// n8n Workflow: Anomalie-Erkennung

// 1. Schedule Trigger - Jede Stunde

// 2. HTTP Request Node - Bei Metabase anmelden
Methode: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "{{$env.METABASE_USER}}",
  "password": "{{$env.METABASE_PASSWORD}}"
}

// 3. HTTP Request Node - Überwachungs-Query ausführen
Methode: POST
URL: http://metabase:3000/api/card/5/query
Header:
  X-Metabase-Session: {{$json.id}}

// Query prüft Workflow-Fehlerrate
// Gibt zurück: {failure_rate: 25.5, failed_count: 10}

// 4. IF Node - Prüfe ob Fehlerrate Schwellenwert überschreitet
Bedingung: {{$json.data.rows[0][0]}} > 20  // 20% Fehlerrate

// IF TRUE:

// 5. Code Node - Fehler analysieren
const failureRate = $json.data.rows[0][0];
const failedCount = $json.data.rows[0][1];
const topErrors = $json.data.rows.slice(0, 5);

return [{
  json: {
    alert_type: 'Hohe Fehlerrate',
    failure_rate: failureRate,
    failed_count: failedCount,
    top_errors: topErrors,
    severity: failureRate > 30 ? 'Kritisch' : 'Warnung',
    timestamp: new Date().toISOString()
  }
}];

// 6. HTTP Request Node - Incident-Ticket erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "⚠️ Hohe Workflow-Fehlerrate: {{$json.failure_rate}}%",
  "description": |
    Fehlerrate: {{$json.failure_rate}}%
    Fehlgeschlagene Ausführungen: {{$json.failed_count}}
    
    Top-Fehler:
    {{$json.top_errors}}
    
    Dashboard: https://analytics.deinedomain.com/dashboard/1
  "priority": 3,
  "labels": ["alarm", "automatisierung", "{{$json.severity}}"],
  "due_date": "{{$now.plus({hours: 4}).toISO()}}"
}

// 7. Slack Alert - Sofortige Benachrichtigung
Kanal: #alerts
Nachricht: |
  🚨 **{{$json.alert_type}}** 🚨
  
  Fehlerrate: {{$json.failure_rate}}%
  Fehlgeschlagen: {{$json.failed_count}}
  Schweregrad: {{$json.severity}}
  
  [Dashboard ansehen](https://analytics.deinedomain.com/dashboard/1)
  [Ticket ansehen](https://vikunja.deinedomain.com/tasks/{{$json.task_id}})

// 8. Email Alert - Nur für kritischen Schweregrad
IF: {{$json.severity}} === 'Kritisch'
To: oncall@deinedomain.com
Subject: KRITISCH: Workflow-Fehler-Alarm
Priority: Hoch

// 9. HTTP Request Node - Abmelden
Methode: DELETE
URL: http://metabase:3000/api/session
Header:
  X-Metabase-Session: {{$vars.metabase_session}}
```

### Erweiterte Metabase-Funktionen

#### X-Ray - Automatische Einblicke

Metabases KI-gestützte Datenexploration:

1. Navigiere zu deinen Daten in "Browse Data"
2. Klicke auf eine beliebige Tabelle
3. Klicke auf "X-ray this table"
4. Metabase generiert automatisch:
   - Verteilungsdiagramme für alle Spalten
   - Zeitreihen falls Datumsspalten existieren
   - Korrelationsanalyse zwischen Feldern
   - Vorgeschlagene Fragen basierend auf Datenmustern

**Anwendungsfälle:**
- Neue Datenquellen schnell erkunden
- Versteckte Muster entdecken
- Erste Dashboard-Ideen generieren
- Datenqualität validieren

#### Pulses - Geplante Berichte

Automatisierte Berichtsauslieferung:

1. Erstelle oder öffne ein Dashboard
2. Klicke auf "Sharing" → "Dashboard Subscriptions"
3. Konfiguriere Zeitplan:
   - Häufigkeit: Täglich, Wöchentlich, Monatlich
   - Zeit: Wähle Auslieferungszeit
   - Empfänger: E-Mail-Adressen oder Slack-Kanäle
   - Format: Charts inline oder als PDF angehängt
4. Berichte werden automatisch mit aktuellsten Daten gesendet

**Anwendungsfälle:**
- Tägliche Verkaufsberichte
- Wöchentliche Team-Metriken
- Monatliche Executive Summaries
- Automatisierte Compliance-Berichte

#### Öffentliches Teilen & Einbetten

Dashboards extern teilen:

```javascript
// In Admin → Settings → Public Sharing aktivieren

// 1. Öffentlichen Link für Dashboard generieren
// Dashboard → Sharing → Create public link
// URL: https://analytics.deinedomain.com/public/dashboard/UUID

// 2. In Website mit iframe einbetten:
<iframe
  src="https://analytics.deinedomain.com/public/dashboard/DEIN-UUID"
  frameborder="0"
  width="100%"
  height="600"
  allowtransparency
  sandbox="allow-scripts allow-same-origin"
></iframe>

// 3. Parameter zu iframe-URL hinzufügen:
src="https://analytics.deinedomain.com/public/dashboard/UUID?param1=value1"

// 4. Sicheres Einbetten mit signierten URLs:
// Signierte URL via API für zeitbegrenzten Zugriff generieren
```

**Anwendungsfälle:**
- Kundenseitige Dashboards
- Öffentliche Metrik-Seiten
- Eingebettete Analytics in SaaS-Apps
- Investor-Reporting

#### Models - Datenabstraktionsschicht

Erstelle saubere, wiederverwendbare Datenmodelle:

1. Browse Data → Tabelle auswählen → Turn into Model
2. Definiere bereinigte Spaltennamen
3. Verberge technische Spalten
4. Füge Beschreibungen und Metadaten hinzu
5. Richte Beziehungen zwischen Modellen ein
6. Nutze Modelle als Basis für Fragen

**Vorteile:**
- Nicht-technische Benutzer können Daten einfach abfragen
- Konsistente Metrik-Definitionen
- Schnellere Query-Performance
- Zentralisierte Business-Logik

### Performance-Optimierung

#### Für große Datensätze

```yaml
# Java-Heap in docker-compose.yml erhöhen
environment:
  - JAVA_OPTS=-Xmx2g -Xms2g  # Von 1g auf 2g erhöhen
  - MB_QUERY_TIMEOUT_MINUTES=10  # Timeout für lange Queries erhöhen
  - MB_DB_CONNECTION_TIMEOUT_MS=10000  # Verbindungs-Timeout
```

#### Query-Caching aktivieren

1. Admin → Settings → Caching
2. Caching global aktivieren
3. TTL (Time To Live) setzen:
   - Echtzeit-Dashboards: 1 Minute
   - Tägliche Berichte: 24 Stunden
   - Historische Daten: 7 Tage
4. "Adaptive Caching" für automatische Optimierung aktivieren
5. Cache-Hit-Rate in Admin → Troubleshooting überwachen

#### Materialized Views erstellen

Für häufig abgerufene Aggregationen:

```sql
-- Materialized View in PostgreSQL erstellen
CREATE MATERIALIZED VIEW workflow_daily_stats AS
SELECT 
  DATE(started_at) as date,
  COUNT(*) as executions,
  AVG(EXTRACT(EPOCH FROM (stopped_at - started_at))) as avg_duration,
  SUM(CASE WHEN finished = true THEN 1 ELSE 0 END) as successful
FROM execution_entity
GROUP BY DATE(started_at);

-- Index auf Datumsspalte erstellen
CREATE INDEX idx_workflow_daily_stats_date 
ON workflow_daily_stats(date);

-- Täglich via n8n-Workflow aktualisieren
REFRESH MATERIALIZED VIEW workflow_daily_stats;

-- Materialized View in Metabase abfragen (viel schneller)
SELECT * FROM workflow_daily_stats 
WHERE date > NOW() - INTERVAL '30 days';
```

### Tipps für Metabase + n8n Integration

1. **Interne URLs verwenden:** Von n8n immer `http://metabase:3000` verwenden, nicht die externe URL
2. **API-Authentifizierung:** Metabase-Session-Tokens in n8n-Zugangsdaten mit Ablaufbehandlung speichern
3. **Query-Optimierung:** Metabases Query-Caching für häufig abgerufene Daten nutzen
4. **Berechtigungen:** Richte Gruppen in Metabase für verschiedene Zugriffsebenen ein (Admin, Analyst, Viewer)
5. **Models zuerst:** Erstelle Metabase-Modelle für saubere Datenabstraktion
6. **Collections:** Organisiere Dashboards/Questions in Collections passend zu deiner Teamstruktur
7. **Alarme:** Konfiguriere Metabase-Alarme um n8n-Webhooks für Automatisierung auszulösen
8. **Versionierung:** Exportiere Dashboard-Definitionen als JSON für Versionskontrolle
9. **Testing:** Nutze Metabases Question-Vorschau um Queries vor dem Dashboarding zu validieren
10. **Dokumentation:** Füge Beschreibungen zu allen Questions und Dashboards für Team-Klarheit hinzu

### Häufige Anwendungsfälle

#### SaaS Metrics Dashboard

```sql
-- MRR Tracking
SELECT 
  DATE_TRUNC('month', subscription_date) as month,
  SUM(amount) as mrr,
  COUNT(DISTINCT customer_id) as customers,
  ROUND(SUM(amount) / COUNT(DISTINCT customer_id), 2) as arpu
FROM subscriptions
WHERE status = 'active'
GROUP BY month;

-- Churn-Analyse
SELECT 
  DATE_TRUNC('month', cancelled_date) as month,
  COUNT(*) as churned_customers,
  ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM customers) * 100, 2) as churn_rate
FROM subscriptions
WHERE status = 'cancelled'
GROUP BY month;

-- Benutzer-Engagement (aus n8n-Logs)
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as daily_active_users,
  COUNT(*) as total_actions
FROM user_activity_log
GROUP BY date;
```

#### Team-Performance-Dashboard

```sql
-- Automatisierungs-Effizienz
SELECT 
  u.name as team_member,
  COUNT(w.id) as workflows_created,
  SUM(e.executions) as total_executions,
  ROUND(AVG(e.success_rate), 2) as avg_success_rate
FROM users u
LEFT JOIN workflows w ON u.id = w.creator_id
LEFT JOIN workflow_stats e ON w.id = e.workflow_id
GROUP BY u.name;

-- Projekt-Abschluss
SELECT 
  project_name,
  COUNT(*) as total_tasks,
  SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) as completed,
  ROUND(SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) as completion_rate
FROM tasks
GROUP BY project_name;

-- Ressourcen-Zuteilung (aus Kimai)
SELECT 
  project,
  ROUND(SUM(duration) / 3600, 2) as hours_allocated,
  COUNT(DISTINCT user_id) as team_members,
  ROUND(SUM(billable_duration) / SUM(duration) * 100, 2) as billable_percentage
FROM time_entries
WHERE date > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY project;
```

#### Finanz-Dashboard

```sql
-- Umsatz nach Produkt/Service
SELECT 
  product_name,
  COUNT(DISTINCT customer_id) as customers,
  SUM(amount) as total_revenue,
  ROUND(AVG(amount), 2) as avg_transaction
FROM invoices
WHERE status = 'paid'
  AND date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY product_name
ORDER BY total_revenue DESC;

-- Cashflow-Prognose
SELECT 
  DATE_FORMAT(due_date, '%Y-%m') as month,
  SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as received,
  SUM(CASE WHEN status IN ('sent', 'partial') THEN balance ELSE 0 END) as expected,
  SUM(CASE WHEN status IN ('sent', 'partial') AND due_date < NOW() THEN balance ELSE 0 END) as overdue
FROM invoices
WHERE due_date >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
  AND due_date <= DATE_ADD(NOW(), INTERVAL 3 MONTH)
GROUP BY DATE_FORMAT(due_date, '%Y-%m')
ORDER BY month;

-- Ausgaben-Kategorisierung
SELECT 
  category,
  COUNT(*) as transaction_count,
  SUM(amount) as total_spent,
  ROUND(AVG(amount), 2) as avg_transaction
FROM expenses
WHERE date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY category
ORDER BY total_spent DESC;
```

### Fehlerbehebung

#### Metabase-Container startet nicht

```bash
# 1. Logs auf Fehler prüfen
docker logs metabase --tail 100

# 2. Häufiges Problem: Datenbank-Migration ausstehend
docker exec metabase java -jar /app/metabase.jar migrate up

# 3. Festplattenspeicher prüfen
df -h

# 4. Verifiziere dass metabase_db läuft
docker ps | grep metabase_db

# 5. Falls korrupt, Metabase-Datenbank zurücksetzen (verliert alle Einstellungen!)
docker compose down metabase metabase_db
docker volume rm ${PROJECT_NAME:-localai}_metabase_postgres
docker compose up -d metabase metabase_db

# Warte 2-3 Minuten für Initialisierung
docker logs metabase --follow
```

#### Kann nicht mit Datenbank verbinden

```bash
# 1. Hostname verifizieren (nutze Container-Namen, nicht localhost)
# Korrekt: postgres
# Falsch: localhost, 127.0.0.1

# 2. Verbindung von Metabase-Container testen
docker exec metabase ping postgres

# 3. Datenbank-Zugangsdaten in .env prüfen
grep POSTGRES .env

# 4. Verifiziere dass Datenbank Verbindungen akzeptiert
docker exec postgres pg_isready -U postgres

# 5. Metabase-Logs auf Verbindungsfehler prüfen
docker logs metabase | grep -i "database"
```

#### Langsame Query-Performance

```bash
# 1. Indizes zu häufig abgefragten Spalten hinzufügen
# In PostgreSQL:
docker exec postgres psql -U postgres -d n8n
CREATE INDEX idx_execution_started ON execution_entity(started_at);
CREATE INDEX idx_execution_workflow ON execution_entity(workflow_id);

# 2. Metabase Query-Caching aktivieren
# Admin → Settings → Caching → Enable

# 3. Erwäge Summary-Tabellen zu erstellen
# Aktualisiert via n8n nach Zeitplan

# 4. Query-Ausführungszeit überwachen
# Metabase zeigt Query-Zeit unten rechts

# 5. Nutze EXPLAIN ANALYZE um Queries zu optimieren
EXPLAIN ANALYZE SELECT ...;
```

#### Speicher-Probleme

```bash
# 1. Metabase-Speichernutzung prüfen
docker stats metabase

# 2. Speicherzuweisung in .env erhöhen
# Standard: METABASE_MEMORY=1g
# Empfohlen: METABASE_MEMORY=2g oder 4g

# 3. Metabase neu starten
docker compose restart metabase

# 4. Java-Heap-Nutzung überwachen
docker exec metabase java -XX:+PrintFlagsFinal -version | grep HeapSize
```

#### Dashboard wird nicht aktualisiert

```bash
# 1. Prüfe ob Caching zu aggressiv ist
# Admin → Settings → Caching → TTL-Werte senken

# 2. Dashboard manuell aktualisieren
# Klicke auf Refresh-Button im Dashboard

# 3. Cache für spezifische Question löschen
# Question → Settings → Clear cache

# 4. Prüfe ob Datenquelle aktualisiert wird
# Direkt in Datenbank verifizieren

# 5. Geplante Pulse-Einstellungen überprüfen
# Dashboard → Subscriptions → Timing prüfen
```

### Ressourcen

- **Dokumentation:** https://www.metabase.com/docs
- **Learn Metabase:** https://www.metabase.com/learn
- **Community Forum:** https://discourse.metabase.com
- **SQL Templates:** https://www.metabase.com/learn/sql-templates
- **GitHub:** https://github.com/metabase/metabase
- **API-Dokumentation:** https://www.metabase.com/docs/latest/api-documentation
- **Video-Tutorials:** https://www.metabase.com/learn/getting-started

### Best Practices

**Dashboard-Design:**
- Halte Dashboards fokussiert (max. 8-10 Visualisierungen)
- Nutze konsistente Farbschemata
- Füge beschreibende Titel und Beschreibungen hinzu
- Inkludiere Datumsfilter für zeitbasierte Analysen
- Ordne Visualisierungen nach Wichtigkeit
- Nutze passende Diagrammtypen für Daten
- Füge Kontext mit Text-Karten hinzu

**Query-Optimierung:**
- Filtere Daten vor Aggregation
- Nutze Indizes auf häufig abgefragten Spalten
- Begrenze Result-Sets angemessen
- Vermeide SELECT * Queries
- Nutze Materialized Views für komplexe Aggregationen
- Cache häufig abgerufene Queries
- Setze vernünftige Query-Timeouts

**Team-Zusammenarbeit:**
- Organisiere Content in Collections nach Team/Funktion
- Richte passende Berechtigungen ein
- Dokumentiere Queries mit Kommentaren
- Nutze konsistente Benennungskonventionen
- Erstelle wiederverwendbare gespeicherte Questions
- Richte Alarme für Schlüssel-Metriken ein
- Plane regelmäßige Bericht-Reviews

**Data Governance:**
- Definiere Metriken zentral mit Models
- Dokumentiere Datenquellen und Definitionen
- Richte Datenvalidierungs-Checks ein
- Regelmäßiges Audit ungenutzter Questions
- Archiviere veraltete Dashboards
- Versionskontrolle für wichtige Queries
- Regelmäßiges Backup der Metabase-Config

**Sicherheit:**
- Nutze Row-Level-Permissions wo nötig
- Regelmäßige Credential-Rotation
- Aktiviere 2FA für Admin-Konten
- Audit-Log-Review
- Sichere öffentliche Links angemessen
- Überwache API-Nutzung
- Regelmäßige Sicherheits-Updates
