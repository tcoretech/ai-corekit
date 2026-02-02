# 🌍 LibreTranslate - Übersetzungs-API

### Was ist LibreTranslate?

LibreTranslate ist eine kostenlose, quelloffene, selbst gehostete Übersetzungs-API, die maschinelle Übersetzung für über 50 Sprachen bereitstellt. Sie bietet vollständige Privatsphäre, da alle Übersetzungen auf deinem Server stattfinden, ohne dass Daten an externe Dienste gesendet werden, und beinhaltet automatische Spracherkennung.

### Funktionen

- **50+ Sprachen**: Übersetzung zwischen wichtigen Weltsprachen
- **Automatische Spracherkennung**: Keine Notwendigkeit, die Ausgangssprache anzugeben
- **Privatsphäre zuerst**: Alle Übersetzungen erfolgen lokal auf deinem Server
- **Unbegrenzte Übersetzungen**: Keine API-Ratenlimits oder Kosten
- **Format-Beibehaltung**: HTML-Formatierung wird in Übersetzungen beibehalten
- **Dokumentenübersetzung**: Übersetze TXT-, DOCX-, PDF-Dateien direkt
- **OpenAPI/Swagger**: Vollständige API-Dokumentation mit interaktivem Testen

### Erste Einrichtung

**Erster Login bei LibreTranslate:**

1. Navigiere zu `https://translate.deinedomain.com`
2. **Web-Oberfläche verfügbar**: Einfache UI zum Testen von Übersetzungen
3. **Keine Authentifizierung erforderlich**: Interner Zugriff von n8n benötigt keine Authentifizierung
4. **Externer Zugriff**: Geschützt durch Basic Auth (Anmeldedaten in `.env`)

**Zugriffsmethoden:**
- **Web-UI**: `https://translate.deinedomain.com` (zum Testen)
- **Interne API**: `http://libretranslate:5000` (für n8n-Automatisierung)
- **Externe API**: `https://translate.deinedomain.com` (erfordert Basic Auth)

### n8n-Integration einrichten

**Keine Anmeldedaten erforderlich für internen Zugriff** - LibreTranslate wird über den HTTP-Request-Node von n8n ohne Authentifizierung aufgerufen.

**Interne URL:** `http://libretranslate:5000`

### Beispiel-Workflows

#### Beispiel 1: Einfache Textübersetzung

```javascript
// Einfache Textübersetzung

// 1. Trigger-Node (Webhook, Datenbank, etc.)
// Eingabe: { "text": "Hello, how are you?", "target_lang": "de" }

// 2. HTTP-Request-Node - Text übersetzen
Methode: POST
URL: http://libretranslate:5000/translate

Header:
  - Name: Content-Type
    Wert: application/json

Send Body: JSON
{
  "q": "{{ $json.text }}",
  "source": "auto",
  "target": "{{ $json.target_lang }}",
  "format": "text"
}

// Antwort:
{
  "translatedText": "Hallo, wie geht es dir?"
}

// 3. Set-Node - Übersetzung extrahieren
return {
  original: $json.text,
  translated: $('HTTP Request').json.translatedText,
  language: $json.target_lang
};
```

#### Beispiel 2: Mehrsprachiger Kundensupport

```javascript
// Automatisierter Kundensupport mit Spracherkennung

// 1. Webhook-Trigger - Kundenanfrage erhalten
// Eingabe: { "customer_id": "12345", "message": "Hola, necesito ayuda" }

// 2. HTTP-Request - Sprache erkennen
Methode: POST
URL: http://libretranslate:5000/detect

Header:
  Content-Type: application/json

Body: {
  "q": "{{ $json.message }}"
}

// Antwort:
[
  {
    "confidence": 0.95,
    "language": "es"
  }
]

// 3. IF-Node - Prüfe ob Übersetzung benötigt wird
If: {{ $json[0].language }} !== 'de'

// 4. HTTP-Request - Ins Deutsche übersetzen
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Webhook').json.message }}",
  "source": "{{ $('Detect Language').json[0].language }}",
  "target": "de",
  "format": "text"
}

// 5. OpenAI-Node - Antwort auf Deutsch generieren
Modell: gpt-4o-mini
Prompt: Antworte auf diese Kundenanfrage: {{ $json.translatedText }}

// 6. HTTP-Request - Antwort zurück in Kundensprache übersetzen
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $json.response }}",
  "source": "de",
  "target": "{{ $('Detect Language').json[0].language }}",
  "format": "text"
}

// 7. Antwort senden - In Kundensprache zurückgeben
To: {{ $('Webhook').json.customer_id }}
Nachricht: {{ $json.translatedText }}
```

