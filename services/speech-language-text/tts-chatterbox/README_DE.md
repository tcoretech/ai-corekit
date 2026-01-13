# 🗣️ TTS Chatterbox - Fortgeschrittenes TTS

### Was ist TTS Chatterbox?

TTS Chatterbox ist ein hochmoderner Text-zu-Sprache-Dienst, der Emotionskontrolle, Stimmen-Klonen und mehrsprachige Unterstützung bietet. Basierend auf Resemble AIs Chatterbox-Modell erreichte es eine 63,75% Präferenzrate gegenüber ElevenLabs in Blindtests und ist damit eine der qualitativ hochwertigsten Open-Source-TTS-Lösungen, die verfügbar sind.

### Funktionen

- **Höchste Qualität**: 63,75% Präferenz gegenüber ElevenLabs in Blindtests
- **Emotionskontrolle**: Passe emotionale Intensität mit Exaggeration-Parameter an (0,25-2,0)
- **Stimmen-Klonen**: Klone jede Stimme mit nur 10-30 Sekunden Audio-Sample
- **22+ Sprachen**: Sprachbewusste Synthese für natürlich klingende Sprache
- **OpenAI-kompatible API**: Direkter Ersatz für OpenAI TTS API
- **Integriertes Wasserzeichen**: PerTh neuronales Wasserzeichen für Audio-Rückverfolgbarkeit
- **GPU-Beschleunigung**: <1 Sekunde pro Satz mit GPU-Unterstützung

### Erste Einrichtung

**Erster Login bei Chatterbox:**

1. Navigiere zu `https://chatterbox.deinedomain.com`
2. **Web-Oberfläche**: Einfache UI zum Testen von Stimmen und Generieren von Audio
3. **API-Schlüssel**: Wird während der Installation generiert und in `.env` gespeichert
4. Standard-Stimme sofort verfügbar

**Zugriffsmethoden:**
- **Web-UI**: `https://chatterbox.deinedomain.com` (zum Testen)
- **Interne API**: `http://chatterbox-tts:4123` (für n8n-Automatisierung)
- **Swagger-Docs**: `http://chatterbox-tts:4123/docs` (API-Dokumentation)

### n8n-Integration einrichten

**Erforderliche Anmeldedaten:**

1. Gehe zu n8n: `https://n8n.deinedomain.com`
2. Einstellungen → Anmeldedaten → Neu erstellen
3. Typ: HTTP Header Auth
4. Header hinzufügen:
   - **Name**: `X-API-Key`
   - **Wert**: `${CHATTERBOX_API_KEY}` (aus deiner `.env`-Datei)

**Interne URL:** `http://chatterbox-tts:4123`

### Beispiel-Workflows

#### Beispiel 1: Einfache Text-zu-Sprache mit Emotion

```javascript
// Generiere Sprache mit emotionaler Kontrolle

// 1. Trigger-Node (Webhook, Zeitplan, etc.)
// Eingabe: { "text": "Ich bin so begeistert davon!", "emotion": "happy" }

// 2. Set-Node - Ordne Emotion einem Exaggeration-Wert zu
const emotionMap = {
  "calm": 0.25,      // Sehr gedämpft
  "neutral": 0.5,    // Ausgewogen
  "normal": 1.0,     // Standard-Emotion
  "happy": 1.5,      // Fröhlich, energiegeladen
  "excited": 2.0,    // Sehr enthusiastisch
  "sad": 0.3,        // Melancholisch
  "angry": 1.8       // Intensiv
};

return {
  text: $json.text,
  exaggeration: emotionMap[$json.emotion] || 1.0
};

// 3. HTTP-Request-Node - Generiere Sprache mit Chatterbox
Methode: POST
URL: http://chatterbox-tts:4123/v1/audio/speech

Header:
  - Name: X-API-Key
    Wert: {{ $credentials.CHATTERBOX_API_KEY }}
  - Name: Content-Type
    Wert: application/json

Send Body: JSON
{
  "model": "chatterbox",
  "voice": "default",
  "input": "{{ $json.text }}",
  "response_format": "mp3",
  "exaggeration": {{ $json.exaggeration }},
  "language_id": "en"
}

Response Format: File
Put Output in Field: data

// 4. Aktions-Node - Audio verwenden
// Speichern, per E-Mail senden, in Speicher hochladen, etc.
```

