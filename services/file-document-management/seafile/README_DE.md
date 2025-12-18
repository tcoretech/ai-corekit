# 🌊 Seafile - Professionelle Datei-Synchronisation & Freigabe

### Was ist Seafile?

Seafile ist eine professionelle Open-Source-Plattform für Dateisynchronisation und -freigabe, die eine selbst gehostete Alternative zu Dropbox, Google Drive und OneDrive bietet. Sie bietet zuverlässige Dateisynchronisation, Team-Kollaborationsfunktionen, Versionskontrolle und Verschlüsselung, was sie perfekt für Unternehmen macht, die volle Kontrolle über ihre Daten benötigen. Mit Desktop- und Mobile-Clients, WebDAV-Unterstützung und umfangreicher API integriert sich Seafile nahtlos in jeden Workflow.

### Funktionen

- **Datei-Sync** - Echtzeit-Synchronisation über alle Geräte mit selektiver Synchronisation
- **Versionskontrolle** - Vollständiger Dateiverlauf mit einfachem Rollback zu vorherigen Versionen
- **Team-Bibliotheken** - Gemeinsame Ordner mit granularer Rechteverwaltung
- **Datei-Sperrung** - Verhindert Bearbeitungskonflikte mit automatischer Dateisperrung
- **WebDAV-Unterstützung** - Als Netzlaufwerk unter Windows/Mac/Linux einbinden
- **Mobile Apps** - iOS und Android Apps mit Offline-Zugriff und Auto-Upload
- **Ende-zu-Ende-Verschlüsselung** - Client-seitige Verschlüsselung für sensible Daten
- **Office-Integration** - Online-Bearbeitung von Dokumenten mit OnlyOffice/Collabora
- **Volltextsuche** - Suche in Dokumenten, PDFs und Office-Dateien
- **Aktivitäts-Stream** - Verfolge alle Dateiänderungen und Team-Aktivitäten

### Erste Einrichtung

**Erste Anmeldung bei Seafile:**

1. Navigiere zu `https://files.deinedomain.com`
2. Anmeldung mit:
   - **E-Mail:** Deine konfigurierte Admin-E-Mail
   - **Passwort:** Prüfe deine `.env` Datei für `SEAFILE_ADMIN_PASSWORD`
3. Vervollständige das Ersteinrichtungs-Setup:
   - Erstelle deine erste Bibliothek (Ordner)
   - Installiere den Desktop-Client vom Dashboard
   - Konfiguriere Sync-Ordner

**Desktop-Client-Einrichtung:**

1. Download von `https://www.seafile.com/en/download/`
2. Account hinzufügen:
   - **Server:** `https://files.deinedomain.com`
   - **E-Mail:** Deine Admin-E-Mail
   - **Passwort:** Dein Admin-Passwort
3. Wähle Bibliotheken zur Synchronisation
4. Wähle lokale Ordner für die Synchronisation

**API-Token für n8n generieren:**

1. Gehe zu **Avatar** → **Einstellungen**
2. Navigiere zu **Web API** → **Auth Token**
3. Klicke auf **Generieren**
4. Kopiere und sichere den Token

### n8n-Integration einrichten

**Seafile Community Node installieren:**

1. In n8n, gehe zu **Einstellungen** → **Community Nodes**
2. Installiere: `n8n-nodes-seafile`
3. n8n neu starten: `docker compose restart n8n`

**Seafile-Anmeldedaten konfigurieren:**

1. Füge **Seafile**-Node zum Workflow hinzu
2. Neue Anmeldedaten erstellen:
   - **Server URL:** `http://seafile:80` (intern)
   - **API Token:** Dein generierter Token
   - Anmeldedaten speichern

### Beispiel-Workflows

#### Beispiel 1: Automatisches Dokument-Backup
```javascript
// Tägliches Backup wichtiger Dokumente zu Seafile

// 1. Schedule Trigger - Täglich um 2 Uhr
Cron Expression: 0 2 * * *

// 2. Read Binary Files - Dokumente aus lokalem Ordner holen
File Path: /data/shared/documents/*.pdf

// 3. Seafile Node - In Backup-Bibliothek hochladen
Operation: Upload File
Library: Backups
Path: /{{$now.format('YYYY-MM-DD')}}/
File: {{$binary}}

// 4. Seafile Node - Freigabe-Link erstellen
Operation: Create Share Link
Path: /{{$now.format('YYYY-MM-DD')}}/
Expiration: 30 Tage

// 5. Send Email - Backup-Bestätigung
An: admin@firma.com
Betreff: Tägliches Backup abgeschlossen
Nachricht: |
  Backup erfolgreich abgeschlossen!
  Dateien: {{$items.length}} Dokumente
  Speicherort: {{$json.share_link}}
```

