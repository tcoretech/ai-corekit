# Vexa Troubleshooting Guide - After Updates

**GERMAN VERSION BELOW**

This guide solves all known issues that can occur after running `update.sh`.

---

## Problem 1: "Vexa directory not found - run setup script first"

### Symptoms:
```
[ERROR] Vexa directory not found - run setup script first
[ERROR] Failed to start services. Check logs for details.
```

### Cause:
The update script detected that Vexa was selected, but the Vexa repository was not cloned or the setup script didn't run through correctly.

### Solution - Step by Step:

**1. Check if Vexa is in COMPOSE_PROFILES:**
```bash
cd ~/ai-launchkit
grep "COMPOSE_PROFILES=" .env
```

**Expected output:**
```
COMPOSE_PROFILES=n8n,vexa,...
```

✅ If `vexa` is in the list, continue  
❌ If `vexa` is missing, it wasn't selected in the wizard

---

**2. Check if Vexa directory exists:**
```bash
ls -la ~/ai-launchkit/vexa
```

**Possible outputs:**
- ❌ `No such file or directory` = Vexa not cloned (problem confirmed)
- ✅ Directory exists with files = Different problem

---

**3. Run setup script manually:**
```bash
cd ~/ai-launchkit
sudo bash scripts/04a_setup_vexa.sh
```

**Expected output:**
```
[INFO] Setting up Vexa...
[INFO] Cloning Vexa repository...
[SUCCESS] Vexa repository cloned successfully
[INFO] Patching Playwright version to match runtime...
[SUCCESS] Playwright version patched successfully
[INFO] Copying environment template...
[SUCCESS] Environment file created
[SUCCESS] Vexa setup complete
```

---

**4. Generate secrets for Vexa:**
```bash
cd ~/ai-launchkit
sudo bash scripts/03_generate_secrets.sh
```

**The script:**
- Generates `VEXA_ADMIN_TOKEN` if missing
- Keeps existing values
- Updates the `.env` file

---

**5. Start Vexa services:**
```bash
cd ~/ai-launchkit
sudo bash scripts/05_run_services.sh
```

**Expected output:**
```
[INFO] Starting services with profiles: n8n,vexa,...
[INFO] Starting Vexa services...
[INFO] Vexa services started successfully
```

---

**6. Initialize Vexa (create user & token):**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Expected output:**
```
[INFO] Initializing Vexa with default user and API token...
[SUCCESS] Admin API is ready
[SUCCESS] User created with ID: 1
[SUCCESS] New API token created and saved
[SUCCESS] Vexa initialization complete
```

---

**7. Verification:**
```bash
# Check containers
sudo docker ps | grep vexa

# Should show:
# vexa_dev-api-gateway-1
# vexa_dev-bot-manager-1
# vexa_dev-admin-api-1
# vexa_dev-transcription-collector-1
# vexa_dev-whisperlive-cpu-1
```

---

**8. Get API token for n8n:**
```bash
sudo grep "VEXA_API_KEY=" .env | head -1
```

**Example:**
```
VEXA_API_KEY="5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN"
```

Use this token in n8n workflows!

---

## Problem 2: "Invalid API token" / "403 Forbidden" in n8n

### Symptoms:
- n8n workflow shows `403 Forbidden` or `Invalid API token`
- API Key exists in `.env` file
- Vexa services are running without errors

### Cause:
The API token exists in the `.env` file but was not inserted into the database. This can happen when:
- The init script didn't run correctly during an update
- The token comes from `03_generate_secrets.sh` but was never passed to the API
- The database was reset but the `.env` was kept

### Solution - Step by Step:

**1. Get admin token from .env:**
```bash
cd ~/ai-launchkit
ADMIN_TOKEN=$(sudo grep "VEXA_ADMIN_TOKEN=" .env | cut -d= -f2 | tr -d '"')
echo "Admin Token: $ADMIN_TOKEN"
```

---

**2. Check if user exists in database:**
```bash
curl -s http://localhost:8057/admin/users \
  -H "X-Admin-API-Key: $ADMIN_TOKEN" | jq .
```

**Expected result:**
```json
[
  {
    "id": 1,
    "email": "your-email@example.com",
    "name": "Admin",
    "max_concurrent_bots": 10,
    ...
  }
]
```

**If empty (`[]`)**: User wasn't created → Run init script  
**If user exists**: Continue with step 3

---

**3. Check if token exists in database:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**Expected result:**
- ❌ `(0 rows)` = Token missing in DB (problem confirmed!)
- ✅ Shows token row = Token exists, different problem

---

