# 📄 Paperless-ngx - Intelligentes Dokumentenmanagement-System

### Was ist Paperless-ngx?

Paperless-ngx ist ein leistungsfähiges Dokumentenmanagement-System, das deine physischen Dokumente in ein durchsuchbares Online-Archiv verwandelt. Es führt automatisch OCR bei gescannten Dokumenten durch, verwendet KI zum Taggen und Kategorisieren und bietet eine saubere Web-Oberfläche zur Verwaltung deiner digitalen Unterlagen. Mit Unterstützung für mehrere Sprachen, automatischen Matching-Algorithmen und DSGVO-konformem Speicher ist es die perfekte Lösung für papierloses Arbeiten bei voller Kontrolle über deine Daten.

### Funktionen

- **OCR-Verarbeitung** - Automatische Texterkennung in 100+ Sprachen (konfiguriert für Deutsch + Englisch)
- **KI Auto-Tagging** - Machine Learning kategorisiert Dokumente automatisch
- **Smart Matching** - Lernt aus deinem Verhalten zur Verbesserung der Dokumentenklassifizierung
- **Volltextsuche** - Suche in allen Dokumenten, sogar gescannten PDFs
- **Dokumenttypen** - Automatische Erkennung von Rechnungen, Verträgen, Briefen, etc.
- **Korrespondenten-Erkennung** - Identifiziert Absender/Firmen automatisch
- **Archiv-Versionen** - Behält Original + durchsuchbare PDF/A Archiv-Version
- **Mobile Apps** - iOS und Android Apps zum Scannen und Zugriff
- **E-Mail-Import** - Dokumente aus E-Mail-Anhängen verarbeiten
- **Barcode-Unterstützung** - Verwende Barcodes für Dokumententrennung und Tagging

### Erste Einrichtung

**Erste Anmeldung bei Paperless-ngx:**

1. Navigiere zu `https://docs.deinedomain.com`
2. Anmeldung mit:
   - **Benutzername:** Deine konfigurierte E-Mail
   - **Passwort:** Prüfe `.env` Datei für `PAPERLESS_ADMIN_PASSWORD`
3. Erstkonfiguration:
   - Setze deine bevorzugte Sprache
   - Konfiguriere Datumsformat
   - Aktiviere/Deaktiviere Auto-Tagging

**Dokumentstruktur erstellen:**

1. **Tags** → Kategorien erstellen:
   - `Rechnung`, `Vertrag`, `Beleg`, `Persönlich`, `Arbeit`
2. **Korrespondenten** → Häufige Absender hinzufügen:
   - Firmen mit denen du regelmäßig zu tun hast
3. **Dokumenttypen** → Typen definieren:
   - `Rechnung`, `Brief`, `Bericht`, `Formular`

**API-Token generieren:**

1. Gehe zu **Einstellungen** → **Benutzer & Gruppen**
2. Klicke auf deinen Benutzernamen
3. Unter **Auth Token**, klicke **Generieren**
4. Kopiere und sichere den Token

### Consume-Ordner-Einrichtung

**Automatischer Dokumenten-Import:**

Der Consume-Ordner (`./shared`) wird auf neue Dokumente überwacht:
```bash
# Dokumente hochladen via:
# 1. Direktes Kopieren zum Server
scp rechnung.pdf user@server:~/ai-corekit/shared/

# 2. Via Seafile (wenn installiert)
# Upload zu Seafile → paperless-bridge Ordner

# 3. Via n8n Workflow
# HTTP-Endpunkt → In Consume-Ordner speichern
```

**Ordnerstruktur für Auto-Tagging:**
```
./shared/
├── rechnungen/    # Auto-getaggt als "Rechnung"
├── vertraege/     # Auto-getaggt als "Vertrag"  
├── belege/        # Auto-getaggt als "Beleg"
└── eingang/       # Allgemeine Dokumente
```

### n8n-Integration

