# 📧 Mautic - Marketing-Automatisierung

### Was ist Mautic?

Mautic ist eine leistungsstarke Open-Source-Marketing-Automatisierungsplattform, die anspruchsvolles Lead-Nurturing, E-Mail-Kampagnen, Landing Pages und Multi-Channel-Marketing ermöglicht. Mit umfassender API-Unterstützung und nativem n8n-Community-Node erlaubt Mautic die Erstellung fortschrittlicher Marketing-Workflows, die sich nahtlos in deinen gesamten Tech-Stack für datengetriebene Marketing-Kampagnen integrieren.

### Funktionen

- **E-Mail-Marketing** - Campaign Builder, Vorlagen, A/B-Testing, Personalisierung, dynamische Inhalte
- **Lead-Management** - Lead-Scoring, Segmentierung, Lifecycle-Stages, progressives Profiling
- **Kampagnen-Workflows** - Visueller Campaign Builder mit Triggern, Aktionen und Bedingungen
- **Landing Pages & Formulare** - Drag-and-Drop-Builder, benutzerdefinierte Felder, progressives Profiling
- **Multi-Channel-Marketing** - E-Mail, SMS, Web-Benachrichtigungen, Social-Media-Integration
- **Marketing-Attribution** - Customer Journey Tracking, Multi-Touch-Attribution, ROI-Analytics
- **Erweiterte Segmentierung** - Dynamische Segmente basierend auf Verhalten, Demografie, Engagement
- **Webhooks & API** - RESTful API, OAuth 2.0, Echtzeit-Webhooks für Integrationen
- **Lead-Nurturing** - Automatisierte Drip-Kampagnen, Verhaltens-Trigger, Lead-Scoring-Regeln
- **Analytics & Reporting** - Kampagnen-Performance, E-Mail-Metriken, Conversion-Tracking
- **DSGVO-Konformität** - Einwilligungsverwaltung, Datenschutz-Kontrollen, Opt-in/Opt-out-Tracking
- **Integrationsbereit** - Über 50 native Integrationen plus n8n für unbegrenzte Konnektivität

### Ersteinrichtung

**Erster Login bei Mautic:**

1. Navigiere zu `https://mautic.deinedomain.com`
2. Schließe den Installations-Assistenten ab:
   - Admin-Benutzername und E-Mail
   - Starkes Passwort (mindestens 8 Zeichen)
   - Site-URL (vorkonfiguriert)
   - Setup-Assistent abschließen
3. E-Mail-Einstellungen konfigurieren:
   - Einstellungen → Konfiguration → E-Mail-Einstellungen
   - Mailpit ist vorkonfiguriert (SMTP: `mailpit:1025`)
   - Für Produktion: Docker-Mailserver oder externen SMTP konfigurieren
4. API-Zugriff aktivieren:
   - Einstellungen → Konfiguration → API-Einstellungen
   - API aktivieren: Ja
   - HTTP Basic Auth aktivieren: Ja (für einfachere n8n-Integration)
   - OAuth 2 aktivieren: Ja (für erweiterte Sicherheit)
5. API-Zugangsdaten generieren:
   - Einstellungen → API-Zugangsdaten
   - Auf "Neu" klicken, um Zugangsdaten zu erstellen
   - OAuth 2 oder Basic Auth wählen
   - Client-ID und Secret sicher speichern

**Konfiguration nach der Einrichtung:**

```bash
# Auf Mautic-Container für erweiterte Konfiguration zugreifen
docker exec -it mautic_web bash

# Cache nach Konfigurationsänderungen leeren
php bin/console cache:clear

# Cache für bessere Performance aufwärmen
php bin/console cache:warmup

# Geplante Kampagnen verarbeiten (Cron-Job)
php bin/console mautic:campaigns:trigger
```

### n8n-Integration einrichten

**Methode 1: Community Mautic Node (Empfohlen)**

1. In n8n, gehe zu Einstellungen → Community Nodes
2. Installiere: `@digital-boss/n8n-nodes-mautic`
3. n8n neu starten (docker compose restart n8n)
4. Mautic-Zugangsdaten erstellen:
   - Typ: Mautic OAuth2 API
   - Authorization URL: `http://mautic_web/oauth/v2/authorize`
   - Access Token URL: `http://mautic_web/oauth/v2/token`
   - Client-ID: Aus Mautic API-Zugangsdaten
   - Client Secret: Aus Mautic API-Zugangsdaten
   - Scope: Leer lassen für vollen Zugriff

**Methode 2: HTTP Request mit Basic Auth**

Für einfachere Workflows ohne Community Node:

