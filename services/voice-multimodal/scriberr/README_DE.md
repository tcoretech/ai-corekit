# 📝 Scriberr - Audio-Transkription mit Sprecher-Diarisierung

### Was ist Scriberr?

Scriberr ist ein fortschrittlicher KI-gestützter Audio-Transkriptionsdienst, der auf WhisperX basiert und hochpräzise Transkription mit Sprecher-Diarisierung (Identifizierung wer was gesagt hat) bietet. Perfekt für Meetings, Interviews, Podcasts und Anrufaufzeichnungen - Scriberr geht über einfache Transkription hinaus, indem es automatisch verschiedene Sprecher identifiziert und kennzeichnet, was es ideal für Multi-Sprecher-Inhaltsanalyse macht.

### Funktionen

- **WhisperX-basierte Transkription** - Hohe Genauigkeit mit präziser Zeitstempel-Ausrichtung
- **Sprecher-Diarisierung** - Identifiziert und kennzeichnet automatisch verschiedene Sprecher (Sprecher 1, Sprecher 2, etc.)
- **KI-Zusammenfassungen** - Generiere Meeting-Zusammenfassungen mit OpenAI- oder Anthropic-Modellen
- **YouTube-Unterstützung** - Transkribiere direkt von YouTube-URLs ohne Download
- **REST-API** - Volle Automatisierungsunterstützung für n8n und andere Tools
- **Mehrere Modelloptionen** - Wähle zwischen tiny bis large Modellen basierend auf Genauigkeitsbedarf
- **Mehrsprachige Unterstützung** - Unterstützt 99 Sprachen mit automatischer Erkennung

### Erste Einrichtung

**Erster Login bei Scriberr:**

1. Navigiere zu `https://scriberr.deinedomain.com`
2. Keine Authentifizierung standardmäßig erforderlich (nur internes Netzwerk)
3. Lade eine Test-Audiodatei hoch oder füge eine YouTube-URL ein
4. Konfiguriere Sprechererkennungseinstellungen:
   - **Min Sprecher**: Minimale Anzahl erwarteter Sprecher (Standard: 2)
   - **Max Sprecher**: Maximale Anzahl zu identifizierender Sprecher (Standard: 4)
5. Klicke auf "Transkribieren" und warte auf Verarbeitung
6. Erste Transkription lädt das Modell herunter (2-5 Minuten Ersteinrichtung)
7. Betrachte Ergebnisse mit Sprecher-Labels und Zeitstempeln

**Modellauswahl:**
- **tiny** (~1GB RAM): Schnelle Verarbeitung, Entwurfsqualität
- **base** (~1,5GB RAM): Gute Balance, empfohlener Standard
- **small** (~3GB RAM): Bessere Genauigkeit für Akzente
- **medium** (~5GB RAM): Professionelle Transkription
- **large** (~10GB RAM): Maximale Genauigkeit, langsamere Verarbeitung

### n8n-Integration einrichten

**Zugriff auf Scriberr-API von n8n:**

Scriberr bietet eine REST-API für vollständige Automatisierung. Verwende n8ns HTTP-Request-Node, um mit allen Funktionen zu interagieren.

**Interne URL:** `http://scriberr:8080`

**Verfügbare Endpunkte:**
- `POST /api/upload` - Audiodatei hochladen und transkribieren
- `GET /api/transcripts/{id}` - Transkript nach ID abrufen
- `POST /api/youtube` - Von YouTube-URL transkribieren
- `POST /api/summary` - KI-Zusammenfassung des Transkripts generieren
- `GET /api/models` - Verfügbare Whisper-Modelle auflisten

### Beispiel-Workflows

#### Beispiel 1: Meeting-Aufzeichnung zu Transkript mit Sprechern

