# 👁️ OCR Bundle - Textextraktion

### Was ist das OCR Bundle?

Das OCR Bundle bietet zwei komplementäre OCR (Optical Character Recognition)-Engines, die zusammenarbeiten, um Text aus Bildern und PDFs zu extrahieren: **Tesseract** für Geschwindigkeit und saubere Dokumente, und **EasyOCR** für Qualität bei Fotos und komplexen Dokumenten. Dieser Dual-Engine-Ansatz stellt sicher, dass du das richtige Werkzeug für jeden Dokumententyp hast.

### Funktionen

- **Dual-Engine-Ansatz**: Tesseract (schnell) + EasyOCR (Qualität) für optimale Ergebnisse
- **90+ Sprachen**: Tesseract unterstützt über 90 Sprachen, EasyOCR über 80
- **Mehrere Dokumententypen**: Bilder (JPG, PNG, TIFF), PDFs, gescannte Dokumente
- **Handschrift-Unterstützung**: EasyOCR behandelt handgeschriebenen Text besser als Tesseract
- **PSM-Modi**: Tesseracts Seitensegmentierungsmodi für verschiedene Dokumentenlayouts
- **REST APIs**: Beide Engines über HTTP für einfache n8n-Integration zugänglich
- **Automatische Spracherkennung**: EasyOCR kann Sprache automatisch erkennen

### Erste Einrichtung

**Beide Dienste sind intern bereitgestellt (kein direkter Webzugriff):**

- **Tesseract-URL**: `http://tesseract-ocr:8884`
- **EasyOCR-URL**: `http://easyocr:2000`
- **Authentifizierung**: EasyOCR benötigt Secret Key (aus `.env`)
- **Keine Web-UI**: Nur API-Dienste für Automatisierung

**Leistung:**
- **Tesseract**: ~3-4 Sekunden pro Bild (konstante Geschwindigkeit)
- **EasyOCR**: ~7-8 Sekunden pro Bild (erste Anfrage ~30s für Modell-Laden)

### n8n-Integration einrichten

**Tesseract: Keine Anmeldedaten erforderlich** - Einfacher HTTP-Request-Node

**EasyOCR: Benötigt API-Schlüssel:**
1. Finde Schlüssel in `.env`-Datei: `EASYOCR_SECRET_KEY`
2. Verwende im HTTP-Request-Node Body

**Interne URLs:**
- **Tesseract**: `http://tesseract-ocr:8884`
- **EasyOCR**: `http://easyocr:2000`

### Beispiel-Workflows

#### Beispiel 1: Intelligente OCR-Engine-Auswahl

```javascript
// Wähle automatisch die beste OCR-Engine basierend auf Dokumententyp

// 1. Trigger-Node (Webhook, E-Mail, Google Drive, etc.)
// Empfängt Dokument/Bild

// 2. Code-Node - Dokument analysieren und Engine wählen
const fileType = $binary.data.mimeType;
const fileName = $binary.data.fileName || '';
const fileSize = $binary.data.fileSize;

let ocrEngine = 'tesseract'; // Standard: schnelle Engine
let reasoning = '';

// Entscheidungslogik
if (fileType.includes('jpeg') || fileType.includes('png')) {
  // Fotos benötigen typischerweise bessere Qualität
  if (fileName.toLowerCase().includes('receipt') || 
      fileName.toLowerCase().includes('invoice') ||
      fileName.toLowerCase().includes('photo')) {
    ocrEngine = 'easyocr';
    reasoning = 'Foto/Beleg erkannt - verwende EasyOCR für bessere Qualität';
  } else {
    ocrEngine = 'tesseract';
    reasoning = 'Sauberes Bild - verwende Tesseract für Geschwindigkeit';
  }
} else if (fileType.includes('pdf')) {
  // PDFs sind normalerweise gescannte Dokumente (sauber)
  ocrEngine = 'tesseract';
  reasoning = 'PDF-Dokument - verwende Tesseract für Geschwindigkeit';
} else if (fileSize > 5000000) {
  // Große Dateien (>5MB) profitieren von Geschwindigkeit
  ocrEngine = 'tesseract';
  reasoning = 'Große Datei - verwende Tesseract für schnellere Verarbeitung';
}

return {
  ocrEngine,
  endpoint: ocrEngine === 'easyocr' 
    ? 'http://easyocr:2000/ocr'
    : 'http://tesseract-ocr:8884/tesseract',
  reasoning
};

// 3. Switch-Node - Zur richtigen OCR-Engine routen
Mode: Rules
Output: {{ $json.ocrEngine }}

// 4a. Zweig: Tesseract OCR
// HTTP-Request-Node
Methode: POST
URL: http://tesseract-ocr:8884/tesseract

Send Body: Form Data Multipart
Body Parameter:
  1. Binary File:
     - Parameter Type: n8n Binary File
     - Name: file
     - Input Data Field Name: data
  
  2. OCR Options:
     - Parameter Type: Form Data
     - Name: options
     - Wert: {"languages":["eng","deu"],"psm":3}

// Antwort:
{
  "text": "Extrahierter Text erscheint hier..."
}

// 4b. Zweig: EasyOCR
// HTTP-Request-Node
Methode: POST
URL: http://easyocr:2000/ocr

Header:
  - Name: Content-Type
    Wert: application/json

Send Body: JSON
{
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de"],
  "detail": 1,
  "paragraph": true
}

// Antwort:
{
  "text": "Extrahierter Text...",
  "confidence": 0.95,
  "language": "en"
}

// 5. Merge - Zweige kombinieren
Mode: Combine
Output: All

// 6. Set-Node - Ausgabe standardisieren
return {
  text: $json.text,
  engine: $('Code Node').json.ocrEngine,
  reasoning: $('Code Node').json.reasoning,
  original_Datei: $('Trigger').json.fileName
};
```

