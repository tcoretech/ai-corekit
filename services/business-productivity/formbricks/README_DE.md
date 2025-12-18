# 📝 Formbricks - Umfrageplattform

### Was ist Formbricks?

Formbricks ist eine Open-Source, privatsphäreorientierte Umfrageplattform, die es dir ermöglicht, Benutzer-Feedback zu sammeln, Zufriedenheit zu messen und Erkenntnisse zu gewinnen, ohne die Datensicherheit zu gefährden. Sie ist DSGVO-konform, selbst gehostet und für Produktteams konzipiert, die leistungsstarke Umfragefunktionen mit vollständiger Datenkontrolle benötigen. Im Gegensatz zu Cloud-Diensten wie Typeform oder SurveyMonkey gibt dir Formbricks vollständiges Eigentum an deinen Daten und bietet gleichzeitig erweiterte Funktionen wie Mehrsprachenunterstützung, Logik-Verzweigung und Webhook-Integrationen.

### Funktionen

- **Privatsphäre zuerst:** DSGVO-konform, selbst gehostet, vollständiges Dateneigentum
- **Mehrsprachen-Unterstützung:** Erstelle Umfragen in 20+ Sprachen
- **Logik-Verzweigung:** Dynamische Umfrageabläufe basierend auf Antworten
- **Vielfältige Fragetypen:** NPS, CSAT, Multiple Choice, Text, Bewertung und mehr
- **In-App-Umfragen:** JavaScript SDK für nahtlose Integration
- **E-Mail-Umfragen:** Versende Umfragen per E-Mail mit Tracking
- **Link-Umfragen:** Teile eigenständige Umfrage-Links
- **Webhooks:** Echtzeit-Benachrichtigungen an n8n für Automatisierung
- **Team-Zusammenarbeit:** Multi-User-Zugriff mit rollenbasierten Berechtigungen
- **Custom Branding:** White-Label-Umfragen mit deiner Markenidentität
- **Erweiterte Analysen:** Antwortquoten, Abschlusszeiten, Stimmungsanalyse

### Erste Einrichtung

**Erster Login bei Formbricks:**

1. Navigiere zu `https://forms.deinedomain.com`
2. Klicke auf "Sign up" um das erste Admin-Konto zu erstellen
3. Der erste Benutzer wird automatisch zum Organisations-Eigentümer
4. Schließe die Organisations-Einrichtung ab (Name, Branding)
5. Generiere API-Schlüssel:
   - Gehe zu Einstellungen → API Keys
   - Klicke auf "Create New API Key"
   - Benenne ihn "n8n Integration"
   - Kopiere den Schlüssel für die Verwendung in n8n

**Erstelle deine erste Umfrage:**

1. Klicke auf "Create Survey" im Dashboard
2. Wähle den Umfragetyp:
   - **NPS Survey:** Net Promoter Score (0-10 Skala)
   - **CSAT Survey:** Kundenzufriedenheit
   - **Product Feedback:** Benutzerdefinierte Fragen
   - **Lead Qualification:** Formular mit Bewertung
3. Füge Fragen hinzu und konfiguriere die Logik
4. Richte Trigger ein (beim Laden der Seite, beim Verlassen, nach Zeit)
5. Konfiguriere Webhook für n8n-Integration
6. Veröffentliche und erhalte Embed-Code oder Link

### n8n Integration einrichten

**Methode 1: Webhooks (Empfohlen)**

Konfiguriere Webhooks direkt in Formbricks für Echtzeit-Antwortverarbeitung:

1. In Formbricks: Survey → Settings → Webhooks
2. Webhook-URL hinzufügen: `https://n8n.deinedomain.com/webhook/formbricks-response`
3. Trigger auswählen:
   - Response Created
   - Response Updated
   - Response Completed
4. Webhook-Konfiguration speichern

**Webhook Trigger in n8n erstellen:**

