# ✉️ SnappyMail - Webmail-Client

### Was ist SnappyMail?

SnappyMail ist ein moderner, ultra-schneller Webmail-Client mit nur 138KB Ladezeit. Er bietet eine vollständige E-Mail-Oberfläche für Docker-Mailserver mit professionellen Funktionen wie PGP-Verschlüsselung und Multi-Account-Unterstützung.

### Features

- **Ultra-schnelle Performance:** 138KB initiale Ladegröße, 99% Lighthouse-Score
- **Mehrere Konten:** Verwalte mehrere E-Mail-Konten in einer Oberfläche
- **Mobile Responsive:** Funktioniert perfekt auf allen Geräten
- **PGP-Verschlüsselung:** Integrierte Unterstützung für verschlüsselte E-Mails
- **2-Faktor-Authentifizierung:** Erhöhte Sicherheit für Webmail-Zugriff
- **Keine Datenbank erforderlich:** Einfache dateibasierte Konfiguration
- **Dark Mode:** Integrierte Theme-Unterstützung

### Erste Einrichtung

**Voraussetzung:** Docker-Mailserver muss installiert sein (SnappyMail benötigt IMAP/SMTP).

#### 1. Admin-Passwort abrufen

```bash
# Admin-Passwort anzeigen
docker exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt
```

#### 2. Admin-Panel konfigurieren

1. Öffne Admin-Panel: `https://webmail.deinedomain.com/?admin`
2. Benutzername: `admin`
3. Passwort: (aus Schritt 1)

#### 3. Domain hinzufügen

Im Admin-Panel:

**Domains → Add Domain:**
```
Domain: deinedomain.com
IMAP Server: mailserver
IMAP Port: 143
IMAP Security: STARTTLS
SMTP Server: mailserver
SMTP Port: 587
SMTP Security: STARTTLS
```

#### 4. Benutzer-Login

Nach Domain-Konfiguration können sich Benutzer anmelden:

1. URL: `https://webmail.deinedomain.com`
2. E-Mail: `benutzer@deinedomain.com`
3. Passwort: (Benutzer's Docker-Mailserver-Passwort)

### n8n-Integrations-Setup

**SnappyMail ist ein Webmail-Client ohne direkte API.** Integration erfolgt über Docker-Mailserver:

**E-Mail-Workflow-Architektur:**
```
n8n Send Email Node → Docker-Mailserver → SnappyMail (E-Mails lesen)
```

**IMAP-Integration in n8n (E-Mails abrufen):**

1. Email (IMAP) Trigger Node in n8n
2. Konfiguration:

```
Host: mailserver
Port: 993
User: benutzer@deinedomain.com
Password: [Docker-Mailserver-Passwort]
TLS: Enabled
```

**Interne URLs:**
- IMAP: `mailserver:993` (mit TLS) oder `mailserver:143` (STARTTLS)
- SMTP: `mailserver:587` (STARTTLS)

### Beispiel-Workflows

#### Beispiel 1: E-Mail-Management-Workflow

```javascript
// SnappyMail Anwendungsfall: E-Mails über Web-UI verwalten

// Workflow-Architektur:
// 1. Service sendet E-Mail → Docker-Mailserver
// 2. Benutzer öffnet SnappyMail → Liest E-Mail
// 3. Benutzer antwortet → Gesendet über Docker-Mailserver

// n8n Parallel-Workflow:
// 1. IMAP Trigger Node (mailserver:993)
//    → Verarbeite neue E-Mails automatisch
// 2. Code Node - E-Mail analysieren
// 3. Conditional Node - Nach Kriterien filtern
// 4. Action Nodes - Automatisierte Aktionen
```

#### Beispiel 2: Multi-Account-Verwaltung

```javascript
// SnappyMail Feature: Mehrere Konten verwalten

// Setup in SnappyMail:
// 1. Benutzer-Login: benutzer@deinedomain.com
// 2. Settings → Accounts → Add Account
// 3. Weitere Konten hinzufügen (support@, sales@, etc.)
// 4. Mit einem Klick zwischen Konten wechseln

// Verwalte alle E-Mails zentral!
```

#### Beispiel 3: Ticket-System-Integration

```javascript
// 1. IMAP Trigger Node (mailserver:993)
//    Mailbox: support@deinedomain.com
//    → Wartet auf neue Support-E-Mails

// 2. Code Node - Ticket-Daten extrahieren
const ticketData = {
  from: $json.from.value[0].address,
  subject: $json.subject,
  body: $json.textPlain || $json.textHtml,
  date: $json.date,
  priority: $json.subject.includes('DRINGEND') ? 'high' : 'normal'
};
return ticketData;

// 3. HTTP Request Node - Ticket erstellen
// POST an Ticketsystem-API
{
  "title": ticketData.subject,
  "description": ticketData.body,
  "customer_email": ticketData.from,
  "priority": ticketData.priority
}

// 4. Send Email Node - Bestätigung senden
// → Kunde erhält Ticket-Nummer
// → E-Mail sichtbar in SnappyMail

// Support-Team kann in SnappyMail antworten!
```

### Fehlerbehebung

**SnappyMail Web-UI nicht erreichbar:**

```bash
# 1. Prüfe Container-Status
docker ps | grep snappymail
# Sollte zeigen: STATUS = Up

# 2. Prüfe Logs
docker logs snappymail --tail 50

# 3. Hole Admin-Passwort erneut
docker exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt

# 4. Prüfe Caddy-Logs
docker logs caddy | grep snappymail

# 5. Starte Container neu
docker compose restart snappymail
```

**Benutzer können sich nicht anmelden:**

```bash
# 1. Prüfe Domain-Konfiguration
# → Öffne Admin-Panel: https://webmail.deinedomain.com/?admin
# → Domains → Prüfe Domain
# → Überprüfe IMAP/SMTP-Einstellungen

# 2. Prüfe Benutzer-Konto in Docker-Mailserver
docker exec mailserver setup email list

# 3. Teste IMAP/SMTP-Verbindung
docker exec snappymail nc -zv mailserver 143
docker exec snappymail nc -zv mailserver 587

# 4. Teste Authentifizierung
docker exec mailserver doveadm auth test benutzer@deinedomain.com [passwort]

# 5. Prüfe benutzerspezifische Logs
docker logs snappymail | grep -i "login\|auth\|imap"
```

**E-Mails werden nicht angezeigt:**

```bash
# 1. Prüfe IMAP-Verbindung
docker exec snappymail nc -zv mailserver 143

# 2. Prüfe Mailbox in Docker-Mailserver
docker exec mailserver doveadm mailbox list -u benutzer@deinedomain.com

# 3. Teste E-Mail-Zustellung
# Sende Test-E-Mail an benutzer@deinedomain.com

# 4. Prüfe Docker-Mailserver-Logs
docker logs mailserver | grep benutzer@deinedomain.com

# 5. Leere SnappyMail-Cache
docker exec snappymail rm -rf /var/lib/snappymail/_data_/_default_/cache/*
docker compose restart snappymail
```

**Performance-Probleme:**

```bash
# 1. Prüfe Cache-Größe
docker exec snappymail du -sh /var/lib/snappymail/_data_/_default_/cache/

# 2. Leere Cache (falls zu groß)
docker exec snappymail rm -rf /var/lib/snappymail/_data_/_default_/cache/*

# 3. Prüfe Container-Ressourcen
docker stats snappymail --no-stream

# 4. Prüfe Logs auf Fehler
docker logs snappymail | grep -i "error\|warning"

# 5. Starte Container neu
docker compose restart snappymail
```

### Ressourcen

- **GitHub:** https://github.com/the-djmaze/snappymail
- **Dokumentation:** https://snappymail.eu/docs/
- **Demo:** https://snappymail.eu/demo/
- **Admin-Anleitung:** https://snappymail.eu/docs/admin/
- **Web-UI:** `https://webmail.deinedomain.com`
- **Admin-Panel:** `https://webmail.deinedomain.com/?admin`