1. In n8n, Zugangsdaten erstellen:
   - Typ: Header Auth
   - Header-Name: `Authorization`
   - Header-Wert: `Basic BASE64(benutzername:passwort)`
   
Oder integrierte Basic Auth verwenden:
- Benutzername: Dein Mautic-Benutzername
- Passwort: Dein Mautic-Passwort

**Interne URL für n8n:** `http://mautic_web`

**API-Basis-URL:** `http://mautic_web/api`

### Beispiel-Workflows

#### Beispiel 1: Fortgeschrittenes Lead-Scoring & Nurturing

Leads automatisch basierend auf Verhalten und Engagement bewerten:

```javascript
// KI-gestütztes Lead-Scoring mit Verhaltensanalyse

// 1. Webhook Trigger - Formularübermittlung von Website
// Webhook-URL in Website konfigurieren: https://n8n.deinedomain.com/webhook/lead-capture

// 2. Code Node - Lead-Daten anreichern
const email = $json.email;
const domain = email.split('@')[1];

const leadData = {
  email: email,
  firstname: $json.firstname || '',
  lastname: $json.lastname || '',
  company: $json.company || domain,
  website: $json.website || `https://${domain}`,
  phone: $json.phone || '',
  formSource: $json.form_id || 'unknown',
  ipAddress: $json.ip_address || '',
  tags: ['website-form', $json.form_id || 'general'],
  customFields: {
    lead_source: $json.utm_source || 'direct',
    campaign: $json.utm_campaign || 'none',
    medium: $json.utm_medium || 'organic'
  }
};

return [{ json: leadData }];

// 3. Mautic Node - Kontakt erstellen/aktualisieren
Operation: Create or Update Contact
Email: {{$json.email}}
Fields:
  firstname: {{$json.firstname}}
  lastname: {{$json.lastname}}
  company: {{$json.company}}
  website: {{$json.website}}
  phone: {{$json.phone}}
  last_active: {{$now.toISO()}}
Tags: {{$json.tags.join(',')}}

// 4. HTTP Request - E-Mail-Zustellbarkeit prüfen (optional)
Methode: GET
URL: https://api.zerobounce.net/v2/validate
Query Parameter:
  api_key: {{$env.ZEROBOUNCE_API_KEY}}
  email: {{$json.email}}

// 5. Code Node - Lead-Score berechnen
const baseScore = 10; // Basis-Score
let score = baseScore;
let scoreFactors = [];

// E-Mail-Qualitäts-Scoring
const emailQuality = $('Email Validation').item.json.status;
if (emailQuality === 'valid') {
  score += 20;
  scoreFactors.push('Gültige E-Mail: +20');
} else if (emailQuality === 'catch-all') {
  score += 10;
  scoreFactors.push('Catch-All-E-Mail: +10');
} else if (emailQuality === 'unknown') {
  score += 5;
  scoreFactors.push('Unbekannte E-Mail: +5');
} else {
  score -= 10;
  scoreFactors.push('Ungültige E-Mail: -10');
}

// Formularquellen-Scoring
const formId = $('Enrich Data').item.json.formSource;
if (formId === 'demo-request') {
  score += 40;
  scoreFactors.push('Demo-Anfrage: +40');
} else if (formId === 'contact-sales') {
  score += 35;
  scoreFactors.push('Vertrieb kontaktieren: +35');
} else if (formId === 'whitepaper-download') {
  score += 20;
  scoreFactors.push('Whitepaper-Download: +20');
} else if (formId === 'newsletter') {
  score += 10;
  scoreFactors.push('Newsletter-Anmeldung: +10');
}

// Firmen-Domain-Scoring
const domain = $('Enrich Data').item.json.email.split('@')[1];
const freeEmailDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
if (!freeEmailDomains.includes(domain)) {
  score += 15;
  scoreFactors.push('Geschäfts-E-Mail: +15');
}

// Segment berechnen
let segment = 'cold-leads';
if (score >= 70) segment = 'hot-leads';
else if (score >= 40) segment = 'warm-leads';

return [{
  json: {
    contactId: $('Create Contact').item.json.contact.id,
    email: $('Enrich Data').item.json.email,
    score: score,
    scoreFactors: scoreFactors,
    segment: segment,
    reasoning: scoreFactors.join(', ')
  }
}];

// 6. Mautic Node - Lead-Score aktualisieren
Operation: Bearbeite Contact Points
Contact ID: {{$json.contactId}}
Points: {{$json.score}}
Operator: plus

