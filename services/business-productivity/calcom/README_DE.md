# 📅 Cal.com - Planungsplattform

### Was ist Cal.com?

Cal.com ist eine leistungsstarke Open-Source-Planungsplattform, die eine selbst gehostete Alternative zu Calendly bietet. Sie bietet automatisierte Buchungs-Workflows, Team-Scheduling, Zahlungsintegration und nahtlose n8n-Integration für umfassende Automatisierung. Perfekt für die Verwaltung von Kundenmeetings, Beratungen und Team-Kalendern.

### Funktionen

- **Event-Typen** - Mehrere Meeting-Typen: 15min, 30min, 1-zu-1, Team-Meetings, wiederkehrende Events
- **Team-Scheduling** - Round-Robin-Zuweisung, kollektive Verfügbarkeit, Team-Event-Typen
- **Video-Integration** - Automatisch generierte Links für Jitsi, Zoom, Google Meet, Teams
- **Zahlungsabwicklung** - Stripe und PayPal für bezahlte Beratungen
- **Benutzerdefinierte Felder** - Sammle zusätzliche Informationen während der Buchung
- **Native n8n-Integration** - Eingebaute Cal.com Trigger- und Action-Nodes
- **Webhooks** - Echtzeit-Events für booking.created, cancelled, rescheduled, completed

### Erste Einrichtung

**Erste Anmeldung bei Cal.com:**

1. Navigiere zu `https://cal.deinedomain.com`
2. **Erster Benutzer wird Admin** - Registriere dein Konto
3. Schließe Onboarding-Wizard ab:
   - Setze deinen Verfügbarkeitsplan (Arbeitszeiten)
   - Verbinde Kalenderdienste (Google Calendar, Office 365 - optional)
   - Erstelle Event-Typen (15min Call, 30min Meeting, etc.)
4. Dein Buchungslink: `https://cal.deinedomain.com/[benutzername]`

**API-Schlüssel für n8n generieren:**

1. Gehe zu **Einstellungen** → **Developer** → **API Keys**
2. Klicke auf **Neuen API-Schlüssel erstellen**
3. Nenne ihn `n8n Integration`
4. Kopieren und sicher speichern

### n8n-Integrations-Setup

Cal.com hat **native n8n-Nodes** - keine manuelle Konfiguration erforderlich!

#### Cal.com Trigger Node

**Höre in Echtzeit auf Buchungs-Events:**

1. Füge **Cal.com Trigger** Node zum Workflow hinzu
2. Cal.com-Credentials erstellen:
   - Klicke auf **Neue Credential erstellen**
   - **API Key:** Füge deinen Cal.com API-Schlüssel ein
   - **Base URL:** `http://calcom:3000` (intern) oder `https://cal.deinedomain.com` (extern)
   - Speichern
3. Trigger-Events auswählen:
   - `booking.created` - Neue Buchung erstellt
   - `booking.rescheduled` - Buchungszeit geändert
   - `booking.cancelled` - Buchung storniert
   - `booking.completed` - Meeting beendet
   - `booking.rejected` - Buchung abgelehnt (falls Genehmigung erforderlich)
   - `booking.requested` - Buchung wartet auf Genehmigung
4. Workflow aktivieren

**Der Trigger wird automatisch ausgelöst, wenn Events auftreten!**

#### Cal.com Node (Actions)

**Aktionen in Cal.com ausführen:**

Verfügbare Operationen:
- **Event Types** - Event-Typen auflisten, abrufen, erstellen, aktualisieren, löschen
- **Bookings** - Buchungen auflisten, abrufen, stornieren, bestätigen
- **Availability** - Verfügbarkeitspläne abrufen/setzen
- **Users** - Benutzerinformationen abrufen
- **Webhooks** - Webhooks programmatisch verwalten

### Jitsi Meet-Integration

**Automatische Videokonferenzen:**

1. Einstellungen → **Apps**
2. Finde **Jitsi Video**
3. Klicke auf **App installieren**
4. Konfiguriere:
   - **Server-URL:** `https://meet.deinedomain.com`
   - Kein Trailing Slash!
5. Speichern