```javascript
// Kompletter Workflow: Hochladen → Transkribieren → Sprecher identifizieren → Ergebnisse per E-Mail

// 1. HTTP-Request-Node - Audiodatei hochladen
Methode: POST
URL: http://scriberr:8080/api/upload
Send Body: Form Data Multipart
Body Parameter:
  - Datei: {{ $binary.data }}  // n8n Binary File
  - speaker_detection: true
  - min_speakers: 2
  - max_speakers: 4
  - model: base  // oder: tiny, small, medium, large

// Antwort enthält transcript_id für nächste Schritte

// 2. Wait-Node - Verarbeitungszeit
Time: 30 seconds
// Anpassen basierend auf Audio-Länge (1:1 Verhältnis typisch)

// 3. HTTP-Request-Node - Transkript-Ergebnisse abrufen
Methode: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// Antwortformat:
{
  "transcript_id": "abc123",
  "status": "completed",
  "text": "Vollständiger Transkript-Text...",
  "segments": [
    {
      "start": 0.0,
      "end": 3.5,
      "text": "Hallo zusammen, willkommen zum Meeting.",
      "speaker": "SPEAKER_00"
    },
    {
      "start": 3.5,
      "end": 7.2,
      "text": "Danke für die Einladung.",
      "speaker": "SPEAKER_01"
    }
  ],
  "speakers": {
    "SPEAKER_00": "Sprecher 1",
    "SPEAKER_01": "Sprecher 2"
  }
}

// 4. Code-Node - Transkript mit Sprecher-Labels formatieren
const segments = $input.item.json.segments;
const speakers = $input.item.json.speakers;

const formatted = segments.map(seg => {
  const speakerLabel = speakers[seg.speaker] || seg.speaker;
  const timestamp = new Date(seg.start * 1000).toISOString().substr(11, 8);
  return `[${timestamp}] ${speakerLabel}: ${seg.text}`;
}).join('\n\n');

return {
  formatted_transcript: formatted,
  full_text: $input.item.json.text
};

// 5. E-Mail-Node - Transkript an Teilnehmer senden
To: meeting@company.com
Subject: Meeting-Transkript - {{ $now.format('YYYY-MM-DD') }}
Body: |
  Meeting-Transkript (mit Sprecheridentifikation):
  
  {{ $json.formatted_transcript }}
  
  ---
  Vollständiges Transkript im Anhang.
```

#### Beispiel 2: YouTube-Video zu Meeting-Protokoll

```javascript
// YouTube-Video transkribieren und KI-Zusammenfassung generieren

// 1. Webhook-Trigger - YouTube-URL empfangen
// Input: { "youtube_url": "https://youtube.com/watch?v=..." }

// 2. HTTP-Request-Node - YouTube-Video transkribieren
Methode: POST
URL: http://scriberr:8080/api/youtube
Send Body: JSON
{
  "url": "{{ $json.youtube_url }}",
  "speaker_detection": true,
  "min_speakers": 1,
  "max_speakers": 5,
  "model": "small"  // Besser für Online-Videos
}

// Antwort: { "transcript_id": "xyz789", "status": "processing" }

// 3. Wait-Node - YouTube-Verarbeitung
Time: 2 minutes
// YouTube-Downloads dauern länger

// 4. HTTP-Request-Node - Transkript-Status prüfen
Methode: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// 5. HTTP-Request-Node - KI-Zusammenfassung generieren
Methode: POST
URL: http://scriberr:8080/api/summary
Send Body: JSON
{
  "transcript_id": "{{$json.transcript_id}}",
  "prompt": "Erstelle detailliertes Meeting-Protokoll mit:\n- Hauptdiskussionspunkte\n- Wichtige Entscheidungen\n- Aktionspunkte mit zugewiesenen Verantwortlichen\n- Follow-up-Punkte",
  "model": "gpt-4o-mini"  // oder: gpt-4, claude-3-5-sonnet
}

// Antwort:
{
  "summary": "# Meeting-Protokoll\n\n## Hauptpunkte...",
  "action_items": ["Aufgabe 1", "Aufgabe 2"]
}

// 6. Google Docs-Node - Dokument erstellen
Title: Meeting-Protokoll - {{ $now.format('YYYY-MM-DD') }}
Inhalt: |
  # Video-Meeting-Protokoll
  
  **Video:** {{ $json.youtube_url }}
  **Datum:** {{ $now.format('YYYY-MM-DD HH:mm') }}
  
  ## KI-Generierte Zusammenfassung
  {{ $json.summary }}
  
  ## Vollständiges Transkript mit Sprechern
  {{ $json.transcript_text }}
  
  ## Aktionspunkte
  {{ $json.action_items.map(item => `- [ ] ${item}`).join('\n') }}

// 7. Slack-Node - Team benachrichtigen
Kanal: #meetings
Nachricht: |
  📝 Neues Meeting-Protokoll verfügbar:
  {{ $json.document_url }}
  
  Wichtige Aktionspunkte:
  {{ $json.action_items[0] }}
  {{ $json.action_items[1] }}
```