**4. Read token from .env:**
```bash
cd ~/ai-launchkit
OLD_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Old token from .env: $OLD_TOKEN"
```

---

**5. Run init script again (generates valid token):**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Expected output with token problem:**
```
[SUCCESS] User created with ID: 1
[INFO] Found token in .env - validating against API...
[WARNING] Token in .env is invalid (HTTP 403/405) - generating new one
[SUCCESS] New API token created and saved
[SUCCESS] Vexa initialization complete
```

---

**6. Read new token:**
```bash
NEW_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "New token: $NEW_TOKEN"
```

---

**7. Confirm token in database:**
```bash
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**Successful output:**
```
                  token                   | user_id |        created_at         
------------------------------------------+---------+---------------------------
 5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN |       1 | 2025-10-13 08:28:21
(1 row)
```

✅ Token is now in the database!

---

**8. Update token in n8n workflows:**

Open **EVERY** n8n workflow that uses Vexa:

**a) HTTP Request Node "Start Vexa Bot"**
```javascript
Headers:
{
  "X-API-Key": "5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN",
  "Content-Type": "application/json"
}
```

**b) HTTP Request Node "Get Transcript"**
```javascript
Headers:
{
  "X-API-Key": "5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN"
}
```

**Important:** Save & activate the workflow!

---

**9. Test workflow:**
```bash
# Test from server:
curl -X POST http://localhost:8056/bots \
  -H "X-API-Key: $NEW_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"test-token"}'
```

**Successful response:**
```json
{
  "id": 1,
  "status": "requested",
  "native_meeting_id": "test-token",
  ...
}
```

**Error responses:**
- `403 Forbidden` → Token is still invalid, repeat steps
- `Connection refused` → Firewall problem (see Problem 3)

---

## Problem 3: "Connection refused" / n8n cannot reach Vexa

### Symptoms:
- n8n shows `The service refused the connection - perhaps it is offline`
- Vexa containers are running (confirmed with `docker ps | grep vexa`)
- API token is correct (confirmed from Problem 2)

### Cause:
Port 8056 is blocked in the firewall (UFW). n8n runs in a Docker container and therefore cannot access Vexa via `localhost` - it needs the server IP or hostname, and the port must be open in the firewall.

### Solution - Step by Step:

**1. Check firewall status:**
```bash
sudo ufw status | grep 8056
```

**Expected result:**
- ❌ No output = Port is blocked (problem confirmed!)
- ✅ Shows `8056/tcp ALLOW` = Port is open

---

**2. Open port 8056 in firewall:**
```bash
sudo ufw allow 8056/tcp comment 'Vexa API Gateway'
sudo ufw reload
```

**Successful output:**
```
Rule added
Rule added (v6)
Firewall reloaded
```

---

**3. Confirm firewall rule:**
```bash
sudo ufw status | grep 8056
```

**Successful output:**
```
8056/tcp                   ALLOW       Anywhere                   # Vexa API Gateway
8056/tcp (v6)              ALLOW       Anywhere (v6)              # Vexa API Gateway
```

---

**4. Get server IP or hostname:**

**Option A: Use server IP (recommended for internal use)**
```bash
hostname -I | awk '{print $1}'
```

**Example output:** `168.119.173.65`

**Option B: Use server hostname (better if IP can change)**
```bash
hostname -f
```

**Example output:** `static.65.173.119.168.clients.your-server.de`

---

**5. Test Vexa API from server:**
```bash
cd ~/ai-launchkit
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
SERVER_IP=$(hostname -I | awk '{print $1}')

# Test API call with server IP
curl -X POST http://$SERVER_IP:8056/bots \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"test-firewall"}'
```

**Successful output:**
```json
{
  "id": 1,
  "status": "requested",
  "native_meeting_id": "test-firewall",
  ...
}
```

**Errors:**
- `Connection refused` → Vexa services not running, back to Problem 1
- `403 Forbidden` → Token problem, back to Problem 2

---

**6. Update n8n workflows with server IP/hostname:**

**IMPORTANT:** n8n CANNOT use `localhost`! Always use server IP or hostname!

**HTTP Request Node "Start Vexa Bot":**
```javascript
// Method: POST
// URL with server IP:
URL: http://168.119.173.65:8056/bots

// OR with hostname:
URL: http://static.65.173.119.168.clients.your-server.de:8056/bots

Headers:
{
  "X-API-Key": "YOUR_API_KEY_HERE",
  "Content-Type": "application/json"
}