**Event-Typen konfigurieren:**
1. Bearbeite einen Event-Typ
2. Unter **Standort**, wähle **Jitsi Video**
3. Speichern

**Meeting-URLs werden automatisch generiert:**
- Format: `https://meet.deinedomain.com/cal/[buchungs-referenz]`
- Automatisch in Bestätigungs-E-Mails enthalten

### Beispiel-Workflows

#### Beispiel 1: Automatisierte Buchungsbestätigung

```javascript
// Kompletter Workflow für neue Buchungen

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Buchungsdaten extrahieren
const booking = $json;
return {
  attendeeName: booking.attendees[0].name,
  attendeeEmail: booking.attendees[0].email,
  meetingTitle: booking.title,
  startTime: new Date(booking.startTime).toLocaleString('de-DE'),
  endTime: new Date(booking.endTime).toLocaleString('de-DE'),
  meetingUrl: `https://meet.deinedomain.com/cal/${booking.uid}`,
  eventType: booking.eventType.title,
  organizerName: booking.organizer.name
};

// 3. Slack Node - Team benachrichtigen
Kanal: #sales
Nachricht: |
  📅 Neue Buchung!
  
  Kunde: {{$json.attendeeName}}
  Meeting: {{$json.meetingTitle}}
  Zeit: {{$json.startTime}}
  Link: {{$json.meetingUrl}}

// 4. Google Calendar Node - Kalendereintrag erstellen
Operation: Create Event
Calendar: Sales Team Calendar
Summary: {{$('Code').json.meetingTitle}}
Description: |
  Meeting mit {{$('Code').json.attendeeName}}
  Beitreten: {{$('Code').json.meetingUrl}}
Start: {{$json.startTime}}
End: {{$json.endTime}}

// 5. Send Email Node - Benutzerdefinierte Bestätigung
To: {{$('Code').json.attendeeEmail}}
Subject: Meeting bestätigt - {{$('Code').json.meetingTitle}}
Nachricht: |
  Hallo {{$('Code').json.attendeeName}},
  
  Dein Meeting mit {{$('Code').json.organizerName}} ist bestätigt!
  
  📅 Datum & Uhrzeit: {{$('Code').json.startTime}}
  🔗 Meeting beitreten: {{$('Code').json.meetingUrl}}
  
  Wir freuen uns auf das Gespräch!

// 6. Baserow/NocoDB Node - Zu CRM hinzufügen
Table: bookings
Fields: {
  customer_name: {{$('Code').json.attendeeName}},
  customer_email: {{$('Code').json.attendeeEmail}},
  meeting_type: {{$('Code').json.eventType}},
  scheduled_time: {{$json.startTime}},
  status: "confirmed"
}
```

#### Beispiel 2: Meeting-Erinnerungs-System

```javascript
// Automatisierte Erinnerungen 1 Stunde vor Meeting

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Erinnerungszeit berechnen
const meetingTime = new Date($json.startTime);
const reminderTime = new Date(meetingTime.getTime() - 3600000); // 1 Stunde vorher

return {
  attendeeEmail: $json.attendees[0].email,
  attendeeName: $json.attendees[0].name,
  meetingTitle: $json.title,
  meetingUrl: `https://meet.deinedomain.com/cal/${$json.uid}`,
  reminderTime: reminderTime.toISOString(),
  hostName: $json.user.name
};

// 3. Wait Node
Wait Until: {{$json.reminderTime}}

// 4. Send Email Node - Erinnerung
To: {{$('Code Node').json.attendeeEmail}}
Subject: Meeting-Erinnerung - Beginnt in 1 Stunde!
Nachricht: |
  Hallo {{$('Code Node').json.attendeeName}},
  
  Dein Meeting mit {{$('Code Node').json.hostName}} beginnt in 1 Stunde!
  
  📅 Meeting: {{$('Code Node').json.meetingTitle}}
  🕐 Zeit: In 1 Stunde
  🔗 Hier beitreten: {{$('Code Node').json.meetingUrl}}
  
  Bis gleich!

// 5. SMS Node (optional - via Twilio)
// SMS-Erinnerung für mobile Benachrichtigung senden
```

#### Beispiel 3: KI-gestützte Meeting-Vorbereitung

```javascript
// Recherche und Briefing-Vorbereitung vor Meeting