#### Beispiel 3: Podcast-Verarbeitung mit Sprecher-Identifikation

```javascript
// Automatisierter Podcast-Transkriptions-Workflow

// 1. Google Drive-Trigger - Neue Datei im /Podcasts Ordner
// Überwacht neue Audio-Uploads

// 2. Google Drive-Node - Audiodatei herunterladen
File ID: {{ $json.id }}
Output: Binary

// 3. HTTP-Request-Node - Zu Scriberr hochladen
Methode: POST
URL: http://scriberr:8080/api/upload
Body: Form Data Multipart
  - Datei: {{ $binary.data }}
  - speaker_detection: true
  - min_speakers: 2  // Host + Gast
  - max_speakers: 3  // Falls mehrere Gäste
  - model: medium  // Besser für Produktionsqualität

// 4. Wait-Node - Verarbeitung
Time: {{ Math.ceil($json.duration / 60) }} minutes
// Verarbeitungszeit ≈ Audio-Länge

// 5. Loop-Node - Abfrage auf Fertigstellung
// Alle 30 Sekunden prüfen bis status = "completed"

// 6. HTTP-Request-Node - Ergebnisse abrufen
Methode: GET
URL: http://scriberr:8080/api/transcripts/{{$json.transcript_id}}

// 7. Code-Node - Podcast-Show-Notes erstellen
const segments = $input.item.json.segments;
const speakers = $input.item.json.speakers;

// Nach Sprecher gruppieren
const speakerSegments = {};
segments.forEach(seg => {
  if (!speakerSegments[seg.speaker]) {
    speakerSegments[seg.speaker] = [];
  }
  speakerSegments[seg.speaker].push(seg);
});

// Zeitstempel für bemerkenswerte Momente generieren
const timestamps = [];
segments.forEach((seg, i) => {
  const words = seg.text.split(' ');
  if (words.some(w => ['frage', 'wichtig', 'schlüssel', 'zusammenfassung'].includes(w.toLowerCase()))) {
    timestamps.push({
      time: Math.floor(seg.start),
      text: seg.text.substring(0, 100)
    });
  }
});

return {
  full_transcript: $input.item.json.text,
  speaker_count: Object.keys(speakerSegments).length,
  timestamps: timestamps.slice(0, 10),  // Top 10 Momente
  duration: segments[segments.length - 1].end
};

// 8. WordPress-Node - Show-Notes veröffentlichen
Title: {{ $json.podcast_title }}
Inhalt: |
  ## Podcast-Episode-Notizen
  
  **Dauer:** {{ Math.floor($json.duration / 60) }} Minuten
  **Sprecher:** {{ $json.speaker_count }}
  
  ### Wichtige Momente
  {{ $json.timestamps.map(t => `[${Math.floor(t.time / 60)}:${t.time % 60}] ${t.text}`).join('\n') }}
  
  ### Vollständiges Transkript
  {{ $json.full_transcript }}
  
  ---
  *Transkript automatisch generiert mit Scriberr*

// 9. Social-Media-Nodes - Episode bewerben
// Twitter, LinkedIn, etc. mit Schlüsselzitaten
```