```javascript
// Webhook Trigger Node in n8n
Webhook Pfad: /formbricks-response
HTTP Methode: POST
Response Mode: On Received
Authentication: None (oder füge custom header für Sicherheit hinzu)

// Formbricks sendet Daten in diesem Format:
{
  "event": "responseCreated",
  "data": {
    "surveyId": "clxxx123",
    "responseId": "clyyy456",
    "userId": "user@example.com",
    "responses": {
      "q1": 8,  // NPS score
      "q2": "Great product!",  // Text feedback
      "q3": ["feature1", "feature2"]  // Multi-select
    },
    "metadata": {
      "userAgent": "Mozilla/5.0...",
      "language": "en",
      "url": "https://example.com/product"
    },
    "createdAt": "2025-10-18T10:30:00Z"
  }
}
```

**Methode 2: API-Integration**

Für programmatische Umfragenverwaltung und Antwortabruf:

```javascript
// HTTP Request Node - Umfrage-Antworten abrufen
Methode: GET
URL: https://forms.deinedomain.com/api/v1/surveys/{surveyId}/responses
Authentication: Header Auth
  Header: x-api-key
  Wert: DEIN_FORMBRICKS_API_KEY
Query Parameter:
  limit: 100
  offset: 0
```

**Interne URL für n8n:** `http://formbricks:3000`

### Beispiel-Workflows

#### Beispiel 1: NPS Score Automatisierung

Reagiere sofort auf Kunden-Feedback:

```javascript
// Automatisiere Follow-ups basierend auf NPS-Scores

// 1. Webhook Trigger - Formbricks Umfrage-Antwort
// Konfiguriert in Formbricks: Survey → Settings → Webhooks
// URL: https://n8n.deinedomain.com/webhook/nps-response

// 2. Code Node - Antwort parsen und kategorisieren
const npsScore = $json.data.responses.nps_score;
const feedback = $json.data.responses.feedback || '';
const email = $json.data.userId;

// Kategorisiere basierend auf NPS-Methodik
let category, priority, action;

if (npsScore >= 9) {
  category = 'Promoter';
  priority = 'Mittel';
  action = 'Testimonial/Empfehlung anfordern';
} else if (npsScore >= 7) {
  category = 'Passiv';
  priority = 'Niedrig';
  action = 'Auf Verbesserungsmöglichkeiten achten';
} else {
  category = 'Detractor';
  priority = 'Hoch';
  action = 'Sofortiges Follow-up erforderlich';
}

return [{
  json: {
    score: npsScore,
    category: category,
    priority: priority,
    action: action,
    feedback: feedback,
    email: email,
    timestamp: $json.data.createdAt
  }
}];

// 3. Switch Node - Routing basierend auf Kategorie

// Branch 1 - Detractors (Score 0-6)
// → Dringendes Support-Ticket erstellen
// → Customer-Success-Team benachrichtigen
// → Personalisierte Entschuldigungs-E-Mail senden

// HTTP Request - Ticket im Support-System erstellen
Methode: POST
URL: http://baserow:80/api/database/rows/table/SUPPORT_TICKETS/
Body (JSON):
{
  "Customer Email": "{{$json.email}}",
  "Priority": "Dringend",
  "Type": "NPS Detractor",
  "Score": {{$json.score}},
  "Feedback": "{{$json.feedback}}",
  "Status": "Offen",
  "Created": "{{$now.toISO()}}"
}

// Slack Alert
Kanal: #customer-success
Nachricht: |
  ⚠️ **DRINGEND: NPS Detractor Alarm**
  
  Score: {{$json.score}}/10
  Kunde: {{$json.email}}
  Feedback: {{$json.feedback}}
  
  Maßnahme innerhalb von 24 Stunden erforderlich!

// Send Email - Persönliches Follow-up
To: {{$json.email}}
Subject: Es tut uns leid - Ihr Feedback ist uns wichtig
Body: |
  Hallo,
  
  Wir haben bemerkt, dass Sie uns {{$json.score}}/10 in unserer Umfrage gegeben haben.
  Es tut uns aufrichtig leid, dass wir Ihre Erwartungen nicht erfüllt haben.
  
  Ihr Feedback: "{{$json.feedback}}"
  
  Ein Mitglied unseres Teams wird sich innerhalb von 24 Stunden bei Ihnen melden, um dies in Ordnung zu bringen.

// Branch 2 - Passives (Score 7-8)
// → Zu Nurture-Kampagne hinzufügen
// → Im CRM protokollieren

// HTTP Request - CRM aktualisieren
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/CUSTOMERS/records
Body (JSON):
{
  "Email": "{{$json.email}}",
  "NPS Score": {{$json.score}},
  "Last Survey": "{{$now.toISO()}}",
  "Segment": "Passiv",
  "Notes": "{{$json.feedback}}"
}

// Branch 3 - Promoters (Score 9-10)
// → Testimonial/Bewertung anfordern
// → Einladung zum Empfehlungsprogramm

// Send Email - Testimonial anfordern
To: {{$json.email}}
Subject: Vielen Dank! Würden Sie Ihre Erfahrung teilen?
Body: |
  Hallo,
  
  Vielen Dank für die fantastische Bewertung von {{$json.score}}/10! 🎉
  
  Ihr Feedback: "{{$json.feedback}}"
  
  Wären Sie bereit:
  • Eine Bewertung auf G2/Capterra zu hinterlassen?
  • Ihre Erfahrung als Testimonial zu teilen?
  • Einen Kollegen zu empfehlen (20% Rabatt)?
  
  Hier klicken: [Testimonial-Formular]

// 4. Baserow/NocoDB Node - Alle Antworten protokollieren
Operation: Create
Table: NPS_History
Fields:
  Email: {{$json.email}}
  Score: {{$json.score}}
  Category: {{$json.category}}
  Feedback: {{$json.feedback}}
  Action Taken: {{$json.action}}
  Timestamp: {{$now.toISO()}}
```

