# 📞 Vexa - Echtzeit-Meeting-Transkriptions-Bot

### Was ist Vexa?

Vexa ist ein Echtzeit-Meeting-Transkriptionsdienst, der KI-Bots in Online-Meetings (Google Meet & Microsoft Teams) schickt, um Live-Konversationen mit Sprecheridentifikation zu erfassen. Im Gegensatz zu Post-Meeting-Transkription treten Vexa-Bots Meetings als Teilnehmer bei und liefern Echtzeit-Transkripte mit Sub-Sekunden-Latenz über WebSocket-Streaming. Perfekt für automatisierte Meeting-Notizen, Vertriebsanruf-Analyse und Compliance-Aufzeichnung.

⚠️ **Wichtig:** Bei Problemen mit Installation oder Aktualisierung von Vexa, siehe [Vexa Troubleshooting Guide](https://github.com/freddy-schuetz/ai-corekit/blob/main/vexa-troubleshooting-workarounds.md)

### Funktionen

- **Echtzeit-Transkription** - Sub-Sekunden-Latenz über WebSocket-Streaming
- **Google Meet & Teams Bots** - Automatisierter Bot tritt Meeting als Teilnehmer bei
- **Sprecher-Identifikation** - Verfolge wer was in Echtzeit gesagt hat
- **99 Sprachen** - Mehrsprachige Transkription mit Auto-Erkennung
- **REST & WebSocket APIs** - Wähle zwischen Polling oder Streaming
- **Privacy-First** - Alle Daten bleiben auf deinem Server, keine externen Abhängigkeiten

### Erste Einrichtung

**Vexa läuft in einem separaten Docker-Netzwerk** und benötigt spezielle Konfiguration.

**Zugriffs-URLs:**
- **User-API:** `http://localhost:8056` (von n8n)
- **Admin-API:** `http://localhost:8057` (benötigt Admin-Token)
- **Nicht öffentlich zugänglich** (nur interne API)

**API-Authentifizierung:**

Während der Installation generiert Vexa:
1. **User-API-Key** - Im Installationsbericht angezeigt, für Bot-Steuerung verwendet
2. **Admin-Token** - Für Benutzerverwaltung (siehe `.env`-Datei)

**API-Schlüssel abrufen:**

```bash
# Vexa API-Schlüssel aus Installationslogs anzeigen
cd ~/ai-corekit
grep "VEXA_API_KEY" .env

# Oder Installationsbericht prüfen
cat installation-report-*.txt | grep -A5 "Vexa"
```

**Whisper-Modell konfigurieren:**

Vor Installation `.env` bearbeiten, um Whisper-Modell auszuwählen:

```bash
# Standard ist 'base' - gute Balance
VEXA_WHISPER_MODEL=base

# Optionen: tiny, base, small, medium, large
# Siehe Modellauswahl-Leitfaden unten
```

### n8n-Integration einrichten

**⚠️ Kritisch:** Vexa verwendet separates Docker-Netzwerk. Von n8n aus immer verwenden:
- **API-URL:** `http://localhost:8056`
- **NICHT** `http://vexa:8056` (funktioniert nicht!)

**Interne URL:** `http://localhost:8056`

**Verfügbare Endpunkte:**
- `POST /bots` - Transkriptions-Bot im Meeting starten
- `GET /transcripts/{platform}/{meeting_id}` - Transkript abrufen
- `DELETE /bots/{meeting_id}` - Bot stoppen (stoppt automatisch wenn Meeting endet)
- `GET /` - Gesundheitscheck

### Beispiel-Workflows

#### Beispiel 1: Google Meet-Meetings automatisch transkribieren

```javascript
// Kompletter Workflow: Kalender → Bot beitritt → Transkript → Zusammenfassung → E-Mail

// 1. Google Calendar-Trigger-Node
Event: Event Starting
Time Before: 2 minutes

// 2. IF-Node - Prüfe ob Google Meet-Link existiert
Bedingung: {{$json.hangoutLink}} exists

// 3. Code-Node - Meeting-ID extrahieren
// Google Meet URL: https://meet.google.com/abc-defg-hij
// Meeting-ID ist: abc-defg-hij

const meetUrl = $input.item.json.hangoutLink;
const meetingId = meetUrl.split('/').pop();

return {
  meeting_id: meetingId,
  meeting_title: $input.item.json.summary,
  attendees: $input.item.json.attendees.map(a => a.email)
};

// 4. HTTP-Request-Node - Vexa-Bot starten
Methode: POST
URL: http://localhost:8056/bots
Send Header: ON
Header:
  X-API-Key: {{$env.VEXA_API_KEY}}
Send Body: JSON
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// Antwort:
{
  "id": 1,
  "status": "requested",
  "bot_container_id": "vexa_bot_abc123",
  "platform": "google_meet",
  "native_meeting_id": "abc-defg-hij"
}

// 5. Wait-Node - Meeting-Dauer
Wait: {{$('Calendar Trigger').json.duration}} minutes
// Oder Puffer hinzufügen: + 10 Minuten

// 6. HTTP-Request-Node - Transkript abrufen
Methode: GET
URL: http://localhost:8056/transcripts/google_meet/{{$('Code Node').json.meeting_id}}
Header:
  X-API-Key: {{$env.VEXA_API_KEY}}

// Antwort:
{
  "transcript": [
    {
      "start": 0.5,
      "end": 3.2,
      "text": "Guten Morgen zusammen, danke fürs Kommen.",
      "speaker": "Sprecher 1"
    },
    {
      "start": 3.5,
      "end": 6.8,
      "text": "Freut mich hier zu sein.",
      "speaker": "Sprecher 2"
    }
  ],
  "full_text": "Guten Morgen zusammen...",
  "speakers": ["Sprecher 1", "Sprecher 2"],
  "language": "de"
}

// 7. Code-Node - Transkript formatieren
const transcript = $input.item.json.transcript;

const formatted = transcript.map(seg => {
  const time = new Date(seg.start * 1000).toISOString().substr(14, 5);
  return `[${time}] ${seg.speaker}: ${seg.text}`;
}).join('\n\n');

return {
  formatted_transcript: formatted,
  full_text: $input.item.json.full_text,
  speaker_count: $input.item.json.speakers.length
};

// 8. OpenAI-Node - Meeting-Zusammenfassung generieren
Modell: gpt-4o-mini
Prompt: |
  Erstelle detaillierte Meeting-Notizen aus diesem Transkript:
  
  {{$json.full_text}}
  
  Beinhalte:
  - Hauptdiskussionspunkte
  - Getroffene Entscheidungen
  - Aktionspunkte mit Verantwortlichen
  - Follow-up-Fragen

// 9. Google Docs-Node - Meeting-Notizen erstellen
Title: Meeting-Notizen - {{$('Calendar Trigger').json.summary}} - {{$now.format('YYYY-MM-DD')}}
Inhalt: |
  # Meeting: {{$('Calendar Trigger').json.summary}}
  **Datum:** {{$now.format('YYYY-MM-DD HH:mm')}}
  **Teilnehmer:** {{$('Code Node').json.attendees.join(', ')}}
  **Dauer:** {{$('Calendar Trigger').json.duration}} Minuten
  **Sprecher identifiziert:** {{$('Code Node').json.speaker_count}}
  
  ---
  
  ## KI-Zusammenfassung
  {{$('OpenAI').json.summary}}
  
  ---
  
  ## Vollständiges Transkript mit Zeitstempeln
  {{$('Code Node').json.formatted_transcript}}

// 10. Gmail-Node - Notizen per E-Mail an Teilnehmer
To: {{$('Code Node').json.attendees.join(',')}}
Subject: Meeting-Notizen - {{$('Calendar Trigger').json.summary}}
Body: |
  Hallo Team,
  
  Meeting-Notizen sind fertig!
  
  Dokument ansehen: {{$('Google Docs').json.document_url}}
  
  Wichtige Erkenntnisse:
  {{$('OpenAI').json.key_points}}
  
  Beste Grüße
```

#### Beispiel 2: Microsoft Teams-Meeting-Transkription

```javascript
// Teams-Meetings mit Passcode-Unterstützung transkribieren

// 1. Webhook-Trigger - Teams-Meeting-Info empfangen
// Input: {
//   "meeting_id": "12345678",
//   "passcode": "ABC123",
//   "title": "Kundengespräch",
//   "duration": 30
// }

// 2. HTTP-Request - Vexa-Bot in Teams starten
Methode: POST
URL: http://localhost:8056/bots
Header:
  X-API-Key: {{$env.VEXA_API_KEY}}
Body: {
  "platform": "teams",
  "native_meeting_id": "{{$json.meeting_id}}",
  "passcode": "{{$json.passcode}}"  // Erforderlich für Teams
}

// Antwort enthält bot_container_id

// 3. Wait-Node - Meeting-Dauer + Puffer
Wait: {{$json.duration + 5}} minutes

// 4. HTTP-Request - Transkript abrufen
Methode: GET
URL: http://localhost:8056/transcripts/teams/{{$json.meeting_id}}
Header:
  X-API-Key: {{$env.VEXA_API_KEY}}

// 5. Transkript verarbeiten (wie in Beispiel 1)
```

#### Beispiel 3: Vertriebsanruf-Analyse-Pipeline

```javascript
// Automatisierte Vertriebsanruf-Intelligenz

// 1. Schedule-Trigger - Prüfe auf geplante Vertriebsanrufe
Cron: Every 5 minutes
// Oder: CRM-Webhook wenn Anruf geplant wird

// 2. Salesforce-Node - Kommende Anrufe abrufen
Abfrage: SELECT Id, Meeting_Link__c, Account_Name__c 
       FROM Event 
       WHERE StartDateTime = NEXT_HOUR 
       AND Type = 'Sales Call'

// 3. Loop-Node - Jeden Anruf verarbeiten
Items: {{$json}}

// 4. Code-Node - Google Meet-ID extrahieren
const meetUrl = $item.Meeting_Link__c;
const meetingId = meetUrl.split('/').pop();
return { meeting_id: meetingId, account: $item.Account_Name__c };

// 5. HTTP-Request - Vexa-Bot starten
Methode: POST
URL: http://localhost:8056/bots
Header:
  X-API-Key: {{$env.VEXA_API_KEY}}
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// 6. Wait - 35 Minuten (typische Anrufdauer)
Wait: 35 minutes

// 7. HTTP-Request - Transkript abrufen
Methode: GET
URL: http://localhost:8056/transcripts/google_meet/{{$json.meeting_id}}

// 8. OpenAI-Node - Vertriebs-Intelligenz extrahieren
Modell: gpt-4o
Prompt: |
  Analysiere dieses Vertriebsanruf-Transkript:
  
  {{$json.full_text}}
  
  Extrahiere und gib JSON zurück:
  {
    "pain_points": ["Liste der Kundenschmerzpunkte"],
    "objections": ["Liste der Einwände"],
    "budget_mentioned": true/false,
    "decision_timeline": "erwähnter Zeitrahmen",
    "competitors_mentioned": ["Wettbewerber-Namen"],
    "next_steps": ["vereinbarte Aktionspunkte"],
    "sentiment": "positive/neutral/negative",
    "deal_probability": "high/medium/low",
    "key_quotes": ["wichtige Aussagen"]
  }

// 9. Code-Node - Sprechzeit-Verhältnis berechnen
const transcript = $input.item.json.transcript;

// Annahme: Erster Sprecher ist Vertriebsmitarbeiter
const repSpeaker = transcript[0].speaker;
const repTime = transcript
  .filter(s => s.speaker === repSpeaker)
  .reduce((sum, s) => sum + (s.end - s.start), 0);

const totalTime = transcript[transcript.length - 1].end;
const repTalkRatio = (repTime / totalTime * 100).toFixed(1);

return {
  rep_talk_ratio: repTalkRatio,
  customer_talk_ratio: (100 - repTalkRatio).toFixed(1),
  // Gut: 30-40% Mitarbeiter, 60-70% Kunde
  quality_score: repTalkRatio < 45 ? 'Gut' : 'Verbesserungsbedarf'
};

// 10. Salesforce-Node - Opportunity aktualisieren
Update Record:
  Object: Opportunity
  Record ID: {{$('Salesforce').json.OpportunityId}}
  Fields:
    Pain_Points__c: {{$('OpenAI').json.pain_points.join(', ')}}
    Objections__c: {{$('OpenAI').json.objections.join(', ')}}
    Deal_Probability__c: {{$('OpenAI').json.deal_probability}}
    Rep_Talk_Ratio__c: {{$('Code Node').json.rep_talk_ratio}}
    Call_Sentiment__c: {{$('OpenAI').json.sentiment}}
    Next_Steps__c: {{$('OpenAI').json.next_steps.join('\n')}}

// 11. Slack-Node - Vertriebsleiter bei Problemen alarmieren
IF: {{$('Code Node').json.rep_talk_ratio > 60}} OR {{$('OpenAI').json.sentiment === 'negative'}}

Kanal: #sales-management
Nachricht: |
  ⚠️ Vertriebsanruf benötigt Überprüfung
  
  **Konto:** {{$('Loop').json.account}}
  **Problem:** Mitarbeiter sprach {{$('Code Node').json.rep_talk_ratio}}% (sollte <45% sein)
  **Stimmung:** {{$('OpenAI').json.sentiment}}
  
  **Haupteinwände:**
  {{$('OpenAI').json.objections.join('\n- ')}}
  
  **Empfohlene Maßnahmen:**
  - Coaching zu Zuhörfähigkeiten
  - Einwandbehandlung überprüfen
  - Manager-Follow-up-Anruf erwägen

// 12. Gmail - Zusammenfassung an Vertriebsmitarbeiter senden
To: sales.rep@company.com
Subject: Anruf-Zusammenfassung - {{$('Loop').json.account}}
Body: |
  Dein Anruf wurde analysiert:
  
  **Leistung:**
  - Sprechzeit-Verhältnis: {{$('Code Node').json.rep_talk_ratio}}% ✅/⚠️
  - Stimmung: {{$('OpenAI').json.sentiment}}
  
  **Kunden-Schmerzpunkte:**
  {{$('OpenAI').json.pain_points.join('\n- ')}}
  
  **Nächste Schritte:**
  {{$('OpenAI').json.next_steps.join('\n- ')}}
  
  **Schlüsselzitate:**
  {{$('OpenAI').json.key_quotes.join('\n- ')}}
```

#### Beispiel 4: Compliance-Aufzeichnungssystem

```javascript
// Automatische Compliance-Aufzeichnung mit Alarmierung

// 1. Webhook - Meeting mit Compliance-Flag geplant
// Input: { "meeting_id": "abc-def-ghi", "requires_compliance": true }

// 2. IF-Node - Compliance-Anforderung prüfen
If: {{$json.requires_compliance}} === true

// 3. HTTP-Request - Vexa-Bot starten
Methode: POST
URL: http://localhost:8056/bots
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// 4. E-Mail - Teilnehmer über Aufzeichnung informieren
To: {{$json.participants}}
Subject: Meeting-Aufzeichnungsbenachrichtigung
Body: |
  Dieses Meeting wird zu Compliance-Zwecken aufgezeichnet.
  
  Ein Transkriptions-Bot wird automatisch beitreten.
  Durch Verbleiben im Meeting stimmst du der Aufzeichnung zu.

// 5. Wait - Meeting-Dauer
// 6. Transkript abrufen
// 7. In sicherer Datenbank speichern

// 8. Code-Node - Nach Compliance-Schlüsselwörtern scannen
const transcript = $input.item.json.full_text.toLowerCase();
const flags = [];

const keywords = {
  'legal': ['klage', 'anwalt', 'rechtliche schritte', 'gericht'],
  'financial': ['insider', 'vertraulich', 'wesentliche informationen'],
  'hr': ['belästigung', 'diskriminierung', 'feindliches umfeld']
};

for (const [category, words] of Object.entries(keywords)) {
  for (const word of words) {
    if (transcript.includes(word)) {
      flags.push({ category, keyword: word });
    }
  }
}

return { compliance_flags: flags, flag_count: flags.length };

// 9. IF-Node - Alarmieren wenn Flags gefunden
If: {{$json.flag_count > 0}}

// 10. E-Mail - Compliance-Team-Alarm
To: compliance@company.com
Priority: High
Subject: Compliance-Überprüfung erforderlich
Body: |
  Meeting-Transkript zur Überprüfung markiert:
  
  **Flags:** {{$json.flag_count}}
  **Kategorien:** {{$json.compliance_flags.map(f => f.category).join(', ')}}
  
  Transkript sofort überprüfen.

// 11. Datenbank - Mit Metadaten speichern
Table: compliance_transcripts
Fields:
  - meeting_id
  - transcript
  - flags
  - review_status: 'pending'
  - recorded_at: timestamp
```

### Modellauswahl-Leitfaden

Wähle Whisper-Modell basierend auf deinen Bedürfnissen:

| Modell | RAM | Geschwindigkeit | Qualität | Am besten für |
|--------|-----|-----------------|----------|---------------|
| **tiny** | ~1GB | Am schnellsten | Gut | Testing, Entwicklung |
| **base** | ~1,5GB | Schnell | Besser | **Empfohlener Standard** |
| **small** | ~3GB | Mittel | Gut | Akzente, mehrere Sprachen |
| **medium** | ~5GB | Langsam | Großartig | Hohe Genauigkeitsanforderungen |
| **large** | ~10GB | Am langsamsten | Am besten | Maximale Qualität (übertrieben für die meisten) |

**Echtzeit-Leistung:**
- **tiny/base:** Am besten für Live-Transkription (<1s Latenz)
- **small/medium:** Leichte Verzögerung aber bessere Genauigkeit
- **large:** Nicht empfohlen für Echtzeit (zu langsam)

**Vor Installation konfigurieren:**
```bash
# .env-Datei bearbeiten
VEXA_WHISPER_MODEL=base  # Hier ändern
VEXA_WHISPER_DEVICE=cpu   # Oder 'cuda' für GPU
```

### Fehlerbehebung

**Problem 1: Bot tritt Meeting nicht bei**

```bash
# Vexa-Dienststatus prüfen
docker ps | grep vexa

# Sollte Container anzeigen:
# - vexa-api
# - vexa-bot-manager

# Bot-Logs prüfen
docker logs vexa-api --tail 100

# Häufige Fehler:
# - "Meeting not found" → Meeting-ID-Format prüfen
# - "Meeting not started" → Meeting muss aktiv sein
# - "Access denied" → Google Meet Lobby-Einstellungen prüfen
```

**Lösung:**
- **Google Meet:** "Personen vor Host beitreten lassen" in Google Workspace-Einstellungen aktivieren
- **Meeting muss aktiv sein:** Bot kann noch nicht gestarteten Meetings nicht beitreten
- **Meeting-ID prüfen:** Für `meet.google.com/abc-defg-hij`, nur `abc-defg-hij` verwenden
- **Lobby-Einstellungen:** Lobby-Modus deaktivieren oder Meeting vor Bot-Beitritt starten
- **Teams-Passcode:** Immer erforderlich für Teams-Meetings mit Lobby

**Problem 2: "Separates Docker-Netzwerk"-Verbindungsfehler**

```bash
# Vexa läuft in separatem Netzwerk - localhost verwenden, nicht Dienstnamen
# ❌ FALSCH: http://vexa:8056
# ✅ RICHTIG: http://localhost:8056

# Konnektivität von n8n testen
docker exec n8n curl http://localhost:8056/

# Sollte zurückgeben: {"message": "Vexa API"}

# Bei Verbindungsfehler, Port-Mapping prüfen
docker port vexa-api 8056
```

**Lösung:**
- Immer `http://localhost:8056` von n8n verwenden
- NICHT `http://vexa:8056` verwenden (anderes Netzwerk)
- Vexa ist nicht im Haupt-Docker-Compose-Netzwerk
- Dies ist absichtlich für Sicherheitsisolierung

**Problem 3: Transkript leer oder unvollständig**

```bash
# Prüfen ob Bot erfolgreich beigetreten ist
docker logs vexa-bot-manager | grep "Joined meeting"

# Whisper-Verarbeitung prüfen
docker logs vexa-api | grep -i "whisper\|transcription"

# Meeting-Dauer prüfen
# Bot benötigt mindestens 30 Sekunden Audio um Transkript zu generieren
```

**Lösung:**
- Mindestens 30 Sekunden nach Meeting-Start warten
- Sicherstellen dass Teilnehmer sprechen (Stille = kein Transkript)
- Prüfen ob Bot vom Host aus Meeting entfernt wurde
- Verifizieren dass Whisper-Modell heruntergeladen ist (erste Ausführung braucht Zeit)
- Für sehr kurze Meetings kann Transkript minimal sein

**Problem 4: API-Key-Authentifizierung fehlgeschlagen**

```bash
# Vexa-API-Key finden
cd ~/ai-corekit
grep "VEXA_API_KEY" .env

# Oder Admin-API für Benutzer prüfen
curl -H "Authorization: Bearer $(grep VEXA_ADMIN_TOKEN .env | cut -d= -f2)" \
  http://localhost:8057/admin/users

# API-Key bei Bedarf neu generieren
docker exec vexa-api python3 manage.py create-user
```

**Lösung:**
- API-Key in `.env`-Datei prüfen: `VEXA_API_KEY=...`
- Header einschließen: `X-API-Key: YOUR_KEY` in allen Anfragen
- Groß-/Kleinschreibung beachten: exakte Key-Übereinstimmung sicherstellen
- Falls verloren, über Admin-API neu generieren oder neu installieren

**Problem 5: Hohe Speichernutzung**

```bash
# Container-Speicher prüfen
docker stats vexa-api vexa-bot-manager --no-stream

# Whisper-Modelle verwenden RAM:
# tiny: ~1GB
# base: ~1,5GB
# small: ~3GB
# medium: ~5GB
# large: ~10GB

# Aktuelles Modell prüfen
grep VEXA_WHISPER_MODEL .env
```

**Lösung:**
- Kleineres Whisper-Modell verwenden (base statt large)
- Bot-Container werden pro Meeting erstellt (Cleanup erfolgt automatisch)
- Server-RAM überwachen: `free -h`
- Jeder aktive Bot verwendet 1,5-5GB je nach Modell
- Gleichzeitige Meetings begrenzen bei RAM-Beschränkung
- Bots bereinigen sich automatisch wenn Meetings enden

**Problem 6: Vexa-Installation fehlgeschlagen**

```bash
# Bei Installationsproblemen, siehe Workaround-Leitfaden:
# https://github.com/freddy-schuetz/ai-corekit/blob/main/vexa-troubleshooting-workarounds.md

# Häufige Probleme während Installation:
# - Docker-Netzwerk-Konflikte
# - Port 8056/8057 bereits verwendet
# - Whisper-Modell-Download-Timeout

# Vexa-Logs während Installation prüfen
tail -f /var/log/ai-corekit-install.log | grep -i vexa
```

**Lösung:**
- [Vexa Troubleshooting Guide](https://github.com/freddy-schuetz/ai-corekit/blob/main/vexa-troubleshooting-workarounds.md) folgen
- Die meisten Probleme lösen sich mit den dokumentierten Workarounds
- Falls Probleme bestehen bleiben, ist Vexa optional und kann übersprungen werden

### Meeting-Plattform-Unterstützung

| Plattform | Status | Meeting-ID-Format | Anforderungen |
|-----------|--------|-------------------|---------------|
| **Google Meet** | ✅ Bereit | `abc-defg-hij` | Aus meet.google.com URL extrahieren |
| **Microsoft Teams** | ✅ Bereit | Numerisch + Passcode | Benötigt Meeting-Passcode |
| **Zoom** | ⏳ Kommt bald | - | Für zukünftige Version geplant |

**Google Meet-Einrichtung:**
1. Meeting-ID aus URL extrahieren: `https://meet.google.com/abc-defg-hij` → Verwende `abc-defg-hij`
2. "Personen vor Host beitreten lassen" in Google Workspace-Einstellungen aktivieren
3. Lobby-Modus deaktivieren oder Meeting vor Bot-Beitritt starten
4. Bot erscheint als "Vexa Transcription Bot"-Teilnehmer

**Microsoft Teams-Einrichtung:**
1. Meeting-ID (numerisch) und Passcode von Teams abrufen
2. Beide in API-Anfrage einschließen: `{"native_meeting_id": "12345", "passcode": "ABC123"}`
3. Sicherstellen dass Lobby deaktiviert ist oder Meeting gestartet ist
4. Bot erscheint als Teilnehmer in Teams

### API-Referenz

**Transkriptions-Bot starten:**
```bash
POST http://localhost:8056/bots
Header: X-API-Key: YOUR_KEY
Body: {
  "platform": "google_meet",  # oder "teams"
  "native_meeting_id": "abc-defg-hij",
  "passcode": "ABC123"  # Nur Teams
}

Antwort: {
  "id": 1,
  "status": "requested",
  "bot_container_id": "vexa_bot_abc123",
  "platform": "google_meet",
  "native_meeting_id": "abc-defg-hij"
}
```

**Transkript abrufen (Polling):**
```bash
GET http://localhost:8056/transcripts/{platform}/{meeting_id}
Header: X-API-Key: YOUR_KEY

Antwort: {
  "transcript": [
    {
      "start": 0.5,
      "end": 3.2,
      "text": "Hallo zusammen",
      "speaker": "Sprecher 1"
    }
  ],
  "full_text": "Vollständiges Transkript...",
  "speakers": ["Sprecher 1", "Sprecher 2"],
  "language": "de"
}
```

**Bot stoppen (Optional):**
```bash
DELETE http://localhost:8056/bots/{meeting_id}
Header: X-API-Key: YOUR_KEY

# Hinweis: Bots verlassen automatisch wenn Meeting endet
```

**Gesundheitscheck:**
```bash
GET http://localhost:8056/
# Gibt zurück: {"message": "Vexa API"}
```

**Admin-API (Benutzerverwaltung):**
```bash
GET http://localhost:8057/admin/users
Header: Authorization: Bearer YOUR_ADMIN_TOKEN

# Neuen API-Key erstellen
POST http://localhost:8057/admin/users/{user_id}/tokens
```

### Ressourcen

- **GitHub:** https://github.com/Vexa-ai/vexa
- **Troubleshooting-Guide:** https://github.com/freddy-schuetz/ai-corekit/blob/main/vexa-troubleshooting-workarounds.md
- **Whisper-Modell-Info:** https://github.com/openai/whisper#available-models-and-languages
- **Sprachunterstützung:** 99 Sprachen unterstützt

### Best Practices

**Wann Vexa verwenden:**

✅ **Perfekt für:**
- Automatisierte Meeting-Notizen (Google Meet, Teams)
- Vertriebsanruf-Aufzeichnung und -Analyse
- Compliance-Aufzeichnungsanforderungen
- Echtzeit-Transkriptionsbedarf
- Multi-Sprecher-Meeting-Erfassung
- CRM-Integrations-Workflows
- Qualitätssicherungs-Monitoring
- Remote-Team-Zusammenarbeit

❌ **Nicht ideal für:**
- Vorab aufgezeichnete Audiodateien (verwende stattdessen Scriberr)
- Zoom-Meetings (noch nicht unterstützt)
- Meetings die du nicht organisiert hast (Datenschutz-/Einwilligungsfragen)
- Sehr kurze Meetings (<1 Minute)
- Meetings wo Bot-Teilnehmer nicht erlaubt ist

**Datenschutz & Einwilligung:**

⚠️ **Rechtliche Anforderungen:**
- Teilnehmer immer informieren dass Meeting aufgezeichnet wird
- Lokale Gesetze prüfen (manche erfordern Einwilligung aller Parteien)
- Bot erscheint als sichtbarer Teilnehmer im Meeting
- Erwäge Aufzeichnungshinweis zu Kalendereinladungen hinzuzufügen
- Transkripte sicher speichern und DSGVO/Datenschutzgesetze einhalten

**Optimale Konfiguration:**

1. **Modellauswahl:**
   - Entwicklung/Testing: `tiny` oder `base`
   - Produktion: `base` (beste Balance)
   - Hohe Genauigkeit: `small` oder `medium`
   - Vermeiden: `large` (übertrieben, zu langsam für Echtzeit)

2. **Meeting-Setup:**
   - Lobby-Modus wenn möglich deaktivieren
   - Meeting vor Bot-Beitritt starten (besonders Teams)
   - "Vor Host beitreten" für Google Meet aktivieren
   - Bot mit Beispiel-Meeting vor Produktion testen

3. **Ressourcenplanung:**
   - 1,5-3GB RAM pro aktivem Bot (base/small Modell)
   - Für gleichzeitige Meetings planen
   - Server-Ressourcen während Spitzenzeiten überwachen
   - Auto-Scaling für große Deployments erwägen

4. **Integrationsstrategie:**
   - Kalender-Webhooks verwenden um Bots automatisch zu starten
   - Wiederholungslogik für fehlgeschlagene Bot-Beitritte implementieren
   - Transkript-Endpunkt alle 30-60 Sekunden abfragen
   - Transkripte in Datenbank zur Sicherung speichern
   - Transkripte cachen um Neuverarbeitung zu vermeiden

**Vexa vs Scriberr vs Faster-Whisper:**

| Funktion | Vexa | Scriberr | Faster-Whisper |
|----------|------|----------|----------------|
| **Anwendungsfall** | Live-Meeting-Bots | Post-Recording-Diarisierung | Einzelsprecher-Transkription |
| **Plattformen** | Google Meet, Teams | Vorab aufgezeichnete Dateien, YouTube | Beliebige Audiodatei |
| **Sprecher-ID** | Echtzeit | Nachbearbeitung | Nein |
| **Latenz** | <1 Sekunde | Minuten (Verarbeitung) | Sekunden bis Minuten |
| **Am besten für** | Automatisierte Meeting-Notizen | Detaillierte Analyse | Sprachbefehle, einfache Transkription |
