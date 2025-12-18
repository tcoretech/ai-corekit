# 📬 Docker-Mailserver - Produktive E-Mail

### Was ist Docker-Mailserver?

Docker-Mailserver ist ein voll ausgestatteter, produktionsreifer Mail-Server (SMTP, IMAP) mit integriertem Spam-Schutz und Sicherheitsfunktionen. Perfekt für echte E-Mail-Zustellung in Produktion.

### Features

- **Volle SMTP/IMAP-Unterstützung:** Echte E-Mail-Zustellung und -Empfang
- **DKIM/SPF/DMARC:** Konfiguriert für beste Zustellbarkeit
- **Rspamd-Integration:** Automatischer Spam-Schutz
- **Benutzerverwaltung:** Einfache CLI-Tools für Kontenverwaltung
- **Standardmäßig sicher:** TLS/STARTTLS, moderne Cipher Suites

### Erste Einrichtung

**Voraussetzung:** Docker-Mailserver muss während der Installation ausgewählt worden sein.

#### 1. DNS-Einträge konfigurieren

Diese DNS-Einträge sind **erforderlich** für E-Mail-Zustellung:

**MX-Eintrag:**
```
Type: MX
Name: @ (oder deinedomain.com)
Wert: mail.deinedomain.com
Priority: 10
```

**A-Eintrag für mail-Subdomain:**
```
Type: A
Name: mail
Wert: DEINE_SERVER_IP
```

**SPF-Eintrag:**
```
Type: TXT
Name: @ (oder deinedomain.com)
Wert: "v=spf1 mx ~all"
```

**DMARC-Eintrag:**
```
Type: TXT
Name: _dmarc
Wert: "v=DMARC1; p=none; rua=mailto:postmaster@deinedomain.com"
```

**DKIM-Eintrag (nach Installation):**
```bash
# DKIM-Schlüssel generieren
docker exec mailserver setup config dkim

# Public Key für DNS anzeigen
docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/deinedomain.com/mail.txt

# Als TXT-Eintrag hinzufügen:
# Name: mail._domainkey
# Wert: (der angezeigte Schlüssel)
```

#### 2. E-Mail-Konten erstellen

```bash
# Erstes Konto erstellen
docker exec -it mailserver setup email add admin@deinedomain.com

# Weitere Konten hinzufügen
docker exec mailserver setup email add benutzer@deinedomain.com
docker exec mailserver setup email add support@deinedomain.com

# Alle Konten auflisten
docker exec mailserver setup email list
```

#### 3. Automatische Konfiguration

**Alle Dienste nutzen automatisch Docker-Mailserver:**
- SMTP Host: `mailserver`
- SMTP Port: `587`
- Sicherheit: STARTTLS
- Authentifizierung: noreply@deinedomain.com
- Passwort: automatisch generiert (siehe `.env`)

### n8n-Integrations-Setup

**SMTP-Zugangsdaten in n8n erstellen:**

1. Öffne n8n: `https://n8n.deinedomain.com`
2. Settings → Credentials → Add New
3. Credential Type: SMTP
4. Konfiguration:

```
Host: mailserver
Port: 587
User: noreply@deinedomain.com
Password: [siehe .env-Datei - MAIL_NOREPLY_PASSWORD]
SSL/TLS: Enable STARTTLS
Sender Email: noreply@deinedomain.com
```

**Interne URL für HTTP-Requests:** `http://mailserver:587`

### Beispiel-Workflows

#### Beispiel 1: Produktiv-E-Mail senden

```javascript
// 1. Manual Trigger Node

// 2. Send Email Node
// → Wähle SMTP-Credential (siehe Setup oben)
{
  "to": "kunde@example.com",
  "subject": "Bestellbestätigung #12345",
  "html": `
    <h1>Vielen Dank für deine Bestellung!</h1>
    <p>Deine Bestellung wurde erfolgreich verarbeitet.</p>
    <p>Bestellnummer: #12345</p>
  `
}

// E-Mail gesendet über Docker-Mailserver
// Empfänger erhält echte E-Mail
```

#### Beispiel 2: Cal.com Buchungs-Benachrichtigungen

```javascript
// Cal.com sendet automatisch E-Mails über Docker-Mailserver:
// - Buchungsbestätigungen
// - Kalender-Einladungen (.ics)
// - Erinnerungen
// - Stornierungen/Umplanungen

// Keine Konfiguration nötig - automatisch!
// Alle Cal.com E-Mails → Docker-Mailserver → Empfänger
```

#### Beispiel 3: Invoice Ninja Integration

```javascript
// SMTP in Invoice Ninja konfigurieren:
// Settings → Email Settings → SMTP Configuration
// Host: mailserver
// Port: 587
// Encryption: TLS
// Username: noreply@deinedomain.com
// Password: [aus .env]

// Workflow-Beispiel:
// 1. Invoice Ninja erstellt Rechnung
// 2. Invoice Ninja sendet E-Mail über Docker-Mailserver
// 3. Kunde erhält professionelle Rechnung per E-Mail
```

### Fehlerbehebung

**E-Mails werden nicht zugestellt:**

```bash
# 1. Prüfe DNS-Einträge
nslookup -type=MX deinedomain.com
nslookup -type=TXT deinedomain.com

# 2. Prüfe Docker-Mailserver-Logs
docker logs mailserver --tail 100

# 3. Prüfe Mail-Queue
docker exec mailserver postqueue -p

# 4. Prüfe DKIM-Status
docker exec mailserver setup config dkim status

# 5. Sende Test-E-Mail
docker exec mailserver setup email add test@deinedomain.com
# Dann von extern an test@deinedomain.com senden
```

**SMTP-Authentifizierung schlägt fehl:**

```bash
# 1. Prüfe ob Konto existiert
docker exec mailserver setup email list

# 2. Teste Authentifizierung
docker exec mailserver doveadm auth test noreply@deinedomain.com [passwort]

# 3. Überprüfe Passwort in .env
grep MAIL_NOREPLY_PASSWORD .env

# 4. Starte Service neu
docker compose restart mailserver
```

**Spam-Probleme (E-Mails landen im Spam):**

```bash
# 1. Prüfe DKIM, SPF, DMARC
# Nutze Online-Tools: https://mxtoolbox.com/

# 2. Prüfe IP-Reputation
# https://multirbl.valli.org/

# 3. Prüfe Rspamd-Logs
docker exec mailserver cat /var/log/rspamd/rspamd.log

# 4. Teste ausgehenden Port 25
telnet smtp.gmail.com 25
```

**Docker-Mailserver startet nicht:**

```bash
# 1. Prüfe Logs
docker logs mailserver --tail 100

# 2. Prüfe Volumes
docker volume ls | grep mailserver

# 3. Prüfe Ports (25, 465, 587, 993)
sudo netstat -tulpn | grep -E "25|465|587|993"

# 4. Erstelle Container neu
docker compose up -d --force-recreate mailserver
```

### Ressourcen

- **GitHub:** https://github.com/docker-mailserver/docker-mailserver
- **Dokumentation:** https://docker-mailserver.github.io/docker-mailserver/latest/
- **Setup-Anleitung:** https://docker-mailserver.github.io/docker-mailserver/latest/usage/
- **Best Practices:** https://docker-mailserver.github.io/docker-mailserver/latest/faq/
