# 🔐 Vaultwarden - Passwort-Manager

### Was ist Vaultwarden?

Vaultwarden ist ein leichtgewichtiger, selbst gehosteter Passwort-Manager, der zu 100% kompatibel mit Bitwarden-Clients ist. In Rust geschrieben, bietet er die gleichen Funktionen wie der offizielle Bitwarden-Server, jedoch mit deutlich geringeren Ressourcenanforderungen. Perfekt zur sicheren Verwaltung aller Zugangsdaten, API-Schlüssel und Team-Passwörter deiner AI CoreKit-Services.

Mit über 40 Services im AI CoreKit, die eindeutige Passwörter und API-Schlüssel generieren, wird Credential-Management essentiell. Vaultwarden bietet einen zentralen, verschlüsselten Tresor, der über Browser-Erweiterungen, Mobile Apps und Desktop-Clients zugänglich ist.

### Funktionen

- ✅ **100% Bitwarden-Kompatibel** - Funktioniert mit allen offiziellen Bitwarden-Clients
- ✅ **Leichtgewichtig & Schnell** - Nur 50-200MB RAM statt 2GB+ beim offiziellen Bitwarden
- ✅ **Browser-Integration** - Auto-Fill für alle Services (Chrome, Firefox, Safari, Edge)
- ✅ **Mobile Apps** - iOS und Android Apps mit biometrischer Entsperrung
- ✅ **Team-Freigabe** - Organisationen für sichere Credential-Freigabe
- ✅ **2FA-Unterstützung** - TOTP, WebAuthn, YubiKey, Duo, E-Mail
- ✅ **Passwort-Generator** - Erstelle starke, einzigartige Passwörter
- ✅ **Sicherheitsberichte** - Identifiziere schwache, wiederverwendete oder kompromittierte Passwörter
- ✅ **Notfallzugriff** - Vertrauenspersonen für Account-Wiederherstellung
- ✅ **Send-Funktion** - Sicheres Teilen von Text/Dateien mit Ablaufdatum

### Ersteinrichtung

**Erste Schritte nach der Installation:**

1. **Admin-Panel öffnen:** Navigiere zu `https://vault.deinedomain.com/admin`
2. **Admin-Token eingeben:** Im Installationsbericht oder in der `.env`-Datei als `VAULTWARDEN_ADMIN_TOKEN`
   ```bash
   # Admin-Token aus .env abrufen
   grep "VAULTWARDEN_ADMIN_TOKEN" .env
   ```
3. **SMTP konfigurieren:** Nutzt dein konfiguriertes Mail-System (Mailpit oder Docker-Mailserver)
   - Für Mailpit (Entwicklung): Bereits automatisch konfiguriert
   - Für Docker-Mailserver: SMTP-Einstellungen im Admin-Panel aktualisieren
4. **Öffentliche Registrierungen deaktivieren (Sicherheit):** Im Admin-Panel nach Erstellung deines Accounts
5. **Ersten Benutzer erstellen:** Navigiere zu `https://vault.deinedomain.com` und klicke auf "Konto erstellen"
6. **Browser-Erweiterung installieren:** Verfügbar für Chrome, Firefox, Safari, Edge, Opera

**Dein erstes Konto erstellen:**

1. Gehe zu `https://vault.deinedomain.com`
2. Klicke auf **"Konto erstellen"**
3. E-Mail eingeben und ein **starkes Master-Passwort** erstellen (kann nicht zurückgesetzt werden!)
4. E-Mail verifizieren (falls SMTP konfiguriert ist)
5. Anmelden und mit dem Hinzufügen von Passwörtern beginnen

### Automatischer Zugangsdaten-Import

AI CoreKit generiert automatisch eine Bitwarden-kompatible JSON-Datei mit allen Service-Zugangsdaten:

```bash
# Zugangsdaten generieren und herunterladen (nach Installation)
sudo bash ./scripts/download_credentials.sh
```

**Was dieses Skript macht:**
1. Generiert eine JSON-Datei mit allen Service-Passwörtern, API-Schlüsseln und Tokens
2. Öffnet Port 8889 temporär (60 Sekunden)
3. Zeigt einen Download-Link für deinen Browser an
4. Löscht die Datei automatisch nach dem Download aus Sicherheitsgründen

**In Vaultwarden importieren:**