Body (JSON):
{
  "platform": "google_meet",
  "native_meeting_id": "{{$json['Google Meet ID']}}"
}
```

**HTTP Request Node "Get Transcript":**
```javascript
// Method: GET
// URL:
URL: http://168.119.173.65:8056/transcripts/google_meet/{{$node["Start Vexa Bot"].json["native_meeting_id"]}}

// OR with hostname:
URL: http://static.65.173.119.168.clients.your-server.de:8056/transcripts/google_meet/{{$node["Start Vexa Bot"].json["native_meeting_id"]}}

Headers:
{
  "X-API-Key": "YOUR_API_KEY_HERE"
}
```

---

**7. Test workflow in n8n:**
- Fill form with test meeting ID
- Workflow should run without "Connection refused"
- Bot should join meeting

---

## Problem 4: Combination of multiple problems

### When multiple problems occur simultaneously:

**Order of resolution:**
1. **First:** Vexa directory not found (Problem 1)
2. **Then:** Open firewall (Problem 3)
3. **Last:** Validate/regenerate token (Problem 2)
4. **Final:** Update n8n workflows with correct URL AND valid token

**Reasoning:** Setup must be complete before tokens can be generated, and the firewall must be open for token validation to work.

---

## Complete End-to-End Test

**After all fixes, this complete test should work:**

```bash
cd ~/ai-launchkit

# 1. Collect all required values
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
SERVER_IP=$(hostname -I | awk '{print $1}')
ADMIN_TOKEN=$(sudo grep "VEXA_ADMIN_TOKEN=" .env | cut -d= -f2 | tr -d '"')

echo "============================================"
echo "Vexa Configuration:"
echo "============================================"
echo "Server IP: $SERVER_IP"
echo "API Key: $API_KEY"
echo "Admin Token: $ADMIN_TOKEN"
echo "============================================"

# 2. Container status
echo ""
echo "Checking Vexa containers..."
sudo docker ps | grep vexa | awk '{print $2}'

# 3. Check user in DB
echo ""
echo "Checking users in database..."
curl -s http://localhost:8057/admin/users \
  -H "X-Admin-API-Key: $ADMIN_TOKEN" | jq -r '.[].email'

# 4. Check token in DB
echo ""
echo "Checking tokens in database..."
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT LEFT(token, 20) || '...' as token, user_id FROM api_tokens;"

# 5. Check firewall
echo ""
echo "Checking firewall..."
sudo ufw status | grep 8056

# 6. API test
echo ""
echo "Testing API with bot creation..."
curl -X POST http://$SERVER_IP:8056/bots \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"final-test-123"}' | jq .

echo ""
echo "============================================"
echo "If you see a bot JSON response above with"
echo "'status': 'requested', everything works!"
echo "============================================"
```

**Successful output at the end:**
```json
{
  "id": 1,
  "user_id": 1,
  "platform": "google_meet",
  "native_meeting_id": "final-test-123",
  "status": "requested",
  ...
}
```

✅ **Everything works!**

---

## Common Errors and Quick Fixes

### "User already exists" when running init script
**Solution:** This is normal and not a problem. The script only creates the user if it doesn't exist.

### "jq: command not found"
**Solution:**
```bash
sudo apt update && sudo apt install -y jq
```

### "Permission denied" when accessing .env
**Solution:**
```bash
# Always use sudo:
sudo grep VEXA .env
```

### API returns empty response `{}`
**Problem:** Admin token or API key is wrong
**Solution:** Regenerate tokens with Problem 2

### Port 8056 doesn't appear in `docker ps`
**Problem:** Vexa uses internal port, not exposed
**Solution:** This is correct! Caddy/firewall forward traffic

---

## Preventive Measures for Future Updates

**1. Backup API token before update:**
```bash
sudo grep "VEXA_API_KEY=" .env | head -1 > ~/vexa_token_backup_$(date +%Y%m%d).txt
```

**2. Compare token after each update:**
```bash
# Show backup
cat ~/vexa_token_backup_*.txt | tail -1

# Show current token
sudo grep "VEXA_API_KEY=" .env | head -1

# Should be identical!
```

**3. Firewall rules persist:**
- Port 8056 will NOT be closed during updates
- If problems occur: Add rule again (see Problem 3)

**4. Create quick-check script:**
```bash
cat > ~/check_vexa.sh << 'EOF'
#!/bin/bash
echo "Checking Vexa status..."
cd ~/ai-launchkit

# Container status
echo "1. Containers:"
sudo docker ps | grep vexa | wc -l
echo "   (Should be 5)"

# Firewall
echo "2. Firewall:"
sudo ufw status | grep 8056

# Token in DB
echo "3. Tokens in DB:"
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;" | grep -A 1 count

