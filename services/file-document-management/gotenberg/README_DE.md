# 📄 Gotenberg - Dokumenten-Konverter

### Was ist Gotenberg?

Gotenberg ist eine containerisierte, zustandslose API für nahtlose PDF-Konvertierung. Sie bietet eine entwicklerfreundliche HTTP-API, die leistungsstarke Tools wie Chromium (für HTML/URL-Rendering) und LibreOffice (für Office-Dokumentkonvertierung) nutzt, um zahlreiche Dokumentformate in PDF-Dateien zu konvertieren. In Go geschrieben, ist Gotenberg für Skalierbarkeit, verteilte Systeme und hochvolumige Dokumentenverarbeitung konzipiert. Es ist die perfekte Lösung für automatisierte PDF-Generierung in Workflows, Rechnungssystemen, Berichtserstellung und Dokumentenarchivierung.

### Features

- **Multi-Engine-Dokumentenkonvertierung** - Chromium für HTML/Markdown/URLs, LibreOffice für Office-Dokumente (Word, Excel, PowerPoint)
- **Vielseitige Eingabeformate** - HTML, Markdown, URLs, .docx, .xlsx, .pptx, .odt, .ods und mehr
- **Zustandslos & Skalierbar** - Keine lokale Speicherung, perfekt für horizontale Skalierung und verteilte Systeme
- **HTTP/2-Unterstützung** - Moderne Protokollunterstützung mit H2C (HTTP/2 Cleartext) für Performance
- **Webhook-Integration** - Asynchrone Workflows mit automatischen Datei-Uploads zu Zielen
- **PDF-Manipulation** - Zusammenführen, Aufteilen, Komprimieren und Konvertierung in PDF/A-Archivformat
- **Benutzerdefinierte Header & Metadaten** - PDF-Metadaten (Autor, Titel, Erstellungsdatum) über API-Header einfügen
- **Multi-Architektur-Unterstützung** - Verfügbar für amd64, arm64, armhf, i386 und ppc64le
- **Keine Abhängigkeiten** - Alles im Docker-Image gebündelt (Chromium, LibreOffice, PDFtk, QPDF)
- **Container-Native** - Einfache Docker-Bereitstellung, funktioniert in Kubernetes, Cloud Run, ECS, etc.

### Ersteinrichtung

**Gotenberg ist im AI CoreKit vorkonfiguriert:**

Gotenberg läuft bereits und ist intern unter `http://gotenberg:3000` erreichbar. Du kannst sofort mit der Konvertierung von Dokumenten von n8n oder jedem anderen Dienst beginnen.

**Teste Gotenberg von der Kommandozeile:**

```bash
# Test 1: URL zu PDF konvertieren
curl --request POST http://localhost:3000/forms/chromium/convert/url \
  --form 'url="https://example.com"' \
  -o example.pdf

# Test 2: HTML-String zu PDF konvertieren
echo '<html><body><h1>Hallo Gotenberg!</h1></body></html>' > test.html

curl --request POST http://localhost:3000/forms/chromium/convert/html \
  --form 'files=@"test.html"' \
  -o output.pdf

# Test 3: Word-Dokument zu PDF konvertieren (wenn du eine .docx-Datei hast)
curl --request POST http://localhost:3000/forms/libreoffice/convert \
  --form 'files=@"dokument.docx"' \
  -o dokument.pdf

# Test 4: Mehrere PDFs zusammenführen
curl --request POST http://localhost:3000/forms/pdfengines/merge \
  --form 'files=@"datei1.pdf"' \
  --form 'files=@"datei2.pdf"' \
  -o zusammengefuehrt.pdf
```

**Gotenberg-Status prüfen:**

```bash
# Prüfe ob Gotenberg läuft
docker ps | grep gotenberg

# Gotenberg-Logs anzeigen
docker logs gotenberg --tail 50

# Gotenberg-Health prüfen (sollte 200 OK zurückgeben)
curl -I http://localhost:3000/health

# Gotenberg-Version und Module anzeigen
curl http://localhost:3000/health
```

### API-Endpunkte Übersicht

Gotenberg bietet mehrere Konvertierungs-Endpunkte:

**Chromium-basierte Konvertierungen (HTML/URLs):**
- `POST /forms/chromium/convert/url` - URL zu PDF konvertieren
- `POST /forms/chromium/convert/html` - HTML-Dateien zu PDF konvertieren
- `POST /forms/chromium/convert/markdown` - Markdown-Dateien zu PDF konvertieren

**LibreOffice-Konvertierungen (Office-Dokumente):**
- `POST /forms/libreoffice/convert` - Office-Dokumente (.docx, .xlsx, .pptx, etc.) zu PDF konvertieren

**PDF-Manipulation:**
- `POST /forms/pdfengines/merge` - Mehrere PDFs zu einem zusammenführen
- `POST /forms/pdfengines/convert` - PDF in PDF/A-Format konvertieren

**Screenshot:**
- `POST /forms/chromium/screenshot/url` - Screenshot einer URL erstellen
- `POST /forms/chromium/screenshot/html` - Screenshot aus HTML erstellen

### n8n Integration Setup

**Keine Zugangsdaten benötigt!** Gotenberg hat standardmäßig keine Authentifizierung. Nutze HTTP Request Nodes mit `multipart/form-data` um die API aufzurufen.

**Interne URL:** `http://gotenberg:3000`

**Grundlegendes Integrationsmuster:**

1. Füge in n8n einen **HTTP Request** Node hinzu
2. Konfiguriere:
   - **Methode:** POST
   - **URL:** `http://gotenberg:3000/forms/chromium/convert/html` (oder anderer Endpunkt)
   - **Body Content Type:** Multipart-Form Data
   - **Body-Parameter:** Füge deine Dateien und Optionen hinzu
3. Führe aus um PDF-Binärausgabe zu erhalten

### Beispiel-Workflows

#### Beispiel 1: HTML zu PDF konvertieren (Einfacher Rechnungsgenerator)

Generiere Rechnungen aus HTML-Templates und konvertiere sie zu PDF.

```javascript
// 1. Manual Trigger oder Webhook
// Input: Kundendaten, Rechnungsposten

// 2. Code Node - Rechnungs-HTML generieren
const customer = $json.customer || {
  name: "Max Mustermann",
  email: "max@beispiel.de",
  address: "Hauptstraße 123"
};

const items = $json.items || [
  { description: "Webentwicklung", quantity: 10, rate: 100 },
  { description: "Beratung", quantity: 5, rate: 150 }
];

const total = items.reduce((sum, item) => sum + (item.quantity * item.rate), 0);

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    .header { text-align: center; margin-bottom: 30px; }
    .invoice-info { margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #4CAF50; color: white; }
    .total { font-size: 18px; font-weight: bold; text-align: right; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>RECHNUNG</h1>
    <p>Rechnung #${Date.now()}</p>
  </div>
  
  <div class="invoice-info">
    <strong>Rechnung an:</strong><br>
    ${customer.name}<br>
    ${customer.email}<br>
    ${customer.address}
  </div>
  
  <table>
    <tr>
      <th>Beschreibung</th>
      <th>Menge</th>
      <th>Preis</th>
      <th>Betrag</th>
    </tr>
    ${items.map(item => `
      <tr>
        <td>${item.description}</td>
        <td>${item.quantity}</td>
        <td>${item.rate}€</td>
        <td>${item.quantity * item.rate}€</td>
      </tr>
    `).join('')}
  </table>
  
  <div class="total">
    Gesamt: ${total}€
  </div>
</body>
</html>
`;

return {
  json: {
    html: html,
    customer: customer,
    total: total
  }
};

// 3. Code Node - HTML zu Binärdatei konvertieren
const htmlContent = $json.html;

return {
  json: {},
  binary: {
    data: {
      data: Buffer.from(htmlContent, 'utf-8').toString('base64'),
      mimeType: 'text/html',
      fileName: 'index.html'
    }
  }
};

// 4. HTTP Request Node - Gotenberg API aufrufen
Methode: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body Content Type: Multipart-Form Data
Specify Body: Using Fields Below

Body Parameter:
  files = {{ $binary.data }}  // Wähle "Binary Data" aus dem Dropdown

Header:
  Gotenberg-Output-Filename: rechnung-{{ $('Code Node').first().json.customer.name }}.pdf