// 7. Mautic Node - Zu Segment hinzufügen
Operation: Add Contact to Segment
Contact ID: {{$json.contactId}}
Segment ID: Segment-ID basierend auf {{$json.segment}} abrufen

// 8. Mautic Node - Kampagne auslösen
Operation: Add Contact to Campaign
Contact ID: {{$json.contactId}}
Campaign ID: {{$json.score >= 70 ? 'sales-outreach-campaign-id' : 'nurture-campaign-id'}}

// 9. IF Node - Hochwertiger Lead-Alarm
Bedingung: {{$json.score}} >= 80

// Zweig: Hochwertige Leads
// 10a. Slack Node - Vertriebsteam benachrichtigen
Kanal: #sales-hot-leads
Nachricht: |
  🔥 **Hochwertiger Lead-Alarm!**
  
  Name: {{$('Create Contact').item.json.contact.fields.all.firstname}} {{$('Create Contact').item.json.contact.fields.all.lastname}}
  E-Mail: {{$json.email}}
  Firma: {{$('Create Contact').item.json.contact.fields.all.company}}
  Score: {{$json.score}}/100
  
  Bewertung: {{$json.reasoning}}
  
  👉 Sofortiges Follow-up empfohlen!

// 11a. Twenty CRM HTTP Request - Opportunity erstellen
Methode: POST
URL: http://twenty-crm:3000/rest/opportunities
Body (JSON):
{
  "name": "Hot Lead: {{$('Create Contact').item.json.contact.fields.all.company}}",
  "amount": 0,
  "stage": "New",
  "companyId": "lookup-or-create-company",
  "customFields": {
    "leadScore": {{$json.score}},
    "source": "mautic",
    "mauticContactId": "{{$json.contactId}}"
  }
}

// 12a. Cal.com HTTP Request - Prioritäts-Buchung anbieten
Methode: POST
URL: http://cal:3000/api/booking-links
Body (JSON):
{
  "eventTypeId": 123, // Verkaufs-Demo Event-Typ
  "name": "{{$('Create Contact').item.json.contact.fields.all.firstname}} {{$('Create Contact').item.json.contact.fields.all.lastname}}",
  "email": "{{$json.email}}",
  "customNote": "Hochwertiger Lead (Score: {{$json.score}})"
}

// 13a. E-Mail Node - Prioritäts-Buchungslink senden
To: {{$json.email}}
Subject: Kurze Frage zu {{$('Create Contact').item.json.contact.fields.all.company}}
Body: |
  Hallo {{$('Create Contact').item.json.contact.fields.all.firstname}},
  
  vielen Dank für Ihr Interesse! Basierend auf Ihrem Firmenprofil
  würde ich Ihnen gerne zeigen, wie wir Ihnen helfen können.
  
  Buchen Sie einen prioritären Demo-Termin: {{$('Cal.com Booking').json.bookingLink}}
  
  Ich freue mich auf unser Gespräch!
  
  Mit freundlichen Grüßen,
  Vertriebsteam
```

#### Beispiel 2: Multi-Channel-Kampagnen-Orchestrierung

Kampagnen über E-Mail, SMS und soziale Medien koordinieren:

```javascript
// Intelligente Multi-Channel-Marketing-Automatisierung

// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. Mautic Node - Kampagnen-Kontakte abrufen
Operation: Get Contacts
Segment ID: active-campaign-recipients-segment-id
Filters:
  - isPublished: true
  - dnc: 0  // Do Not Contact = false
Limit: 100

// 3. Loop Over Items - Jeden Kontakt verarbeiten

// 4. Mautic Node - Kontakt-Aktivität abrufen
Operation: Get Contact Activity
Contact ID: {{$json.id}}
Date From: {{$now.minus(7, 'days').toISO()}}
Include Events: true

// 5. Code Node - Nächste beste Aktion bestimmen
const activity = $input.first().json.events || [];
const contact = $('Loop Over Items').item.json;

// Engagement-Muster analysieren
const lastEmail = activity.filter(a => a.type === 'email.read').sort((a,b) => 
  new Date(b.timestamp) - new Date(a.timestamp))[0];
const lastClick = activity.filter(a => a.type === 'page.hit').sort((a,b) => 
  new Date(b.timestamp) - new Date(a.timestamp))[0];

const daysSinceEmail = lastEmail ? 
  Math.floor((new Date() - new Date(lastEmail.timestamp)) / (1000 * 60 * 60 * 24)) : 999;
const daysSinceClick = lastClick ?
  Math.floor((new Date() - new Date(lastClick.timestamp)) / (1000 * 60 * 60 * 24)) : 999;