// 1. Cal.com Trigger Node
Event: booking.created

// 2. Code Node - Firmen-Domain extrahieren
const attendeeEmail = $json.attendees[0].email;
const companyDomain = attendeeEmail.split('@')[1];

return {
  attendeeName: $json.attendees[0].name,
  attendeeEmail: attendeeEmail,
  companyDomain: companyDomain,
  meetingTitle: $json.title,
  meetingTime: $json.startTime,
  bookingId: $json.id
};

// 3. HTTP Request - Firma recherchieren (via Perplexica)
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{$json.companyDomain}} Firmeninformationen, aktuelle News, wichtige Personen",
  "focusMode": "webSearch"
}

// 4. OpenAI Node - Meeting-Briefing generieren
Modell: gpt-4o-mini
System Nachricht: "Du bist ein Meeting-Vorbereitungsassistent."
User Nachricht: |
  Erstelle ein prägnantes Meeting-Briefing für:
  
  Meeting: {{$('Code Node').json.meetingTitle}}
  Teilnehmer: {{$('Code Node').json.attendeeName}}
  Firma: {{$('Code Node').json.companyDomain}}
  
  Recherche-Ergebnisse:
  {{$json.results}}
  
  Beinhalte:
  1. Firmenhintergrund (2-3 Sätze)
  2. Aktuelle News oder Entwicklungen
  3. Wichtige Gesprächspunkte
  4. Zu stellende Fragen

// 5. Wait Node
Wait until: 30 Minuten vor Meeting

// 6. Slack Node - Briefing an Host senden
Kanal: @{{$('Code Node').json.hostName}}
Nachricht: |
  📋 Meeting-Briefing
  
  Meeting in 30 Minuten mit {{$('Code Node').json.attendeeName}}
  
  {{$('OpenAI').json.briefing}}

// 7. Cal.com Node - Notizen zur Buchung hinzufügen
Operation: Update Booking
Booking ID: {{$('Code Node').json.bookingId}}
Notes: {{$('OpenAI').json.briefing}}
```

#### Beispiel 4: Follow-up nach Meeting

```javascript
// Automatisches Follow-up nach Meeting-Abschluss

// 1. Cal.com Trigger Node
Event: booking.completed

// 2. Wait Node
Wait: 1 Stunde nach Meeting-Ende

// 3. Send Email Node - Dankeschön & Feedback
To: {{$json.attendees[0].email}}
Subject: Danke für das Meeting!
Nachricht: |
  Hallo {{$json.attendees[0].name}},
  
  Danke, dass du dir heute Zeit für uns genommen hast!
  
  📝 Wir würden uns über dein Feedback freuen:
  https://forms.deinedomain.com/meeting-feedback?id={{$json.id}}
  
  Nächste Schritte:
  - Zusammenfassung wird bis EOD gesendet
  - Follow-up-Meeting in 2 Wochen
  
  Fragen? Antworte einfach auf diese E-Mail.
  
  Mit freundlichen Grüßen,
  {{$json.user.name}}

// 4. HTTP Request - Follow-up-Aufgabe erstellen (via Vikunja)
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Header:
  Authorization: Bearer {{$env.VIKUNJA_API_TOKEN}}
Body: {
  "title": "Follow-up mit {{$json.attendees[0].name}}",
  "description": "Meeting: {{$json.title}}\nDatum: {{$json.startTime}}",
  "due_date": "{{$now.plus(2, 'weeks').toISO()}}",
  "project_id": 1
}

// 5. Cal.com Node - Follow-up-Meeting planen (optional)
Operation: Create Booking
Event Type: Follow-up Call
Datum: {{$now.plus(2, 'weeks')}}
```

#### Beispiel 5: Smartes Scheduling mit KI

```javascript
// KI-gestützte Terminplanung aus natürlicher Sprache

// 1. Webhook Trigger - Scheduling-Anfrage empfangen
// Beispiel: Kunde füllt Formular aus oder sendet Chat-Nachricht