#### Beispiel 3: Automatisierte Dokumentenübersetzung

```javascript
// Übersetze auf Google Drive hochgeladene Dokumente

// 1. Google Drive-Trigger - Neue Datei hochgeladen
Folder: "/Documents/To Translate"
File Type: TXT, DOCX, PDF

// 2. HTTP-Request - Dokumentensprache erkennen
Methode: POST
URL: http://libretranslate:5000/detect
Body: {
  "q": "{{ $json.content_preview }}"
}

// 3. Loop-Node - In mehrere Sprachen übersetzen
Items: ["de", "fr", "es", "it", "pt"]  // Zielsprachen

// 4. HTTP-Request - Dokument übersetzen
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Google Drive').json.content }}",
  "source": "{{ $('Detect Language').json[0].language }}",
  "target": "{{ $json }}",
  "format": "text"
}

// 5. Google Docs - Übersetztes Dokument erstellen
Title: {{ $('Google Drive').json.name }}_{{ $json }}
Inhalt: {{ $json.translatedText }}

// 6. In Ordner verschieben - Nach Sprache organisieren
Source: Translated document
Destination: /Documents/Translated/{{ $json }}
```

#### Beispiel 4: Echtzeit-Chat-Übersetzung

```javascript
// Übersetze Chat-Nachrichten in Echtzeit

// 1. Webhook-Trigger - Neue Chat-Nachricht
// Eingabe: { "user_id": "123", "message": "Bonjour!", "room_id": "general" }

// 2. HTTP-Request - Nachrichtensprache erkennen
Methode: POST
URL: http://libretranslate:5000/detect
Body: {
  "q": "{{ $json.message }}"
}

// 3. Code-Node - Originalsprache speichern
return {
  user_id: $json.user_id,
  message: $json.message,
  original_lang: $('Detect Language').json[0].language,
  room_id: $json.room_id
};

// 4. HTTP-Request - Mitglieder-Sprachen des Raums abrufen
// Datenbank nach Benutzer-Sprachpräferenzen abfragen

// 5. Loop-Node - Für jeden Benutzer übersetzen
Items: {{ $json.room_members }}

// 6. IF-Node - Überspringen wenn gleiche Sprache
If: {{ $json.preferred_lang }} !== {{ $('Code').json.original_lang }}

// 7. HTTP-Request - Nachricht übersetzen
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $('Code').json.message }}",
  "source": "{{ $('Code').json.original_lang }}",
  "target": "{{ $json.preferred_lang }}",
  "format": "text"
}

// 8. Slack/Discord/Matrix - Übersetzte Nachricht senden
Kanal: {{ $('Code').json.room_id }}
User: @{{ $json.username }}
Nachricht: [🌍 {{ $json.preferred_lang }}] {{ $json.translatedText }}
```

### Unterstützte Sprachen

LibreTranslate unterstützt über 50 Sprachen:

**Hauptsprachen:**

| Code | Sprache | Code | Sprache | Code | Sprache |
|------|----------|------|----------|------|----------|
| `en` | Englisch | `de` | Deutsch | `zh` | Chinesisch |
| `es` | Spanisch | `fr` | Französisch | `ja` | Japanisch |
| `it` | Italienisch | `pt` | Portugiesisch | `ar` | Arabisch |
| `ru` | Russisch | `nl` | Niederländisch | `ko` | Koreanisch |
| `pl` | Polnisch | `tr` | Türkisch | `hi` | Hindi |
| `sv` | Schwedisch | `fi` | Finnisch | `th` | Thai |
| `da` | Dänisch | `no` | Norwegisch | `vi` | Vietnamesisch |
| `cs` | Tschechisch | `el` | Griechisch | `id` | Indonesisch |
| `ro` | Rumänisch | `he` | Hebräisch | `ms` | Malaiisch |
| `hu` | Ungarisch | `uk` | Ukrainisch | `fa` | Persisch |

**Vollständige Liste über API abrufen:**

```bash
# Alle verfügbaren Sprachen auflisten
curl http://libretranslate:5000/languages

# Antwort:
[
  {"code": "en", "name": "English"},
  {"code": "de", "name": "German"},
  ...
]
```

### API-Endpunkt-Referenz