// Engagement-Bewertung
const engagementScore = activity.length;
let nextAction = 'email';
let content = 'standard';
let channel = 'email';

if (lastClick && daysSinceClick < 2) {
  // Hohes kürzliches Engagement - aggressiv sein
  nextAction = 'sms';
  content = 'urgent-offer';
  channel = 'sms';
} else if (lastEmail && !lastClick && daysSinceEmail < 7) {
  // E-Mail geöffnet, aber keine Aktion - anderen Inhalt versuchen
  nextAction = 'email';
  content = 'alternative-content';
  channel = 'email';
} else if (daysSinceEmail > 14) {
  // Inaktiv - Reaktivierungskampagne
  nextAction = 'reactivation';
  content = 'win-back';
  channel = 'email';
} else if (engagementScore > 10 && daysSinceEmail < 3) {
  // Sehr engagiert - persönliche Ansprache
  nextAction = 'personal-outreach';
  content = 'direct-call';
  channel = 'phone';
}

return [{
  json: {
    contactId: contact.id,
    email: contact.fields.all.email,
    firstname: contact.fields.all.firstname,
    phone: contact.fields.all.phone,
    nextAction,
    content,
    channel,
    engagementScore,
    daysSinceEmail
  }
}];

// 6. Switch Node - Nach Kanal routen

// Zweig: E-Mail
// 7a. Mautic Node - E-Mail senden
Operation: Send Email to Contact
Email ID: {{$json.content === 'urgent-offer' ? 'email-15' : 
           $json.content === 'alternative-content' ? 'email-12' :
           $json.content === 'win-back' ? 'email-20' : 'email-10'}}
Contact ID: {{$json.contactId}}

// Zweig: SMS
// 7b. HTTP Request - SMS über Twilio senden
Methode: POST
URL: https://api.twilio.com/2010-04-01/Accounts/{{$env.TWILIO_ACCOUNT_SID}}/Messages.json
Authentication: Basic Auth
Username: {{$env.TWILIO_ACCOUNT_SID}}
Password: {{$env.TWILIO_AUTH_TOKEN}}
Body (Form):
  To: {{$json.phone}}
  From: {{$env.TWILIO_PHONE_NUMBER}}
  Body: "Exklusives Angebot endet bald! Details in Ihrer E-Mail. - {{$env.COMPANY_NAME}}"

// Zweig: Persönliche Ansprache
// 7c. Aufgabe für Vertriebsmitarbeiter erstellen
// HTTP Request - Aufgabe in Vikunja erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body (JSON):
{
  "title": "{{$json.firstname}} anrufen - Hohes Engagement",
  "description": "Kontakt hat {{$json.engagementScore}} kürzliche Interaktionen. Persönlich nachfassen.",
  "priority": 3,
  "dueDate": "{{$now.plus(1, 'day').toISO()}}",
  "labels": ["hot-lead", "personal-outreach"]
}

// Zweig: Reaktivierung
// 7d. Mautic Node - Aus aktueller Kampagne entfernen
Operation: Remove Contact from Campaign
Contact ID: {{$json.contactId}}
Campaign ID: current-campaign-id

// 7e. Mautic Node - Zu Rückgewinnungs-Kampagne hinzufügen
Operation: Add Contact to Campaign
Contact ID: {{$json.contactId}}
Campaign ID: win-back-campaign-id

// 8. Mautic Node - Benutzerdefinierte Aktivität protokollieren
Operation: Add Contact Note
Contact ID: {{$json.contactId}}
Hinweis: |
  Multi-Channel-Aktion ausgelöst: {{$json.nextAction}}
  Kanal: {{$json.channel}}
  Engagement-Score: {{$json.engagementScore}}
  Letzte E-Mail: vor {{$json.daysSinceEmail}} Tagen

// 9. HTTP Request - Analytics-Dashboard aktualisieren
Methode: POST
URL: http://metabase:3000/api/card/campaign-performance/refresh
Header:
  X-Metabase-Session: {{$env.METABASE_SESSION}}
```

#### Beispiel 3: Dynamische Content-Personalisierung mit KI

Personalisierte Inhalte basierend auf Lead-Verhalten und KI-Analyse erstellen:

```javascript
// KI-gestützte Content-Personalisierungs-Engine

// 1. Mautic Webhook - E-Mail geöffnet
// In Mautic konfigurieren: Webhooks → Webhook für "Email Opened"-Event erstellen

// 2. HTTP Request - Vollständiges Kontaktprofil abrufen
Methode: GET
URL: http://mautic_web/api/contacts/{{$json.contact.id}}
Authentication: Mautic-Zugangsdaten verwenden