// 5. Code Node - PDF-Binärdatei umbenennen (Optional)
return {
  json: $json,
  binary: {
    invoice: $binary.data  // Umbenennen von 'data' zu 'invoice' für Klarheit
  }
};

// 6. Send Email Node (Gmail/SMTP)
Operation: Send Email
To: {{ $('Code Node').first().json.customer.email }}
Subject: Ihre Rechnung
Nachricht: Anbei finden Sie Ihre Rechnung.
Anhänge: {{ $binary.invoice }}  // PDF anhängen

// Ergebnis: Automatisierte Rechnungserstellung und Zustellung per E-Mail
```

#### Beispiel 2: URL zu PDF konvertieren (Website-Archivierung)

Archiviere Webseiten automatisch als PDFs nach Zeitplan.

```javascript
// 1. Schedule Trigger
// Jeden Tag um 2 Uhr morgens

// 2. Set Node - Define URLs to Archive
urls = [
  { name: "Unternehmens-Homepage", url: "https://example.com" },
  { name: "Produktseite", url: "https://example.com/products" },
  { name: "Blog", url: "https://example.com/blog" }
]

// 3. Loop Over Items

// 4. HTTP Request Node - Convert URL to PDF
Methode: POST
URL: http://gotenberg:3000/forms/chromium/convert/url
Body Content Type: Multipart-Form Data

Body Parameter:
  url = {{ $json.url }}

Header:
  Gotenberg-Output-Filename: {{ $json.name }}-{{ $now.format('YYYY-MM-DD') }}.pdf
  Gotenberg-Chromium-Wait-Delay: 2s  // 2 Sekunden warten bis Seite geladen ist
  Gotenberg-Chromium-Emulated-Media-Type: print  // Print-CSS verwenden

// 5. Move/Upload PDF
// Option A: Save to Google Drive
// Option B: Save to local storage
// Option C: Upload to S3/Supabase Storage

// 6. Slack Notification
Kanal: #archives
Nachricht: |
  📄 *Website Archive Complete*
  
  Archived pages: {{ $('Set').all().length }}
  Datum: {{ $now.format('YYYY-MM-DD') }}
```

#### Example 3: Convert Office Documents to PDF (Document Pipeline)

Monitor a folder for Office documents and auto-convert to PDF.

```javascript
// 1. Google Drive Trigger (or FTP Watch)
Trigger: On File Created/Updated
Folder: /Documents/ToConvert
File Extensions: .docx, .xlsx, .pptx

// 2. Google Drive Download Node
Operation: Download
File: {{ $json.id }}

// 3. HTTP Request Node - Convert to PDF
Methode: POST
URL: http://gotenberg:3000/forms/libreoffice/convert
Body Content Type: Multipart-Form Data

Body Parameter:
  files = {{ $binary.data }}

Header:
  Gotenberg-Output-Filename: {{ $json.name.replace(/\.[^/.]+$/, "") }}.pdf

// 4. Code Node - Add Metadata
const originalName = $('Google Drive Trigger').first().json.name;
const pdfName = originalName.replace(/\.[^/.]+$/, '.pdf');

return {
  json: {
    original_Datei: originalName,
    pdf_Datei: pdfName,
    converted_at: new Date().toISOString()
  },
  binary: {
    pdf: $binary.data
  }
};

// 5. Google Drive Upload Node
Operation: Upload
Folder: /Documents/Converted
File Name: {{ $json.pdf_file }}
Binary Daten: {{ $binary.pdf }}

// 6. Notify User (Email/Slack)
Nachricht: |
  ✅ Dokument erfolgreich konvertiert
  
  Original: {{ $json.original_file }}
  PDF: {{ $json.pdf_file }}
  Time: {{ $json.converted_at }}
```

#### Beispiel 4: Mehrere PDFs zusammenführen (Report Aggregation)

Combine multiple PDF reports into a single document.

```javascript
// 1. Webhook/Manual Trigger
// Receives array of PDF URLs or file IDs

// 2. Loop to Download PDFs
// For each PDF URL/ID

// 3. HTTP Request - Download PDF
Methode: GET
URL: {{ $json.pdf_url }}
Response Format: File

// 4. Aggregate to List Node
// Collect all PDF binaries

// 5. HTTP Request - Merge PDFs
Methode: POST
URL: http://gotenberg:3000/forms/pdfengines/merge
Body Content Type: Multipart-Form Data

