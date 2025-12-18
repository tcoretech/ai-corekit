# 💼 Twenty CRM - Modernes CRM

### Was ist Twenty CRM?

Twenty CRM ist eine moderne, Open-Source Customer-Relationship-Management-Plattform mit Notion-ähnlicher Oberfläche. Es bietet eine leichtgewichtige, flexible Lösung perfekt für Startups und kleine Teams, die leistungsstarke GraphQL- und REST-APIs ohne die Komplexität traditioneller CRM-Systeme benötigen.

### Funktionen

- **Notion-ähnliche Oberfläche** - Intuitive, moderne UI mit anpassbaren Ansichten und Feldern
- **Leistungsstarke APIs** - Sowohl GraphQL- als auch REST-APIs für maximale Flexibilität
- **Kunden-Pipelines** - Visuelle Pipeline-Verwaltung für Vertrieb und Opportunities
- **Team-Zusammenarbeit** - Echtzeit-Kollaboration mit gemeinsamen Workspaces
- **Custom Fields** - Flexibles Datenmodell mit benutzerdefinierten Feldtypen
- **Leichtgewichtig & Schnell** - Minimaler Ressourcenverbrauch im Vergleich zu traditionellen CRMs
- **Open Source** - Selbst gehostet, datenschutzfokussiert, kein Vendor-Lock-in

### Erste Einrichtung

**Erster Login bei Twenty CRM:**

1. Navigiere zu `https://twenty.deinedomain.com`
2. Erstelle deinen ersten Workspace während der initialen Einrichtung
3. Konfiguriere Workspace-Einstellungen und passe Felder an
4. API-Key generieren:
   - Gehe zu Settings → Developers → API Keys
   - Klicke "Create New API Key"
   - Benenne ihn "n8n Integration"
   - Kopiere den Token für die Verwendung in n8n
5. Richte deine erste Pipeline und Custom Fields ein

### n8n Integration einrichten

**Twenty CRM Zugangsdaten in n8n erstellen:**

Twenty CRM hat keine native n8n Node. Verwende HTTP Request Nodes mit Bearer-Token-Authentifizierung.

1. In n8n, erstelle Zugangsdaten:
   - Typ: Header Auth
   - Name: Twenty CRM API
   - Header Name: `Authorization`
   - Header Wert: `Bearer DEIN_API_KEY_HIER`

**Interne URL für n8n:** `http://twenty-crm:3000`

**Basis-API-Endpunkte:**
- REST API: `http://twenty-crm:3000/rest/`
- GraphQL API: `http://twenty-crm:3000/graphql`

### Beispiel-Workflows

#### Beispiel 1: KI-Lead-Qualifizierungs-Pipeline

Leads automatisch mit KI qualifizieren und bewerten:

```javascript
// Lead-Scoring mit KI-Analyse automatisieren

// 1. Webhook Trigger - Neuen Lead von Website-Formular empfangen

// 2. HTTP Request Node - Lead in Twenty CRM erstellen
Methode: POST
URL: http://twenty-crm:3000/rest/companies
Authentication: Use Twenty CRM Credentials
Header:
  Content-Type: application/json
Body (JSON):
{
  "name": "{{$json.company_name}}",
  "domainName": "{{$json.website}}",
  "employees": "{{$json.company_size}}",
  "address": "{{$json.location}}"
}

// 3. OpenAI Node - Lead-Qualität analysieren
Operation: Message a Model
Modell: gpt-4o-mini
Nachrichten:
  System: "Du bist ein Lead-Qualifizierungs-Experte. Analysiere Leads und gib einen Score (1-10) mit Begründung."
  User: |
    Analysiere diesen Lead:
    Firma: {{$json.company_name}}
    Branche: {{$json.industry}}
    Größe: {{$json.company_size}}
    Budget: {{$json.budget_range}}
    Website: {{$json.website}}
    
    Gib Score und Begründung im JSON-Format:
    {
      "score": <nummer>,
      "reasoning": "<warum dieser Score>",
      "priority": "<Hoch/Normal/Niedrig>"
    }

// 4. Code Node - KI-Antwort parsen
const aiResponse = JSON.parse($input.first().json.message.content);
return {
  json: {
    companyId: $('Create Lead').item.json.id,
    score: aiResponse.score,
    reasoning: aiResponse.reasoning,
    priority: aiResponse.priority
  }
};

// 5. HTTP Request Node - Lead mit KI-Score aktualisieren
Methode: PATCH
URL: http://twenty-crm:3000/rest/companies/{{$json.companyId}}
Body (JSON):
{
  "customFields": {
    "leadScore": {{$json.score}},
    "aiAnalysis": "{{$json.reasoning}}",
    "priority": "{{$json.priority}}"
  }
}

// 6. IF Node - Prüfe ob hochwertiger Lead
Bedingung: {{$json.score}} >= 8

// Branch: Hochwertige Leads
// 7a. Slack Node - Verkaufsteam benachrichtigen
Kanal: #vertrieb-alerts
Nachricht: |
  🔥 **Hochwertiger Lead-Alarm!**
  
  Firma: {{$('Create Lead').json.name}}
  Score: {{$json.score}}/10
  Priorität: {{$json.priority}}
  
  KI-Analyse: {{$json.reasoning}}
  
  👉 Aktion erforderlich: Kontakt innerhalb von 24 Stunden

// 8a. Email Node - Personalisierte E-Mail an Vertriebsmitarbeiter
To: vertrieb@firma.com
Subject: Hochpriorisierter Lead: {{$('Create Lead').json.name}}
Body: Detaillierte Lead-Informationen mit KI-Einblicken

// Branch: Normale Leads
// 7b. HTTP Request - Zu Nurture-Kampagne hinzufügen
// 8b. Email - Automatisierte Willkommenssequenz senden
```