// 3. Code Node - Personalisierungs-Kontext vorbereiten
const contact = $input.first().json.contact;
const fields = contact.fields.all;

const personalizationContext = {
  firstname: fields.firstname || 'dort',
  company: fields.company || 'Ihr Unternehmen',
  industry: fields.industry || 'Ihre Branche',
  leadScore: contact.points || 0,
  tags: contact.tags.map(t => t.tag).join(', '),
  utmSource: fields.utm_source || 'direct',
  lastActive: fields.last_active || 'kürzlich',
  customFields: {
    jobTitle: fields.job_title || '',
    companySize: fields.company_size || '',
    interests: fields.interests || ''
  }
};

return [{ json: personalizationContext }];

// 4. OpenAI Node - Personalisierten Inhalt generieren
Operation: Message a Model
Modell: gpt-4o-mini
Nachrichten:
  System: "Du bist ein Marketing-Content-Spezialist, der personalisierte E-Mail-Inhalte erstellt."
  User: |
    Erstelle ein personalisiertes E-Mail-Follow-up für:
    - Name: {{$json.firstname}}
    - Firma: {{$json.company}}
    - Branche: {{$json.industry}}
    - Jobtitel: {{$json.customFields.jobTitle}}
    - Lead-Score: {{$json.leadScore}}
    - Interessen: {{$json.customFields.interests}}
    - Frühere Interaktionen: {{$json.tags}}
    - Traffic-Quelle: {{$json.utmSource}}
    
    Fokussiere auf deren Schmerzpunkte und unsere Lösungsvorteile.
    Füge einen klaren CTA hinzu, passend zu deren Lead-Score.
    Halte es unter 150 Wörtern.
    Verwende einen freundlichen, professionellen Ton.

// 5. Code Node - Dynamische E-Mail-Vorlage erstellen
const aiContent = $input.first().json.message.content;
const context = $('Prepare Context').item.json;