#### Beispiel 1: E-Mail-Anhänge verarbeiten
```javascript
// E-Mail-Anhänge automatisch verarbeiten

// 1. Email Trigger (IMAP) - Auf neue E-Mails prüfen
Account: Deine E-Mail-Anmeldedaten
Ordner: INBOX
Filter: Hat Anhänge

// 2. Loop - Für jeden Anhang

// 3. IF Node - Prüfe ob PDF oder Bild
Bedingung: {{$binary.attachment.mimeType}} enthält "pdf" ODER "image"

// 4. HTTP Request - Zu Paperless hochladen
Method: POST
URL: http://paperless:8000/api/documents/post_document/
Headers:
  Authorization: Token {{$credentials.paperless_token}}
Body: Binärer Anhang
Zusätzliche Felder:
  title: E-Mail von {{$json.from}} - {{$json.subject}}
  correspondent: {{$json.from}}
  tags: email,eingang

// 5. E-Mail in verarbeiteten Ordner verschieben
Operation: Move Message
Ordner: Verarbeitet
```

#### Beispiel 2: Rechnungsverarbeitungs-Workflow
```javascript
// Daten aus Rechnungen extrahieren und Buchhaltungseinträge erstellen

// 1. Paperless Webhook - Dokument hinzugefügt
// Webhook in Paperless-Einstellungen konfigurieren

// 2. HTTP Request - Dokumentdetails abrufen
Method: GET
URL: http://paperless:8000/api/documents/{{$json.document_id}}/
Headers:
  Authorization: Token {{$credentials.paperless_token}}

// 3. IF Node - Prüfe ob Rechnung
Bedingung: {{$json.document_type}} == "Rechnung"

// 4. HTTP Request - Dokumentinhalt abrufen
Method: GET  
URL: http://paperless:8000/api/documents/{{$json.id}}/download/
Headers:
  Authorization: Token {{$credentials.paperless_token}}

// 5. OpenAI Node - Rechnungsdaten extrahieren
Prompt: |
  Extrahiere folgendes aus dieser Rechnung:
  - Rechnungsnummer
  - Datum
  - Gesamtbetrag
  - MwSt-Betrag
  - Lieferantenname
  Als JSON zurückgeben.

// 6. Google Sheets Node - Zur Buchhaltung hinzufügen
Operation: Append
Sheet: Rechnungen 2024
Werte: Extrahierte Daten

// 7. Benachrichtigung senden
Kanal: #buchhaltung
Nachricht: Neue Rechnung verarbeitet: {{$json.rechnungsnummer}}
```

#### Beispiel 3: Dokument-Aufbewahrungsrichtlinie
```javascript
// Alte Dokumente automatisch archivieren

// 1. Schedule Trigger - Monatlich
Cron: 0 0 1 * *

// 2. HTTP Request - Alte Dokumente abrufen
Method: GET
URL: http://paperless:8000/api/documents/
Query Parameter:
  created__lt: {{$now.minus(7, 'years').format('YYYY-MM-DD')}}
  
// 3. Loop - Für jedes Dokument

// 4. HTTP Request - Archiv-Tag hinzufügen
Method: PATCH
URL: http://paperless:8000/api/documents/{{$json.id}}/
Body:
  tags: [...existing_tags, "archiviert"]
  
// 5. Backup zu Cold Storage
// Zu S3/Backblaze/externer Festplatte verschieben
```

### Mobiles Scannen

