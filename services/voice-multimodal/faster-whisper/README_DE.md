# 🎤 Faster-Whisper - Speech-to-Text

### Was ist Faster-Whisper?

Faster-Whisper ist eine optimierte Implementierung von OpenAIs Whisper-Spracherkennungsmodell, die OpenAI-kompatible API-Endpoints für Sprache-zu-Text-Transkription bereitstellt. Es bietet erhebliche Performance-Verbesserungen bei gleichbleibender Genauigkeit wie das Original-Whisper-Modell und ist somit perfekt für selbst gehostete Transkriptions-Workflows.

### Funktionen

- **OpenAI-kompatible API**: Drop-in-Ersatz für OpenAIs Whisper API
- **Hohe Performance**: Bis zu 4x schneller als die Original-Whisper-Implementierung
- **Multi-Sprachen-Unterstützung**: Transkribiere Audio in 99 Sprachen inkl. Englisch, Deutsch, Spanisch, Französisch, Chinesisch, Japanisch und mehr
- **Automatische Spracherkennung**: Keine Sprachangabe erforderlich, wenn unbekannt
- **Timestamp-Unterstützung**: Erhalte Zeitstempel auf Wort- und Satzebene
- **Mehrere Modellgrößen**: Wähle zwischen tiny, base, small, medium und large Modellen basierend auf Genauigkeit vs. Geschwindigkeit

### Ersteinrichtung

**Faster-Whisper ist intern bereitgestellt (kein direkter Web-Zugriff):**

- **Interne URL**: `http://faster-whisper:8000`
- **API Endpoint**: `/v1/audio/transcriptions`
- **Authentifizierung**: Nicht erforderlich (interner Service)
- **Modell-Loading**: Modelle werden beim ersten Gebrauch automatisch heruntergeladen

**Die erste Transkription dauert länger** (~2-5 Minuten), da das Modell heruntergeladen wird. Nachfolgende Transkriptionen sind viel schneller.

### n8n Integration Setup

**Keine Zugangsdaten erforderlich** - Faster-Whisper wird über HTTP Request Node mit interner URL aufgerufen.

**Interne URL:** `http://faster-whisper:8000`

### Beispiel-Workflows

#### Beispiel 1: Basis Audio-Transkription

```javascript
// 1. Trigger Node (Webhook, File Upload, etc.)
// Empfängt Audio-Datei in verschiedenen Formaten (mp3, wav, m4a, flac, etc.)

// 2. HTTP Request Node - Audio transkribieren
Methode: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Send Body: Form Data Multipart

Body Parameter:
1. Binary File:
   - Parameter Type: n8n Binary File
   - Name: file
   - Input Data Field Name: data

2. Modell:
   - Parameter Type: Form Data
   - Name: model
   - Wert: Systran/faster-whisper-large-v3

3. Language (optional):
   - Parameter Type: Form Data
   - Name: language
   - Wert: en
   // Unterstützt: en, de, es, fr, it, pt, nl, pl, ru, ja, ko, zh, ar, etc.

// Response-Format:
{
  "text": "Transkribierter Text erscheint hier..."
}

// 3. Set Node oder Code Node - Text extrahieren
// Zugriff auf Transkription: {{ $json.text }}
```

#### Beispiel 2: Sprache-zu-Sprache KI-Assistent

```javascript
// Komplette Sprachagenten-Pipeline

// 1. Telegram Trigger - Sprachnachricht empfangen
// Telegram sendet Audio-Datei automatisch

// 2. HTTP Request - Sprachdatei von Telegram herunterladen
Methode: GET
URL: {{ $json.file_url }}

// 3. HTTP Request - Mit Faster-Whisper transkribieren
Methode: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body: Form Data Multipart
  - Datei: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  - language: de  // oder 'en' für Englisch

// 4. AI Agent Node - Mit LLM verarbeiten
// OpenAI, Claude oder Ollama Node verwenden
Modell: gpt-4 / claude-3-5-sonnet / llama3.2
Prompt: Du bist ein hilfreicher Sprachassistent. Antworte auf: {{ $json.text }}

// 5. HTTP Request - Sprachantwort generieren
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Header:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.response }}",
  "voice": "alloy"  // oder "thorsten" für Deutsch
}

// 6. Telegram Node - Audio-Antwort senden
Action: Send Audio
Audio: {{ $binary.data }}

// Benutzer erhält KI-Sprachantwort in Sekunden!
```