const template = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Personalisiert für ${context.firstname}</title>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #007bff; color: white; padding: 20px; }
    .content { padding: 20px; }
    .cta { display: inline-block; padding: 12px 24px; background: #28a745; 
           color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
    .footer { font-size: 12px; color: #666; padding: 20px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Hallo ${context.firstname}! 👋</h1>
    </div>
    <div class="content">
      ${aiContent}
      
      <!-- Dynamischer CTA basierend auf Lead-Score -->
      ${context.leadScore > 70 ? 
        '<a href="{trackinglink=demo-booking}" class="cta">Demo buchen</a>' :
        context.leadScore > 40 ?
        '<a href="{trackinglink=learn-more}" class="cta">Mehr erfahren</a>' :
        '<a href="{trackinglink=resources}" class="cta">Ressourcen ansehen</a>'
      }
      
      <!-- Dynamische Produktempfehlungen basierend auf Branche -->
      <h3>Empfohlen für ${context.industry}:</h3>
      ${context.industry === 'SaaS' || context.industry === 'Technology' ? 
        '{dynamiccontent="tech-features"}' :
        context.industry === 'Healthcare' ?
        '{dynamiccontent="healthcare-features"}' :
        '{dynamiccontent="enterprise-features"}'
      }
    </div>
    <div class="footer">
      <p>Sie erhalten diese E-Mail, weil Sie Interesse an unseren Lösungen gezeigt haben.</p>
      <p><a href="{unsubscribe_url}">Abmelden</a> | <a href="{webview_url}">Im Browser ansehen</a></p>
    </div>
  </div>
</body>
</html>
`;

return [{
  json: {
    template,
    contactId: $('Get Profile').item.json.contact.id,
    subject: `${context.firstname}, kurze Frage zu ${context.company}`
  }
}];

// 6. Mautic Node - Dynamische E-Mail erstellen
Operation: Create Email
Name: "Personalisiertes Follow-up - {{$now.format('YYYY-MM-DD HH:mm')}}"
Subject: {{$json.subject}}
Custom HTML: {{$json.template}}
Email Type: template

// 7. Mautic Node - An Kontakt senden
Operation: Send Email to Contact
Email ID: {{$('Create Email').item.json.email.id}}
Contact ID: {{$json.contactId}}

// 8. Mautic Node - Personalisierung protokollieren
Operation: Add Contact Note
Contact ID: {{$json.contactId}}
Hinweis: |
  KI-personalisierte E-Mail gesendet
  Betreff: {{$json.subject}}
  Generiert: {{$now.toISO()}}
```

#### Beispiel 4: Lead-Attribution & ROI-Tracking

Vollständige Customer Journey tracken und Marketing-ROI berechnen:

```javascript
// Vollständiges Attribution-Tracking-System

// 1. Webhook Trigger - Conversion-Event (Kauf/Anmeldung abgeschlossen)
// Von deiner Anwendung gesendet, wenn Conversion erfolgt

// 2. Mautic Node - Kontakt-Journey abrufen
Operation: Get Contact
Contact ID: {{$json.contact_id}}
Include Timeline: true

// 3. Code Node - Attributionspfad analysieren
const contact = $input.first().json.contact;
const timeline = contact.timeline || [];
const touchpoints = [];

// Alle Marketing-Touchpoints extrahieren
timeline.forEach(event => {
  const marketingEvents = ['email.read', 'email.sent', 'page.hit', 
                          'form.submitted', 'asset.download', 'campaign.event'];
  
  if (marketingEvents.includes(event.eventType)) {
    touchpoints.push({
      type: event.eventType,
      timestamp: event.timestamp,
      campaign: event.event.campaign?.name || null,
      email: event.event.email?.name || null,
      source: event.event.source || 'direct',
      metadata: event.event
    });
  }
});

// Nach Zeitstempel sortieren
touchpoints.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

// Attributionsgewichte berechnen (lineares Modell)
const attribution = {};
const weight = touchpoints.length > 0 ? 1 / touchpoints.length : 0;

touchpoints.forEach(tp => {
  const key = tp.campaign || tp.email || tp.source || 'direct';
  attribution[key] = (attribution[key] || 0) + weight;
});

// First und Last Touch identifizieren
const firstTouch = touchpoints[0];
const lastTouch = touchpoints[touchpoints.length - 1];

// Zeit bis zur Conversion berechnen
const firstTouchDate = firstTouch ? new Date(firstTouch.timestamp) : new Date();
const conversionDate = new Date();
const daysToConversion = Math.floor((conversionDate - firstTouchDate) / (1000 * 60 * 60 * 24));

return [{
  json: {
    contactId: contact.id,
    email: contact.fields.all.email,
    conversionWert: $('Webhook').item.json.order_value || 0,
    touchpoints: touchpoints,
    touchpointCount: touchpoints.length,
    attribution: attribution,
    firstTouch: firstTouch,
    lastTouch: lastTouch,
    daysToConversion: daysToConversion
  }
}];

// 4. HTTP Request - Kampagnen-ROI in Datenbank aktualisieren
Methode: POST
URL: http://nocodb:8080/api/v2/tables/CAMPAIGN_ATTRIBUTION/records
Authentication: NocoDB-Zugangsdaten verwenden
Body (JSON):
{
  "ContactId": "{{$json.contactId}}",
  "Email": "{{$json.email}}",
  "ConversionValue": {{$json.conversionValue}},
  "TouchpointCount": {{$json.touchpointCount}},
  "FirstTouchCampaign": "{{$json.firstTouch?.campaign || 'Unbekannt'}}",
  "LastTouchCampaign": "{{$json.lastTouch?.campaign || 'Unbekannt'}}",
  "DaysToConversion": {{$json.daysToConversion}},
  "AttributionData": "{{JSON.stringify($json.attribution)}}",
  "ConversionDate": "{{$now.toISO()}}"
}

// 5. Mautic Node - Kontakt mit Conversion-Daten aktualisieren
Operation: Bearbeite Contact
Contact ID: {{$json.contactId}}
Custom Fields:
  lifetime_value: {{$json.conversionValue}}
  conversion_date: {{$now.toISODate()}}
  touchpoint_count: {{$json.touchpointCount}}
  days_to_conversion: {{$json.daysToConversion}}

// 6. Mautic Node - Zu Kunden-Segment hinzufügen
Operation: Add Contact to Segment
Contact ID: {{$json.contactId}}
Segment ID: customers-segment-id

// 7. Mautic Node - Aus Lead-Nurture-Kampagnen entfernen
Operation: Remove Contact from Campaign
Contact ID: {{$json.contactId}}
Campaign ID: nurture-campaign-id

// 8. Invoice Ninja Node - Rechnung erstellen (falls zutreffend)
Operation: Create Invoice
Client: {{$json.email}}
Betrag: {{$json.conversionValue}}
Description: Produktkauf - Mautic Tracking

// 9. Google Sheets Node - Conversion protokollieren
Operation: Append
Spreadsheet: Marketing Attribution Report
Sheet: Conversions
Daten:
  - Datum: {{$now.toISODate()}}
  - Contact: {{$json.email}}
  - Wert: {{$json.conversionValue}}
  - First Touch: {{$json.firstTouch?.campaign}}
  - Last Touch: {{$json.lastTouch?.campaign}}
  - Days to Convert: {{$json.daysToConversion}}
  - Touchpoints: {{$json.touchpointCount}}

// 10. Slack Node - Team benachrichtigen
Kanal: #conversions
Nachricht: |
  🎉 **Neue Conversion!**
  
  Kunde: {{$json.email}}
  Wert: {{$json.conversionValue}}€
  
  Journey:
  • First Touch: {{$json.firstTouch?.campaign || 'Direkt'}}
  • Last Touch: {{$json.lastTouch?.campaign || 'Direkt'}}
  • Zeit bis Conversion: {{$json.daysToConversion}} Tage
  • Gesamt-Touchpoints: {{$json.touchpointCount}}
  
  Attributions-Aufschlüsselung:
  {{#each $json.attribution}}
  • {{@key}}: {{(this * 100).toFixed(1)}}%
  {{/each}}
```

### Fehlerbehebung

**Problem 1: Webhook empfängt keine Daten**

```bash
# Mautic Webhook-Konfiguration prüfen
docker exec mautic_web php bin/console mautic:webhooks:list

# Ausstehende Webhooks manuell verarbeiten
docker exec mautic_web php bin/console mautic:webhooks:process

# Webhook-URL-Erreichbarkeit testen
curl -X POST https://n8n.deinedomain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Mautic-Logs nach Webhook-Fehlern durchsuchen
docker logs mautic_web | grep -i webhook
```

**Lösung:**
- Webhook-URL in Mautic verifizieren (Einstellungen → Webhooks)
- Sicherstellen, dass Webhook-URL vom Mautic-Container erreichbar ist
- Falls möglich interne URL verwenden: `http://n8n:5678/webhook/...`
- Prüfen, dass Webhook-Trigger und Events korrekt konfiguriert sind
- Webhook-Debugging in Mautic-Konfiguration aktivieren

**Problem 2: API-Authentifizierungs-Fehler**

```bash
# OAuth2-Zugangsdaten neu generieren
docker exec mautic_web php bin/console mautic:integration:synccontacts

# API-Verbindung testen
curl -u benutzername:passwort \
  http://localhost/api/contacts

# API-Einstellungen in Mautic prüfen
# Einstellungen → Konfiguration → API-Einstellungen → API aktivieren
```

**Lösung:**
- API-Zugangsdaten in Mautic neu generieren (Einstellungen → API-Zugangsdaten)
- OAuth2-Callback-URL mit n8n-Konfiguration abgleichen
- Für Basic Auth: Benutzername und Passwort auf Korrektheit prüfen
- Prüfen, dass API in Mautic-Konfiguration aktiviert ist
- Interne URL verwenden: `http://mautic_web/api` von n8n aus

**Problem 3: E-Mails werden nicht gesendet**

```bash
# E-Mail-Warteschlange prüfen
docker exec mautic_web php bin/console mautic:emails:send

# E-Mail-Warteschlange verarbeiten
docker exec mautic_worker php bin/console messenger:consume email

# SMTP-Konfiguration prüfen
docker logs mautic_web | grep -i smtp

# E-Mail-Konfiguration testen
docker exec mautic_web php bin/console mautic:email:test deine@email.com
```

**Lösung:**
- SMTP-Einstellungen verifizieren (Einstellungen → Konfiguration → E-Mail-Einstellungen)
- Für Mailpit: Host=`mailpit`, Port=`1025`, keine Authentifizierung
- Für Docker-Mailserver: Host=`mailserver`, Port=`587`, TLS aktiviert
- E-Mail-Warteschlange prüfen: Einstellungen → Systeminfo → E-Mail-Warteschlange
- Warteschlange manuell verarbeiten, falls blockiert
- VON-E-Mail-Adresse auf Gültigkeit prüfen

**Problem 4: Performance-Probleme / Langsame Kampagnen**

```bash
# Kampagnen-Warteschlange prüfen
docker exec mautic_web php bin/console mautic:campaigns:update
docker exec mautic_web php bin/console mautic:campaigns:trigger

# Redis-Cache überwachen
docker exec mautic_redis redis-cli INFO stats

# Segment-Verarbeitung prüfen
docker exec mautic_web php bin/console mautic:segments:update

# Datenbank optimieren
docker exec mautic_db mysql -u root -p \
  -e "OPTIMIZE TABLE mautic.leads, mautic.lead_event_log, mautic.campaign_lead_event_log;"

# Container-Ressourcen prüfen
docker stats mautic_web mautic_worker mautic_redis --no-stream
```

**Lösung:**
- Sicherstellen, dass mautic_worker-Container für Hintergrund-Jobs läuft
- Redis-Memory-Limit in docker-compose.yml erhöhen
- Segmente optimieren (Komplexität reduzieren, statische Segmente nutzen wenn möglich)
- Alte Kampagnen und inaktive Kontakte archivieren
- PHP Memory Limit erhöhen: `memory_limit = 512M` in php.ini
- Opcache für bessere PHP-Performance aktivieren
- Cron-Jobs regelmäßig für Kampagnen-Verarbeitung ausführen

### Ressourcen

- **Offizielle Dokumentation:** https://docs.mautic.org/
- **API-Dokumentation:** https://developer.mautic.org/
- **Community Mautic Node:** https://www.npmjs.com/package/@digital-boss/n8n-nodes-mautic
- **GitHub:** https://github.com/mautic/mautic
- **Community-Forum:** https://forum.mautic.org/
- **Best Practices Guide:** https://docs.mautic.org/en/best-practices
- **Campaign Builder:** https://docs.mautic.org/en/campaigns
- **E-Mail-Marketing:** https://docs.mautic.org/en/emails
- **Lead-Scoring:** https://docs.mautic.org/en/points

### Best Practices

**Kampagnen-Optimierung:**
1. **Strategisch segmentieren** - Halte Segmente unter 10.000 Kontakten für Performance
2. **Dynamische Inhalte nutzen** - Personalisiere E-Mails mit Tokens und dynamischen Content-Blöcken
3. **Alles testen** - A/B-teste Betreffzeilen, Inhalte, Sendezeiten
4. **Engagement überwachen** - Tracke Öffnungen, Klicks, Abmeldungen; passe Kampagnen entsprechend an
5. **Liste bereinigen** - Entferne regelmäßig Hard Bounces und nicht-engagierte Kontakte

**Datenmanagement:**
1. **Progressives Profiling** - Sammle Daten schrittweise über mehrere Formular-Interaktionen
2. **Alte Daten archivieren** - Verschiebe inaktive Kontakte (>1 Jahr) in Archiv-Segmente
3. **Datenhygiene** - Regelmäßige Bereinigung von Duplikaten, ungültigen E-Mails, Test-Kontakten
4. **API-Limits überwachen** - Implementiere Rate Limiting in n8n-Workflows
5. **Regelmäßig sichern** - Datenbank-Backups vor größeren Kampagnen-Starts

**Sicherheit & Compliance:**
```javascript
// DSGVO-Compliance-Workflow-Beispiel

// 1. Einwilligung in benutzerdefinierten Feldern tracken
custom_field: gdpr_consent
value: true/false
consent_date: timestamp

// 2. Einwilligung vor dem Senden prüfen
IF Node: {{$json.gdpr_consent}} === true

// 3. Einfaches Abmelden ermöglichen
Alle E-Mails müssen {unsubscribe_url} enthalten

// 4. Datenlöschungs-Workflow implementieren
Auf Anfrage: Kontakt löschen + Aktivitätslogs anonymisieren
```

**Integrationsmuster:**

**Mautic + CRM (Twenty/EspoCRM):**
- Mautic für Marketing nutzen, CRM für Vertrieb
- Bi-direktionale Synchronisation via n8n
- Qualifizierte Leads von Mautic an CRM übergeben wenn Score > 70

**Mautic + Cal.com:**
- Hochwertige Leads erhalten automatische Buchungslinks
- Meetings basierend auf Engagement-Scores buchen
- Meeting-Status zurück zu Mautic synchronisieren

**Mautic + E-Commerce:**
- Warenkorbabbruch-Kampagnen
- Post-Purchase-Nurturing
- Rückgewinnungs-Kampagnen für inaktive Kunden

**API Best Practices:**
1. **OAuth2 nutzen** für Produktionsumgebungen (sicherer)
2. **Batch-Operationen** - Kontakte in Batches von 50-100 verarbeiten
3. **Rate Limiting** - API-Limits respektieren (typischerweise 100 Req/Min)
4. **Fehlerbehandlung** - Retry-Logik für fehlgeschlagene Requests implementieren
5. **Webhooks statt Polling** - Webhooks für Echtzeit-Updates nutzen statt API-Polling
6. **Daten cachen** - Häufig abgerufene Daten (Segmente, Kampagnen) in n8n cachen
7. **Logging** - Alle API-Aufrufe für Debugging und Audit-Trails protokollieren