**Mobile Apps:**
- **iOS:** [Paperless Mobile](https://apps.apple.com/app/paperless-mobile/id1556098941)
- **Android:** [Paperless Mobile](https://play.google.com/store/apps/details?id=de.astubenbord.paperless_mobile)

**App-Konfiguration:**
1. Server-URL: `https://docs.deinedomain.com`
2. Benutzername: Deine E-Mail
3. Passwort: Dein Passwort

**Scan-Workflow:**
1. Mobile App öffnen
2. Kamera-Symbol antippen
3. Dokument scannen (Auto-Crop und Verbesserung)
4. Tags/Korrespondent hinzufügen (optional)
5. Upload → Automatische OCR-Verarbeitung

### Erweiterte Funktionen

**Benutzerdefinierte Matching-Regeln:**

Erstelle Regeln für automatische Dokumentenverarbeitung:

1. **Einstellungen** → **Matching**
2. Regel hinzufügen:
   - **Muster:** "Rechnungs-Nr."
   - **Dokumenttyp:** Rechnung
   - **Tags:** "Zahlung-erforderlich" hinzufügen

**E-Mail-Verarbeitungsregeln:**

E-Mail-Import konfigurieren:

1. **Einstellungen** → **Mail**
2. IMAP-Konto hinzufügen
3. Regeln setzen:
   - Von `amazon@email.amazon.com` → Tag "Amazon", "Beleg"
   - Betreff enthält "Rechnung" → Dokumenttyp "Rechnung"

### Fehlerbehebung

**OCR funktioniert nicht:**
```bash
# Prüfen ob OCR-Sprachen installiert sind
docker exec paperless-ngx ls /usr/share/tesseract-ocr/*/

# Sprachpakete neu installieren
docker exec paperless-ngx apt-get update
docker exec paperless-ngx apt-get install tesseract-ocr-deu tesseract-ocr-eng

# Service neu starten
docker compose restart paperless
```

**Kann Dokumente nicht hochladen:**
```bash
# Berechtigungen am Consume-Ordner prüfen
ls -la ./shared/

# Berechtigungen korrigieren
sudo chown -R 1000:1000 ./shared/

# Paperless Logs prüfen
docker logs paperless-ngx --tail 100 | grep ERROR
```

**Datenbank-Probleme:**
```bash
# PostgreSQL-Status prüfen
docker ps | grep paperless-postgres

# Datenbank-Logs prüfen
docker logs paperless-postgres --tail 50

# Datenbank-Migrationen ausführen
docker exec paperless-ngx python manage.py migrate
```

**Suche funktioniert nicht:**
```bash
# Suchindex neu aufbauen
docker exec paperless-ngx python manage.py document_index reindex

# Redis-Verbindung prüfen
docker exec paperless-ngx python manage.py shell
>>> from django.core.cache import cache
>>> cache.set('test', 'value')
>>> cache.get('test')
```

### Backup & Migration

**Dokumente sichern:**
```bash
# Alle Dokumente mit Metadaten exportieren
docker exec paperless-ngx python manage.py document_exporter ../export

# Backup-Speicherort: ./export/
# Beinhaltet: Dokumente, Metadaten, Datenbank-Dump
```

**Dokumente wiederherstellen:**
```bash
# Aus Backup importieren
docker exec paperless-ngx python manage.py document_importer ../export
```

### Performance-Tipps

- **OCR-Einstellungen:** `skip`-Modus für bereits OCR-bearbeitete PDFs verwenden
- **Parallele Verarbeitung:** `PAPERLESS_TASK_WORKERS` erhöhen für schnellere Verarbeitung
- **Thumbnail-Generierung:** Für reine Text-Dokumente deaktivieren
- **Datenbank:** PostgreSQL performt besser als SQLite für große Archive
- **Speicher:** SSD für Media-Verzeichnis für bessere Performance verwenden

### DSGVO-Konformität

Paperless-ngx hilft bei DSGVO-Compliance:

- **Aufbewahrungsrichtlinien:** Automatische Dokument-Löschung nach X Jahren
- **Zugriffsprotokolle:** Verfolgen wer auf welche Dokumente zugegriffen hat
- **Verschlüsselung:** Optionale GPG-Verschlüsselung für sensible Dokumente
- **Datenexport:** Alle Daten für Datenportabilität exportieren
- **Recht auf Löschung:** Massenlöschung nach Korrespondent

### Ressourcen

- **Offizielle Dokumentation:** https://docs.paperless-ngx.com/
- **API-Dokumentation:** https://docs.paperless-ngx.com/api/
- **GitHub:** https://github.com/paperless-ngx/paperless-ngx
- **Community-Forum:** https://github.com/paperless-ngx/paperless-ngx/discussions
- **Mobile Apps:** https://github.com/astubenbord/paperless-mobile
- **Backup-Strategie:** https://docs.paperless-ngx.com/administration/#backup