#### Beispiel 2: Kunden-Onboarding-Automatisierung

Kunden-Onboarding mit automatisierten Aufgaben optimieren:

```javascript
// Vollständiger Onboarding-Automatisierungs-Workflow

// 1. Twenty CRM Webhook - Bei gewonnener Opportunity
// Konfiguriere Webhook in Twenty CRM um auszulösen wenn Opportunity-Phase = "Gewonnen"

// 2. HTTP Request Node - Kundendetails abrufen
Methode: GET
URL: http://twenty-crm:3000/rest/companies/{{$json.companyId}}
Authentication: Use Twenty CRM Credentials

// 3. Invoice Ninja Node - Kundenkonto erstellen
Operation: Create Customer
Name: {{$json.name}}
Email: {{$json.email}}
Address: {{$json.address}}
Currency: EUR

// 4. Cal.com HTTP Request - Onboarding-Anruf planen
Methode: POST
URL: http://cal:3000/api/bookings
Body (JSON):
{
  "eventTypeId": 123, // Deine Onboarding-Anruf Event-Type ID
  "start": "{{$now.plus(2, 'days').toISO()}}",
  "responses": {
    "name": "{{$json.name}}",
    "email": "{{$json.email}}",
    "notes": "Kunden-Onboarding-Anruf - Opportunity gewonnen"
  }
}

// 5. HTTP Request Node - Twenty CRM Pipeline-Phase aktualisieren
Methode: PATCH
URL: http://twenty-crm:3000/rest/opportunities/{{$json.opportunityId}}
Body (JSON):
{
  "stage": "Onboarding",
  "customFields": {
    "onboardingStarted": "{{$now.toISO()}}",
    "invoiceCreated": true,
    "meetingScheduled": "{{$json.booking_time}}"
  }
}

// 6. Vikunja Node - Onboarding-Aufgaben erstellen
Operation: Create Task
Project: Kunden-Onboarding
Title: "Onboarding: {{$json.name}}"
Description: |
  - Willkommens-E-Mail senden
  - Zugangsdaten bereitstellen
  - Schulungssession planen
  - Account Manager zuweisen
Due Datum: {{$now.plus(7, 'days').toISO()}}

// 7. Email Node - Willkommenspaket senden
To: {{$json.email}}
Subject: Willkommen bei {{$env.COMPANY_NAME}}! 🎉
Body: |
  Hallo {{$json.name}},
  
  Willkommen an Bord! Wir freuen uns, Sie als Kunden zu haben.
  
  Ihr Onboarding-Anruf ist geplant für {{$json.booking_time}}.
  
  In der Zwischenzeit, hier ist was Sie erwarten können:
  ✅ Account-Setup (abgeschlossen)
  ✅ Willkommenspaket (angehängt)
  📅 Onboarding-Anruf geplant
  📚 Schulungsmaterialien (kommen bald)
  
  Ihr dedizierter Account Manager wird sich in Kürze melden.
  
  Beste Grüße,
  Das Team

Anhänge: Willkommenspaket PDF, Getting-Started-Guide

// 8. Slack Notification - Internes Team
Kanal: #kundenerfolg
Nachricht: |
  🎉 Neuer Kunde onboardet!
  
  Firma: {{$json.name}}
  E-Mail: {{$json.email}}
  Onboarding-Anruf: {{$json.booking_time}}
  
  ✅ Rechnung erstellt
  ✅ Willkommens-E-Mail gesendet
  ✅ Aufgaben in Vikunja erstellt
```

#### Beispiel 3: GraphQL Erweiterte Queries

Nutze Twentys leistungsstarke GraphQL API für komplexe Operationen:

```javascript
// Wöchentlicher Sales-Pipeline-Report mit Metriken

// 1. Schedule Trigger - Wöchentlich am Montag um 9 Uhr

// 2. HTTP Request Node - GraphQL Query für Pipeline-Metriken
Methode: POST
URL: http://twenty-crm:3000/graphql
Authentication: Use Twenty CRM Credentials
Header:
  Content-Type: application/json
Body (JSON):
{
  "query": "query GetPipelineMetrics { opportunities(where: { createdAt: { gte: \"{{$now.minus(7, 'days').toISO()}}\" } }) { edges { node { id name amount stage probability company { name domainName } } } } }"
}

// 3. Code Node - Metriken berechnen
const opportunities = $input.first().json.data.opportunities.edges;

// Schlüsselmetriken berechnen
const metrics = {
  total_opportunities: opportunities.length,
  total_value: opportunities.reduce((sum, opp) => sum + opp.node.amount, 0),
  weighted_pipeline: opportunities.reduce((sum, opp) => 
    sum + (opp.node.amount * opp.node.probability / 100), 0),
  by_stage: {},
  top_deals: []
};

// Nach Phase gruppieren
opportunities.forEach(opp => {
  const stage = opp.node.stage;
  if (!metrics.by_stage[stage]) {
    metrics.by_stage[stage] = { count: 0, value: 0 };
  }
  metrics.by_stage[stage].count++;
  metrics.by_stage[stage].value += opp.node.amount;
});

// Top 5 Deals ermitteln
metrics.top_deals = opportunities
  .map(opp => opp.node)
  .sort((a, b) => b.amount - a.amount)
  .slice(0, 5);

return { json: metrics };

// 4. Metabase HTTP Request - Dashboard aktualisieren
Methode: POST
URL: http://metabase:3000/api/card/{{$env.SALES_DASHBOARD_ID}}/query
Body: Berechnete Metriken senden

// 5. Google Sheets Node - In Spreadsheet exportieren
Operation: Append
Spreadsheet: Wöchentliche Verkaufsberichte
Sheet: {{$now.format('YYYY-MM')}}
Daten: Pipeline-Metriken

// 6. Email Node - Report an Stakeholder senden
To: geschaeftsfuehrung@firma.com, vertriebsteam@firma.com
Subject: Wöchentlicher Sales-Pipeline-Report - {{$now.format('D. MMMM YYYY')}}
Body: |
  📊 Wöchentlicher Sales-Pipeline-Report
  
  **Schlüsselmetriken (Letzte 7 Tage):**
  • Gesamt-Opportunities: {{$json.total_opportunities}}
  • Gesamt-Pipeline-Wert: €{{$json.total_value.toLocaleString()}}
  • Gewichtete Prognose: €{{$json.weighted_pipeline.toLocaleString()}}
  
  **Nach Phase:**
  {{#each $json.by_stage}}
  • {{@key}}: {{this.count}} Deals (€{{this.value.toLocaleString()}})
  {{/each}}
  
  **Top 5 Deals:**
  {{#each $json.top_deals}}
  {{@index + 1}}. {{this.company.name}} - €{{this.amount.toLocaleString()}} ({{this.probability}}%)
  {{/each}}
  
  Vollständiges Dashboard ansehen: https://analytics.deinedomain.com

Anhänge: Generierter PDF-Report
```

#### Beispiel 4: CRM-übergreifende Datensynchronisation

Twenty CRM mit anderen CRM-Systemen für einheitliche Daten synchronisieren:

```javascript
// Kontakte zwischen Twenty CRM und EspoCRM synchronisieren

// 1. Schedule Trigger - Alle 15 Minuten

// 2. HTTP Request - Kürzlich aktualisierte Kontakte von Twenty abrufen
Methode: POST
URL: http://twenty-crm:3000/graphql
Body (JSON):
{
  "query": "query GetRecentContacts { people(where: { updatedAt: { gte: \"{{$now.minus(15, 'minutes').toISO()}}\" } }) { edges { node { id firstName lastName email phone company { id name } customFields } } } }"
}

// 3. Loop Over Items - Jeden Kontakt verarbeiten

// 4. HTTP Request - Prüfen ob Kontakt in EspoCRM existiert
Methode: GET
URL: http://espocrm:80/api/v1/Contact
Query Parameter:
  where: [{"type":"equals","attribute":"emailAddress","value":"{{$json.email}}"}]

// 5. IF Node - Kontakt existiert?

// Branch: Ja - Existierenden aktualisieren
// 6a. HTTP Request - In EspoCRM aktualisieren
Methode: PUT
URL: http://espocrm:80/api/v1/Contact/{{$json.espocrm_id}}
Body: Aktualisierte Kontaktdaten

// Branch: Nein - Neu erstellen
// 6b. HTTP Request - In EspoCRM erstellen
Methode: POST
URL: http://espocrm:80/api/v1/Contact
Body: Neue Kontaktdaten

// 7. HTTP Request - Twenty mit Sync-Status aktualisieren
Methode: PATCH
URL: http://twenty-crm:3000/rest/people/{{$json.twenty_id}}
Body:
{
  "customFields": {
    "lastSyncedAt": "{{$now.toISO()}}",
    "syncStatus": "success",
    "espocrmId": "{{$json.espocrm_id}}"
  }
}
```