#### Beispiel 2: Rechnungsverarbeitungs-Pipeline

```javascript
// Extrahiere Daten aus Rechnungsbildern und erstelle Buchhaltungseinträge

// 1. E-Mail-IMAP-Trigger - Rechnungspostfach überwachen
Host: mailserver
Port: 993
Mailbox: INBOX/Invoices
Check for new emails every: 5 minutes

// 2. Loop-Node - Jeden E-Mail-Anhang verarbeiten

// 3. IF-Node - Prüfe ob Bild/PDF
Bedingung: {{ $json.mimeType }} contains "image" OR "pdf"

// 4. HTTP-Request - Text mit Tesseract extrahieren
Methode: POST
URL: http://tesseract-ocr:8884/tesseract
Body (Form Data):
  Datei: {{ $binary.data }}
  options: {"languages":["eng","deu"],"psm":6}

// 5. Code-Node - Rechnungsdaten parsen
const text = $json.text;

// Rechnungsdetails mit Regex extrahieren
const invoiceNumber = text.match(/Invoice\s*#?\s*:?\s*(\w+-?\d+)/i)?.[1] || '';
const invoiceDate = text.match(/Date\s*:?\s*([\d\/\-]+)/i)?.[1] || '';
const vendor = text.match(/From\s*:?\s*(.+?)\n/i)?.[1]?.trim() || '';

// Betrag extrahieren (mehrere Muster)
const amountPatterns = [
  /Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Amount\s*Due\s*:?\s*\$?\s?([\d,]+\.?\d*)/i,
  /Grand\s*Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i
];

let amount = '';
for (const pattern of amountPatterns) {
  const match = text.match(pattern);
  if (match) {
    amount = match[1].replace(',', '');
    break;
  }
}

// Datum in YYYY-MM-DD Format parsen
let parsedDate = '';
if (invoiceDate) {
  const dateParts = invoiceDate.split(/[\/\-]/);
  if (dateParts.length === 3) {
    // Annahme: MM/DD/YYYY oder DD/MM/YYYY Format
    parsedDate = `20${dateParts[2]}-${dateParts[0].padStart(2, '0')}-${dateParts[1].padStart(2, '0')}`;
  }
}

return {
  invoiceNumber,
  vendor,
  amount: parseFloat(amount) || 0,
  date: parsedDate || new Date().toISOString().split('T')[0],
  originalText: text,
  fileName: $('Loop').json.filename
};

// 6. IF-Node - Erforderliche Felder validieren
Bedingung: {{ $json.invoiceNumber }} AND {{ $json.amount }} > 0

// 7. HTTP-Request - Eintrag in Buchhaltungssystem erstellen
Methode: POST
URL: http://odoo:8069/api/v1/invoices
Header:
  Content-Type: application/json
  Authorization: Bearer {{ $env.ODOO_API_KEY }}
Body: {
  "vendor": "{{ $json.vendor }}",
  "invoice_number": "{{ $json.invoiceNumber }}",
  "amount": {{ $json.amount }},
  "date": "{{ $json.date }}",
  "status": "pending_review"
}

// 8. E-Mail senden - Bestätigung
To: accounting@deinedomain.com
Subject: Rechnung verarbeitet: {{ $json.invoiceNumber }}
Body: |
  Rechnung automatisch verarbeitet:
  
  Lieferant: {{ $json.vendor }}
  Rechnung #: {{ $json.invoiceNumber }}
  Betrag: ${{ $json.amount }}
  Datum: {{ $json.date }}
  
  Bitte im Buchhaltungssystem überprüfen.

// 9. E-Mail verschieben - Verarbeitete Rechnung archivieren
Mailbox: INBOX/Invoices/Processed
```