#### Text übersetzen

```javascript
POST http://libretranslate:5000/translate
Content-Type: application/json

{
  "q": "Zu übersetzender Text",
  "source": "auto",  // oder spezifischer Sprachcode
  "target": "de",
  "format": "text"  // oder "html"
}
```

#### Sprache erkennen

```javascript
POST http://libretranslate:5000/detect
Content-Type: application/json

{
  "q": "Zu erkennender Text"
}

// Antwort:
[
  {
    "confidence": 0.95,
    "language": "en"
  }
]
```

#### Verfügbare Sprachen abrufen

```javascript
GET http://libretranslate:5000/languages

// Antwort:
[
  {"code": "en", "name": "English", "targets": ["de", "es", "fr", ...]},
  {"code": "de", "name": "German", "targets": ["en", "es", "fr", ...]},
  ...
]
```

#### Datei übersetzen

```javascript
POST http://libretranslate:5000/translate_file
Content-Type: multipart/form-data

Datei: [binäre Dateidaten]
source: auto
target: de
```

### Format-Beibehaltung

LibreTranslate kann HTML-Formatierung während der Übersetzung beibehalten:

**HTML-Übersetzung:**

```javascript
// HTTP-Request-Node
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "<h1>Hello World</h1><p>This is a <strong>test</strong>.</p>",
  "source": "en",
  "target": "de",
  "format": "html"  // Behält HTML-Tags bei
}

// Antwort:
{
  "translatedText": "<h1>Hallo Welt</h1><p>Dies ist ein <strong>Test</strong>.</p>"
}
```

### Fehlerbehebung

**Problem 1: Dienst antwortet nicht**

```bash
# Dienststatus prüfen
docker ps | grep libretranslate

# Sollte zeigen: STATUS = Up

# Logs prüfen
docker logs libretranslate --tail 50

# Bei Bedarf neu starten
docker compose restart libretranslate
```

**Problem 2: Erste Übersetzung ist langsam**

```bash
# Modell-Laden überwachen
docker logs libretranslate -f

# Du wirst sehen:
# Loading language models...
# Models loaded successfully
```

**Lösung:**
- Erste Übersetzung löst Modell-Download aus (1-3 Minuten pro Sprachpaar)
- Nachfolgende Übersetzungen sind schnell (<1 Sekunde)
- Modelle werden dauerhaft zwischengespeichert
- Lade häufige Sprachen vorab, indem du Übersetzungen nach Installation testest

**Problem 3: Übersetzungsqualität ist schlecht**

**Lösung:**
- LibreTranslate verwendet Argos Translate (neuronale maschinelle Übersetzung)
- Qualität variiert nach Sprachpaar
- Am besten für: Englisch ↔ Wichtige europäische Sprachen
- Mäßig für: Asiatische Sprachen, Arabisch
- Für bessere Qualität: Erwäge OpenAI/Claude API für kritische Inhalte
- Kombiniere mit menschlicher Überprüfung für wichtige Dokumente

**Problem 4: Kein Zugriff von n8n**

```bash
# Verbindung vom n8n-Container testen
docker exec n8n curl http://libretranslate:5000/languages

# Sollte JSON-Liste der Sprachen zurückgeben

# Übersetzungs-Endpunkt testen
docker exec n8n curl -X POST http://libretranslate:5000/translate \
  -H "Content-Type: application/json" \
  -d '{"q":"test","source":"auto","target":"de"}'
```

**Lösung:**
- Verwende interne URL: `http://libretranslate:5000` (nicht localhost)
- Stelle sicher, dass beide Dienste im gleichen Docker-Netzwerk sind
- Keine Authentifizierung für internen Zugriff erforderlich
- Prüfe, ob Dienst läuft: `docker ps | grep libretranslate`

**Problem 5: Dateiübersetzung schlägt fehl**

```bash
# Unterstützte Dateitypen prüfen
# Nur TXT, DOCX, PDF

# Dateigröße prüfen (max 10MB Standard)
docker logs libretranslate | grep "file size"

# Datei-Kodierung prüfen
file uploaded_document.txt
```

**Lösung:**
- Stelle sicher, dass Datei UTF-8 kodiert ist
- Maximale Dateigröße: 10MB (konfigurierbar)
- Für PDFs: Extrahiere zuerst Text mit OCR-Tools
- Für große Dateien: Teile in Abschnitte auf und übersetze separat
- Verwende Text-Extraktions-Tools vor Übersetzung

