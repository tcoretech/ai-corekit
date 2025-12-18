# 📞 EspoCRM - CRM-Plattform

### Was ist EspoCRM?

EspoCRM ist eine umfassende, voll ausgestattete Open-Source-CRM-Plattform für Unternehmen jeder Größe. Sie bietet erweiterte E-Mail-Kampagnenverwaltung, Workflow-Automatisierung, detaillierte Berichterstattung und rollenbasierten Zugriff. Im Gegensatz zu leichtgewichtigen CRMs bietet EspoCRM Enterprise-Grade-Funktionen einschließlich Marketing-Automatisierung, Service-Management und umfangreichen Anpassungsoptionen.

### Funktionen

- **Komplette CRM-Suite** - Leads, Kontakte, Accounts, Opportunities, Cases, Dokumente
- **E-Mail-Marketing** - Kampagnenverwaltung, Massen-E-Mails, Tracking, Vorlagen
- **Workflow-Automatisierung** - Erweiterte BPM (Business Process Management) mit visuellem Designer
- **Erweiterte Berichterstattung** - Custom Reports, Dashboards, Charts, Listen-Ansichten mit Filtern
- **Rollenbasierter Zugriff** - Granulare Berechtigungen, Team-Hierarchien, Feld-Level-Sicherheit
- **E-Mail-Integration** - IMAP/SMTP-Sync, Gruppen-Postfächer, Email-to-Case
- **Kalender & Aktivitäten** - Meetings, Anrufe, Aufgaben mit Planung und Erinnerungen
- **Custom Entities** - Erstelle Custom-Module für jeden Geschäftsprozess
- **REST API** - Umfassende API für Integrationen und Automatisierung
- **Multi-Language** - 40+ Sprachen out-of-the-box unterstützt
- **Portal** - Kunden-Self-Service-Portal für Cases und Knowledge Base
- **Erweiterte Workflows** - Formeln, berechnete Felder, bedingte Logik

### Erste Einrichtung

**Erster Login bei EspoCRM:**

1. Navigiere zu `https://espocrm.deinedomain.com`
2. Login mit Admin-Zugangsdaten aus dem Installationsbericht:
   - **Benutzername:** Prüfe `.env` Datei für `ESPOCRM_ADMIN_USERNAME` (Standard: `admin`)
   - **Passwort:** Prüfe `.env` Datei für `ESPOCRM_ADMIN_PASSWORD`
3. Initiale Konfiguration abschließen:
   - Administration → System → Settings
   - Firmeninformationen konfigurieren
   - Zeitzone und Datums-/Zeitformat festlegen
   - Währung und Sprache konfigurieren
4. E-Mail-Integration einrichten:
   - Administration → Outbound Emails
   - Mailpit (vorkonfiguriert) oder Docker-Mailserver konfigurieren
5. API-Key generieren:
   - Administration → API Users
   - Neuen API-Benutzer erstellen
   - API-Key für n8n-Integration generieren
   - Key sicher speichern

**Wichtig:** Für Produktiv-Nutzung das Standard-Admin-Passwort sofort ändern!

### n8n Integration einrichten

**EspoCRM Zugangsdaten in n8n erstellen:**

EspoCRM hat keine native n8n Node. Verwende HTTP Request Nodes mit API-Key-Authentifizierung.

1. In n8n, erstelle Zugangsdaten:
   - Typ: Header Auth
   - Name: EspoCRM API
   - Header Name: `X-Api-Key`
   - Header Wert: Dein generierter API-Key aus EspoCRM

**Interne URL für n8n:** `http://espocrm:80`

**API Basis-URL:** `http://espocrm:80/api/v1`

**Häufige Endpunkte:**
- `/Lead` - Lead-Verwaltung
- `/Contact` - Kontakt-Datensätze
- `/Account` - Account/Firmen-Datensätze
- `/Opportunity` - Verkaufs-Opportunities
- `/Case` - Support-Cases
- `/Task` - Aufgaben und Todos
- `/Meeting` - Meetings und Anrufe
- `/Campaign` - E-Mail-Kampagnen