#### Beispiel 2: Formular zu CRM Pipeline

Wandle Umfrage-Antworten in qualifizierte Leads um:

```javascript
// Automatisiere Lead-Qualifizierung und CRM-Updates

// 1. Webhook Trigger - Formbricks Lead-Formular-Einreichung

// 2. Code Node - Lead parsen und bewerten
const formData = $json.data.responses;

// Lead-Score basierend auf Antworten berechnen
let leadScore = 0;

// Unternehmensgröße bewerten
const companySize = formData.company_size;
if (companySize === '50-200') leadScore += 20;
if (companySize === '200-1000') leadScore += 30;
if (companySize === '1000+') leadScore += 40;

// Budget bewerten
const budget = formData.annual_budget;
if (budget === '10k-50k') leadScore += 15;
if (budget === '50k-100k') leadScore += 25;
if (budget === '100k+') leadScore += 35;

// Zeitplan bewerten
const timeline = formData.implementation_timeline;
if (timeline === 'Immediate') leadScore += 30;
if (timeline === '1-3 months') leadScore += 20;
if (timeline === '3-6 months') leadScore += 10;

// Interessensniveau
const interest = formData.interest_level;
if (interest === 'Very interested') leadScore += 25;
if (interest === 'Interested') leadScore += 15;

// Lead-Qualität bestimmen
let leadQuality;
if (leadScore >= 80) leadQuality = 'Heiß';
else if (leadScore >= 50) leadQuality = 'Warm';
else leadQuality = 'Kalt';

return [{
  json: {
    name: formData.name,
    email: formData.email,
    company: formData.company,
    phone: formData.phone || '',
    companySize: companySize,
    budget: budget,
    timeline: timeline,
    interests: formData.interested_features || [],
    leadScore: leadScore,
    leadQuality: leadQuality,
    source: 'Formbricks Lead-Formular',
    submittedAt: $json.data.createdAt
  }
}];

// 3. Switch Node - Routing basierend auf Lead-Qualität

// Branch 1 - Heiße Leads (Score >= 80)
// → Sofort im CRM erstellen
// → Sales-Team benachrichtigen
// → Follow-up-Anruf planen

// HTTP Request - Im CRM erstellen (Odoo/Twenty/EspoCRM)
Methode: POST
URL: http://odoo:8069/api/v1/leads
Body (JSON):
{
  "name": "{{$json.name}}",
  "email": "{{$json.email}}",
  "company": "{{$json.company}}",
  "phone": "{{$json.phone}}",
  "priority": "3",  // Hohe Priorität
  "tag_ids": ["Heißer Lead", "Formbricks"],
  "description": |
    Lead-Score: {{$json.leadScore}}
    Unternehmensgröße: {{$json.companySize}}
    Budget: {{$json.budget}}
    Zeitplan: {{$json.timeline}}
    Interessen: {{$json.interests.join(', ')}}
}

// Slack Notification - Sofortige Benachrichtigung
Kanal: #sales
Nachricht: |
  🔥 **HEISSER LEAD ALARM** 🔥
  
  Name: {{$json.name}}
  Unternehmen: {{$json.company}}
  E-Mail: {{$json.email}}
  Score: {{$json.leadScore}}/100
  
  Zeitplan: {{$json.timeline}}
  Budget: {{$json.budget}}
  
  [Im CRM anzeigen](https://odoo.deinedomain.com/leads/{{$json.id}})

// Cal.com Node - Discovery-Call automatisch planen
// (Falls Cal.com installiert ist)
Methode: POST
URL: http://calcom:3000/api/v1/bookings
Body (JSON):
{
  "eventTypeId": DEIN_EVENT_TYPE_ID,
  "name": "{{$json.name}}",
  "email": "{{$json.email}}",
  "notes": "Heißer Lead von Formbricks - Score: {{$json.leadScore}}",
  "rescheduleUid": null
}

// Branch 2 - Warme Leads (Score 50-79)
// → Zu Nurture-Kampagne hinzufügen
// → Info-Paket senden

// HTTP Request - Zu E-Mail-Kampagne hinzufügen (Mautic)
Methode: POST
URL: http://mautic_web/api/contacts/new
Body (JSON):
{
  "firstname": "{{$json.name.split(' ')[0]}}",
  "lastname": "{{$json.name.split(' ')[1]}}",
  "email": "{{$json.email}}",
  "company": "{{$json.company}}",
  "tags": ["Warmer Lead", "Formbricks", "Nurture-Kampagne"]
}

// Send Email - Info-Paket
To: {{$json.email}}
Subject: Hier sind die angeforderten Informationen
Body: |
  Hallo {{$json.name}},
  
  Danke für Ihr Interesse! Basierend auf Ihren Antworten finden Sie hier einige Ressourcen:
  
  • [Produkt-Demo-Video]
  • [Fallstudie: Ähnliches Unternehmen]
  • [Preisleitfaden]
  • [Implementierungs-Zeitplan]
  
  Ich werde mich in ein paar Tagen melden. In der Zwischenzeit können Sie gerne einen Termin buchen:
  [Demo planen]

// Branch 3 - Kalte Leads (Score < 50)
// → Zu langfristiger Nurture hinzufügen
// → Bildungsinhalte senden

// HTTP Request - Zur Datenbank für zukünftige Nurture hinzufügen
Methode: POST
URL: http://baserow:80/api/database/rows/table/LEADS_DATABASE/
Body (JSON):
{
  "Name": "{{$json.name}}",
  "Email": "{{$json.email}}",
  "Company": "{{$json.company}}",
  "Score": {{$json.leadScore}},
  "Quality": "Kalt",
  "Source": "Formbricks",
  "Status": "Nurture",
  "Created": "{{$now.toISO()}}"
}

// 4. Final Node - In Analytik protokollieren
// Conversion-Raten und Lead-Qualitäts-Metriken tracken
```