#### Beispiel 3: Meeting-Aufnahmen Auto-Transkription

```javascript
// Automatisierter Meeting-Transkript-Workflow

// 1. Schedule Trigger - Neue Aufnahmen prüfen
// Oder Webhook von Videokonferenz-Tool

// 2. Google Drive Node - Aktuelle Aufnahmen auflisten
Folder: /Recordings
Filter: Erstellt in den letzten 24 Stunden

// 3. Loop Node - Jede Aufnahme verarbeiten
Items: {{ $json.files }}

// 4. Google Drive - Audio-Datei herunterladen
File ID: {{ $json.id }}

// 5. HTTP Request - Mit Zeitstempeln transkribieren
Methode: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body:
  - Datei: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  - language: en
  - timestamp_granularities: ["segment"]  // Wort- oder Segment-Ebene

// 6. HTTP Request - Mit LLM zusammenfassen
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [{
    "role": "system",
    "content": "Fasse dieses Meeting-Transkript mit Kernpunkten und Action Items zusammen."
  }, {
    "role": "user",
    "content": "{{ $json.text }}"
  }]
}

// 7. Google Docs - Meeting-Notizen erstellen
Title: Meeting Notes - {{ $json.meeting_date }}
Inhalt: 
  ## Meeting-Transkript
  {{ $json.transcription }}
  
  ## Zusammenfassung
  {{ $json.summary }}
  
  ## Action Items
  - [ ] {{ $json.action_items }}

// 8. Gmail - An Teilnehmer senden
To: {{ $json.participants }}
Subject: Meeting Notes - {{ $now.format('YYYY-MM-DD') }}
```

#### Beispiel 4: Multi-Sprachen Kundensupport

```javascript
// Automatische Transkription und Übersetzung

// 1. Webhook - Voicemail von Kunde empfangen
// Audio-Datei in beliebiger Sprache

// 2. HTTP Request - Transkribieren (Auto-Erkennung der Sprache)
Methode: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body:
  - Datei: {{ $binary.data }}
  - model: Systran/faster-whisper-large-v3
  // Keine Sprache angegeben = Auto-Erkennung

// Antwort enthält erkannte Sprache:
{
  "text": "Transkribierter Text",
  "language": "de"  // Erkannt: Deutsch
}

// 3. IF Node - Prüfen ob Übersetzung benötigt
If: {{ $json.language }} !== 'en'

// 4. HTTP Request - Ins Englische übersetzen
Methode: POST
URL: http://translate:5000/translate
Body: {
  "q": "{{ $json.text }}",
  "source": "{{ $json.language }}",
  "target": "en"
}

// 5. Set Node - Informationen kombinieren
{
  "original_text": "{{ $node.Transcribe.json.text }}",
  "original_language": "{{ $json.language }}",
  "translated_text": "{{ $json.translatedText }}",
  "customer_id": "{{ $json.customer_id }}"
}

// 6. Ticket im CRM mit beiden Versionen erstellen
// 7. Support-Team benachrichtigen
```

### Modell-Auswahl-Leitfaden

Wähle das richtige Modell basierend auf deinen Anforderungen:

| Modell | RAM | Geschwindigkeit | Qualität | Am besten für |
|-------|-----|-----------------|----------|---------------|
| **tiny** | ~1GB | Schnellste | Gut | Echtzeit, Entwicklung, Testing |
| **base** | ~1.5GB | Schnell | Besser | Standard-Wahl, ausgewogene Performance |
| **small** | ~3GB | Mittel | Gut | Akzente, professionelle Nutzung |
| **medium** | ~5GB | Langsam | Sehr gut | Hohe Genauigkeitsanforderungen |
| **large-v3** | ~10GB | Langsamste | Beste | Maximale Qualität, komplexes Audio |

**Modell-Download-Zeiten (nur beim ersten Mal):**
- tiny: ~40MB (~30 Sekunden)
- base: ~145MB (~1 Minute)
- small: ~466MB (~3 Minuten)
- medium: ~1.5GB (~8 Minuten)
- large-v3: ~6GB (~30 Minuten)

**Empfohlene Einstellungen:**
- **Nur Englisch**: `large-v3` für beste Genauigkeit
- **Multi-Sprachen**: `large-v3` mit Spracherkennung
- **Echtzeit-Apps**: `base` oder `small` für Geschwindigkeit
- **Entwicklung/Testing**: `tiny` für schnelle Iteration

### Fehlerbehebung

**Problem 1: Erste Transkription ist sehr langsam**

```bash
# Modell wird beim ersten Gebrauch heruntergeladen - das ist normal
# Download-Fortschritt prüfen
docker logs faster-whisper

# Du siehst:
# Downloading model: Systran/faster-whisper-large-v3
# Progress: [████████████████████] 100%

# Nachfolgende Transkriptionen sind schnell
```

**Lösung:**
- Erste Anfrage dauert 2-30 Minuten je nach Modellgröße
- Nachfolgende Anfragen werden in Sekunden abgeschlossen
- Modelle vorab herunterladen, indem du nach Installation eine Test-Transkription durchführst

**Problem 2: Deutsches Audio wird als englischer Kauderwelsch transkribiert**

```bash
# Problem: Falsches Modell oder keine Sprache angegeben
```

**Lösung:**
- Verwende vollständiges Modell: `Systran/faster-whisper-large-v3` (nicht distil Version)
- Füge Sprach-Parameter hinzu: `"language": "de"`
- Distil-Modelle haben schlechte Nicht-Englisch-Unterstützung

**Problem 3: Transkriptions-Qualität ist schlecht**

```bash
# Audio-Qualität prüfen
ffmpeg -i input.mp3 -af "volumedetect" -f null -

# Prüfen auf:
# - Niedrige Lautstärke (< -20dB)
# - Starke Hintergrundgeräusche
# - Mehrere Sprecher gleichzeitig
```

**Lösung:**
- Verwende größeres Modell (medium oder large-v3)
- Audio vorverarbeiten, um Rauschen zu entfernen
- Multi-Sprecher-Audio vor Transkription aufteilen
- Stelle sicher, dass Audio mindestens 16kHz Sample-Rate hat
- In Mono umwandeln, wenn Stereo (Whisper verwendet Mono)

**Problem 4: Service antwortet nicht / Timeout**

```bash
# Service-Status prüfen
docker ps | grep faster-whisper

# Logs prüfen
docker logs faster-whisper --tail 50

# Service neustarten
docker compose restart faster-whisper

# Speichernutzung prüfen (Modelle benötigen RAM)
free -h
```

**Lösung:**
- Stelle sicher, dass Server genug RAM für Modell hat (siehe Tabelle oben)
- Erste Transkription löst Modell-Download aus (warte 5-30 Min)
- Logs auf Out-of-Memory-Fehler prüfen
- Auf kleineres Modell reduzieren, wenn RAM unzureichend

**Problem 5: Kein Zugriff von n8n aus**

```bash
# API-Endpoint testen
docker exec n8n curl http://faster-whisper:8000/

# Sollte zurückgeben: {"detail":"Not Found"}
# Das bestätigt, dass Service erreichbar ist

# Tatsächlichen Transkriptions-Endpoint testen
docker exec n8n curl -X POST http://faster-whisper:8000/v1/audio/transcriptions
```