### Beispiel-Workflows

#### Beispiel 1: KI-gestützte E-Mail-Kampagnen-Automatisierung

Lead-Recherche automatisieren und zur E-Mail-Kampagne hinzufügen:

```javascript
// Neue Leads recherchieren und zu Nurture-Kampagne hinzufügen

// 1. Schedule Trigger - Täglich um 10 Uhr

// 2. HTTP Request Node - Neue Leads der letzten 24 Stunden abrufen
Methode: GET
URL: http://espocrm:80/api/v1/Lead
Authentication: Use EspoCRM Credentials
Query Parameter:
  where[0][type]: after
  where[0][attribute]: createdAt
  where[0][value]: {{$now.minus(1, 'day').toISO()}}
  select: id,name,emailAddress,companyName,website,status

// 3. Loop Over Items - Jeden Lead verarbeiten

// 4. Perplexica Node - Lead-Firma recherchieren
Methode: POST
URL: http://perplexica:3000/api/search
Body (JSON):
{
  "query": "{{$json.companyName}} Firma aktuelle News Umsatz Finanzierung",
  "focusMode": "webSearch"
}

// 5. OpenAI Node - Lead bewerten und analysieren
Operation: Message a Model
Modell: gpt-4o-mini
Nachrichten:
  System: "Du bist ein Lead-Qualifizierungs-Experte. Analysiere Firmenrecherche und gib einen Qualitäts-Score (0-100)."
  User: |
    Firma: {{$json.companyName}}
    Website: {{$json.website}}
    Recherche: {{$('Perplexica').json.answer}}
    
    Gib JSON-Antwort:
    {
      "score": <0-100>,
      "reasoning": "<Analyse>",
      "industry": "<erkannte Branche>",
      "company_size": "<geschätzte Größe>",
      "priority": "<Hoch/Mittel/Niedrig>"
    }

// 6. Code Node - KI-Antwort parsen
const aiResult = JSON.parse($input.first().json.message.content);
return {
  json: {
    leadId: $('Loop Over Items').item.json.id,
    score: aiResult.score,
    reasoning: aiResult.reasoning,
    industry: aiResult.industry,
    companySize: aiResult.company_size,
    priority: aiResult.priority
  }
};

// 7. HTTP Request Node - Lead mit KI-Einblicken aktualisieren
Methode: PUT
URL: http://espocrm:80/api/v1/Lead/{{$json.leadId}}
Body (JSON):
{
  "description": "{{$json.reasoning}}",
  "leadScore": {{$json.score}},
  "industry": "{{$json.industry}}",
  "status": "{{$json.score >= 70 ? 'Qualified' : 'New'}}"
}

// 8. IF Node - Prüfe ob qualifiziert (Score >= 70)

// Branch: Qualifizierte Leads
// 9a. HTTP Request - Zu Nurture E-Mail-Kampagne hinzufügen
Methode: POST
URL: http://espocrm:80/api/v1/CampaignLogRecord
Body (JSON):
{
  "campaignId": "deine-nurture-kampagnen-id",
  "targetId": "{{$json.leadId}}",
  "targetType": "Lead",
  "action": "Sent"
}

// 10a. HTTP Request - Follow-up-Aufgabe für Vertriebsmitarbeiter erstellen
Methode: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Follow-up mit {{$('Loop Over Items').item.json.name}}",
  "status": "Not Started",
  "priority": "{{$json.priority}}",
  "parentType": "Lead",
  "parentId": "{{$json.leadId}}",
  "dateEnd": "{{$now.plus(2, 'days').toISO()}}"
}

// 11a. Slack Node - Verkaufsteam benachrichtigen
Kanal: #vertrieb-qualifizierte-leads
Nachricht: |
  🎯 **Qualifizierter Lead-Alarm**
  
  Firma: {{$('Loop Over Items').item.json.companyName}}
  Score: {{$json.score}}/100
  Priorität: {{$json.priority}}
  
  KI-Analyse: {{$json.reasoning}}
  
  👉 Follow-up innerhalb von 48 Stunden

// Branch: Niedrigere Priorität Leads
// 9b. HTTP Request - Zu allgemeiner Nurture-Kampagne hinzufügen
// 10b. Follow-up-Erinnerung für 7 Tage setzen
```