#### Beispiel 3: Kunden-Feedback-Schleife

Sammle, analysiere und reagiere auf Produkt-Feedback:

```javascript
// Automatisierter Produkt-Feedback-Workflow

// 1. Webhook Trigger - Produkt-Feedback-Umfrage-Antwort

// 2. Code Node - Feedback-Sentiment analysieren
const feedback = $json.data.responses.feedback_text;
const satisfaction = $json.data.responses.satisfaction_score;
const feature = $json.data.responses.requested_feature;

// Einfache Sentiment-Analyse (in Produktion AI verwenden)
const negativeKeywords = ['bug', 'broken', 'problem', 'issue', 'frustrated', 'slow'];
const positiveKeywords = ['love', 'great', 'awesome', 'excellent', 'perfect', 'helpful'];

let sentiment = 'neutral';
const lowerFeedback = feedback.toLowerCase();

if (negativeKeywords.some(word => lowerFeedback.includes(word))) {
  sentiment = 'negative';
} else if (positiveKeywords.some(word => lowerFeedback.includes(word))) {
  sentiment = 'positive';
}

return [{
  json: {
    email: $json.data.userId,
    feedback: feedback,
    satisfaction: satisfaction,
    requestedFeature: feature || 'Keine',
    sentiment: sentiment,
    needsAntwort: sentiment === 'negative' || satisfaction <= 2,
    timestamp: $json.data.createdAt
  }
}];

// 3. IF Node - Prüfe ob Antwort erforderlich
Bedingung: {{$json.needsResponse}} === true

// IF JA - Negatives Feedback oder niedrige Zufriedenheit:

// HTTP Request - Ticket in Vikunja/Leantime erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "Kunden-Feedback-Antwort: {{$json.email}}",
  "description": |
    Zufriedenheit: {{$json.satisfaction}}/5
    Sentiment: {{$json.sentiment}}
    Feedback: {{$json.feedback}}
    Angefragte Funktion: {{$json.requestedFeature}}
  "priority": 3,
  "labels": ["kunden-feedback", "dringend"],
  "due_date": "{{$now.plus({days: 2}).toISO()}}"
}

// Send Email - Persönliche Antwort
To: {{$json.email}}
Subject: Vielen Dank für Ihr Feedback
Body: |
  Hallo,
  
  Vielen Dank, dass Sie sich die Zeit genommen haben, uns Ihr Feedback mitzuteilen.
  
  Ihr Feedback: "{{$json.feedback}}"
  
  Wir nehmen jedes Feedback ernst und arbeiten daran, Ihre Anliegen zu bearbeiten.
  Ein Teammitglied wird sich innerhalb von 48 Stunden bei Ihnen melden.

// IF NEIN - Positives Feedback oder hohe Zufriedenheit:

// HTTP Request - In Feature-Request-Datenbank speichern
Methode: POST
URL: http://nocodb:8080/api/v2/tables/FEATURE_REQUESTS/records
Body (JSON):
{
  "Customer Email": "{{$json.email}}",
  "Feedback": "{{$json.feedback}}",
  "Satisfaction": {{$json.satisfaction}},
  "Requested Feature": "{{$json.requestedFeature}}",
  "Sentiment": "{{$json.sentiment}}",
  "Status": "Geprüft",
  "Created": "{{$now.toISO()}}"
}

// 4. Immer - In Analytik-Datenbank speichern
Methode: POST
URL: http://baserow:80/api/database/rows/table/FEEDBACK_ANALYTICS/
Body (JSON):
{
  "Date": "{{$now.toISODate()}}",
  "Email": "{{$json.email}}",
  "Score": {{$json.satisfaction}},
  "Sentiment": "{{$json.sentiment}}",
  "Feedback": "{{$json.feedback}}",
  "Feature Request": "{{$json.requestedFeature}}",
  "Response Required": {{$json.needsResponse}},
  "Timestamp": "{{$now.toISO()}}"
}
```