#### Beispiel 2: Paperless Integration Bridge
```javascript
// Dokumente von Seafile zu Paperless für OCR-Verarbeitung verschieben

// 1. Seafile Node - Neue Dateien auflisten
Operation: List Directory
Library: Eingang
Path: /scans/

// 2. Loop Over Items
// Für jede Datei im Verzeichnis

// 3. Seafile Node - Datei herunterladen
Operation: Download File
File ID: {{$json.id}}

// 4. Move Binary Data
// Für Paperless vorbereiten

// 5. HTTP Request - An Paperless senden
Method: POST
URL: http://paperless:8000/api/documents/post_document/
Headers:
  Authorization: Token {{$credentials.paperless_token}}
Body: Binärdatei

// 6. Seafile Node - Verarbeitete Datei verschieben
Operation: Move File
Source: /scans/{{$json.name}}
Destination: /verarbeitet/{{$now.format('YYYY-MM')}}/
```

#### Beispiel 3: Team-Kollaborations-Automatisierung
```javascript
// Automatisch Projektordner mit Vorlagen erstellen

// 1. Webhook Trigger - Neues Projekt erstellt
// Von deinem Projektmanagementsystem

// 2. Seafile Node - Bibliothek erstellen
Operation: Create Library
Name: Projekt-{{$json.projekt_name}}
Description: {{$json.projekt_beschreibung}}

// 3. Seafile Node - Ordnerstruktur erstellen
Paths: [
  "/Dokumente",
  "/Designs",
  "/Meeting-Notizen",
  "/Ressourcen"
]

// 4. Seafile Node - Vorlagen-Dateien kopieren
Source Library: Vorlagen
Destination: Projekt-{{$json.projekt_name}}

// 5. Seafile Node - Mit Team teilen
Operation: Share Library
Users: {{$json.team_mitglieder}}
Permission: rw

// 6. Benachrichtigungen an Team senden
// Via E-Mail/Slack
```

### Mobile & WebDAV-Zugriff

**Mobile Apps:**
- **iOS:** [Seafile Pro](https://apps.apple.com/app/seafile-pro/id639202512)
- **Android:** [Seafile](https://play.google.com/store/apps/details?id=com.seafile.seadroid2)

**WebDAV-Konfiguration:**

Windows:
```
URL: https://files.deinedomain.com/seafdav
Benutzername: deine-email@domain.com
Passwort: dein-passwort
```

Mac Finder:
```
Gehe zu → Mit Server verbinden
Server: https://files.deinedomain.com/seafdav
```

Linux:
```bash
# davfs2 installieren
sudo apt-get install davfs2

# Einbinden
sudo mount -t davfs https://files.deinedomain.com/seafdav /mnt/seafile
```

### Fehlerbehebung

**Kann mich nicht anmelden:**
```bash
# Prüfen ob Seafile läuft
docker ps | grep seafile

# Logs auf Fehler prüfen
docker logs seafile --tail 100

# Admin-Passwort zurücksetzen
docker exec -it seafile /opt/seafile/seafile-server-latest/reset-admin.sh
```

**Sync-Probleme:**
```bash
# Seafile-Service-Status prüfen
docker exec seafile /opt/seafile/seafile-server-latest/seafile.sh status

# Services neu starten
docker compose restart seafile seafile-db

# Datenbankverbindung prüfen
docker logs seafile-mariadb --tail 50
```

**Speicherplatz:**
```bash
# Genutzten Speicher prüfen
docker exec seafile df -h /shared

# Gelöschte Dateien aufräumen (Garbage Collection)
docker exec seafile /opt/seafile/seafile-server-latest/seaf-gc.sh
```

### Performance-Optimierung

**Für große Deployments:**
- Memcached für bessere Performance aktivieren
- Nginx für statische Dateien konfigurieren
- S3/MinIO für Object Storage Backend verwenden
- Elasticsearch für Volltextsuche aktivieren

**Backup Best Practices:**
- Regelmäßige Datenbank-Backups (MariaDB)
- Daten-Verzeichnis zu externem Speicher synchronisieren
- Wiederherstellungsverfahren vierteljährlich testen

### Ressourcen

- **Offizielle Dokumentation:** https://manual.seafile.com/
- **API-Dokumentation:** https://manual.seafile.com/develop/web_api_v2.1/
- **Community-Forum:** https://forum.seafile.com/
- **GitHub:** https://github.com/haiwen/seafile
- **Desktop-Clients:** https://www.seafile.com/en/download/
- **n8n Community Node:** https://www.npmjs.com/package/n8n-nodes-seafile