#### Beispiel 2: Service-Request-Automatisierung mit SLA-Verwaltung

Support-Cases mit automatischem SLA-Tracking verwalten:

```javascript
// Automatisierte Case-Verwaltung mit SLA-Berechnungen

// 1. Webhook Trigger - Neue Service-Anfrage erstellt
// Webhook in EspoCRM konfigurieren: Administration → Webhooks

// 2. HTTP Request Node - Zugehörige Account-Details abrufen
Methode: GET
URL: http://espocrm:80/api/v1/Account/{{$json.accountId}}
Authentication: Use EspoCRM Credentials
Query Parameter:
  select: name,website,industry,assignedUserId

// 3. HTTP Request Node - Service-Vertrag/SLA prüfen
Methode: GET
URL: http://espocrm:80/api/v1/ServiceContract
Query Parameter:
  where[0][type]: equals
  where[0][attribute]: accountId
  where[0][value]: {{$json.accountId}}
  select: id,name,type,slaHours

// 4. Code Node - Priorität und SLA-Frist berechnen
const account = $('Get Account').item.json;
const contract = $('Check SLA').item.json.list?.[0];

// Priorität basierend auf Vertragstyp bestimmen
const priority = contract?.type === 'Premium' ? 'High' : 
                 contract?.type === 'Standard' ? 'Normal' : 'Low';

// SLA-Stunden berechnen
const slaHours = {
  'Premium': 4,
  'Standard': 24,
  'Basic': 48
}[contract?.type] || 72;

// Fälligkeitsdatum berechnen
const dueDate = new Date();
dueDate.setHours(dueDate.getHours() + slaHours);

return {
  json: {
    caseId: $('Webhook').item.json.id,
    priority,
    slaHours,
    dueDatum: dueDate.toISOString(),
    assignedUserId: account.assignedUserId,
    accountName: account.name,
    contractType: contract?.type || 'None'
  }
};

// 5. HTTP Request Node - Case mit SLA-Info aktualisieren
Methode: PUT
URL: http://espocrm:80/api/v1/Case/{{$json.caseId}}
Body (JSON):
{
  "priority": "{{$json.priority}}",
  "status": "Assigned",
  "assignedUserId": "{{$json.assignedUserId}}",
  "dateEnd": "{{$json.dueDate}}"
}

// 6. HTTP Request Node - Aufgabe für zugewiesenen Benutzer erstellen
Methode: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Service-Anfrage: {{$('Webhook').item.json.subject}}",
  "description": "SLA: {{$json.slaHours}} Stunden | Fällig: {{$json.dueDate}}",
  "status": "Not Started",
  "priority": "{{$json.priority}}",
  "dateEnd": "{{$json.dueDate}}",
  "assignedUserId": "{{$json.assignedUserId}}",
  "parentType": "Case",
  "parentId": "{{$json.caseId}}"
}

// 7. Email Node - Bestätigung an Kunden senden
To: {{$('Webhook').item.json.contactEmail}}
Subject: Case #{{$json.caseId}} - {{$('Webhook').item.json.subject}}
Body: |
  Sehr geehrter Kunde,
  
  Ihre Service-Anfrage wurde empfangen und zugewiesen.
  
  Case ID: #{{$json.caseId}}
  Priorität: {{$json.priority}}
  Erwartete Antwort: Innerhalb von {{$json.slaHours}} Stunden
  Zugewiesen an: {{$json.assignedUserId}}
  
  Wir informieren Sie, sobald wir weitere Informationen haben.
  
  Beste Grüße,
  Support-Team

// 8. Slack Node - Support-Team benachrichtigen
Kanal: #support-cases
Nachricht: |
  🆕 Neue Service-Anfrage
  
  Case: #{{$json.caseId}}
  Account: {{$json.accountName}}
  Priorität: {{$json.priority}}
  SLA: {{$json.slaHours}}h
  Vertrag: {{$json.contractType}}
  Fällig: {{$json.dueDate}}
```