// 2. OpenAI Node - Scheduling-Anfrage parsen
Modell: gpt-4o-mini
Prompt: |
  Extrahiere Terminplanungs-Präferenzen aus dieser Anfrage:
  "{{$json.message}}"
  
  Gib JSON zurück:
  {
    "preferredDays": ["Montag", "Mittwoch"],
    "preferredTimes": ["morgens", "nachmittags"],
    "duration": 30,
    "topic": "Produktdemo",
    "urgency": "hoch"
  }

// 3. Cal.com Node - Verfügbarkeit abrufen
Operation: Get Available Slots
Event Type: Consultation
Date Range: Nächste 7 Tage

// 4. Code Node - Slots nach KI-Präferenzen ranken
const slots = $json.slots;
const preferences = $('OpenAI').json;

// Jeden Slot basierend auf Präferenzen bewerten
const rankedSlots = slots.map(slot => {
  let score = 0;
  
  // Bevorzugter Tag übereinstimmend
  const slotDay = new Date(slot.time).toLocaleDateString('de-DE', {weekday: 'long'});
  if (preferences.preferredDays.includes(slotDay)) score += 10;
  
  // Bevorzugte Zeit übereinstimmend
  const slotHour = new Date(slot.time).getHours();
  if (preferences.preferredTimes.includes('morgens') && slotHour < 12) score += 5;
  if (preferences.preferredTimes.includes('nachmittags') && slotHour >= 12) score += 5;
  
  // Dringlichkeit (früher bevorzugen)
  if (preferences.urgency === 'hoch') {
    const daysUntil = Math.floor((new Date(slot.time) - new Date()) / (1000 * 60 * 60 * 24));
    score += (7 - daysUntil);
  }
  
  return { ...slot, score };
}).sort((a, b) => b.score - a.score);

return rankedSlots[0]; // Beste Übereinstimmung

// 5. Cal.com Node - Buchung erstellen
Operation: Create Booking
Event Type ID: 1
Start Time: {{$json.time}}
Attendee Name: {{$('Webhook').json.name}}
Attendee Email: {{$('Webhook').json.email}}

// 6. Bestätigung senden
To: {{$('Webhook').json.email}}
Subject: Meeting geplant!
Nachricht: |
  Tolle Neuigkeiten! Dein Meeting ist geplant:
  
  📅 {{$json.startTime}}
  🔗 {{$json.conferenceUrl}}
  
  Diese Zeit wurde basierend auf deinen Präferenzen ausgewählt.
```

### Erweiterte API-Nutzung

**Für Operationen, die nicht im nativen Node verfügbar sind, nutze HTTP Request:**

```javascript
// Alle Event-Typen mit vollständigen Details abrufen
Methode: GET
URL: http://calcom:3000/api/v2/event-types
Header:
  Authorization: Bearer {{$env.CAL_API_KEY}}
  Content-Type: application/json

// Benutzerdefinierten Verfügbarkeitsplan erstellen
Methode: POST
URL: http://calcom:3000/api/v2/schedules
Body: {
  "name": "Sommerzeiten",
  "timeZone": "Europe/Berlin",
  "availability": [
    {
      "days": [1, 2, 3, 4, 5],
      "startTime": "09:00",
      "endTime": "17:00"
    }
  ]
}

// Buchungen in Masse stornieren
Methode: POST
URL: http://calcom:3000/api/v2/bookings/cancel
Body: {
  "bookingIds": [123, 124, 125],
  "reason": "Feiertagsschließung"
}
```

### Häufige Webhook-Payload

**booking.created Event:**
```json
{
  "triggerEvent": "booking.created",
  "payload": {
    "id": 12345,
    "uid": "abc123def456",
    "title": "30 Min Meeting",
    "description": "Lass uns über das Projekt sprechen",
    "startTime": "2025-01-20T10:00:00.000Z",
    "endTime": "2025-01-20T10:30:00.000Z",
    "organizer": {
      "name": "John Host",
      "email": "john@example.com",
      "username": "john"
    },
    "attendees": [{
      "name": "Jane Guest",
      "email": "jane@example.com"
    }],
    "eventType": {
      "id": 1,
      "title": "30 Min Meeting",
      "slug": "30min"
    },
    "location": "Jitsi Video",
    "conferenceUrl": "https://meet.deinedomain.com/cal/abc123",
    "status": "ACCEPTED"
  }
}
```

### E-Mail-Benachrichtigungen

Cal.com sendet automatisch E-Mails für:
- **Buchungsbestätigungen** - An Organisator und Teilnehmer
- **Erinnerungen** - Konfigurierbares Timing (15min, 1h, 1 Tag vorher)
- **Stornierungen** - Benachrichtigung an alle Parteien
- **Umplanungen** - Update-E-Mails mit neuer Zeit

Alle E-Mails nutzen dein konfiguriertes Mail-System (Mailpit für Entwicklung, Docker-Mailserver für Produktion).

### Fehlerbehebung

**Webhook wird nicht ausgelöst:**

```bash
# Cal.com-Logs prüfen
docker logs calcom --tail 100 | grep -i webhook