echo "Done!"
EOF

chmod +x ~/check_vexa.sh

# Run it:
~/check_vexa.sh
```

---

## If Nothing Helps - Complete Reset

**As absolute last resort (DELETES ALL TRANSCRIPTS!):**

```bash
cd ~/ai-launchkit

# 1. Backup .env
sudo cp .env .env.backup

# 2. Stop Vexa completely
cd vexa
sudo docker compose down

# 3. Delete volumes (WARNING: Deletes all data!)
sudo docker volume rm vexa_dev_postgres_data vexa_dev_redis_data 2>/dev/null || true

# 4. Delete Vexa directory
cd ~/ai-launchkit
sudo rm -rf vexa

# 5. Complete fresh setup
sudo bash scripts/04a_setup_vexa.sh
sudo bash scripts/03_generate_secrets.sh
sudo bash scripts/05_run_services.sh
sudo bash scripts/05a_init_vexa.sh

# 6. Get new token for n8n
sudo grep "VEXA_API_KEY=" .env | head -1

# 7. Ensure firewall is open
sudo ufw allow 8056/tcp comment 'Vexa API Gateway'
sudo ufw reload
```

**Afterwards:** Update all n8n workflows with new token!

---

## Support & Help

**For further problems:**

**1. Open GitHub issue:**
https://github.com/freddy-schuetz/ai-launchkit/issues

**2. Collect and attach logs:**
```bash
cd ~/ai-launchkit/vexa

# All relevant logs
sudo docker compose logs bot-manager --tail 50 > ~/vexa_bot_manager.log
sudo docker compose logs api-gateway --tail 50 > ~/vexa_api_gateway.log
sudo docker compose logs admin-api --tail 50 > ~/vexa_admin_api.log

# System info
echo "=== System Info ===" > ~/vexa_system_info.txt
echo "OS: $(lsb_release -d)" >> ~/vexa_system_info.txt
echo "Docker: $(docker --version)" >> ~/vexa_system_info.txt
echo "Firewall:" >> ~/vexa_system_info.txt
sudo ufw status | grep 8056 >> ~/vexa_system_info.txt

# Upload to issue
```

**3. Quick diagnostic command:**
```bash
cd ~/ai-launchkit/vexa
sudo docker compose ps
sudo docker compose logs --tail 20
```

---

## Summary - Quick Checklist

- [ ] Problem 1: Vexa directory exists? → `ls -la ~/ai-launchkit/vexa`
- [ ] Setup executed? → `sudo bash scripts/04a_setup_vexa.sh`
- [ ] Services running? → `sudo docker ps | grep vexa` (5 containers)
- [ ] Problem 2: Token in DB? → `sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa -c "SELECT COUNT(*) FROM api_tokens;"`
- [ ] Init script executed? → `sudo bash scripts/05a_init_vexa.sh`
- [ ] Problem 3: Firewall open? → `sudo ufw status | grep 8056`
- [ ] Port allowed? → `sudo ufw allow 8056/tcp`
- [ ] n8n URLs updated? → Server IP instead of localhost
- [ ] n8n token updated? → New token from `.env`
- [ ] End-to-end test successful? → See "Complete End-to-End Test"

**If all points are ✅: Vexa is ready to use!** 🎉

# GERMAN VERSION

# Vexa Troubleshooting Guide - Nach Updates

Dieser Guide löst alle bekannten Probleme, die nach einem `update.sh` auftreten können.

---

## Problem 1: "Vexa directory not found - run setup script first"

### Symptome:
```
[ERROR] Vexa directory not found - run setup script first
[ERROR] Failed to start services. Check logs for details.
```

### Ursache:
Das Update-Script hat erkannt, dass Vexa ausgewählt wurde, aber das Vexa-Repository wurde noch nicht geklont oder das Setup-Script lief nicht durch.

### Lösung - Schritt für Schritt:

**1. Vexa in COMPOSE_PROFILES prüfen:**
```bash
cd ~/ai-launchkit
grep "COMPOSE_PROFILES=" .env
```

**Erwartete Ausgabe:**
```
COMPOSE_PROFILES=n8n,vexa,...
```

✅ Wenn `vexa` in der Liste ist, fortfahren  
❌ Wenn `vexa` fehlt, wurde es nicht im Wizard ausgewählt

---

**2. Vexa-Verzeichnis prüfen:**
```bash
ls -la ~/ai-launchkit/vexa
```

**Mögliche Ausgaben:**
- ❌ `No such file or directory` = Vexa nicht geklont (Problem bestätigt)
- ✅ Verzeichnis existiert mit Dateien = Anderes Problem

---

**3. Setup-Script manuell ausführen:**
```bash
cd ~/ai-launchkit
sudo bash scripts/04a_setup_vexa.sh
```

**Erwartete Ausgabe:**
```
[INFO] Setting up Vexa...
[INFO] Cloning Vexa repository...
[SUCCESS] Vexa repository cloned successfully
[INFO] Patching Playwright version to match runtime...
[SUCCESS] Playwright version patched successfully
[INFO] Copying environment template...
[SUCCESS] Environment file created
[SUCCESS] Vexa setup complete
```

---

**4. Secrets für Vexa generieren:**
```bash
cd ~/ai-launchkit
sudo bash scripts/03_generate_secrets.sh
```

**Das Script:**
- Generiert `VEXA_ADMIN_TOKEN` falls fehlend
- Behält existierende Werte bei
- Updated die `.env` Datei

---

**5. Vexa Services starten:**
```bash
cd ~/ai-launchkit
sudo bash scripts/05_run_services.sh
```

**Erwartete Ausgabe:**
```
[INFO] Starting services with profiles: n8n,vexa,...
[INFO] Starting Vexa services...
[INFO] Vexa services started successfully
```

---

**6. Vexa initialisieren (User & Token erstellen):**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Erwartete Ausgabe:**
```
[INFO] Initializing Vexa with default user and API token...
[SUCCESS] Admin API is ready
[SUCCESS] User created with ID: 1
[SUCCESS] New API token created and saved
[SUCCESS] Vexa initialization complete
```

---

**7. Verifizierung:**
```bash
# Container prüfen
sudo docker ps | grep vexa