#### Beispiel 3: Sales-Pipeline-Automatisierung

Opportunity-Verwaltung mit phasenbasierten Workflows automatisieren:

```javascript
// Automatisierte Aktionen basierend auf Opportunity-Phasenänderungen

// 1. EspoCRM Webhook - Opportunity-Phase geändert
// In EspoCRM konfigurieren: Administration → Webhooks → Für Opportunity Entity erstellen

// 2. Switch Node - Route basierend auf neuer Phase
Mode: Rules
Output Key: {{$json.stage}}

// Branch 1: "Angebot versendet"
// 3a. HTTP Request - Angebots-Dokument generieren
Methode: POST
URL: http://stirling-pdf:8080/api/v1/general/create-pdf
Body (Multipart):
  template: angebot_template.html
  data: {{JSON.stringify($json)}}

// 4a. HTTP Request - Angebot an Opportunity anhängen
Methode: POST
URL: http://espocrm:80/api/v1/Attachment
Body (JSON):
{
  "name": "Angebot_{{$json.name}}_{{$now.format('YYYY-MM-DD')}}.pdf",
  "type": "application/pdf",
  "role": "Attachment",
  "relatedType": "Opportunity",
  "relatedId": "{{$json.id}}",
  "contents": "{{$('Generate PDF').json.base64}}"
}

// 5a. Invoice Ninja Node - Rechnungsentwurf erstellen
Operation: Create Invoice
Customer: {{$json.accountName}}
Items: Von Opportunity-Produkten parsen
Status: Draft

// 6a. Email Node - Angebot mit Tracking senden
To: {{$json.contactEmail}}
Subject: Angebot für {{$json.name}}
Anhänge: Generiertes Angebots-PDF
Body: Professionelle Angebots-E-Mail-Vorlage

// Branch 2: "Verhandlung"
// 3b. Cal.com HTTP Request - Verhandlungsmeeting planen
Methode: POST
URL: http://cal:3000/api/bookings
Body (JSON):
{
  "eventTypeId": 456, // Verhandlungsmeeting Event-Type
  "start": "{{$now.plus(3, 'days').toISO()}}",
  "responses": {
    "name": "{{$json.contactName}}",
    "email": "{{$json.contactEmail}}",
    "notes": "Verhandlungsmeeting für Opportunity: {{$json.name}}"
  }
}

// 4b. HTTP Request - Opportunity-Wahrscheinlichkeit aktualisieren
Methode: PUT
URL: http://espocrm:80/api/v1/Opportunity/{{$json.id}}
Body (JSON):
{
  "probability": 60
}

// 5b. Slack Node - Sales Manager benachrichtigen
Kanal: #vertrieb-pipeline
Nachricht: |
  💼 Opportunity in Verhandlung
  
  Deal: {{$json.name}}
  Betrag: €{{$json.amount}}
  Meeting geplant: {{$('Schedule Meeting').json.start}}

// Branch 3: "Gewonnen"
// 3c. HTTP Request - Opportunity in Account konvertieren (falls Neukunde)
Methode: POST
URL: http://espocrm:80/api/v1/Account
Body (JSON):
{
  "name": "{{$json.accountName}}",
  "website": "{{$json.website}}",
  "industry": "{{$json.industry}}",
  "type": "Customer"
}

// 4c. Twenty CRM HTTP Request - Zu sekundärem CRM synchronisieren
Methode: POST
URL: http://twenty-crm:3000/rest/companies
Body (JSON):
{
  "name": "{{$json.accountName}}",
  "domainName": "{{$json.website}}",
  "customFields": {
    "espocrmId": "{{$json.id}}",
    "dealValue": {{$json.amount}}
  }
}

// 5c. Kimai HTTP Request - Projekt für Zeiterfassung erstellen
Methode: POST
URL: http://kimai:8001/api/projects
Body (JSON):
{
  "name": "{{$json.accountName}} - Implementierung",
  "customer": "{{$json.accountName}}",
  "visible": true,
  "budget": {{$json.amount}}
}

// 6c. Vikunja HTTP Request - Onboarding-Aufgaben erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects
Body (JSON):
{
  "title": "Kunden-Onboarding: {{$json.accountName}}",
  "description": "Onboarding-Aufgaben für Neukunden"
}

// 7c. Email Node - Willkommens-E-Mail an Kunden
To: {{$json.contactEmail}}
Subject: Willkommen bei {{$env.COMPANY_NAME}}!
Body: Willkommens-E-Mail mit nächsten Schritten

// Branch 4: "Verloren"
// 3d. HTTP Request - Follow-up-Aufgabe für 90 Tage erstellen
Methode: POST
URL: http://espocrm:80/api/v1/Task
Body (JSON):
{
  "name": "Follow-up mit {{$json.name}} - Verlorene Opportunity",
  "status": "Not Started",
  "dateEnd": "{{$now.plus(90, 'days').toISO()}}",
  "parentType": "Opportunity",
  "parentId": "{{$json.id}}"
}

// 4d. Formbricks HTTP Request - Verlustgrund-Umfrage senden
Methode: POST
URL: http://formbricks:3000/api/v1/client/displays
Body: Umfrage um zu verstehen warum Deal verloren ging

// 5d. Metabase HTTP Request - Analytics-Dashboard aktualisieren
// Verlorenen Deal für Reporting protokollieren
```

