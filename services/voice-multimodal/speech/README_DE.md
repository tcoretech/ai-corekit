# 🔊 OpenedAI-Speech - Text-zu-Sprache

### Was ist OpenedAI-Speech?

OpenedAI-Speech ist ein selbst gehosteter Text-zu-Sprache-Dienst, der OpenAI-kompatible API-Endpunkte bereitstellt, angetrieben von Piper TTS. Er bietet hochwertige, natürlich klingende Stimmen in mehreren Sprachen mit vollständiger Privatsphäre - die gesamte Audio-Generierung erfolgt auf deinem Server, ohne Daten an externe Dienste zu senden.

### Funktionen

- **OpenAI-kompatible API**: Direkter Ersatz für OpenAIs TTS-API (`/v1/audio/speech`)
- **Mehrere Stimmenmodelle**: Vorkonfigurierte englische Stimmen (alloy, echo, fable, onyx, nova, shimmer)
- **Mehrsprachige Unterstützung**: Füge Stimmen in über 50 Sprachen hinzu, darunter Deutsch, Französisch, Spanisch, Italienisch und mehr
- **Schnelle Generierung**: ~2-5 Sekunden pro Satz auf CPU, <1 Sekunde mit GPU
- **Privatsphäre zuerst**: Die gesamte Audio-Generierung erfolgt lokal auf deinem Server
- **Automatischer Modell-Download**: Stimmenmodelle werden beim ersten Gebrauch automatisch heruntergeladen

### Erste Einrichtung

**OpenedAI-Speech ist intern bereitgestellt (kein direkter Webzugriff):**

- **Interne URL**: `http://openedai-speech:8000`
- **API-Endpunkt**: `/v1/audio/speech`
- **Authentifizierung**: Bearer-Token (Dummy-Token akzeptiert: `sk-dummy`)
- **Stimmenmodelle**: Werden beim ersten Gebrauch automatisch heruntergeladen

**Vorkonfigurierte englische Stimmen:**
- `alloy` - Neutrale, ausgewogene Stimme
- `echo` - Männliche, selbstbewusste Stimme
- `fable` - Britische, narrative Stimme
- `onyx` - Tiefe, autoritative Stimme
- `nova` - Weibliche, energiegeladene Stimme
- `shimmer` - Sanfte, warme Stimme

### n8n-Integration einrichten

**Keine Anmeldedaten erforderlich** - OpenedAI-Speech wird über den HTTP-Request-Node mit Dummy-Authentifizierung aufgerufen.

**Interne URL:** `http://openedai-speech:8000`

### Beispiel-Workflows

#### Beispiel 1: Einfache Text-zu-Sprache

```javascript
// 1. Trigger-Node (Webhook, Zeitplan, etc.)
// Eingabetext zur Umwandlung in Sprache

// 2. HTTP-Request-Node - Sprache generieren
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech

Header:
  - Name: Content-Type
    Wert: application/json
  - Name: Authorization
    Wert: Bearer sk-dummy

Send Body: JSON
{
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "alloy",
  "response_format": "mp3"
}

Response Format: File
Put Output in Field: data

// 3. Aktions-Node - Audio verwenden
// In Datei speichern, per E-Mail senden, in Cloud hochladen, etc.
```

#### Beispiel 2: Mehrsprachige Sprachantwort

```javascript
// Text-zu-Sprache auf Deutsch oder Englisch

// 1. Webhook-Trigger - Empfange Text + Sprache
// Eingabe: { "text": "Hallo Welt", "language": "de" }

// 2. IF-Node - Prüfe Sprache
If: {{ $json.language }} === 'de'

// 3a. HTTP-Request - Deutsche Stimme
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Header:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "thorsten"  // Deutsche männliche Stimme
}

// 3b. HTTP-Request - Englische Stimme
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "alloy"
}

// 4. HTTP-Response - Audio-Datei zurückgeben
Antwort: Binary
Binary Property: data
```

#### Beispiel 3: Automatisierte Podcast-Generierung