#### Beispiel 3: Beleg-Scanner für Ausgabenverfolgung

```javascript
// OCR von Belegen aus Telegram und Ausgaben verfolgen

// 1. Telegram-Trigger - Foto-Nachrichten empfangen
Bot Token: {{ $env.TELEGRAM_BOT_TOKEN }}
Updates: Message with photo

// 2. Telegram-Node - Foto abrufen
Operation: Get File
File ID: {{ $json.message.photo[0].file_id }}

// 3. HTTP-Request - OCR mit EasyOCR (besser für Fotos)
Methode: POST
URL: http://easyocr:2000/ocr
Header:
  Content-Type: application/json
Body: {
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de"],
  "detail": 2,
  "paragraph": true
}

// 4. Code-Node - Ausgabendaten extrahieren
const text = $json.text;
const userId = $('Telegram Trigger').json.message.from.id;

// Händlername extrahieren (normalerweise oben)
const lines = text.split('\n');
const merchant = lines[0]?.trim() || 'Unbekannter Händler';

// Gesamtbetrag extrahieren
const amountMatch = text.match(/Total\s*:?\s*\$?\s?([\d,]+\.?\d*)/i) ||
                   text.match(/Sum\s*:?\s*\$?\s?([\d,]+\.?\d*)/i) ||
                   text.match(/EUR\s*([\d,]+\.?\d*)/i);
const amount = amountMatch ? parseFloat(amountMatch[1].replace(',', '')) : 0;

// Datum extrahieren
const dateMatch = text.match(/(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/);
const date = dateMatch ? dateMatch[1] : new Date().toISOString().split('T')[0];

// Kategorie aus Text erkennen
let category = 'Sonstiges';
if (/restaurant|café|coffee|food|pizza/i.test(text)) {
  category = 'Essen & Gastronomie';
} else if (/taxi|uber|transport|fuel|gas/i.test(text)) {
  category = 'Transport';
} else if (/hotel|airbnb|accommodation/i.test(text)) {
  category = 'Unterkunft';
} else if (/supermarket|grocery|aldi|rewe/i.test(text)) {
  category = 'Lebensmittel';
}

return {
  userId,
  merchant,
  amount,
  date,
  category,
  fullText: text
};

// 5. HTTP-Request - In Ausgaben-Datenbank speichern
Methode: POST
URL: http://supabase-kong:8000/rest/v1/expenses
Header:
  apikey: {{ $env.SUPABASE_ANON_KEY }}
  Content-Type: application/json
Body: {
  "user_id": "{{ $json.userId }}",
  "merchant": "{{ $json.merchant }}",
  "amount": {{ $json.amount }},
  "date": "{{ $json.date }}",
  "category": "{{ $json.category }}",
  "receipt_text": "{{ $json.fullText }}"
}

// 6. Telegram-Node - Bestätigung senden
Operation: Send Message
Chat ID: {{ $('Telegram Trigger').json.message.chat.id }}
Nachricht: |
  ✅ Beleg verarbeitet!
  
  🏪 Händler: {{ $json.merchant }}
  💰 Betrag: ${{ $json.amount }}
  📅 Datum: {{ $json.date }}
  📂 Kategorie: {{ $json.category }}
  
  Ausgabe in deinem Tracker gespeichert!
```

#### Beispiel 4: Mehrsprachige Dokumentendigitalisierung