#### Beispiel 4: Monatliche Report-Generierung und -Verteilung

Automatisierte Executive-Reports mit Daten aus EspoCRM:

```javascript
// Umfassende monatliche CRM-Reports generieren

// 1. Schedule Trigger - Erster Montag jeden Monats um 9 Uhr

// 2. HTTP Request Node - Monatliche Opportunity-Metriken abrufen
Methode: GET
URL: http://espocrm:80/api/v1/Opportunity
Authentication: Use EspoCRM Credentials
Query Parameter:
  select: id,name,amount,stage,closeDate,probability,assignedUserId
  where[0][type]: currentMonth
  where[0][attribute]: closeDate

// 3. Code Node - KPIs berechnen
const opportunities = $input.first().json.list;

const kpis = {
  total_opportunities: opportunities.length,
  total_pipeline: opportunities.reduce((sum, opp) => sum + opp.amount, 0),
  weighted_forecast: opportunities.reduce((sum, opp) => 
    sum + (opp.amount * opp.probability / 100), 0),
  average_deal_size: opportunities.length > 0 ? 
    opportunities.reduce((sum, opp) => sum + opp.amount, 0) / opportunities.length : 0,
  won_deals: opportunities.filter(o => o.stage === 'Closed Won').length,
  lost_deals: opportunities.filter(o => o.stage === 'Closed Lost').length,
  conversion_rate: opportunities.length > 0 ?
    (opportunities.filter(o => o.stage === 'Closed Won').length / opportunities.length * 100).toFixed(2) : 0
};

// Nach Phase gruppieren
kpis.by_stage = {};
opportunities.forEach(opp => {
  if (!kpis.by_stage[opp.stage]) {
    kpis.by_stage[opp.stage] = { count: 0, value: 0 };
  }
  kpis.by_stage[opp.stage].count++;
  kpis.by_stage[opp.stage].value += opp.amount;
});

// Top-Performer
const performanceByUser = {};
opportunities.forEach(opp => {
  if (opp.stage === 'Closed Won') {
    if (!performanceByUser[opp.assignedUserId]) {
      performanceByUser[opp.assignedUserId] = { deals: 0, value: 0 };
    }
    performanceByUser[opp.assignedUserId].deals++;
    performanceByUser[opp.assignedUserId].value += opp.amount;
  }
});

kpis.top_performers = Object.entries(performanceByUser)
  .sort((a, b) => b[1].value - a[1].value)
  .slice(0, 5);

return { json: kpis };

// 4. HTTP Request Node - Aktivitäts-Metriken abrufen
Methode: GET
URL: http://espocrm:80/api/v1/Meeting
Query Parameter:
  where[0][type]: currentMonth
  where[0][attribute]: dateStart
  select: id,assignedUserId,status

// 5. Code Node - Aktivitätsanalyse
const meetings = $input.first().json.list;
const kpis = $('Calculate KPIs').item.json;

kpis.total_meetings = meetings.length;
kpis.completed_meetings = meetings.filter(m => m.status === 'Held').length;

return { json: kpis };

// 6. Metabase HTTP Request - Executive-Dashboard aktualisieren
Methode: POST
URL: http://metabase:3000/api/card/{{$env.SALES_DASHBOARD_ID}}/query
Header:
  X-Metabase-Session: {{$env.METABASE_SESSION}}
Body: Berechnete KPIs senden

// 7. Google Sheets Node - In Spreadsheet exportieren
Operation: Append
Spreadsheet: Monatliche CRM-Reports
Sheet: {{$now.format('YYYY-MM')}}
Daten: Alle berechneten KPIs und Metriken

// 8. HTTP Request - PDF-Report generieren
Methode: POST
URL: http://stirling-pdf:8080/api/v1/convert/html-to-pdf
Body (Multipart):
  html: Formatierter HTML-Report mit allen Metriken und Charts

// 9. Email Node - Report an Stakeholder senden
To: geschaeftsfuehrung@firma.com, vertriebsteam@firma.com
CC: finanzen@firma.com
Subject: Monatlicher CRM-Report - {{$now.format('MMMM YYYY')}}
Body: |
  📊 **Monatlicher CRM-Performance-Report**
  
  **Schlüsselmetriken:**
  • Gesamt-Opportunities: {{$json.total_opportunities}}
  • Pipeline-Wert: €{{$json.total_pipeline.toLocaleString()}}
  • Gewichtete Prognose: €{{$json.weighted_forecast.toLocaleString()}}
  • Durchschnittliche Deal-Größe: €{{$json.average_deal_size.toLocaleString()}}
  • Gewonnene Deals: {{$json.won_deals}}
  • Verlorene Deals: {{$json.lost_deals}}
  • Conversion Rate: {{$json.conversion_rate}}%
  
  **Aktivitäten:**
  • Gesamt-Meetings: {{$json.total_meetings}}
  • Abgeschlossen: {{$json.completed_meetings}}
  
  **Pipeline nach Phase:**
  {{#each $json.by_stage}}
  • {{@key}}: {{this.count}} Deals (€{{this.value.toLocaleString()}})
  {{/each}}
  
  **Top-Performer:**
  {{#each $json.top_performers}}
  {{@index + 1}}. Benutzer {{this[0]}}: {{this[1].deals}} Deals (€{{this[1].value.toLocaleString()}})
  {{/each}}
  
  📎 Vollständiger Report angehängt
  📊 Live-Dashboard ansehen: https://analytics.deinedomain.com

Anhänge: 
  - Generierter PDF-Report
  - Excel-Export aus Google Sheets

// 10. Slack Node - Zusammenfassung in Team-Channel posten
Kanal: #vertriebsteam
Nachricht: |
  📊 **Monatlicher CRM-Report veröffentlicht**
  
  Key Highlights:
  • €{{$json.total_pipeline.toLocaleString()}} in Pipeline
  • {{$json.conversion_rate}}% Conversion Rate
  • {{$json.won_deals}} Deals abgeschlossen
  
  📧 Vollständiger Report an Geschäftsführung gesendet
  📊 Dashboard: https://analytics.deinedomain.com
```