#### Beispiel 4: Kundensupport-Anruf-Analyse

```javascript
// Support-Anrufe auf Qualität und Erkenntnisse analysieren

// 1. FTP-Trigger - Neue Anrufaufzeichnungen hochgeladen
// Oder Webhook vom Telefonsystem

// 2. HTTP-Request - Anruf transkribieren
Methode: POST
URL: http://scriberr:8080/api/upload
Body:
  - Datei: {{ $binary.data }}
  - speaker_detection: true
  - min_speakers: 2  // Agent + Kunde
  - max_speakers: 2

// 3. Wait + Transkript abrufen (siehe Beispiel 1)

// 4. Code-Node - Anrufqualität analysieren
const segments = $input.item.json.segments;

// Agent vs. Kunde identifizieren
const agentSpeaker = segments[0].speaker;  // Erster Sprecher = Agent
const customerSpeaker = segments.find(s => s.speaker !== agentSpeaker)?.speaker;

// Metriken berechnen
const agentWords = segments
  .filter(s => s.speaker === agentSpeaker)
  .reduce((sum, s) => sum + s.text.split(' ').length, 0);
  
const customerWords = segments
  .filter(s => s.speaker === customerSpeaker)
  .reduce((sum, s) => sum + s.text.split(' ').length, 0);

const talkRatio = agentWords / customerWords;
const callDuration = segments[segments.length - 1].end;
const avgPause = segments.reduce((sum, s, i, arr) => {
  if (i === 0) return 0;
  return sum + (s.start - arr[i-1].end);
}, 0) / segments.length;

return {
  transcript: $input.item.json.text,
  agent_speaker: agentSpeaker,
  customer_speaker: customerSpeaker,
  talk_ratio: talkRatio.toFixed(2),
  call_duration_seconds: callDuration,
  avg_pause_seconds: avgPause.toFixed(2),
  total_segments: segments.length
};

// 5. HTTP-Request - Sentiment-Analyse (OpenAI)
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [{
    "role": "system",
    "content": "Analysiere diesen Kundensupport-Anruf und bewerte: Kundenzufriedenheit (1-10), Problemlösung (ja/nein), Agent-Leistung (1-10), Hauptprobleme, Empfehlungen"
  }, {
    "role": "user",
    "content": "{{ $json.transcript }}"
  }]
}

// 6. IF-Node - Prüfe ob Eskalation erforderlich
If: {{ $json.customer_satisfaction < 5 }} OR {{ $json.issue_resolved === false }}

// 7a. Slack-Node - Manager alarmieren
Kanal: #support-escalations
Nachricht: |
  ⚠️ Anruf erfordert Überprüfung
  
  **Anrufdauer:** {{ $json.call_duration_seconds }}s
  **Kundenzufriedenheit:** {{ $json.customer_satisfaction }}/10
  **Problem gelöst:** {{ $json.issue_resolved }}
  **Hauptprobleme:** {{ $json.key_issues }}
  
  **Empfehlungen:** {{ $json.recommendations }}

// 7b. Datenbank - Anruf-Analysen speichern
// Metriken für Reporting-Dashboard einfügen
```

### Fehlerbehebung

**Problem 1: Erste Transkription dauert ewig**

```bash
# Modell wird bei erster Nutzung heruntergeladen - das ist normal
docker logs scriberr --tail 100

# Du wirst Modell-Download-Fortschritt sehen:
# Downloading WhisperX model: base
# Progress: [████████████] 100%

# Speicherplatz prüfen
df -h

# Modelle benötigen:
# tiny: ~40MB
# base: ~145MB
# small: ~466MB
# medium: ~1,5GB
# large: ~6GB
```