```javascript
// Dokumente in mehreren Sprachen scannen und digitalisieren

// 1. Google Drive-Trigger - Neue Datei im Ordner
Folder: /Documents/To Scan
File Types: PDF, Image

// 2. HTTP-Request - Sprache mit EasyOCR erkennen
Methode: POST
URL: http://easyocr:2000/ocr
Body: {
  "secret_key": "{{ $env.EASYOCR_SECRET_KEY }}",
  "image_base64": "{{ $binary.data.toString('base64') }}",
  "languages": ["en", "de", "fr", "es"],
  "detail": 0,
  "paragraph": false
}

// 3. Code-Node - Primärsprache bestimmen
const text = $json.text;
const confidence = $json.confidence || 0;

// Einfache Spracherkennung basierend auf häufigen Wörtern
let detectedLang = 'eng';
if (/der|die|das|und|ich|Sie|werden/i.test(text)) {
  detectedLang = 'deu';
} else if (/le|la|les|et|je|vous|sont/i.test(text)) {
  detectedLang = 'fra';
} else if (/el|la|los|las|y|yo|usted|son/i.test(text)) {
  detectedLang = 'spa';
}

return {
  detectedLang,
  confidence,
  fileName: $('Google Drive Trigger').json.name
};

// 4. HTTP-Request - Vollständiges OCR mit korrekter Sprache
Methode: POST
URL: http://tesseract-ocr:8884/tesseract
Body (Form Data):
  Datei: {{ $('Google Drive Trigger').binary.data }}
  options: {
    "languages": ["{{ $json.detectedLang }}"],
    "psm": 3
  }

// 5. HTTP-Request - Ins Englische übersetzen (falls nötig)
IF: {{ $('Code Node').json.detectedLang }} !== 'eng'
Methode: POST
URL: http://libretranslate:5000/translate
Body: {
  "q": "{{ $json.text }}",
  "source": "{{ $('Code Node').json.detectedLang.substring(0,2) }}",
  "target": "en"
}

// 6. Google Docs - Durchsuchbares Dokument erstellen
Title: {{ $('Code Node').json.fileName }}_text
Inhalt: |
  Originalsprache: {{ $('Code Node').json.detectedLang }}
  
  OCR-Text:
  {{ $('Full OCR').json.text }}
  
  Englische Übersetzung:
  {{ $json.translatedText }}

// 7. Google Drive - In verarbeiteten Ordner verschieben
Source: {{ $('Google Drive Trigger').json.id }}
Destination: /Documents/Processed/{{ $('Code Node').json.detectedLang }}
```

### Tesseract-Konfiguration

**Seitensegmentierungsmodi (PSM):**

| PSM | Beschreibung | Am besten für |
|-----|-------------|----------|
| `0` | Nur Ausrichtungs- und Skript-Erkennung | Erstanalyse |
| `1` | Automatische Seitensegmentierung mit OSD | Gemischte Layouts |
| `3` | Vollautomatisch (Standard) | Allgemeine Dokumente |
| `4` | Einzelne Spalte variabler Größen | Zeitung |
| `5` | Einzelner gleichmäßiger Block vertikalen Texts | Vertikaler Text |
| `6` | Einzelner gleichmäßiger Block | Saubere Dokumente |
| `7` | Einzelne Textzeile | Kurzer Text |
| `8` | Einzelnes Wort | Einzelne Wörter |
| `11` | Spärlicher Text, finde so viel wie möglich | Belege, Formulare |
| `13` | Rohe Zeile, behandle als einzelne Textzeile | Visitenkarten |

**Wähle PSM basierend auf Dokument:**
```javascript
// Sauberer Geschäftsbrief
{"psm": 6}

// Beleg oder Formular
{"psm": 11}

// Visitenkarte
{"psm": 13}

// Gemischtes Dokumentenlayout
{"psm": 1}
```

### Sprachunterstützung

**Häufige Sprachcodes:**

**Tesseract:**

| Sprache | Code | Sprache | Code |
|----------|------|----------|------|
| Englisch | `eng` | Deutsch | `deu` |
| Spanisch | `spa` | Französisch | `fra` |
| Italienisch | `ita` | Portugiesisch | `por` |
| Niederländisch | `nld` | Polnisch | `pol` |
| Russisch | `rus` | Chinesisch (vereinfacht) | `chi_sim` |
| Chinesisch (traditionell) | `chi_tra` | Japanisch | `jpn` |
| Koreanisch | `kor` | Arabisch | `ara` |
| Türkisch | `tur` | Hindi | `hin` |