#### Beispiel 2: Mehrsprachiges dynamisches Storytelling

```javascript
// Erstelle Hörbuch mit emotionsbewusster Erzählung

// 1. Google Docs-Trigger - Neues Kapitel hinzugefügt
// Oder aus CMS/Datenbank abrufen

// 2. Code-Node - Text parsen und Emotionen erkennen
const text = $json.chapter_text;

// Nach Dialog und Erzählung aufteilen
const segments = [];
const dialogueRegex = /"([^"]+)"/g;
let lastIndex = 0;
let match;

while ((match = dialogueRegex.exec(text)) !== null) {
  // Erzählung vor Dialog hinzufügen
  if (match.index > lastIndex) {
    segments.push({
      text: text.substring(lastIndex, match.index),
      type: 'narration',
      exaggeration: 0.5
    });
  }
  
  // Dialog hinzufügen
  segments.push({
    text: match[1],
    type: 'dialogue',
    exaggeration: 1.5  // Ausdrucksstärker für Dialog
  });
  
  lastIndex = match.index + match[0].length;
}

// Verbleibende Erzählung hinzufügen
if (lastIndex < text.length) {
  segments.push({
    text: text.substring(lastIndex),
    type: 'narration',
    exaggeration: 0.5
  });
}

return segments;

// 3. Loop-Node - Jeden Abschnitt verarbeiten
Items: {{ $json }}

// 4. HTTP-Request - Audio für Abschnitt generieren
Methode: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Header:
  X-API-Key: {{ $credentials.CHATTERBOX_API_KEY }}
Body: {
  "model": "chatterbox",
  "voice": "default",
  "input": "{{ $json.text }}",
  "exaggeration": {{ $json.exaggeration }},
  "language_id": "en"
}

// 5. Code-Node - Audio-Segmente zusammenfügen
// Verwende FFmpeg zum Zusammenführen aller Audio-Dateien

// 6. Google Drive - Komplettes Hörbuch-Kapitel hochladen
File Name: Chapter_{{ $json.chapter_number }}.mp3
```

#### Beispiel 3: Kundenservice mit geklonter Markenstimme

```javascript
// Verwende geklonte Unternehmenssprecher-Stimme für automatisierte Antworten

// 1. Webhook-Trigger - Kundenanfrage erhalten
// Eingabe: { "customer_name": "Alice", "question": "Was sind eure Öffnungszeiten?" }

// 2. HTTP-Request - Antwort aus Wissensdatenbank abrufen
// Oder verwende LLM zur Antwortgenerierung

// 3. Set-Node - Personalisierte Antwort formatieren
return {
  response: `Hallo ${$json.customer_name}, ${$json.answer}. Gibt es noch etwas, womit ich dir helfen kann?`
};

// 4. HTTP-Request - Sprache mit geklonter Stimme generieren
Methode: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Header:
  X-API-Key: {{ $credentials.CHATTERBOX_API_KEY }}
Body: {
  "model": "chatterbox",
  "voice": "company_spokesperson",  // Zuvor geklonte Stimme
  "input": "{{ $json.response }}",
  "exaggeration": 1.0,
  "language_id": "de"
}

// 5. Twilio-Node - Sprachantwort senden
// Oder Audio in Webhook-Antwort zurückgeben
```

#### Beispiel 4: Automatische Podcast-Generierung mit mehreren Sprechern

```javascript
// Erstelle Podcast mit verschiedenen Stimmen für Moderatoren und Gäste

// 1. RSS-Feed-Trigger - Neuer Blog-Beitrag veröffentlicht

// 2. HTTP-Request - An LLM für Podcast-Skript senden
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o",
  "messages": [{
    "role": "system",
    "content": "Konvertiere diesen Blog-Beitrag in ein Podcast-Skript mit Moderator- und Gast-Dialog."
  }, {
    "role": "user",
    "content": "{{ $json.blog_content }}"
  }]
}

// 3. Code-Node - Skript in Segmente parsen
const script = $json.response;
const segments = [];

// Parse "Moderator: Text" und "Gast: Text" Format
const lines = script.split('\n');
for (const line of lines) {
  if (line.startsWith('Moderator:')) {
    segments.push({
      speaker: 'host',
      text: line.replace('Moderator:', '').trim(),
      voice: 'host_voice',
      exaggeration: 1.2
    });
  } else if (line.startsWith('Gast:')) {
    segments.push({
      speaker: 'guest',
      text: line.replace('Gast:', '').trim(),
      voice: 'guest_voice',
      exaggeration: 1.0
    });
  }
}

return segments;

// 4. Loop-Node - Audio für jedes Segment generieren
Items: {{ $json }}

// 5. HTTP-Request - Chatterbox TTS
Methode: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Body: {
  "model": "chatterbox",
  "voice": "{{ $json.voice }}",
  "input": "{{ $json.text }}",
  "exaggeration": {{ $json.exaggeration }}
}

// 6. Code-Node - Audio-Segmente mit FFmpeg zusammenführen
// 7. Auf Podcast-Hosting-Plattform hochladen
```