**Lösung:**
- Erste Transkription mit neuem Modell dauert 2-30 Minuten (Modell-Download)
- Nachfolgende Transkriptionen sind schnell (Modell gecacht)
- Modelle vorab herunterladen durch Test-Transkription nach Installation
- Ausreichenden Speicherplatz für Modelle sicherstellen

**Problem 2: Sprecher-Diarisierung funktioniert nicht**

```bash
# Sprechererkennungseinstellungen in API-Anfrage prüfen
# Verifiziere dass min_speakers und max_speakers korrekt gesetzt sind

# Scriberr-Logs prüfen
docker logs scriberr | grep -i "speaker\|diarization"

# Häufige Probleme:
# - Audio zu kurz (< 30 Sekunden)
# - Nur ein Sprecher im Audio
# - Schlechte Audioqualität (Hintergrundgeräusche)
# - min_speakers > tatsächliche Sprecher
```

**Lösung:**
- Audio muss mindestens 30 Sekunden für Diarisierung sein
- Setze realistische min/max Sprecherbereich (2-4 typisch)
- Stelle klares Audio mit deutlichen Sprechern bereit
- Verwende Mono-Audio (Stereo kann Diarisierung verwirren)
- Sprecher-Labels sind generisch (SPEAKER_00, SPEAKER_01) - bei Bedarf manuell umbenennen

**Problem 3: YouTube-Transkription schlägt fehl**

```bash
# Scriberr-Logs prüfen
docker logs scriberr --tail 50

# Häufige Fehler:
# - "Video unavailable" → Privates/eingeschränktes Video
# - "Network timeout" → Video zu lang
# - "Format not supported" → Altersbeschränkter Inhalt
```

**Lösung:**
- Verwende nur öffentliche, nicht eingeschränkte YouTube-Videos
- Für lange Videos (>2 Stunden), separat herunterladen und hochladen
- Prüfe dass YouTube-URL korrektes Format hat: `https://youtube.com/watch?v=...`
- Manche Unternehmensnetzwerke blockieren YouTube-Downloads - in anderem Netzwerk testen

**Problem 4: Speicherfehler**

```bash
# Container-Speichernutzung prüfen
docker stats scriberr --no-stream

# Server-RAM prüfen
free -h

# Scriberr-Speicheranforderungen:
# tiny Modell: ~1GB RAM
# base Modell: ~1,5GB RAM
# small Modell: ~3GB RAM
# medium Modell: ~5GB RAM
# large Modell: ~10GB RAM

# Docker-Container-Limits prüfen
docker inspect scriberr | grep -i memory
```

**Lösung:**
- Kleineres Modell verwenden (base statt large)
- Kürzere Audiodateien verarbeiten (<30 Minuten)
- Lange Dateien vor Upload aufteilen
- Docker-Speicherlimits in docker-compose.yml erhöhen
- Sicherstellen dass keine anderen schweren Dienste gleichzeitig laufen

**Problem 5: KI-Zusammenfassungsgenerierung schlägt fehl**

```bash
# Prüfen ob OpenAI/Anthropic API-Schlüssel konfiguriert ist
docker exec scriberr env | grep -i "api_key\|openai\|anthropic"

# Scriberr-Summary-Endpunkt prüfen
docker logs scriberr | grep -i "summary\|openai\|anthropic"
```

**Lösung:**
- OpenAI- oder Anthropic-API-Schlüssel in Scriberr-Einstellungen konfigurieren
- Oder lokales LLM über Open WebUI für Zusammenfassungen verwenden
- Summary-Endpunkt benötigt transcript_id von abgeschlossener Transkription
- Ausreichend API-Guthaben verfügbar sicherstellen
- Für Datenschutz, lokales LLM statt externer APIs verwenden

### Tipps für beste Ergebnisse