**Lösung:**
- Verwende interne URL: `http://faster-whisper:8000` (nicht localhost)
- Stelle sicher, dass beide Services im selben Docker-Netzwerk sind
- Prüfe ob Service läuft: `docker ps | grep faster-whisper`

### Sprach-Unterstützung

Faster-Whisper unterstützt 99 Sprachen:

**Häufige Sprachen:**
- Englisch: `en`
- Deutsch: `de`
- Spanisch: `es`
- Französisch: `fr`
- Italienisch: `it`
- Portugiesisch: `pt`
- Niederländisch: `nl`
- Polnisch: `pl`
- Russisch: `ru`
- Japanisch: `ja`
- Koreanisch: `ko`
- Chinesisch: `zh`
- Arabisch: `ar`
- Türkisch: `tr`
- Hindi: `hi`

**Auto-Erkennung:**
- Lasse `language`-Parameter weg für Auto-Erkennung
- Whisper erkennt Sprache automatisch
- Etwas langsamer als Sprachangabe
- Sehr genau für die meisten Sprachen

### Ressourcen

- **GitHub**: https://github.com/SYSTRAN/faster-whisper
- **Original Whisper**: https://github.com/openai/whisper
- **Model Card**: https://huggingface.co/Systran/faster-whisper-large-v3
- **Sprach-Unterstützung**: https://github.com/openai/whisper#available-models-and-languages
- **API-Dokumentation**: OpenAI-kompatible Endpoints

### Best Practices

**Für beste Transkriptions-Ergebnisse:**

1. **Audio-Qualität ist wichtig:**
   - Verwende verlustfreie Formate wenn möglich (WAV, FLAC)
   - Mindestens 16kHz Sample-Rate (höher ist besser)
   - Klare, frontale Mikrofon-Aufnahmen
   - Minimiere Hintergrundgeräusche

2. **Wähle das richtige Modell:**
   - Entwicklung: tiny/base für Geschwindigkeit
   - Produktion: medium/large-v3 für Genauigkeit
   - Echtzeit: base/small mit Streaming

3. **Gib Sprache an, wenn bekannt:**
   - Schnellere Verarbeitung (überspringt Erkennung)
   - Etwas bessere Genauigkeit
   - Erforderlich für beste Nicht-Englisch-Ergebnisse

4. **Audio vorverarbeiten:**
   - Lautstärke-Pegel normalisieren
   - Lange Pausen entfernen
   - Dateien >30 Minuten für bessere Verarbeitung aufteilen
   - In Mono umwandeln (Whisper nutzt kein Stereo)

5. **Fehler elegant behandeln:**
   - Retry-Logik für Netzwerkprobleme hinzufügen
   - Audio-Format vor Senden validieren
   - Angemessenes Timeout setzen (5-10 Min für lange Dateien)
   - Ergebnisse cachen, um Wiederverarbeitung zu vermeiden

6. **Performance optimieren:**
   - Mehrere Dateien mit Queue im Batch verarbeiten
   - Kleinere Modelle für Preview/Entwurf verwenden
   - Modelle während Nebenzeiten vorab herunterladen
   - Server-RAM-Nutzung überwachen

**Wann Faster-Whisper verwenden:**

- ✅ Sprachnachrichten, Voicemail-Transkription
- ✅ Meeting- und Interview-Aufnahmen
- ✅ Podcast- und Video-Untertitel
- ✅ Sprachbefehl-Oberflächen
- ✅ Multi-Sprachen Kundensupport
- ✅ Barrierefreiheits-Features (Untertitel)
- ✅ Sprachgesteuerte Workflows und Automatisierung
- ❌ Echtzeit Live-Transkription (verwende stattdessen Scriberr/Vexa)
- ❌ Sprecher-Diarisierung (verwende stattdessen Scriberr)