Body Parameter:
  files = {{ $binary.data0 }}  // Erstes PDF
  files = {{ $binary.data1 }}  // Zweites PDF
  files = {{ $binary.data2 }}  // Third PDF
  // ... add all PDFs
  // Hinweis: n8n will automatically send multiple files with same parameter name

Header:
  Gotenberg-Output-Filename: merged-report-{{ $now.format('YYYY-MM-DD') }}.pdf
  Gotenberg-Pdf-Format: PDF/A-1b  // Convert to archival format

// 6. Upload Merged PDF
// Save to storage or send via email
```

#### Example 5: Dynamic PDF with Images (Certificate Generator)

Generate certificates with dynamic text and images using HTML + Gotenberg.

```javascript
// 1. Webhook Trigger
// Receives: name, course, date

// 2. Code Node - Generate Certificate HTML with Embedded Image
const name = $json.name || "John Doe";
const course = $json.course || "Web Development";
const date = $json.date || new Date().toLocaleDateString();

// Option 1: Use base64 embedded image (logo, signature, etc.)
const logoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAUA...";  // Dein logo in base64

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Georgia', serif;
      text-align: center;
      margin: 100px 50px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }
    .certificate {
      background: white;
      color: #333;
      padding: 60px;
      border: 10px solid gold;
      box-shadow: 0 0 30px rgba(0,0,0,0.3);
      max-width: 800px;
    }
    h1 { font-size: 48px; color: #667eea; margin-bottom: 30px; }
    .name { font-size: 36px; font-weight: bold; color: #764ba2; margin: 30px 0; }
    .course { font-size: 24px; margin: 20px 0; }
    .logo { width: 120px; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="certificate">
    <img src="data:image/png;base64,${logoBase64}" class="logo" alt="Logo">
    <h1>Certificate of Completion</h1>
    <p>This certifies that</p>
    <div class="name">${name}</div>
    <p>has successfully completed the course</p>
    <div class="course">${course}</div>
    <p>on ${date}</p>
  </div>
</body>
</html>
`;

return {
  json: {
    html: html,
    recipient_name: name
  }
};

// 3. Code Node - Convert HTML to Binary
const htmlContent = $json.html;

return {
  json: $json,
  binary: {
    html: {
      data: Buffer.from(htmlContent, 'utf-8').toString('base64'),
      mimeType: 'text/html',
      fileName: 'certificate.html'
    }
  }
};

// 4. HTTP Request - Generate PDF
Methode: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body Content Type: Multipart-Form Data

Body Parameter:
  files = {{ $binary.html }}

Header:
  Gotenberg-Output-Filename: certificate-{{ $('Code Node').first().json.recipient_name }}.pdf
  Gotenberg-Chromium-Paper-Width: 11  // Letter-Größe Breite (Zoll)
  Gotenberg-Chromium-Paper-Height: 8.5  // Letter-Größe Höhe (Zoll)
  Gotenberg-Chromium-Landscape: true  // Querformat

// 5. Send Certificate via Email
To: {{ $json.recipient_email }}
Subject: Ihr Kurs-Zertifikat
Anhänge: {{ $binary.data }}
```

### Fehlerbehebung

**Gotenberg antwortet nicht:**
```bash
# Prüfe ob Gotenberg-Container läuft
docker ps | grep gotenberg

# Prüfe Gotenberg-Logs auf Fehler
docker logs gotenberg --tail 100

# Starte Gotenberg-Service neu
docker compose restart gotenberg

# Teste Health-Endpunkt
curl http://localhost:3000/health
```

**Konvertierungs-Timeout-Fehler:**
```bash
# Erhöhe Timeout für große Dokumente (füge Header zu n8n HTTP Request hinzu)
Gotenberg-Chromium-Wait-Delay: 10s  # Länger auf Seitenladung warten

# Oder erhöhe globales Timeout in docker-compose.yml
environment:
  - CHROMIUM_REQUEST_TIMEOUT=30s
  - LIBREOFFICE_REQUEST_TIMEOUT=30s
```

**PDF-Ausgabe ist leer oder unvollständig:**
```bash
# Füge Warte-Verzögerung für JavaScript-lastige Seiten hinzu
Gotenberg-Chromium-Wait-Delay: 3s

# Stelle sicher dass Seite vollständig lädt vor Konvertierung
Gotenberg-Chromium-Wait-For-Selector: .content-ready  # CSS-Selektor

# Für Office-Docs: Prüfe ob Datei beschädigt ist
# Gotenberg nutzt LibreOffice - teste zuerst Öffnen der Datei in LibreOffice
```

**Bilder werden im PDF nicht geladen:**
```bash
# Verwende base64-eingebettete Bilder in HTML statt externe URLs
<img src="data:image/png;base64,iVBORw0KG..." />

# Oder stelle sicher dass externe URLs vom Gotenberg-Container erreichbar sind
# Füge extra Header hinzu falls nötig:
Gotenberg-Chromium-Extra-Http-Header: {"Authorization": "Bearer token"}

# Für lokale Dateireferenzen, füge sie als zusätzliche Dateien in Anfrage ein
```

**Ungültige multipart/form-data in n8n:**
```bash
# Häufiger Fehler: Falsche Binärreferenz verwenden
# Korrekt:
Body Parameter:
  files = {{ $binary.data }}  # Wähle "Binary Data" aus Dropdown

# Falsch:
  files = {{ $json.html }}  # Das sendet JSON, nicht binär

# Stelle sicher HTML-String zuerst zu binär zu konvertieren (nutze Code Node)
```

**LibreOffice-Konvertierung schlägt fehl:**
```bash
# Prüfe ob LibreOffice läuft
docker exec gotenberg ps aux | grep soffice

# Prüfe unterstützte Formate
# .docx, .xlsx, .pptx funktionieren am besten
# .doc, .xls, .ppt (ältere Formate) können Probleme haben

# Erhöhe Speicher wenn große Dateien konvertiert werden
# docker-compose.yml:
services:
  gotenberg:
    image: gotenberg/gotenberg:8
    deploy:
      resources:
        limits:
          memory: 2G  # Erhöhe von Standard 1G
```

**n8n Verbindung abgelehnt:**
```bash
# Prüfe Docker-Netzwerk
docker network inspect ai-corekit_default
# Verifiziere dass gotenberg und n8n im selben Netzwerk sind

# Teste interne Verbindung vom n8n-Container
docker exec n8n curl http://gotenberg:3000/health

# Falls fehlschlägt, starte beide Services neu
docker compose restart gotenberg n8n
```

### Erweiterte Funktionen

**Benutzerdefinierte Header für PDF-Metadaten:**

```javascript
// HTTP Request Node Headers
Header:
  Gotenberg-Output-Filename: report.pdf
  Gotenberg-Pdf-Metadata-Author: John Doe
  Gotenberg-Pdf-Metadata-Title: Monthly Sales Report
  Gotenberg-Pdf-Metadata-Subject: Sales Analytics
  Gotenberg-Pdf-Metadata-Keywords: sales, report, analytics
  Gotenberg-Pdf-Metadata-Creator: AI CoreKit n8n
```

**Webhook für asynchrone Verarbeitung:**

```javascript
// Useful for very large documents or batch processing
Header:
  Gotenberg-Webhook-Url: https://n8n.yourdomain.com/webhook/pdf-complete
  Gotenberg-Webhook-Methode: POST
  Gotenberg-Webhook-Error-Url: https://n8n.yourdomain.com/webhook/pdf-error
```

**PDF/A-Archivformat:**

```javascript
// Convert to PDF/A-1b for long-term archiving
Header:
  Gotenberg-Pdf-Format: PDF/A-1b
  Gotenberg-Pdf-Universal-Access: true  // PDF/UA for accessibility
```

**Benutzerdefinierte Papiergröße & Ränder:**

```javascript
// Custom page dimensions
Header:
  Gotenberg-Chromium-Paper-Width: 8.5   // inches
  Gotenberg-Chromium-Paper-Height: 11   // inches
  Gotenberg-Chromium-Margin-Top: 0.5    // inches
  Gotenberg-Chromium-Margin-Bottom: 0.5
  Gotenberg-Chromium-Margin-Left: 0.5
  Gotenberg-Chromium-Margin-Right: 0.5
  Gotenberg-Chromium-Landscape: false
```

### Ressourcen

- **Offizielle Website:** https://gotenberg.dev
- **Dokumentation:** https://gotenberg.dev/docs/getting-started/introduction
- **API-Referenz:** https://gotenberg.dev/docs/routes
- **Konfigurationsleitfaden:** https://gotenberg.dev/docs/configuration
- **GitHub Repository:** https://github.com/gotenberg/gotenberg
- **Docker Hub:** https://hub.docker.com/r/gotenberg/gotenberg
- **n8n Community-Beispiele:** https://n8n.io/workflows?search=gotenberg
- **Support:** https://github.com/gotenberg/gotenberg/discussions

### Best Practices

**HTML zu PDF Optimierung:**
- Verwende Inline-CSS statt externe Stylesheets für schnelleres Rendering
- Bette Bilder als base64 Data URIs ein um externe Abhängigkeiten zu vermeiden
- Teste HTML zuerst im Chrome-Browser (Gotenberg nutzt Chromium)
- Verwende Print-Media-Queries: `@media print { ... }`
- Setze explizite Seitenumbrüche: `page-break-after: always;`

**Performance-Optimierung:**
- Nutze LibreOffice für Office-Docs, Chromium für HTML/URLs
- Batch-verarbeite mehrere Konvertierungen parallel (Gotenberg ist zustandslos)
- Setze angemessene Timeouts basierend auf Dokumentkomplexität
- Für hohe Last: Stelle mehrere Gotenberg-Instanzen hinter Load Balancer bereit
- Nutze Webhooks für asynchrone Verarbeitung großer Dokumente

**Fehlerbehandlung in n8n:**
- Füge immer Fehler-Workflow-Zweige für Timeout/Konvertierungsfehler hinzu
- Validiere Binärdaten vor dem Senden an Gotenberg
- Protokolliere fehlgeschlagene Konvertierungen zum Debuggen
- Implementiere Wiederholungslogik mit exponentiellem Backoff

**Sicherheitsüberlegungen:**
- Gotenberg hat keine eingebaute Authentifizierung - sichere mit Reverse Proxy/Firewall
- Bereinige HTML-Eingaben um XSS in generierten PDFs zu verhindern
- Begrenze Datei-Upload-Größen um DoS-Angriffe zu verhindern
- Nutze internes Docker-Netzwerk für n8n ↔ Gotenberg Kommunikation
- Exponiere niemals Gotenberg-Port direkt ins Internet

**Ressourcenverwaltung:**
- Gotenberg nutzt ~500MB-1GB RAM pro Instanz
- LibreOffice-Konvertierungen sind speicherintensiver als Chromium
- Überwache Container-Ressourcen: `docker stats gotenberg`
- Setze Speicherlimits in docker-compose.yml für Produktion
- Räume temporäre Dateien bei benutzerdefinierter Bereitstellung auf (nicht nötig mit Docker)

### Integration mit AI CoreKit Services

**Gotenberg + n8n:**
- Automatisiere Dokumentengenerierungs-Workflows
- Konvertiere Formular-Einreichungen zu PDFs
- Generiere Rechnungen, Berichte, Zertifikate
- Archiviere Webinhalte nach Zeitplan

**Gotenberg + Supabase:**
- Speichere generierte PDFs in Supabase Storage
- Triggere PDF-Generierung aus Datenbank-Events
- Baue Dokumentenverwaltungssysteme

**Gotenberg + Open WebUI:**
- Generiere Konversationstranskripte als PDFs
- Exportiere KI-Chat-Historien zur Archivierung
- Erstelle formatierte Berichte aus KI-Ausgaben

**Gotenberg + Ollama:**
- Generiere KI-geschriebene Berichte und konvertiere zu PDF
- Erstelle KI-generierte Rechnungen/Dokumente
- Kombiniere LLM-Content-Generierung + PDF-Konvertierungs-Pipeline

**Gotenberg + Cal.com:**
- Generiere Meeting-Bestätigungs-PDFs
- Erstelle Termin-Zusammenfassungen
- Exportiere Kalender-Zeitpläne als PDFs

**Gotenberg + Vikunja:**
- Exportiere Aufgabenlisten und Projektpläne zu PDF
- Generiere Projektberichte
- Archiviere abgeschlossene Projektdokumentation