# Sollte zeigen:
# vexa_dev-api-gateway-1
# vexa_dev-bot-manager-1
# vexa_dev-admin-api-1
# vexa_dev-transcription-collector-1
# vexa_dev-whisperlive-cpu-1
```

---

**8. API Token abrufen für n8n:**
```bash
sudo grep "VEXA_API_KEY=" .env | head -1
```

**Beispiel:**
```
VEXA_API_KEY="5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN"
```

Diesen Token in n8n Workflows verwenden!

---

## Problem 2: "Invalid API token" / "403 Forbidden" in n8n

### Symptome:
- n8n Workflow zeigt `403 Forbidden` oder `Invalid API token`
- API Key ist in `.env` vorhanden
- Vexa Services laufen ohne Fehler

### Ursache:
Der API Token existiert in der `.env` Datei, wurde aber nicht in die Datenbank eingetragen. Dies kann passieren, wenn:
- Das Init-Script während eines Updates nicht korrekt durchlief
- Der Token aus `03_generate_secrets.sh` stammt, aber nie an die API übergeben wurde
- Die Datenbank zurückgesetzt wurde, aber die `.env` beibehalten wurde

### Lösung - Schritt für Schritt:

**1. Admin Token aus .env holen:**
```bash
cd ~/ai-launchkit
ADMIN_TOKEN=$(sudo grep "VEXA_ADMIN_TOKEN=" .env | cut -d= -f2 | tr -d '"')
echo "Admin Token: $ADMIN_TOKEN"
```

---

**2. Prüfen ob User in Datenbank existiert:**
```bash
curl -s http://localhost:8057/admin/users \
  -H "X-Admin-API-Key: $ADMIN_TOKEN" | jq .
```

**Erwartetes Ergebnis:**
```json
[
  {
    "id": 1,
    "email": "ihre-email@example.com",
    "name": "Admin",
    "max_concurrent_bots": 10,
    ...
  }
]
```

**Wenn leer (`[]`)**: User wurde nicht erstellt → Init-Script laufen lassen  
**Wenn User vorhanden**: Mit Schritt 3 fortfahren

---

**3. Prüfen ob Token in Datenbank existiert:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**Erwartetes Ergebnis:**
- ❌ `(0 rows)` = Token fehlt in DB (Problem bestätigt!)
- ✅ Zeigt Token-Zeile = Token existiert, anderes Problem

---

**4. Token aus .env auslesen:**
```bash
cd ~/ai-launchkit
OLD_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Alter Token aus .env: $OLD_TOKEN"
```

---

**5. Init-Script nochmal ausführen (generiert validen Token):**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Erwartete Ausgabe bei Token-Problem:**
```
[SUCCESS] User created with ID: 1
[INFO] Found token in .env - validating against API...
[WARNING] Token in .env is invalid (HTTP 403/405) - generating new one
[SUCCESS] New API token created and saved
[SUCCESS] Vexa initialization complete
```

---

**6. Neuen Token auslesen:**
```bash
NEW_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Neuer Token: $NEW_TOKEN"
```

---

**7. Token in Datenbank bestätigen:**
```bash
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**Erfolgreiche Ausgabe:**
```
                  token                   | user_id |        created_at         
------------------------------------------+---------+---------------------------
 5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN |       1 | 2025-10-13 08:28:21
(1 row)
```