**Audioqualität ist wichtig:**
1. **Verwende hochwertige Aufnahmen:** WAV- oder FLAC-Format bevorzugt
2. **Mindestens 16kHz Abtastrate:** Höher ist besser (44,1kHz ideal)
3. **Klare, frontale Mikrofone:** Ansteckmikrofone oder gute USB-Mikrofone
4. **Hintergrundgeräusche minimieren:** Ruhiger Raum, Türen schließen, Lüfter ausschalten
5. **Kompression vermeiden:** Unkomprimiertes Audio hochladen wenn möglich

**Sprecher-Diarisierungs-Tipps:**
1. **Setze realistische Sprecheranzahl:** Die meisten Meetings haben 2-6 Sprecher
2. **Deutliche Sprecher:** Physische Trennung hilft bei Identifikation
3. **Überlappende Sprache vermeiden:** Auf Pausen zwischen Sprechern warten
4. **Längeres Audio = bessere Genauigkeit:** 5+ Minuten empfohlen
5. **Sprecher manuell kennzeichnen:** SPEAKER_00 → "Max Mustermann" in Nachbearbeitung

**Verarbeitungszeit-Optimierung:**
1. **Wähle richtiges Modell für Aufgabe:**
   - Entwicklung/Testing: tiny oder base
   - Produktion: small oder medium
   - Genauigkeitskritisch: large
2. **Audio vorverarbeiten:** Stille entfernen, Lautstärke normalisieren
3. **Lange Dateien aufteilen:** <30 Minuten pro Datei für schnellere Verarbeitung
4. **Batch-Verarbeitung:** Mehrere Dateien während Nebenzeiten in Warteschlange

**Integrations-Best-Practices:**
1. **Verwende Polling für lange Transkriptionen:** Status alle 30-60 Sekunden prüfen
2. **Fehler elegant behandeln:** Bei Netzwerkfehlern wiederholen
3. **Ergebnisse cachen:** Transkripte in Datenbank speichern um Neuverarbeitung zu vermeiden
4. **Webhook-Unterstützung:** Callbacks für asynchrone Verarbeitung konfigurieren
5. **Rate-Limiting:** Nicht mit simultanen Anfragen überlasten

### Ressourcen

- **GitHub:** https://github.com/rishikanthc/Scriberr
- **WhisperX Paper:** https://arxiv.org/abs/2303.00747
- **API-Dokumentation:** Verfügbar unter `http://scriberr:8080/docs` (wenn laufend)
- **Sprecher-Diarisierungs-Leitfaden:** https://github.com/pyannote/pyannote-audio
- **Modellvergleich:** https://github.com/openai/whisper#available-models-and-languages
- **Sprachunterstützung:** 99 Sprachen unterstützt von Whisper

### Wann Scriberr verwenden

**✅ Perfekt für:**
- Meeting-Aufzeichnungen mit mehreren Sprechern
- Podcast-Episode-Transkription
- Interview-Analyse
- Kundensupport-Anruf-Qualitätssicherung
- Rechtliche Aussagen und Gerichtsaufzeichnungen
- Fokusgruppen-Analyse
- Medizinische Konsultationen (mit entsprechender Einwilligung)
- Akademische Forschungsinterviews
- Konferenzvortrag-Transkription

**❌ Nicht ideal für:**
- Echtzeit-Live-Transkription (verwende stattdessen Vexa)
- Einzelsprecher mit Echtzeitanforderungen (verwende Faster-Whisper)
- Sehr kurze Audio-Clips (<10 Sekunden)
- Stark überlappende Sprache
- Extrem laute Umgebungen
- Musik-Transkription (nicht dafür konzipiert)

**Scriberr vs Faster-Whisper vs Vexa:**
- **Scriberr:** Am besten für Sprecher-Diarisierung, asynchrone Verarbeitung, detaillierte Transkripte
- **Faster-Whisper:** Am besten für Geschwindigkeit, Echtzeit-Apps, Einzelsprecher
- **Vexa:** Am besten für Live-Meeting-Transkription (Google Meet, Teams)