**EasyOCR:**

| Sprache | Code | Sprache | Code |
|----------|------|----------|------|
| Englisch | `en` | Deutsch | `de` |
| Spanisch | `es` | Französisch | `fr` |
| Italienisch | `it` | Portugiesisch | `pt` |
| Niederländisch | `nl` | Polnisch | `pl` |
| Russisch | `ru` | Chinesisch (vereinfacht) | `ch_sim` |
| Chinesisch (traditionell) | `ch_tra` | Japanisch | `ja` |
| Koreanisch | `ko` | Arabisch | `ar` |
| Türkisch | `tr` | Hindi | `hi` |

**Mehrsprachiges OCR:**
```javascript
// Tesseract - mehrere Sprachen
{"languages": ["eng", "deu", "fra"], "psm": 3}

// EasyOCR - mehrere Sprachen
{"languages": ["en", "de", "fr"], "detail": 1}
```

### Fehlerbehebung

**Problem 1: Dienste antworten nicht**

```bash
# Dienststatus prüfen
docker ps | grep "tesseract\|easyocr"

# Sollte beide Dienste als laufend zeigen

# Tesseract-Logs prüfen
docker logs tesseract-ocr --tail 50

# EasyOCR-Logs prüfen
docker logs easyocr --tail 50

# Bei Bedarf neu starten
docker compose restart tesseract-ocr easyocr
```

**Problem 2: EasyOCR erste Anfrage sehr langsam**

```bash
# Modell-Laden überwachen
docker logs easyocr -f

# Du wirst sehen:
# Downloading detection model...
# Downloading recognition model...
# Models loaded successfully
```

**Lösung:**
- Erste Anfrage lädt Modelle (~30-90 Sekunden)
- Nachfolgende Anfragen sind schnell (7-8 Sekunden)
- Modelle dauerhaft zwischengespeichert nach erstem Laden
- Erhöhe HTTP-Timeout auf 120 Sekunden für erste Anfrage

**Problem 3: Schlechte OCR-Qualität**

```bash
# Bildqualität prüfen
file input_image.jpg

# Überprüfe, dass Bild nicht zu klein ist
identify -format "%wx%h" input_image.jpg
# Sollte mindestens 1000x1000 Pixel für gute Ergebnisse sein
```

**Lösung:**
- **Für Tesseract:** Verwende PSM-Modus passend zum Layout
- **Für EasyOCR:** Versuche mit `detail: 2` für bessere Genauigkeit
- **Vorverarbeitung:** In Graustufen konvertieren, Kontrast erhöhen
- **Auflösung:** Stelle mindestens 300 DPI für gescannte Dokumente sicher
- **Wechsle Engines:** Versuche EasyOCR wenn Tesseract versagt (oder umgekehrt)

**Problem 4: Falsche Sprache erkannt**

**Lösung:**
- Spezifiziere Sprache explizit statt Auto-Erkennung
- Verwende mehrere Sprachen wenn Dokument mehrsprachig ist
- Stelle sicher, dass korrekte Sprachpakete installiert sind
- Für gemischte Schriften (Englisch + Chinesisch), spezifiziere beide Sprachen

**Problem 5: Kein Zugriff von n8n**

```bash
# Tesseract-Verbindung testen
docker exec n8n curl -I http://tesseract-ocr:8884/

# Sollte HTTP-Header zurückgeben

# EasyOCR-Verbindung testen
docker exec n8n curl -I http://easyocr:2000/

# Tatsächlichen OCR-Endpunkt testen
docker exec n8n curl -X POST http://tesseract-ocr:8884/tesseract \
  -F "file=@test.jpg" \
  -F 'options={"languages":["eng"],"psm":3}'
```

**Lösung:**
- Verwende interne URLs: `http://tesseract-ocr:8884` und `http://easyocr:2000`
- Stelle sicher, dass Dienste im gleichen Docker-Netzwerk sind
- EasyOCR benötigt secret_key im Request-Body
- Prüfe, ob Dienste laufen: `docker ps | grep ocr`

**Problem 6: Leere oder unleserliche Textausgabe**