1. Lade die Datei über den vom Skript bereitgestellten Link herunter
2. Öffne Vaultwarden: `https://vault.deinedomain.com`
3. Gehe zu **Werkzeuge** → **Daten importieren**
4. Wähle Format: **Bitwarden (json)**
5. Wähle die heruntergeladene Datei
6. Klicke auf **Daten importieren**

Alle Zugangsdaten werden in einem Ordner "AI CoreKit Services" organisiert mit:
- Service-URLs
- Benutzernamen/E-Mails
- Passwörtern
- API-Tokens
- Admin-Zugangsdaten
- SMTP-Einstellungen

### Client-Konfiguration

**Browser-Erweiterungen:**

1. Installiere die offizielle Bitwarden-Erweiterung von:
   - Chrome Web Store: Suche "Bitwarden"
   - Firefox Add-ons: Suche "Bitwarden"
   - Safari-Erweiterungen: Verfügbar im Mac App Store
   - Edge Add-ons: Suche "Bitwarden"
2. Klicke auf Erweiterungs-Symbol
3. Klicke auf **"Einstellungen"** (Zahnrad-Symbol)
4. Gib Server-URL ein: `https://vault.deinedomain.com`
5. Klicke auf **"Speichern"**
6. Melde dich mit deinen Zugangsdaten an
7. Aktiviere Auto-Fill in den Erweiterungs-Einstellungen

**Mobile Apps:**

1. Lade Bitwarden herunter von:
   - iOS: App Store - "Bitwarden Password Manager"
   - Android: Play Store - "Bitwarden Password Manager"
2. Öffne App und tippe während Setup auf **"Selbst gehostet"**
3. Gib Server-URL ein: `https://vault.deinedomain.com`
4. Melde dich mit deinen Zugangsdaten an
5. Aktiviere biometrische Entsperrung (Face ID, Touch ID, Fingerabdruck)

**Desktop-Apps:**