✅ Token ist jetzt in der Datenbank!

---

**8. Token in n8n Workflows aktualisieren:**

Öffnen Sie **JEDEN** n8n Workflow, der Vexa nutzt:

**a) HTTP Request Node "Start Vexa Bot"**
```javascript
Headers:
{
  "X-API-Key": "5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN",
  "Content-Type": "application/json"
}
```

**b) HTTP Request Node "Get Transcript"**
```javascript
Headers:
{
  "X-API-Key": "5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN"
}
```

**Wichtig:** Workflow speichern & aktivieren!

---

**9. Workflow testen:**
```bash
# Test von Server aus:
curl -X POST http://localhost:8056/bots \
  -H "X-API-Key: $NEW_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"test-token"}'
```

**Erfolgreiche Antwort:**
```json
{
  "id": 1,
  "status": "requested",
  "native_meeting_id": "test-token",
  ...
}
```

**Fehler-Antworten:**
- `403 Forbidden` → Token ist immer noch ungültig, Schritte wiederholen
- `Connection refused` → Firewall-Problem (siehe Problem 3)

---

## Problem 3: "Connection refused" / n8n kann Vexa nicht erreichen

### Symptome:
- n8n zeigt `The service refused the connection - perhaps it is offline`
- Vexa Container laufen (mit `docker ps | grep vexa` bestätigt)
- API Token ist korrekt (aus Problem 2 bestätigt)

### Ursache:
Port 8056 ist in der Firewall (UFW) blockiert. n8n läuft in einem Docker Container und kann daher nicht über `localhost` auf Vexa zugreifen - es braucht die Server-IP oder den Hostname, und der Port muss in der Firewall offen sein.

### Lösung - Schritt für Schritt:

**1. Firewall Status prüfen:**
```bash
sudo ufw status | grep 8056
```

**Erwartetes Ergebnis:**
- ❌ Keine Ausgabe = Port ist blockiert (Problem bestätigt!)
- ✅ Zeigt `8056/tcp ALLOW` = Port ist offen

---

**2. Port 8056 in Firewall öffnen:**
```bash
sudo ufw allow 8056/tcp comment 'Vexa API Gateway'
sudo ufw reload
```

**Erfolgreiche Ausgabe:**
```
Rule added
Rule added (v6)
Firewall reloaded
```

---

**3. Firewall Regel bestätigen:**
```bash
sudo ufw status | grep 8056
```

**Erfolgreiche Ausgabe:**
```
8056/tcp                   ALLOW       Anywhere                   # Vexa API Gateway
8056/tcp (v6)              ALLOW       Anywhere (v6)              # Vexa API Gateway
```

---

**4. Server-IP oder Hostname ermitteln:**

**Option A: Server-IP nutzen (empfohlen für interne Nutzung)**
```bash
hostname -I | awk '{print $1}'
```

**Beispiel-Ausgabe:** `168.119.173.65`

**Option B: Server-Hostname nutzen (besser wenn IP sich ändern kann)**
```bash
hostname -f
```

**Beispiel-Ausgabe:** `static.65.173.119.168.clients.your-server.de`

---

**5. Vexa API von Server aus testen:**
```bash
cd ~/ai-launchkit
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
SERVER_IP=$(hostname -I | awk '{print $1}')

# Test API Call mit Server-IP
curl -X POST http://$SERVER_IP:8056/bots \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"test-firewall"}'
```

**Erfolgreiche Ausgabe:**
```json
{
  "id": 1,
  "status": "requested",
  "native_meeting_id": "test-firewall",
  ...
}
```

**Fehler:**
- `Connection refused` → Vexa Services laufen nicht, zurück zu Problem 1
- `403 Forbidden` → Token-Problem, zurück zu Problem 2

---

**6. n8n Workflows mit Server-IP/Hostname aktualisieren:**

**WICHTIG:** n8n kann NICHT `localhost` verwenden! Immer Server-IP oder Hostname nutzen!