```javascript
// Generiere Audio-Podcast aus Blog-Beiträgen

// 1. RSS-Feed-Trigger - Neuer Blog-Beitrag veröffentlicht
// Oder Zeitplan-Trigger + RSS abrufen

// 2. HTTP-Request - Artikel-Inhalt abrufen
Methode: GET
URL: {{ $json.link }}

// 3. HTML-Extrahierungs-Node - Haupttext extrahieren
Selector: article, .post-content, main
Output: text

// 4. Code-Node - Text bereinigen und formatieren
const text = $input.item.json.text;

// Überflüssige Leerzeichen entfernen
const cleaned = text.replace(/\s+/g, ' ').trim();

// In Abschnitte aufteilen (Piper hat ~500 Zeichen-Limit pro Anfrage)
const chunks = [];
const sentences = cleaned.match(/[^.!?]+[.!?]+/g) || [cleaned];
let currentChunk = '';

for (const sentence of sentences) {
  if ((currentChunk + sentence).length < 450) {
    currentChunk += sentence;
  } else {
    if (currentChunk) chunks.push(currentChunk);
    currentChunk = sentence;
  }
}
if (currentChunk) chunks.push(currentChunk);

return chunks.map(chunk => ({ text: chunk }));

// 5. Loop-Node - Jeden Abschnitt verarbeiten
Items: {{ $json }}

// 6. HTTP-Request - Sprache für Abschnitt generieren
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Header:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.text }}",
  "voice": "fable"  // Britische Erzähler-Stimme
}

// 7. Code-Node - Audio-Dateien zusammenfügen
// Verwende FFmpeg, um alle Audio-Abschnitte zu verbinden

// 8. In Cloud-Speicher hochladen - Finale Podcast-Audio
// Google Drive, S3, Dropbox, etc.

// 9. WordPress/Ghost aktualisieren - Audio-Player zum Beitrag hinzufügen
```

#### Beispiel 4: Sprachaktivierte Kundenbenachrichtigungen

```javascript
// Sprachnachrichten an Kunden senden

// 1. Webhook-Trigger - Bestellstatus-Update
// Eingabe: { "customer_phone": "+491234567890", "status": "shipped", "order_id": "12345" }

// 2. Set-Node - Benachrichtigungsnachricht erstellen
const messages = {
  shipped: `Deine Bestellung ${$json.order_id} wurde versandt! Verfolge dein Paket auf unserer Website.`,
  delivered: `Großartig! Deine Bestellung ${$json.order_id} wurde zugestellt. Viel Freude mit deinem Kauf!`,
  delayed: `Entschuldigung, aber Bestellung ${$json.order_id} hat sich verzögert. Wir informieren dich bald.`
};

return {
  phone: $json.customer_phone,
  message: messages[$json.status] || 'Bestellungs-Update verfügbar'
};

// 3. HTTP-Request - Sprachnachricht generieren
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Header:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "{{ $json.message }}",
  "voice": "nova"  // Freundliche weibliche Stimme
}

// 4. Twilio-Node - Sprachanruf tätigen
Action: Make Call
To: {{ $json.phone }}
URL: [URL zur gehosteten Audio-Datei]

// Oder WhatsApp/Telegram mit Audio-Nachricht
```

### Deutsche Stimmen hinzufügen (oder andere Sprachen)

OpenedAI-Speech verwendet Piper TTS, welches über 50 Sprachen unterstützt. So fügst du deutsche Stimmen hinzu:

**Schritt 1: Stimmen-Konfiguration bearbeiten**

```bash
# Auf deinen Server zugreifen
ssh user@deinedomain.com

# Zum AI CoreKit navigieren
cd ~/ai-corekit

# Stimmen-Konfiguration bearbeiten
nano openedai-config/voice_to_speaker.yaml
```

**Schritt 2: Deutsche Stimmen hinzufügen**

Finde den `tts-1`-Abschnitt und füge deutsche Stimmen hinzu:

```yaml
tts-1:
  # Bestehende englische Stimmen...
  alloy:
    model: en_US-amy-medium
    speaker: # Standard-Sprecher
  
  # Deutsche Stimmen unten hinzufügen:
  thorsten:
    model: de_DE-thorsten-medium
    speaker: # Standard-Sprecher
  eva:
    model: de_DE-eva_k-x_low
    speaker: # Standard-Sprecher
  kerstin:
    model: de_DE-kerstin-low
    speaker: # Standard-Sprecher
```

**Schritt 3: Dienst neu starten**

```bash
docker compose restart openedai-speech
```

**Schritt 4: Deutsche Stimmen in n8n verwenden**

```javascript
// HTTP-Request-Node
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Header:
  Content-Type: application/json
  Authorization: Bearer sk-dummy
Body: {
  "model": "tts-1",
  "input": "Hallo, dies ist ein Test der deutschen Sprachausgabe.",
  "voice": "thorsten"  // Hochwertige deutsche männliche Stimme
}
```

**Verfügbare deutsche Stimmen:**

| Stimme | Geschlecht | Qualität | Geschwindigkeit | Am besten für |
|-------|--------|---------|-------|----------|
| `thorsten` | Männlich | Medium | Ausgewogen | Allgemeine Nutzung, professionell |
| `eva` | Weiblich | X-Low | Sehr schnell | Schnelle Benachrichtigungen |
| `kerstin` | Weiblich | Low | Schnell | Lockere Inhalte |