1. Herunterladen von [bitwarden.com/download](https://bitwarden.com/download/)
2. Installieren und Anwendung öffnen
3. Gehe zu **Einstellungen** → **Server-URL**
4. Eingeben: `https://vault.deinedomain.com`
5. Klicke auf **"Speichern"**
6. Melde dich mit deinen Zugangsdaten an

### AI CoreKit Zugangsdaten organisieren

**Empfohlene Ordnerstruktur:**

```
📁 AI CoreKit Services (Hauptordner aus Import)
├── 📁 Kern-Services
│   ├── 🔑 n8n Admin (https://n8n.deinedomain.com)
│   ├── 🔑 Supabase Dashboard
│   ├── 🔑 PostgreSQL Datenbank
│   └── 🔑 Redis (intern)
├── 📁 KI-Tools
│   ├── 🔑 OpenAI API Key
│   ├── 🔑 Anthropic API Key
│   ├── 🔑 Groq API Key
│   ├── 🔑 Ollama Admin
│   └── 🔑 Open WebUI
├── 📁 Entwicklung
│   ├── 🔑 bolt.diy Zugang
│   ├── 🔑 ComfyUI Login
│   ├── 🔑 GitHub Tokens
│   └── 🔑 Portainer Admin
├── 📁 Business-Tools
│   ├── 🔑 Cal.com Admin
│   ├── 🔑 Vikunja Login
│   ├── 🔑 NocoDB API Token
│   └── 🔑 Leantime Admin
└── 📁 Überwachung
    ├── 🔑 Grafana Admin
    ├── 🔑 Prometheus Zugang
    └── 🔑 Mailpit Dashboard
```

**Best Practices für die Organisation:**

- Nutze **Ordner** um verwandte Services zu gruppieren
- Füge **benutzerdefinierte Felder** für API-Schlüssel, Tokens, interne URLs hinzu
- Nutze **Tags** für schnelles Filtern (z.B. #produktion, #staging, #api)
- Aktiviere **Favoriten** für häufig genutzte Zugangsdaten
- Füge **Notizen** mit Setup-Anweisungen oder Wiederherstellungscodes hinzu

### Sicherheitsfunktionen

**Zwei-Faktor-Authentifizierung (2FA) aktivieren:**

1. Gehe zu **Einstellungen** → **Zweistufige Anmeldung**
2. Wähle Methode:
   - **Authenticator App** (empfohlen): Nutze Google Authenticator, Authy, etc.
   - **E-Mail:** Codes per E-Mail erhalten
   - **WebAuthn:** Hardware-Schlüssel verwenden (YubiKey, etc.)
   - **Duo:** Falls du ein Duo-Konto hast
3. Folge dem Setup-Assistenten
4. **Speichere Wiederherstellungscode** an einem sicheren Ort (offline!)

**Passwort-Generator:**

- Zugriff über Browser-Erweiterung oder Web-Oberfläche des Tresors
- Anpassen: Länge (8-128 Zeichen), Groß-/Kleinbuchstaben, Zahlen, Symbole
- Optionen: Passphrasen (leichter zu merken), minimale Zahlen/Symbole
- Generierte Passwörter sind automatisch stark und einzigartig

**Sicherheitsberichte:**

1. Gehe zu **Werkzeuge** → **Berichte**
2. Verfügbare Berichte:
   - **Offengelegte Passwörter:** Prüfung gegen haveibeenpwned.com-Datenbank
   - **Wiederverwendete Passwörter:** Finde mehrfach verwendete Passwörter
   - **Schwache Passwörter:** Identifiziere Passwörter unter Stärkeschwellenwert
   - **Ungesicherte Websites:** HTTP-Seiten, die Zugangsdaten speichern
   - **Inaktive 2FA:** Seiten, die 2FA anbieten, die du nicht aktiviert hast
   - **Datenleck-Bericht:** Prüfe, ob deine Accounts kompromittiert wurden

**Notfallzugriff:**

1. Gehe zu **Einstellungen** → **Notfallzugriff**
2. Klicke auf **"Notfallkontakt hinzufügen"**
3. Gib E-Mail der Vertrauensperson ein
4. Setze Wartezeit (0-90 Tage)
5. Wähle Zugriffsebene: Ansehen oder Übernehmen
6. Kontakt erhält Einladung zur Annahme

**Send-Funktion (Sicheres Teilen):**

1. Klicke auf **"Send"** im Tresor-Menü
2. Wähle Typ: Text oder Datei (max. 500MB)
3. Setze Optionen:
   - Löschdatum (1 Stunde bis 31 Tage, oder manuell)
   - Ablaufdatum
   - Maximale Zugriffszahl
   - Passwortschutz
   - E-Mail vor Empfängern verbergen
4. Teile den generierten Link

### n8n Integration

Während Vaultwarden keine native n8n-Node hat, kannst du es programmatisch über die API nutzen:

**API-Authentifizierung:**

1. Melde dich in der Vaultwarden Web-Oberfläche an
2. Hole API-Zugangsdaten durch Login via CLI:
   ```bash
   # Mit curl Auth-Token abrufen
   curl -X POST https://vault.deinedomain.com/identity/connect/token \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=password&username=DEINE_EMAIL&password=DEIN_PASSWORT&scope=api&client_id=web"
   ```

**Beispiel: Zugangsdaten in n8n Workflow abrufen**

```javascript
// Dies ist ein konzeptionelles Beispiel - benötigt API-Token

// 1. HTTP Request - Access Token abrufen
Methode: POST
URL: https://vault.deinedomain.com/identity/connect/token
Header:
  Content-Type: application/x-www-form-urlencoded
Body (Form):
  grant_type: password
  username: {{$env.VAULTWARDEN_EMAIL}}
  password: {{$env.VAULTWARDEN_PASSWORD}}
  scope: api
  client_id: web

// 2. Set Node - Token speichern
Keep Only Set: true
Values:
  token: {{$json.access_token}}

// 3. HTTP Request - Tresor-Einträge abrufen
Methode: GET
URL: https://vault.deinedomain.com/api/ciphers
Header:
  Authorization: Bearer {{$json.token}}

// 4. Code Node - Spezifische Zugangsdaten finden
const items = $input.item.json.Data;
const targetItem = items.find(item => 
  item.Name.includes('OpenAI') || 
  item.Login?.Uris?.some(uri => uri.Uri.includes('openai.com'))
);

return {
  name: targetItem.Name,
  username: targetItem.Login?.Username,
  password: targetItem.Login?.Password,
  notes: targetItem.Notes
};
```

**Besserer Ansatz:** API-Schlüssel direkt in n8n Umgebungsvariablen speichern:
- Sicherer als Abrufen von Vaultwarden in jedem Workflow
- Schnellere Ausführung
- Einfachere Workflow-Logik
- Nutze Vaultwarden als sicheren Speicher, aktualisiere n8n .env manuell bei Schlüsseländerungen

### Backup & Wiederherstellung

**Vaultwarden-Daten sichern:**

```bash
# Methode 1: Komplettes Datenverzeichnis sichern
docker exec vaultwarden tar -czf /tmp/vaultwarden-backup-$(date +%Y%m%d).tar.gz /data
docker cp vaultwarden:/tmp/vaultwarden-backup-$(date +%Y%m%d).tar.gz ./backups/

# Methode 2: Docker Volume sichern
docker run --rm \
  -v vaultwarden_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/vaultwarden-backup-$(date +%Y%m%d).tar.gz /data

# Backup verifizieren
ls -lh ./backups/vaultwarden-backup-*.tar.gz
```

**Tresor exportieren (Benutzerebenen-Backup):**

1. Melde dich in der Vaultwarden Web-Oberfläche an
2. Gehe zu **Werkzeuge** → **Tresor exportieren**
3. Wähle Format:
   - **JSON** (empfohlen): Vollständiger Export mit Ordnern
   - **CSV**: Einfaches Format, keine Ordner
   - **JSON (Verschlüsselt)**: Passwortgeschützter Export
4. Klicke auf **"Tresor exportieren"**
5. Speichere Export-Datei sicher (verschlüsselter Speicher empfohlen)

**Aus Backup wiederherstellen:**

```bash
# Vaultwarden stoppen
docker stop vaultwarden

# Daten wiederherstellen
docker run --rm \
  -v vaultwarden_data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /data && tar -xzf /backup/vaultwarden-backup-JJJJMMTT.tar.gz --strip-components=1"

# Vaultwarden starten
docker start vaultwarden
```

**Automatisiertes Backup-Skript:**

Erstelle einen Cron-Job für automatisierte Backups:

```bash
# Backup-Skript erstellen
cat > ~/vaultwarden-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/$(whoami)/vaultwarden-backups"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

# Backup erstellen
docker run --rm \
  -v vaultwarden_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf "/backup/vaultwarden-${DATE}.tar.gz" /data

# Nur die letzten 30 Tage behalten
find "$BACKUP_DIR" -name "vaultwarden-*.tar.gz" -mtime +30 -delete

echo "Backup abgeschlossen: vaultwarden-${DATE}.tar.gz"
EOF

chmod +x ~/vaultwarden-backup.sh

# Zu Cron hinzufügen (läuft täglich um 2 Uhr morgens)
crontab -e
# Zeile hinzufügen:
0 2 * * * /home/$(whoami)/vaultwarden-backup.sh >> /var/log/vaultwarden-backup.log 2>&1
```

### Fehlerbehebung

**Kann nicht auf Admin-Panel zugreifen / Admin-Token vergessen:**

```bash
# Admin-Token aus Umgebungsdatei abrufen
grep "VAULTWARDEN_ADMIN_TOKEN" .env

# Oder Token neu generieren
NEW_TOKEN=$(openssl rand -base64 32)
echo "Neues Admin-Token: $NEW_TOKEN"

# .env-Datei aktualisieren
sed -i "s/VAULTWARDEN_ADMIN_TOKEN=.*/VAULTWARDEN_ADMIN_TOKEN=$NEW_TOKEN/" .env

# Vaultwarden neu starten
docker compose restart vaultwarden
```

**E-Mail-Verifizierung funktioniert nicht:**

```bash
# Vaultwarden Logs prüfen
docker logs vaultwarden --tail 100 | grep -i "mail\|smtp"

# SMTP-Konfiguration testen
docker exec vaultwarden cat /data/config.json | grep -i smtp

# Für Mailpit (Entwicklung):
# E-Mails gehen zu http://mail.deinedomain.com - dort prüfen

# Für Docker-Mailserver:
# Mailserver-Logs prüfen
docker logs mailserver --tail 100
```

**Browser extension not connecting:**

1. Verify server URL is correct: `https://vault.yourdomain.com`
2. Check for HTTPS errors (certificate issues):
   ```bash
   curl -I https://vault.yourdomain.com
   # Should return: HTTP/2 200
   ```
3. Clear browser extension data:
   - Extension settings → Logout
   - Remove extension and reinstall
   - Reconfigure server URL
4. Check if Vaultwarden is running:
   ```bash
   docker ps | grep vaultwarden
   docker logs vaultwarden --tail 50
   ```

**Master password forgotten (NO RECOVERY POSSIBLE):**

⚠️ **Critical:** There is NO way to recover or reset a forgotten master password!

**Prevention:**
- Write down master password and store in physical safe
- Use a very memorable but strong passphrase
- Enable emergency access with trusted contact
- Regular vault exports as backup

**If Lost:**
- Delete account and create new one
- Re-import credentials from backup/export
- Update all changed passwords manually

**Slow vault sync / Performance issues:**

```bash
# Check container resources
docker stats vaultwarden --no-stream

# Restart Vaultwarden
docker compose restart vaultwarden

# Rebuild vault icon cache (if icons slow)
docker exec vaultwarden rm -rf /data/icon_cache/*
docker compose restart vaultwarden

# Check available disk space
df -h

# Compact SQLite database
docker exec vaultwarden sqlite3 /data/db.sqlite3 "VACUUM;"
```

**Signups disabled but need to add user:**

```bash
# Option 1: Temporarily enable signups in admin panel
# Access: https://vault.yourdomain.com/admin
# Enable signups → Add user → Disable signups

# Option 2: Invite user via admin panel
# Admin panel → Invite User → Enter email → Send invite

# Option 3: Enable via environment variable
echo "SIGNUPS_ALLOWED=true" >> .env
docker compose restart vaultwarden
# After user registers:
echo "SIGNUPS_ALLOWED=false" >> .env  
docker compose restart vaultwarden
```

### Ressourcen

- **Offizielle Dokumentation:** https://github.com/dani-garcia/vaultwarden/wiki
- **Bitwarden Help Center:** https://bitwarden.com/help/
- **API-Dokumentation:** https://bitwarden.com/help/api/
- **Browser Extensions:** https://bitwarden.com/download/
- **Mobile Apps:** Available on App Store and Play Store
- **Desktop Apps:** https://bitwarden.com/download/
- **Community:** https://github.com/dani-garcia/vaultwarden/discussions

### Best Practices

**Password Management:**
- Use Vaultwarden's password generator for all new accounts
- Enable 2FA (TOTP) on all services that support it
- Never reuse passwords across services
- Run security reports monthly
- Use different master passwords for work/personal vaults
- Store recovery codes in secure offline location

**Team Collaboration:**
- Create **Organizations** for team credential sharing
- Use **Collections** to organize shared credentials by project
- Assign appropriate permissions (Can View, Can Bearbeite)
- Regularly audit organization members
- Remove access immediately when team members leave

**Security Hardening:**
- Enable 2FA on your Vaultwarden account
- Disable public signups after initial setup
- Use strong master password (15+ characters, passphrases)
- Enable emergency access with trusted contact
- Regular vault exports (weekly/monthly)
- Keep master password offline in secure location
- Use password manager for password manager backup (ironic but effective)

**API Key Management:**
- Store all API keys in Vaultwarden (OpenAI, Anthropic, etc.)
- Use custom fields for multiple keys per service
- Add expiration date in notes field
- Tag with #api #production #staging
- Document key permissions and scope
- Rotate keys quarterly

**Browser Extension Tips:**
- Enable auto-fill only on HTTPS sites
- Disable auto-fill for financial sites (manual verification)
- Use keyboard shortcuts (Ctrl+Shift+L for auto-fill)
- Review auto-fill matches before submitting
- Clear clipboard after copying passwords (auto-clear setting)

**Resource Usage:**
- **RAM:** 50-200MB typical (vs 2GB+ official Bitwarden)
- **Storage:** ~100MB base + user data (minimal)
- **CPU:** Negligible except during login/sync
- **Network:** Minimal bandwidth usage
- **Perfect for VPS:** Designed for resource-constrained environments

**Überwachung:**
```bash
# Check Vaultwarden status
docker ps | grep vaultwarden

# Monitor resource usage
docker stats vaultwarden

# Check recent logins (in admin panel)
# https://vault.yourdomain.com/admin

# Database size
docker exec vaultwarden du -sh /data/db.sqlite3
```