### Problembehandlung

**Problem 1: API-Authentifizierung schlägt fehl**

```bash
# Prüfen ob EspoCRM läuft
docker ps | grep espocrm

# EspoCRM Logs anzeigen
docker logs espocrm

# API-Verbindung testen
curl -H "X-Api-Key: DEIN_API_KEY" \
  http://localhost:80/api/v1/Lead

# API-Key in EspoCRM verifizieren
# Administration → API Users → Deinen API-Benutzer prüfen
```

**Lösung:**
- API-Key in EspoCRM neu generieren (Administration → API Users)
- Sicherstellen dass API-Benutzer entsprechende Berechtigungen hat
- Prüfen dass Header-Name genau `X-Api-Key` ist (case-sensitive)
- Firewall-Regeln verifizieren dass internes Docker-Netzwerk erlaubt ist
- Prüfen dass EspoCRM vollständig initialisiert ist (kann 2-3 Minuten beim ersten Start dauern)

**Problem 2: Webhook wird nicht ausgelöst**

```bash
# Webhook manuell testen
curl -X POST https://dein-n8n.com/webhook/espocrm \
  -H "Content-Type: application/json" \
  -d '{"id": "test123", "entityType": "Lead", "action": "create"}'

# n8n Webhook-Logs prüfen
docker logs n8n | grep webhook

# Webhook-Konfiguration in EspoCRM verifizieren
# Administration → Webhooks → URL und Event-Typen prüfen
```