### Umfragetypen & Anwendungsfälle

**NPS-Umfragen (Net Promoter Score):**
- Kundenzufriedenheit und -loyalität messen
- Promoters, Passive und Detractors identifizieren
- Zufriedenheitstrends über Zeit verfolgen
- Follow-ups basierend auf Score automatisieren

**CSAT-Umfragen (Kundenzufriedenheit):**
- Post-Interaktions-Feedback (Support, Sales)
- Produkt-/Feature-Zufriedenheit
- Service-Qualitätsmessung
- Sofortige Problem-Erkennung

**Lead-Qualifizierungs-Formulare:**
- Kontaktinformationen erfassen
- Leads basierend auf Antworten bewerten
- An passenden Sales-Rep weiterleiten
- Nurture-Kampagnen auslösen

**Produkt-Feedback:**
- Feature-Anfragen und Vorschläge
- Bug-Reports und Probleme
- Benutzer-Erfahrungs-Einblicke
- Beta-Testing-Feedback

**Mitarbeiter-Pulse-Umfragen:**
- Team-Zufriedenheits-Monitoring
- Arbeitsplatzkultur-Bewertung
- Anonyme Feedback-Sammlung
- Engagement-Tracking

**Marktforschung:**
- Kundenpräferenz-Studien
- Produkt-Markt-Fit-Validierung
- Wettbewerbsanalyse
- Pricing-Forschung