**Lösung:**
- Versuche die andere OCR-Engine (wechsle zwischen Tesseract/EasyOCR)
- Prüfe, ob Bild nicht beschädigt ist: `identify input.jpg`
- Stelle sicher, dass Bild ausreichenden Kontrast hat
- Überprüfe, ob Spracheinstellungen korrekt sind
- Für Fotos: Immer EasyOCR verwenden
- Für Scans: Immer Tesseract verwenden

### Ressourcen

**Tesseract:**
- **GitHub**: https://github.com/tesseract-ocr/tesseract
- **Dokumentation**: https://tesseract-ocr.github.io/
- **Sprachdaten**: https://github.com/tesseract-ocr/tessdata
- **PSM-Modi**: https://tesseract-ocr.github.io/tessdoc/ImproveQuality.html

**EasyOCR:**
- **GitHub**: https://github.com/JaidedAI/EasyOCR
- **Dokumentation**: https://www.jaided.ai/easyocr/documentation/
- **Unterstützte Sprachen**: https://www.jaided.ai/easyocr/
- **API-Referenz**: https://github.com/JaidedAI/EasyOCR#api

### Best Practices

**Die richtige Engine wählen:**

| Dokumententyp | Empfohlene Engine | Grund |
|---------------|-------------------|---------|
| **Gescannte PDFs** | Tesseract | Schnell, optimiert für saubere Scans |
| **Geschäftsdokumente** | Tesseract | Konsistente Formatierung, hohe Geschwindigkeit |
| **Fotos von Belegen** | EasyOCR | Bessere Qualität bei Fotos |
| **Handgeschriebener Text** | EasyOCR | Überlegene Handschrifterkennung |
| **Bilder niedriger Qualität** | EasyOCR | Bessere Rauschbehandlung |
| **Gemischte Sprachen** | EasyOCR | Bessere Mehrsprachenunterstützung |
| **Massenverarbeitung** | Tesseract | Konstante schnelle Geschwindigkeit |
| **Straßenschilder/Fotos** | EasyOCR | Optimiert für reale Bilder |

**Bildvorverarbeitung:**

```javascript
// Code-Node - Bild vor OCR vorverarbeiten
const sharp = require('sharp');

// Bild vom vorherigen Node abrufen
const imageBuffer = Buffer.from($binary.data.data, 'base64');

// Vorverarbeitung: Graustufen, Kontrast erhöhen, schärfen
const processedImage = await sharp(imageBuffer)
  .grayscale()
  .normalize()
  .sharpen()
  .toBuffer();

return {
  binary: {
    data: {
      ...$ $binary.data,
      data: processedImage.toString('base64')
    }
  }
};

// Dann an OCR-Engine senden
```

**Leistungsoptimierung:**

1. **Batch-Verarbeitung:**
   - Verarbeite mehrere Dateien parallel mit Loop-Node
   - Verwende Queue-Node zur Steuerung der Gleichzeitigkeit
   - Tesseract verträgt 5-10 simultane Anfragen gut

2. **Caching:**
   - Speichere OCR-Ergebnisse in Datenbank, um Neuverarbeitung zu vermeiden
   - Prüfe, ob Dokument bereits verarbeitet wurde, bevor OCR

3. **Intelligentes Routing:**
   - Analysiere Dokument zuerst (Größe, Typ, Qualität)
   - Route basierend auf Analyse zur passenden Engine
   - Verwende Tesseract standardmäßig, EasyOCR für Sonderfälle

4. **Fehlerbehandlung:**
   - Füge immer Try/Catch-Nodes hinzu
   - Wiederhole mit anderer Engine, wenn erste fehlschlägt
   - Protokolliere fehlgeschlagene Dokumente zur manuellen Überprüfung

**Dokumententypen:**

- ✅ **Tesseract**: Bücher, Zeitungen, Geschäftsbriefe, Formulare, saubere PDFs
- ✅ **EasyOCR**: Belege, Rechnungen, Fotos, Straßenschilder, Screenshots, Handschrift
- ❌ **Keiner**: Sehr niedrige Bildqualität, stark verzerrter Text, künstlerische Schriftarten

**Wann beide verwenden:**

1. **Qualitätsprüfung:** Führe beide Engines aus und vergleiche Ergebnisse
2. **Konfidenz:** Verwende Engine mit höherem Konfidenz-Score
3. **Gemischte Dokumente:** Tesseract für Haupttext, EasyOCR für Fotos
4. **Fallback:** Versuche zuerst Tesseract (schnell), verwende EasyOCR wenn Konfidenz <80%