**Lösung:**
- Webhook-URL muss vom EspoCRM-Container erreichbar sein
- Interne URL verwenden wenn beide Services im gleichen Docker-Netzwerk: `http://n8n:5678/webhook/...`
- Webhook in EspoCRM aktivieren: Administration → Webhooks
- Korrekten Entity-Typ setzen (Lead, Contact, Opportunity, etc.)
- Korrektes Event wählen (create, update, delete)
- Webhook mit "Test"-Button in EspoCRM testen

**Problem 3: E-Mail-Integration funktioniert nicht**

```bash
# E-Mail-Account-Konfiguration prüfen
docker exec espocrm cat data/.htaccess

# E-Mail-Sync-Logs ansehen
docker logs espocrm | grep -i "email\|imap\|smtp"

# SMTP-Verbindung testen
docker exec espocrm php command.php app:test-email DEINE_EMAIL

# Prüfen ob Mailpit E-Mails empfängt
curl http://localhost:8025/api/v1/messages
```

**Lösung:**
- Mailpit SMTP-Einstellungen: Host=`mailpit`, Port=`1025`, keine Auth
- Für Docker-Mailserver: Host=`mailserver`, Port=`587`, TLS aktiviert
- E-Mail-Account in Administration → Email Accounts prüfen
- Gruppen-Postfach-Konfiguration verifizieren
- Persönliche E-Mail-Accounts in Benutzereinstellungen aktivieren
- Spam-Ordner prüfen falls E-Mails nicht ankommen

**Problem 4: Performance-Probleme mit großen Datensätzen**

```bash
# Datenbankgröße prüfen
docker exec espocrm-db mysql -u espocrm -p -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = 'espocrm' ORDER BY (data_length + index_length) DESC;"

# Datenbanktabellen optimieren
docker exec espocrm-db mysql -u espocrm -p espocrm -e "OPTIMIZE TABLE lead, contact, account, opportunity;"

# Container-Ressourcen prüfen
docker stats espocrm --no-stream

# EspoCRM Cache leeren
docker exec espocrm rm -rf data/cache/*
docker compose restart espocrm
```