# Webhook registriert überprüfen
# Cal.com → Einstellungen → Webhooks
# Sollte n8n-Webhook-URL zeigen

# Webhook manuell testen
curl -X POST https://n8n.deinedomain.com/webhook/cal-com-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Cal.com bei Bedarf neu starten
docker compose restart calcom
```

**API-Authentifizierung fehlgeschlagen:**

```bash
# API-Schlüssel gültig überprüfen
# Cal.com → Einstellungen → Developer → API Keys
# Prüfen, ob Schlüssel nicht abgelaufen ist

# API-Schlüssel testen
curl -H "Authorization: Bearer DEIN_API_KEY" \
  https://cal.deinedomain.com/api/v2/me

# Sollte deine Benutzerinfo zurückgeben, nicht 401
```

**Kalender-Sync funktioniert nicht:**

```bash
# Prüfen, ob Cal.com externe Kalender erreichen kann
docker exec calcom curl https://www.googleapis.com

# Kalenderintegration neu verbinden
# Cal.com → Einstellungen → Apps → Google Calendar → Neu verbinden

# Logs auf OAuth-Fehler prüfen
docker logs calcom | grep -i oauth
```

**Langsames Laden der Buchungsseite:**

```bash
# Datenbankperformance prüfen
docker exec calcom-db pg_stat_activity

# Cal.com-Dienste neu starten
docker compose restart calcom calcom-db

# Serverressourcen prüfen
docker stats calcom
```

### Ressourcen

- **Offizielle Dokumentation:** https://cal.com/docs
- **API-Referenz:** https://cal.com/docs/api-reference
- **GitHub:** https://github.com/calcom/cal.com
- **n8n-Integration:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.calcom/
- **Community-Forum:** https://github.com/calcom/cal.com/discussions

### Best Practices

**Event-Type-Setup:**
- Erstelle spezifische Typen für verschiedene Anwendungsfälle (Vertrieb, Support, Beratung)
- Setze angemessene Pufferzeiten zwischen Meetings
- Nutze standortspezifische Event-Typen (Büro vs. Remote)
- Konfiguriere benutzerdefinierte Felder, um erforderliche Informationen zu sammeln

**Verfügbarkeitsverwaltung:**
- Setze realistische Arbeitszeiten
- Blockiere persönliche Zeit in verbundenen Kalendern
- Nutze mehrere Zeitpläne für verschiedene Jahreszeiten
- Aktiviere "Mindestvorlaufzeit", um Last-Minute-Buchungen zu vermeiden

**n8n-Integration:**
- Nutze interne URL (`http://calcom:3000`) für Performance
- Implementiere Fehlerbehandlung für fehlgeschlagene Buchungen
- Füge Deduplizierungslogik für Webhook-Events hinzu
- Speichere API-Schlüssel in n8n-Credentials, nicht hartcodiert

**Team-Koordination:**
- Nutze Round-Robin für Sales-Leads
- Richte kollektive Events für Panel-Interviews ein
- Konfiguriere Team-Routing-Regeln
- Überwache Team-Buchungsmetriken

**Kundenerfahrung:**
- Passe Bestätigungs-E-Mails mit Branding an
- Gib klare Meeting-Vorbereitungsanweisungen
- Richte automatische Erinnerungen ein
- Sammle Feedback nach Meetings