**HTTP Request Node "Start Vexa Bot":**
```javascript
// Method: POST
// URL mit Server-IP:
URL: http://168.119.173.65:8056/bots

// ODER mit Hostname:
URL: http://static.65.173.119.168.clients.your-server.de:8056/bots

Headers:
{
  "X-API-Key": "IHR_API_KEY_HIER",
  "Content-Type": "application/json"
}

Body (JSON):
{
  "platform": "google_meet",
  "native_meeting_id": "{{$json['Google Meet ID']}}"
}
```

**HTTP Request Node "Get Transcript":**
```javascript
// Method: GET
// URL:
URL: http://168.119.173.65:8056/transcripts/google_meet/{{$node["Start Vexa Bot"].json["native_meeting_id"]}}

// ODER mit Hostname:
URL: http://static.65.173.119.168.clients.your-server.de:8056/transcripts/google_meet/{{$node["Start Vexa Bot"].json["native_meeting_id"]}}

Headers:
{
  "X-API-Key": "IHR_API_KEY_HIER"
}
```

---

**7. Workflow in n8n testen:**
- Formular mit Test-Meeting-ID ausfüllen
- Workflow sollte ohne "Connection refused" durchlaufen
- Bot sollte in Meeting joinen

---

## Problem 4: Kombination mehrerer Probleme

### Wenn mehrere Probleme gleichzeitig auftreten:

**Reihenfolge der Behebung:**
1. **Zuerst:** Vexa directory not found (Problem 1)
2. **Dann:** Firewall öffnen (Problem 3)
3. **Zuletzt:** Token validieren/neu generieren (Problem 2)
4. **Final:** n8n Workflows mit korrekter URL UND gültigem Token aktualisieren

**Begründung:** Setup muss vollständig sein bevor Tokens generiert werden können, und die Firewall muss offen sein damit die Token-Validierung funktioniert.

---

## Vollständiger End-to-End Test

**Nach allen Fixes sollte dieser komplette Test funktionieren:**

```bash
cd ~/ai-launchkit

# 1. Alle benötigten Werte sammeln
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
SERVER_IP=$(hostname -I | awk '{print $1}')
ADMIN_TOKEN=$(sudo grep "VEXA_ADMIN_TOKEN=" .env | cut -d= -f2 | tr -d '"')

echo "============================================"
echo "Vexa Configuration:"
echo "============================================"
echo "Server IP: $SERVER_IP"
echo "API Key: $API_KEY"
echo "Admin Token: $ADMIN_TOKEN"
echo "============================================"

# 2. Container Status
echo ""
echo "Checking Vexa containers..."
sudo docker ps | grep vexa | awk '{print $2}'

# 3. User in DB prüfen
echo ""
echo "Checking users in database..."
curl -s http://localhost:8057/admin/users \
  -H "X-Admin-API-Key: $ADMIN_TOKEN" | jq -r '.[].email'

# 4. Token in DB prüfen
echo ""
echo "Checking tokens in database..."
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT LEFT(token, 20) || '...' as token, user_id FROM api_tokens;"

# 5. Firewall prüfen
echo ""
echo "Checking firewall..."
sudo ufw status | grep 8056

# 6. API Test
echo ""
echo "Testing API with bot creation..."
curl -X POST http://$SERVER_IP:8056/bots \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"final-test-123"}' | jq .

echo ""
echo "============================================"
echo "If you see a bot JSON response above with"
echo "'status': 'requested', everything works!"
echo "============================================"
```

**Erfolgreiche Ausgabe am Ende:**
```json
{
  "id": 1,
  "user_id": 1,
  "platform": "google_meet",
  "native_meeting_id": "final-test-123",
  "status": "requested",
  ...
}
```

✅ **Alles funktioniert!**

---

## Häufige Fehler und schnelle Fixes

### "User already exists" beim Init-Script
**Lösung:** Das ist normal und kein Problem. Das Script erstellt den User nur wenn er nicht existiert.

### "jq: command not found"
**Lösung:**
```bash
sudo apt update && sudo apt install -y jq
```

### "Permission denied" beim Zugriff auf .env
**Lösung:**
```bash
# Immer sudo verwenden:
sudo grep VEXA .env
```

### API gibt leere Antwort `{}`
**Problem:** Admin Token oder API Key ist falsch
**Lösung:** Tokens neu generieren mit Problem 2

### Port 8056 erscheint nicht in `docker ps`
**Problem:** Vexa nutzt internen Port, wird nicht exposed
**Lösung:** Das ist korrekt so! Caddy/Firewall leiten Traffic weiter

---

## Vorbeugende Maßnahmen für zukünftige Updates

**1. API Token vor Update sichern:**
```bash
sudo grep "VEXA_API_KEY=" .env | head -1 > ~/vexa_token_backup_$(date +%Y%m%d).txt
```