**Lösung:**
- Datenbank-Indizes für häufig abgefragte Felder hinzufügen
- Paginierung in API-Anfragen verwenden (`offset` und `maxSize` Parameter)
- Alte Datensätze archivieren (Administration → Jobs → geplante Bereinigung)
- PHP Memory Limit in docker-compose.yml erhöhen
- Filter verwenden statt alle Datensätze abzurufen
- Query-Caching in Administration → System → Settings aktivieren
- Datenbank-Optimierung in Betracht ziehen (OPTIMIZE TABLE monatlich ausführen)

### Ressourcen

- **Offizielle Dokumentation:** https://docs.espocrm.com/
- **API-Dokumentation:** https://docs.espocrm.com/development/api/
- **REST API Client:** https://docs.espocrm.com/development/api-client-php/
- **GitHub:** https://github.com/espocrm/espocrm
- **Community Forum:** https://forum.espocrm.com/
- **Extensions:** https://www.espocrm.com/extensions/
- **Workflow-Guide:** https://docs.espocrm.com/administration/workflows/
- **Admin-Guide:** https://docs.espocrm.com/administration/

### Best Practices

**Wann EspoCRM nutzen:**
- Etablierte Unternehmen die vollständige CRM-Funktionen benötigen
- E-Mail-Marketing und Kampagnenverwaltungs-Anforderungen
- Komplexe Workflow-Automatisierung mit BPM
- Erweiterte Berichterstattungs- und Analytics-Anforderungen
- Service-/Case-Management mit SLA-Tracking
- Multi-User-Teams mit rollenbasierten Berechtigungen
- Organisationen die umfangreiche Anpassungen benötigen

**Wann Twenty CRM stattdessen nutzen:**
- Startups die leichtgewichtige, moderne Oberfläche benötigen
- Projekte die GraphQL API erfordern
- Einfaches Sales-Pipeline-Management
- Notion-Style Workspace-Organisation
- Minimaler Ressourcenverbrauch als Priorität

**Multiple CRMs kombinieren:**
```javascript
// Best Practices für Multi-CRM-Strategie

// EspoCRM nutzen für:
- E-Mail-Kampagnen und Marketing-Automatisierung
- Komplexe Verkaufsprozesse mit mehreren Phasen
- Service-Case-Management
- Detaillierte Berichterstattung und Analytics
- Team-Zusammenarbeit mit Berechtigungen

// Twenty CRM nutzen für:
- Tägliche Operationen und schnelle Updates
- Moderne, schnelle Oberfläche für Field-Teams
- Custom-Field-Flexibilität
- GraphQL-basierte Integrationen

// Daten mit n8n synchronisieren:
- Bidirektionale Kontakt-Synchronisation
- Opportunity-Status-Updates
- Aktivitäts-Logging in beiden Systemen
- Einheitliches Reporting via Metabase
```

**API Best Practices:**
1. **Paginierung verwenden:** Immer `offset` und `maxSize` für große Datensätze verwenden
2. **Feld-Auswahl:** `select` Parameter nutzen um nur benötigte Felder abzurufen
3. **Filter:** `where` Bedingungen anwenden um Datentransfer zu reduzieren
4. **Batch-Operationen:** Datensätze in Batches von 50-100 verarbeiten
5. **Fehlerbehandlung:** Retry-Logik für API-Fehler implementieren
6. **Rate Limiting:** API-Limits respektieren (üblicherweise 100 Anfragen/Minute)
7. **Webhooks:** Webhooks statt Polling für Echtzeit-Updates verwenden
8. **Caching:** Häufig abgerufene Daten cachen (Benutzer, Enums, Einstellungen)
9. **Authentifizierung:** API-Keys verwenden, keine Passwörter für Integrationen
10. **Logging:** Alle API-Aufrufe für Debugging und Audit-Trails protokollieren