**Mehr Stimmen verfügbar unter:** https://rhasspy.github.io/piper-samples/

### Andere Sprachen hinzufügen

Der gleiche Prozess funktioniert für jede von Piper unterstützte Sprache:

**Beliebte Sprachcodes:**
- Deutsch: `de_DE`
- Französisch: `fr_FR`
- Spanisch: `es_ES`
- Italienisch: `it_IT`
- Portugiesisch: `pt_BR`
- Niederländisch: `nl_NL`
- Polnisch: `pl_PL`
- Russisch: `ru_RU`

**Beispiel: Französische Stimme hinzufügen**

```yaml
tts-1:
  # Französische Stimme
  marie:
    model: fr_FR-siwis-medium
    speaker: # Standard-Sprecher
```

Dienst neu starten und verwenden: `"voice": "marie"`

### Stimmenmodell-Download

**Modelle werden automatisch beim ersten Gebrauch heruntergeladen:**

1. Erste Anfrage mit einer neuen Stimme löst Download aus
2. Download-Zeit: ~30-90 Sekunden pro Stimme
3. Modelle werden dauerhaft zwischengespeichert (~20-100MB pro Stimme)
4. Nachfolgende Anfragen sind sofort

**Download-Fortschritt prüfen:**

```bash
docker logs openedai-speech -f
```

### Antwort-Formate

OpenedAI-Speech unterstützt mehrere Audio-Formate:

**Verfügbare Formate:**
- `mp3` - Komprimiert, kleine Dateigröße (Standard)
- `opus` - Hohe Qualität, effiziente Kompression
- `aac` - Gute Qualität, breite Kompatibilität
- `flac` - Verlustfrei, große Dateigröße
- `wav` - Unkomprimiert, beste Qualität, sehr groß
- `pcm` - Rohe Audio-Daten

**Format in Anfrage angeben:**

```json
{
  "model": "tts-1",
  "input": "Hallo Welt",
  "voice": "alloy",
  "response_format": "opus"
}
```

### Fehlerbehebung

**Problem 1: Dienst antwortet nicht**

```bash
# Dienststatus prüfen
docker ps | grep openedai-speech

# Sollte zeigen: STATUS = Up

# Logs prüfen
docker logs openedai-speech --tail 50

# Bei Bedarf neu starten
docker compose restart openedai-speech
```

**Lösung:**
- Stelle sicher, dass der Dienst läuft: `docker ps | grep openedai-speech`
- Prüfe auf Port-Konflikte (Port 8000 wird von Supabase Kong verwendet)
- OpenedAI-Speech verwendet Port 8000 intern (über Dienstname erreichbar)

**Problem 2: Stimme nicht gefunden-Fehler**

```bash
# Verfügbare Stimmen prüfen
docker exec openedai-speech cat /app/config/voice_to_speaker.yaml

# Schreibweise des Stimmennamens überprüfen
# Stimmennamen sind groß-/kleinschreibungssensitiv!
```

**Lösung:**
- Stimmennamen müssen exakt übereinstimmen (groß-/kleinschreibungssensitiv)
- Prüfe `voice_to_speaker.yaml` für konfigurierte Stimmen
- Standard-Stimmen: alloy, echo, fable, onyx, nova, shimmer
- Benutzerdefinierte Stimmen: Müssen zur Konfigurationsdatei hinzugefügt werden

**Problem 3: Erste Anfrage ist sehr langsam**

```bash
# Modell-Download überwachen
docker logs openedai-speech -f

# Du wirst sehen:
# Downloading voice model: en_US-amy-medium
# Progress: [████████████████████] 100%
```

**Lösung:**
- Erste Anfrage lädt Stimmenmodell herunter (~30-90 Sekunden)
- Nachfolgende Anfragen werden in 2-5 Sekunden abgeschlossen
- Modelle werden dauerhaft zwischengespeichert
- Lade Modelle vorab herunter, indem du jede Stimme nach der Einrichtung testest

**Problem 4: Deutsche Stimme klingt falsch**

```bash
# Stimmen-Konfiguration prüfen
docker exec openedai-speech cat /app/config/voice_to_speaker.yaml | grep -A 2 thorsten

# Sollte zeigen:
# thorsten:
#   model: de_DE-thorsten-medium
#   speaker:
```

**Lösung:**
- Stelle korrekten Modellcode sicher: `de_DE-thorsten-medium` (nicht `en_US`)
- Stimme muss zu `voice_to_speaker.yaml` hinzugefügt werden
- Dienst nach Konfigurationsänderungen neu starten
- Überprüfe, ob Sprachcode zum Stimmenmodell passt

**Problem 5: Audio-Qualität ist schlecht**