**2. Nach jedem Update Token vergleichen:**
```bash
# Backup anzeigen
cat ~/vexa_token_backup_*.txt | tail -1

# Aktuellen Token anzeigen
sudo grep "VEXA_API_KEY=" .env | head -1

# Sollten identisch sein!
```

**3. Firewall-Regeln bleiben erhalten:**
- Port 8056 wird bei Updates NICHT geschlossen
- Bei Problemen: Regel erneut hinzufügen (siehe Problem 3)

**4. Quick-Check Script erstellen:**
```bash
cat > ~/check_vexa.sh << 'EOF'
#!/bin/bash
echo "Checking Vexa status..."
cd ~/ai-launchkit

# Container Status
echo "1. Containers:"
sudo docker ps | grep vexa | wc -l
echo "   (Should be 5)"

# Firewall
echo "2. Firewall:"
sudo ufw status | grep 8056

# Token in DB
echo "3. Tokens in DB:"
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;" | grep -A 1 count

echo "Done!"
EOF

chmod +x ~/check_vexa.sh

# Ausführen:
~/check_vexa.sh
```

---

## Wenn nichts hilft - Kompletter Neustart

**Als absolut letzter Ausweg (LÖSCHT ALLE TRANSKRIPTE!):**

```bash
cd ~/ai-launchkit

# 1. Backup von .env erstellen
sudo cp .env .env.backup

# 2. Vexa komplett stoppen
cd vexa
sudo docker compose down

# 3. Volumes löschen (ACHTUNG: Löscht alle Daten!)
sudo docker volume rm vexa_dev_postgres_data vexa_dev_redis_data 2>/dev/null || true

# 4. Vexa-Verzeichnis löschen
cd ~/ai-launchkit
sudo rm -rf vexa

# 5. Komplett neu aufsetzen
sudo bash scripts/04a_setup_vexa.sh
sudo bash scripts/03_generate_secrets.sh
sudo bash scripts/05_run_services.sh
sudo bash scripts/05a_init_vexa.sh

# 6. Neuen Token für n8n abrufen
sudo grep "VEXA_API_KEY=" .env | head -1

# 7. Firewall sicherstellen
sudo ufw allow 8056/tcp comment 'Vexa API Gateway'
sudo ufw reload
```

**Danach:** Alle n8n Workflows mit neuem Token aktualisieren!

---

## Support & Hilfe

**Bei weiteren Problemen:**

**1. GitHub Issue öffnen:**
https://github.com/freddy-schuetz/ai-launchkit/issues

**2. Logs sammeln und mitschicken:**
```bash
cd ~/ai-launchkit/vexa

# Alle relevanten Logs
sudo docker compose logs bot-manager --tail 50 > ~/vexa_bot_manager.log
sudo docker compose logs api-gateway --tail 50 > ~/vexa_api_gateway.log
sudo docker compose logs admin-api --tail 50 > ~/vexa_admin_api.log

# System Info
echo "=== System Info ===" > ~/vexa_system_info.txt
echo "OS: $(lsb_release -d)" >> ~/vexa_system_info.txt
echo "Docker: $(docker --version)" >> ~/vexa_system_info.txt
echo "Firewall:" >> ~/vexa_system_info.txt
sudo ufw status | grep 8056 >> ~/vexa_system_info.txt

# In Issue hochladen
```

**3. Quick Diagnostic Command:**
```bash
cd ~/ai-launchkit/vexa
sudo docker compose ps
sudo docker compose logs --tail 20
```

---

## Zusammenfassung - Schnell-Checkliste

- [ ] Problem 1: Vexa Verzeichnis existiert? → `ls -la ~/ai-launchkit/vexa`
- [ ] Setup ausgeführt? → `sudo bash scripts/04a_setup_vexa.sh`
- [ ] Services laufen? → `sudo docker ps | grep vexa` (5 Container)
- [ ] Problem 2: Token in DB? → `sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa -c "SELECT COUNT(*) FROM api_tokens;"`
- [ ] Init-Script ausgeführt? → `sudo bash scripts/05a_init_vexa.sh`
- [ ] Problem 3: Firewall offen? → `sudo ufw status | grep 8056`
- [ ] Port freigeben? → `sudo ufw allow 8056/tcp`
- [ ] n8n URLs aktualisiert? → Server-IP statt localhost
- [ ] n8n Token aktualisiert? → Neuen Token aus `.env`
- [ ] End-to-End Test erfolgreich? → Siehe "Vollständiger End-to-End Test"

**Wenn alle Punkte ✅ sind: Vexa ist einsatzbereit!** 🎉