### Stimmen-Klonen einrichten

Eine der leistungsstärksten Funktionen von Chatterbox ist die Fähigkeit, Stimmen mit minimalen Audio-Samples zu klonen.

**Schritt 1: Stimmen-Sample vorbereiten**

```bash
# SSH auf deinen Server
ssh user@deinedomain.com

# Stimmenverzeichnis erstellen
mkdir -p ~/ai-corekit/shared/tts/voices

# Lade dein Stimmen-Sample hoch (10-30 Sekunden empfohlen)
# Hochladen via SCP oder direkt speichern:
# scp voice_sample.wav user@deinedomain.com:~/ai-corekit/shared/tts/voices/
```

**Anforderungen für beste Ergebnisse:**
- **Dauer**: 10-30 Sekunden (mehr ist besser, bis zu 60 Sekunden)
- **Format**: WAV oder MP3 (WAV bevorzugt)
- **Qualität**: Klares Audio, minimale Hintergrundgeräusche
- **Inhalt**: Natürliche Sprache mit variierter Intonation
- **Einzelsprecher**: Nur eine Person in der Aufnahme

**Schritt 2: Stimme über API klonen (n8n)**

```javascript
// HTTP-Request-Node - Stimme klonen
Methode: POST
URL: http://chatterbox-tts:4123/v1/voice/clone

Header:
  - Name: X-API-Key
    Wert: {{ $credentials.CHATTERBOX_API_KEY }}

Send Body: Form Data Multipart
Body Parameter:
  1. Audio File:
     - Parameter Type: n8n Binary File
     - Name: audio_file
     - Input Data Field Name: data
  
  2. Voice Name:
     - Parameter Type: Form Data
     - Name: voice_name
     - Wert: meine_geklonte_stimme

// Antwort:
{
  "success": true,
  "voice_id": "meine_geklonte_stimme",
  "message": "Stimme erfolgreich geklont"
}
```

**Schritt 3: Geklonte Stimme verwenden**

```javascript
// HTTP-Request-Node - Mit geklonter Stimme generieren
Methode: POST
URL: http://chatterbox-tts:4123/v1/audio/speech
Body: {
  "model": "chatterbox",
  "voice": "meine_geklonte_stimme",  // Deine geklonte Stimmen-ID
  "input": "Dies wird in meiner geklonten Stimme gesprochen!",
  "exaggeration": 1.0
}
```

**Geklonte Stimmen verwalten:**

```bash
# Alle geklonten Stimmen auflisten
curl -X GET http://chatterbox-tts:4123/v1/voices \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}"

# Eine geklonte Stimme löschen
curl -X DELETE http://chatterbox-tts:4123/v1/voices/meine_geklonte_stimme \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}"
```

### Emotionskontroll-Leitfaden

Der `exaggeration`-Parameter kontrolliert die emotionale Intensität:

| Wert | Effekt | Am besten für |
|-------|--------|----------|
| **0,25** | Sehr ruhig, gedämpft | Meditation, ASMR, Entspannung |
| **0,5** | Ausgewogen, neutral | Erzählung, Hörbücher, formell |
| **1,0** | Normale Emotion | Allgemeine Nutzung, natürliche Sprache |
| **1,5** | Fröhlich, energiegeladen | Marketing, Begeisterung, fröhlich |
| **2,0** | Sehr emotional | Aufregung, dramatische Lesung |

**Beispiel-Szenarien:**