### Problembehandlung

**Problem 1: API-Authentifizierung schlägt fehl**

```bash
# Prüfen ob Twenty CRM läuft
docker ps | grep twenty

# Twenty CRM Logs anzeigen
docker logs twenty-crm

# API-Key in Twenty CRM Einstellungen verifizieren
# Gehe zu Settings → Developers → API Keys

# API-Verbindung testen
curl -H "Authorization: Bearer DEIN_API_KEY" \
  http://localhost:3000/rest/companies
```

**Lösung:**
- API-Key in Twenty CRM Einstellungen neu generieren
- Sicherstellen dass Bearer-Token-Format korrekt ist: `Bearer DEIN_KEY`
- Firewall-Regeln prüfen, dass internes Docker-Netzwerk erlaubt ist
- `TWENTY_API_KEY` in n8n Zugangsdaten verifizieren

**Problem 2: GraphQL Query Fehler**

```bash
# GraphQL Endpunkt testen
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer DEIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ opportunities { edges { node { id name } } } }"}'

# GraphQL Schema prüfen
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer DEIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

**Lösung:**
- GraphQL Syntax im GraphQL Playground validieren
- Prüfen dass Feldnamen mit Twenty CRM Schema übereinstimmen
- Introspection-Query verwenden um verfügbare Felder zu erkunden
- Korrektes Escaping von Anführungszeichen in n8n JSON sicherstellen

**Problem 3: Webhook wird nicht ausgelöst**

```bash
# Webhook-Konfiguration in Twenty CRM prüfen
# Settings → Integrations → Webhooks

# Webhook manuell testen
curl -X POST https://dein-n8n.com/webhook/twenty-crm \
  -H "Content-Type: application/json" \
  -d '{"companyId": "test123", "event": "opportunity.won"}'

# n8n Webhook-Logs prüfen
docker logs n8n | grep webhook
```

**Lösung:**
- Verifizieren dass Webhook-URL vom Twenty CRM Container erreichbar ist
- Interne URL verwenden wenn beide Services im gleichen Docker-Netzwerk sind
- Webhook-Secret/Authentifizierung prüfen falls konfiguriert
- Webhook-Logging in Twenty CRM für Debugging aktivieren

**Problem 4: Custom Fields werden nicht synchronisiert**

**Diagnose:**
```bash
# Feld-Schema von Twenty abrufen
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer DEIN_API_KEY" \
  -d '{"query": "{ __type(name: \"Company\") { fields { name type { name } } } }"}'
```

**Lösung:**
- Custom Fields müssen zuerst in Twenty CRM erstellt werden
- Exakte Feldnamen aus Twenty CRM Schema verwenden
- Feldtypen müssen übereinstimmen (string, number, date, etc.)
- Berechtigungen für API-Key zum Ändern von Custom Fields prüfen

### Ressourcen

- **Offizielle Dokumentation:** https://twenty.com/developers
- **GraphQL API Docs:** https://twenty.com/developers/graphql-api
- **REST API Docs:** https://twenty.com/developers/rest-api
- **GitHub:** https://github.com/twentyhq/twenty
- **Community Forum:** https://twenty.com/community
- **API Playground:** `https://twenty.deinedomain.com/graphql` (wenn eingeloggt)

### Best Practices

**Wann Twenty CRM nutzen:**
- Startups und kleine Teams die Flexibilität benötigen
- Projekte die Custom Fields und Views erfordern
- GraphQL API-Integrations-Anforderungen
- Notion-Style Workspace-Organisation
- Leichtgewichtiger Ressourcenverbrauch ist Priorität

**Kombination mit anderen CRMs:**
- Twenty für tägliche Operationen und Team-Zusammenarbeit nutzen
- EspoCRM oder Odoo für E-Mail-Kampagnen und komplexe Automatisierung nutzen
- Daten zwischen Systemen mit n8n für einheitliche Sicht synchronisieren
- Einheitliche Dashboards in Metabase erstellen die aus beiden Systemen ziehen

**Datenmodell-Tipps:**
- Mit Basis-Feldern starten, Custom Fields nach Bedarf hinzufügen
- Beziehungen verwenden um Firmen, Personen und Opportunities zu verbinden
- Custom Views für verschiedene Teammitglieder erstellen
- Tags für flexible Kategorisierung nutzen
- Regelmäßige Backups über API-Exporte