### Formbricks-Funktionen für Automatisierung

**Umfrage-Trigger:**
- **Bei Seitenaufruf:** Umfrage anzeigen, wenn bestimmte Seite lädt
- **Bei Exit Intent:** Benutzer abfangen, bevor sie die Seite verlassen
- **Nach Zeit:** Nach X Sekunden auf der Seite anzeigen
- **Bei Scroll:** Bei bestimmter Scroll-Tiefe auslösen
- **Bei Klick:** Anzeigen, wenn Benutzer Element anklickt
- **Bei Custom Event:** JavaScript-ausgelöste Umfragen

**Logik-Verzweigung:**
- Fragen basierend auf vorherigen Antworten überspringen
- Fragen bedingt ein-/ausblenden
- Multi-Pfad-Umfrageabläufe
- Personalisierte Umfrage-Erfahrungen

**Mehrsprachigkeit:**
- Umfragen in 20+ Sprachen erstellen
- Automatische Benutzersprachen-Erkennung
- Manuelle Sprachauswahl
- Übersetzte Antwortdaten

**Antwort-Aktionen:**
- Webhooks zu n8n (Echtzeit)
- E-Mail-Benachrichtigungen
- Slack/Discord-Alerts
- Custom JavaScript-Callbacks

### Tipps für Formbricks + n8n Integration

1. **Webhooks verwenden:** Konfiguriere "Response Completed" Webhooks für Echtzeit-Verarbeitung
2. **Interne URL:** Nutze `http://formbricks:3000` von n8n für API-Aufrufe
3. **Webhooks absichern:** Füge Custom Headers für Webhook-Authentifizierung hinzu
4. **Antwort-Filterung:** Nutze n8n IF Nodes um Antworten vor der Verarbeitung zu filtern
5. **Fehlerbehandlung:** Füge Try/Catch Nodes für resiliente Workflows hinzu
6. **Rate Limiting:** Beachte API-Rate-Limits (100 Anfragen/Minute)
7. **Datenschutz:** Stelle DSGVO-Konformität in Datenverarbeitungs-Workflows sicher
8. **Testing:** Nutze Formbricks Preview-Modus um Webhooks vor dem Go-Live zu testen
9. **Analytics:** Speichere alle Antworten in einer Datenbank für langfristige Analyse
10. **Multi-Survey:** Nutze Survey IDs um verschiedene Umfragen zu verschiedenen Workflows zu routen

### Fehlerbehebung

#### Webhooks werden nicht ausgelöst

```bash
# 1. Formbricks Webhook-Konfiguration prüfen
# Survey → Settings → Webhooks → URL und Status verifizieren

# 2. Webhook manuell testen
curl -X POST https://n8n.deinedomain.com/webhook/formbricks-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# 3. Formbricks-Logs prüfen
docker logs formbricks --tail 100 | grep webhook

# 4. n8n Webhook aktiv verifizieren
# n8n UI → Workflows → Webhook Trigger aktiviert prüfen
```

#### Umfrage wird nicht angezeigt