```javascript
// Nachrichtenlesung (neutral)
{ "exaggeration": 0.5, "text": "Die heutigen Schlagzeilen..." }

// Verkaufspräsentation (enthusiastisch)
{ "exaggeration": 1.8, "text": "Dieses erstaunliche Produkt..." }

// Gutenachtgeschichte (ruhig)
{ "exaggeration": 0.3, "text": "Es war einmal..." }

// Sportkommentar (aufgeregt)
{ "exaggeration": 2.0, "text": "TOR! Was für ein unglaubliches Spiel!" }
```

### Unterstützte Sprachen

Chatterbox unterstützt über 22 Sprachen mit sprachbewusster Synthese:

**Hauptsprachen:**
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
- Hebräisch: `he`
- Dänisch: `da`
- Finnisch: `fi`
- Griechisch: `el`
- Norwegisch: `no`
- Schwedisch: `sv`
- Swahili: `sw`

**Sprache in Anfrage angeben:**

```json
{
  "model": "chatterbox",
  "voice": "default",
  "input": "Hallo, wie geht es dir?",
  "language_id": "de"
}
```

### Leistungstipps

**CPU-Modus** (Standard):
- Geschwindigkeit: ~5-10 Sekunden pro Satz
- RAM: 2-4GB
- Am besten für: Geringe Auslastung, Entwicklung

**GPU-Modus** (Falls verfügbar):
- Geschwindigkeit: <1 Sekunde pro Satz
- VRAM: 4GB+
- Am besten für: Produktion, hohe Auslastung

**GPU aktivieren** (wenn dein Server eine NVIDIA GPU hat):

```bash
# Bearbeite docker-compose.yml
nano ~/ai-corekit/docker-compose.yml

# Finde chatterbox-tts Service, füge hinzu:
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]

# Umgebungsvariable hinzufügen:
environment:
  - CHATTERBOX_DEVICE=cuda

# Dienst neu starten
docker compose restart chatterbox-tts
```

**Optimierungstipps:**
- Speichere generierte Audiodaten zwischen, um Neugenerierung zu vermeiden
- Teile lange Texte in Sätze für schnellere Verarbeitung auf
- Verwende niedrigere Exaggeration-Werte für schnellere Generierung
- Modelle werden nach erstem Laden zwischengespeichert
- Verarbeite mehrere Anfragen im Batch, wenn möglich

### Fehlerbehebung

**Problem 1: Dienst antwortet nicht**

```bash
# Dienststatus prüfen
docker ps | grep chatterbox

# Sollte zeigen: STATUS = Up

# Logs prüfen
docker logs chatterbox-tts --tail 50

# Bei Bedarf neu starten
docker compose restart chatterbox-tts
```

**Problem 2: Erste Anfrage ist sehr langsam**

```bash
# Modell-Laden überwachen
docker logs chatterbox-tts -f

# Du wirst sehen:
# Loading Chatterbox model...
# Model loaded successfully (dauert beim ersten Mal 30-60 Sekunden)
```

**Lösung:**
- Erste Anfrage lädt Modell in den Speicher (~2GB, 30-60 Sekunden)
- Nachfolgende Anfragen sind viel schneller (5-10 Sekunden CPU, <1s GPU)
- Modell bleibt im Speicher, während Dienst läuft

**Problem 3: Audio-Qualität ist schlecht**

**Lösung:**
- Prüfe Exaggeration-Wert (zu hoch = verzerrt, zu niedrig = flach)
- Optimaler Bereich: 0,5-1,5 für die meisten Anwendungsfälle
- Für Stimmen-Klonen: Verwende hochwertige Quell-Audiodaten (klar, kein Rauschen)
- Stelle sicher, dass korrekter language_id zum Eingabetext passt
- Probiere verschiedene Stimmen oder klone eine benutzerdefinierte Stimme

**Problem 4: Stimmen-Klonen fehlgeschlagen**

```bash
# Audio-Dateiformat prüfen
file voice_sample.wav
# Sollte zeigen: RIFF (little-endian) data, WAVE audio

# Logs während des Klonens prüfen
docker logs chatterbox-tts -f
```

**Lösung:**
- Audio muss klar sein, Einzelsprecher, 10+ Sekunden
- Konvertiere bei Bedarf zu WAV: `ffmpeg -i input.mp3 -ar 22050 output.wav`
- Entferne Hintergrundgeräusche vor dem Klonen
- Mindestens 10 Sekunden, empfohlen 20-30 Sekunden
- Prüfe, ob API-Schlüssel in Request-Headern korrekt ist