**Problem 6: Spracherkennung ist falsch**

**Lösung:**
- Erkennung funktioniert am besten mit 50+ Zeichen
- Kurzer Text kann falsch erkannt werden
- Gib Ausgangssprache explizit für bessere Ergebnisse an
- Konfidenz-Score <0,5 zeigt unsichere Erkennung an
- Teste mit längeren Textproben

### Ressourcen

- **Offizielle Website**: https://libretranslate.com
- **GitHub**: https://github.com/LibreTranslate/LibreTranslate
- **API-Dokumentation**: `https://translate.deinedomain.com/docs` (Swagger UI)
- **Unterstützte Sprachen**: https://github.com/argosopentech/argos-translate#supported-languages
- **Community**: https://github.com/LibreTranslate/LibreTranslate/discussions

### Best Practices

**Für beste Übersetzungsqualität:**

1. **Quelltext-Qualität:**
   - Verwende korrekte Grammatik und Rechtschreibung
   - Vermeide Slang und Redewendungen
   - Halte Sätze einfach und klar
   - Verwende formelle Sprache wenn möglich

2. **Spracherkennung:**
   - Gib 50+ Zeichen für genaue Erkennung an
   - Spezifiziere Ausgangssprache wenn bekannt (schneller + genauer)
   - Verwende Konfidenz-Score zur Validierung der Erkennung

3. **Leistungsoptimierung:**
   - Speichere häufige Übersetzungen zwischen
   - Lade häufig verwendete Sprachpaare vorab
   - Übersetze mehrere Texte gemeinsam im Batch
   - Verwende asynchrone Verarbeitung für große Mengen

4. **Format-Behandlung:**
   - Verwende `format: "html"` zur Format-Beibehaltung
   - Bereinige Text vor Übersetzung
   - Nachbearbeite Übersetzungen bei Bedarf
   - Teste zuerst mit Beispielinhalten

5. **Fehlerbehandlung:**
   - Validiere Sprachcodes vor dem Senden
   - Behandle Netzwerk-Timeouts elegant
   - Gib Fallback für fehlgeschlagene Übersetzungen
   - Protokolliere fehlgeschlagene Übersetzungen zur Überprüfung

**Wann LibreTranslate verwenden:**

- ✅ Privatsphären-sensible Inhalte
- ✅ Hochvolumen-Übersetzungen (keine API-Kosten)
- ✅ Interne Tools und Automatisierung
- ✅ Grundlegende Kommunikation über Sprachen hinweg
- ✅ Schnelles Prototyping
- ✅ Bildungsprojekte
- ❌ Professionelle/rechtliche Dokumente (verwende menschlichen Übersetzer)
- ❌ Marketing-Texte (erwäge bezahlte Dienste)
- ❌ Kritische Kommunikation

**LibreTranslate vs. kommerzielle Dienste:**

| Funktion | LibreTranslate | Google Translate | DeepL |
|---------|----------------|------------------|-------|
| **Kosten** | Kostenlos (selbst gehostet) | Bezahlung pro Zeichen | Begrenzter kostenloser Tarif |
| **Privatsphäre** | Vollständig | Daten an Google gesendet | Daten an DeepL gesendet |
| **Qualität** | Gut | Ausgezeichnet | Ausgezeichnet |
| **Sprachen** | 50+ | 100+ | 30+ |
| **Geschwindigkeit** | Schnell (lokal) | Schnell | Schnell |
| **Am besten für** | Privatsphäre, Volumen | Allgemeine Nutzung | Professionell |

### Integration mit anderen Diensten

**Übersetzungs-Pipeline:**

```
Inhaltserstellung → LibreTranslate → Überprüfung → Veröffentlichen
```

**Mehrsprachiger Workflow:**

1. Erstelle Inhalt in Primärsprache (Deutsch)
2. Automatische Übersetzung in Zielsprachen (LibreTranslate)
3. Speichere Übersetzungen in Datenbank
4. Menschliche Überprüfung (optional)
5. Veröffentliche in alle Märkte

**Kombiniert mit Sprachdiensten:**

```
Sprache → Whisper (STT) → LibreTranslate → TTS → Sprache
```

**Anwendungsfall:** Echtzeit-Sprachübersetzung für Meetings

**Dokumentenverarbeitung:**

```
Upload → OCR (Tesseract) → LibreTranslate → Format → Speichern
```

**Anwendungsfall:** Gescannte Dokumente übersetzen