```bash
# 1. JavaScript SDK-Installation prüfen
# SDK geladen in Browser-Konsole verifizieren:
# window.formbricks

# 2. Umfrage-Trigger prüfen
# Formbricks UI → Survey → Triggers → Bedingungen verifizieren

# 3. Mit direktem Link testen
# Nutze den direkten Umfrage-Link um Funktionalität zu testen

# 4. Browser-Cache leeren
# Umfrage-Code könnte gecacht sein
```

#### API-Authentifizierungs-Fehler

```bash
# 1. API-Schlüssel korrekt verifizieren
grep FORMBRICKS_API_KEY .env

# 2. API-Schlüssel testen
curl -H "x-api-key: DEIN_KEY" \
  https://forms.deinedomain.com/api/v1/surveys

# 3. API-Schlüssel bei Bedarf neu generieren
# Formbricks UI → Settings → API Keys → Create New

# 4. API-Schlüssel-Berechtigungen prüfen
# Sicherstellen, dass Schlüssel erforderliche Scopes hat
```

#### Datenbank-Verbindungsprobleme

```bash
# 1. Formbricks Container-Status prüfen
docker ps | grep formbricks

# 2. Datenbankverbindung prüfen
docker logs formbricks --tail 50 | grep database

# 3. PostgreSQL läuft verifizieren
docker ps | grep postgres

# 4. Datenbankverbindung testen
docker exec formbricks npm run db:migrate
```

#### Umfrage-Antworten werden nicht gespeichert

```bash
# 1. Datenbank-Migrationen prüfen
docker exec formbricks npm run db:migrate

# 2. Festplattenspeicher prüfen
df -h

# 3. PostgreSQL-Logs prüfen
docker logs postgres --tail 100

# 4. Datenbank-Berechtigungen verifizieren
docker exec postgres psql -U postgres -c "\du"
```

### Ressourcen

- **Dokumentation:** https://formbricks.com/docs
- **API-Referenz:** https://formbricks.com/docs/api/overview
- **JavaScript SDK:** https://formbricks.com/docs/developer-docs/js-library
- **GitHub:** https://github.com/formbricks/formbricks
- **Community:** https://formbricks.com/discord
- **Templates:** https://formbricks.com/templates
- **Beispiele:** https://github.com/formbricks/formbricks/tree/main/examples

### Best Practices

**Umfrage-Design:**
- Halte Umfragen kurz (max. 5-7 Fragen)
- Verwende klare, einfache Sprache
- Vermeide suggestive Fragen
- Teste auf mobilen Geräten
- A/B-teste Umfrage-Designs
- Nutze Fortschrittsanzeigen

**Timing & Trigger:**
- Zeige nicht sofort beim Seitenaufruf (warte 3-5 Sekunden)
- Begrenze Umfrage-Häufigkeit (max. einmal pro 30 Tage)
- Nutze Exit Intent für nicht-aufdringliches Feedback
- Zeitgestaltung basierend auf Benutzer-Engagement
- Respektiere "Nicht wieder anzeigen" Präferenzen

**Datenschutz:**
- Sei transparent über Datenverwendung
- Biete Opt-out-Mechanismen
- Anonymisiere PII wo möglich
- Halte DSGVO/CCPA ein
- Sichere API-Schlüssel korrekt
- Regelmäßige Datenaufbewahrungs-Bereinigung

**Automatisierung:**
- Richte Echtzeit-Webhooks für dringendes Feedback ein
- Erstelle Eskalationsregeln für Detractors
- Automatisiere Dankes-Nachrichten
- Tracke Antwortquoten und Abschluss
- Schließe die Feedback-Schleife (folge Benutzern nach)
- Überwache Umfrage-Performance-Metriken

**Integration:**
- Verbinde mit CRM für Lead-Qualifizierung
- Synchronisiere mit Support-Systemen für Probleme
- Speise in Produkt-Roadmap-Tools ein
- Aktualisiere Kundenprofile automatisch
- Löse Marketing-Kampagnen aus
- Generiere Analytics-Dashboards