**Problem 5: Kein Zugriff von n8n**

```bash
# Verbindung vom n8n-Container testen
docker exec n8n curl -I http://chatterbox-tts:4123/

# Sollte HTTP-Header zurückgeben

# API-Endpunkt testen
docker exec n8n curl -X POST http://chatterbox-tts:4123/v1/audio/speech \
  -H "X-API-Key: ${CHATTERBOX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"chatterbox","input":"test","voice":"default"}'
```

**Lösung:**
- Verwende interne URL: `http://chatterbox-tts:4123` (nicht localhost)
- Stelle sicher, dass beide Dienste im gleichen Docker-Netzwerk sind
- API-Schlüssel muss im Header sein: `X-API-Key: DEIN_SCHLÜSSEL`
- Prüfe, ob Dienst läuft: `docker ps | grep chatterbox`

**Problem 6: Audio klingt robotisch**

**Lösung:**
- Erhöhe Exaggeration (versuche 1,2-1,5)
- Verwende Stimmen-Klonen für natürlichere Ergebnisse
- Prüfe, ob Eingabetext korrekte Interpunktion hat
- Vermeide Text in Großbuchstaben (klingt wie geschrien)
- Füge Kommas für natürliche Pausen hinzu

### Ressourcen

- **GitHub**: https://github.com/travisvn/chatterbox-tts-api
- **Modell-Info**: https://www.resemble.ai/chatterbox/
- **API-Docs**: `http://chatterbox-tts:4123/docs` (nach Installation)
- **Paper**: https://www.resemble.ai/papers/chatterbox
- **Stimmen-Beispiele**: Verfügbar in der Web-UI

### Best Practices

**Für beste Audio-Qualität:**

1. **Eingabetext-Optimierung:**
   - Verwende korrekte Interpunktion (Kommas = Pausen, Punkte = Stopps)
   - Vermeide Abkürzungen (schreibe "Doktor" nicht "Dr.")
   - Schreibe Zahlen aus ("fünfundzwanzig" nicht "25")
   - Verwende natürliche Satzstruktur

2. **Emotionskontrolle:**
   - Beginne mit 1,0 und passe schrittweise an
   - Teste verschiedene Werte für deinen Anwendungsfall
   - Niedriger für formelle Inhalte, höher für energiegeladene
   - Konsistente Werte innerhalb desselben Kontexts

3. **Stimmen-Klonen-Tipps:**
   - Nimm in ruhiger Umgebung auf
   - Verwende externes Mikrofon, wenn möglich
   - Natürlicher, gesprächiger Ton im Sample
   - Variierte Intonation (nicht monoton)
   - 20-30 Sekunden ist der Sweet Spot

4. **Leistung:**
   - Speichere häufig verwendete Audiodaten zwischen
   - Generiere große Projekte über Nacht im Batch
   - Verwende GPU, wenn für Produktion verfügbar
   - Generiere häufige Phrasen vorab

5. **Mehrsprachig:**
   - Gib immer language_id für beste Ergebnisse an
   - Teste mit Muttersprachlern, wenn möglich
   - Einige Sprachen funktionieren besser als andere
   - Englisch hat insgesamt die beste Qualität

**Wann Chatterbox vs OpenedAI-Speech verwenden:**

**Verwende Chatterbox wenn du brauchst:**
- ✅ Emotionskontrolle und Ausdruck
- ✅ Stimmen-Klonen-Fähigkeit
- ✅ Höchste Qualität natürliche Sprache
- ✅ Marketing, Markenstimme, Podcasts
- ✅ Hörbücher mit Emotion
- ✅ Multi-Sprecher-Inhalte

**Verwende OpenedAI-Speech wenn du brauchst:**
- ✅ Schnellere Generierung (niedrigere Latenz)
- ✅ Mehr Stimmenvielfalt (60+ Stimmen)
- ✅ Geringerer Ressourcenverbrauch
- ✅ Einfache Benachrichtigungen
- ✅ Schnelles Prototyping

**Das Beste aus beiden Welten:**
- Verwende OpenedAI-Speech für Entwicklung/Testing
- Verwende Chatterbox für finale Produktions-Audiodaten
- Klone deine Markenstimme mit Chatterbox
- Verwende OpenedAI für schnelle Benachrichtigungen