**Lösung:**
- Verwende höherwertige Stimmenmodelle:
  - `*-low` → `*-medium` → `*-high`
- Wechsle zu unkomprimiertem Format: `"response_format": "wav"`
- Probiere verschiedene Stimmen aus (einige sind qualitativ hochwertiger)
- Für beste Qualität: Verwende Medium- oder High-Quality-Modelle
- Beispiel: `en_US-libritts-high` (beste englische Qualität)

**Problem 6: Kein Zugriff von n8n**

```bash
# Verbindung vom n8n-Container testen
docker exec n8n curl http://openedai-speech:8000/

# Sollte Health-Check oder Fehlerseite zurückgeben

# Tatsächlichen TTS-Endpunkt testen
docker exec n8n curl -X POST http://openedai-speech:8000/v1/audio/speech \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{"model":"tts-1","input":"test","voice":"alloy"}'
```

**Lösung:**
- Verwende interne URL: `http://openedai-speech:8000` (nicht localhost oder IP)
- Stelle sicher, dass beide Dienste im gleichen Docker-Netzwerk sind
- Füge Dummy-Authorization-Header hinzu: `Bearer sk-dummy`
- Prüfe, ob Dienst läuft: `docker ps | grep openedai-speech`

### Ressourcen

- **GitHub**: https://github.com/matatonic/openedai-speech
- **Piper TTS**: https://github.com/rhasspy/piper
- **Stimmen-Beispiele**: https://rhasspy.github.io/piper-samples/
- **OpenAI TTS API-Referenz**: https://platform.openai.com/docs/api-reference/audio/createSpeech
- **Verfügbare Sprachen**: Über 50 Sprachen unterstützt

### Best Practices

**Für beste Audio-Qualität:**

1. **Wähle die richtige Stimmen-Qualität:**
   - Entwicklung/Testing: Low-Quality (schnell, klein)
   - Produktion: Medium-Quality (ausgewogen)
   - Premium: High-Quality (langsam, groß)

2. **Optimiere Text-Eingabe:**
   - Halte Sätze unter 500 Zeichen
   - Verwende korrekte Interpunktion für natürliche Pausen
   - Teile langen Text in Abschnitte auf
   - Füge Kommas für natürliche Geschwindigkeit hinzu

3. **Behandle Fehler elegant:**
   - Wiederhole bei Netzwerkfehlern
   - Validiere Textlänge vor dem Senden
   - Speichere generierte Audiodaten zwischen, um Neugenerierung zu vermeiden
   - Setze sinnvolle Timeouts (10-30 Sekunden)

4. **Leistungsoptimierung:**
   - Lade häufig verwendete Stimmenmodelle vorab herunter
   - Verwende niedrigere Qualität für Echtzeit-Apps
   - Verarbeite mehrere Anfragen im Batch
   - Speichere Ergebnisse für wiederholte Phrasen zwischen

5. **Mehrsprachige Unterstützung:**
   - Konfiguriere Stimmen für alle benötigten Sprachen vorab
   - Teste jede Stimme vor Produktiveinsatz
   - Berücksichtige regionale Akzente (US vs UK Englisch)
   - Verwende sprachspezifische Stimmen für beste Qualität

**Wann OpenedAI-Speech verwenden:**

- ✅ Sprachbenachrichtigungen und Alarme
- ✅ Hörbuch- und Podcast-Generierung
- ✅ Sprachassistenten und Chatbots
- ✅ Barrierefreiheit-Funktionen (Text-zu-Sprache)
- ✅ Mehrsprachiger Inhalt
- ✅ Telefonsystem-IVR-Nachrichten
- ✅ Bildungsinhalte
- ❌ Echtzeit mit niedriger Latenz (<100ms) - verwende stattdessen Chatterbox
- ❌ Emotionale Ausdruckskontrolle - verwende stattdessen Chatterbox
- ❌ Stimmen-Klonen - verwende stattdessen Chatterbox

### Integration mit anderen Diensten

**Sprache-zu-Sprache-Pipeline:**

```
Faster-Whisper (STT) → LLM (Verarbeitung) → OpenedAI-Speech (TTS)
```

**Kompletter Workflow:**
1. Benutzer sendet Sprachnachricht
2. Faster-Whisper transkribiert zu Text
3. LLM (GPT/Claude/Ollama) verarbeitet Anfrage
4. OpenedAI-Speech wandelt Antwort in Audio um
5. Sende Audio zurück an Benutzer

**Beispiel-Plattformen:**
- Telegram Sprachnachrichten
- WhatsApp Audio-Nachrichten
- Telefonsysteme (Twilio)
- Discord Sprach-Bots
- Web-Apps mit Audio
