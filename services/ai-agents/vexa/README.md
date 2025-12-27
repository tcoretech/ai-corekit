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
- The token validation incorrectly marked an invalid token as valid

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
- ❌ `(0 rows)` = Token missing in DB (problem confirmed! Continue with step 4)
- ✅ Shows token row = Token exists, skip to step 9 for n8n update

---

**4. Check what token is in .env:**
```bash
cd ~/ai-launchkit
OLD_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Current token in .env: $OLD_TOKEN"
```

---

**5. FORCE regeneration by clearing the token in .env:**

This is the critical step! If the init script incorrectly thinks the token is valid, we need to clear it first.

```bash
cd ~/ai-launchkit

# Clear the token value (keep the key name)
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env

# Verify it's cleared
sudo grep "VEXA_API_KEY=" .env | head -1
# Should show: VEXA_API_KEY=""
```

---

**6. Run init script to generate NEW token:**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Expected output:**
```
[INFO] Initializing Vexa with default user and API token...
[SUCCESS] Admin API is ready
[SUCCESS] User created with ID: 1
[INFO] No valid token in .env - generating new API token for user...
[SUCCESS] API token created and saved
[SUCCESS] Vexa initialization complete
```

**Key message:** Should say "**generating new API token**" NOT "keeping it"!

---

**7. Get the NEW token:**
```bash
cd ~/ai-launchkit
NEW_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "New token: $NEW_TOKEN"
```

---

**8. Verify token is NOW in database:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**MUST show:**
```
                  token                   | user_id |        created_at         
------------------------------------------+---------+---------------------------
 5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN |       1 | 2025-10-13 18:14:18
(1 row)
```

✅ Token is now in the database!

**If still `(0 rows)`:** Something is seriously wrong - proceed to "Complete Reset" section at the end.

---

**9. Update token in ALL n8n workflows:**

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

**10. Test the workflow:**
```bash
# Test from server:
cd ~/ai-launchkit
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')

curl -X POST http://localhost:8056/bots \
  -H "X-API-Key: $API_KEY" \
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
- `403 Forbidden` → Token STILL invalid - repeat steps 5-8 OR proceed to "Complete Reset"
- `Connection refused` → Firewall problem (see Problem 3)

---

### Problem 2B: Init script says "keeping token" but token is not in DB

**Special case symptoms:**
```
[INFO] Existing API token found - keeping it to maintain workflow compatibility
[SUCCESS] Vexa initialization complete
```

BUT when checking database:
```bash
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;"
# Shows: 0
```

**This means:** The validation check incorrectly passed but the token was never inserted into the database.

**Solution:**

**FORCE regeneration by clearing token first (same as step 5 above):**

```bash
cd ~/ai-launchkit

# 1. Clear token in .env
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env

# 2. Run init script again
sudo bash scripts/05a_init_vexa.sh

# 3. Verify token is in DB
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id FROM api_tokens;"

# 4. Should now show 1 row!
```

**Why this works:** By clearing the token value, the init script's validation check will fail (no token to validate), forcing it to generate a fresh token and insert it into the database.

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
3. **Then:** Force token regeneration by clearing .env (Problem 2/2B)
4. **Final:** Update n8n workflows with correct URL AND valid token

**Reasoning:** Setup must be complete before tokens can be generated, and the firewall must be open for testing to work properly.

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

### API gives empty response `{}`
**Problem:** Admin token or API key is wrong
**Solution:** Force regenerate tokens with Problem 2, step 5

### Port 8056 doesn't appear in `docker ps`
**Problem:** Vexa uses internal port, not exposed
**Solution:** This is correct! Caddy/firewall forward traffic

### Init script says "keeping token" but 403 errors in n8n
**Problem:** This is Problem 2B - token validation incorrectly passed
**Solution:** Clear token in .env first:
```bash
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env
sudo bash scripts/05a_init_vexa.sh
```

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

**3. Verify token is in database after updates:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;"
# Should show: 1 (not 0!)
```

**4. Firewall rules persist:**
- Port 8056 will NOT be closed during updates
- If problems occur: Add rule again (see Problem 3)

**5. Create quick-check script:**
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

# 6. Verify token is in DB
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id FROM api_tokens;"
# MUST show 1 row!

# 7. Get new token for n8n
cd ~/ai-launchkit
sudo grep "VEXA_API_KEY=" .env | head -1

# 8. Ensure firewall is open
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

# Token status
echo "Token in .env:" >> ~/vexa_system_info.txt
sudo grep "VEXA_API_KEY=" .env | head -1 >> ~/vexa_system_info.txt
echo "Tokens in DB:" >> ~/vexa_system_info.txt
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;" >> ~/vexa_system_info.txt 2>&1

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
- [ ] If token NOT in DB: Clear .env token → `sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env`
- [ ] Init script executed? → `sudo bash scripts/05a_init_vexa.sh`
- [ ] Verify token NOW in DB → Should show 1 row, not 0!
- [ ] Problem 3: Firewall open? → `sudo ufw status | grep 8056`
- [ ] Port allowed? → `sudo ufw allow 8056/tcp`
- [ ] n8n URLs updated? → Server IP instead of localhost
- [ ] n8n token updated? → New token from `.env`
- [ ] End-to-end test successful? → See "Complete End-to-End Test"

**If all points are ✅: Vexa is ready to use!** 🎉

---

# Vexa Fehlerbehebungs-Guide - Nach Updates

Dieser Guide löst alle bekannten Probleme, die nach einem `update.sh` auftreten können.

---

## Problem 1: "Vexa directory not found - run setup script first"

### Symptome:
```
[ERROR] Vexa directory not found - run setup script first
[ERROR] Failed to start services. Check logs for details.
```

### Ursache:
Das Update-Script hat erkannt, dass Vexa ausgewählt wurde, aber das Vexa-Repository wurde noch nicht geklont oder das Setup-Script lief nicht korrekt durch.

### Lösung - Schritt für Schritt:

**1. Prüfen ob Vexa in COMPOSE_PROFILES ist:**
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

**2. Prüfen ob Vexa-Verzeichnis existiert:**
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
- Aktualisiert die `.env` Datei

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

**8. API Token für n8n abrufen:**
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
- API Key ist in `.env` Datei vorhanden
- Vexa Services laufen ohne Fehler

### Ursache:
Der API Token existiert in der `.env` Datei, wurde aber nicht in die Datenbank eingetragen. Dies kann passieren, wenn:
- Das Init-Script während eines Updates nicht korrekt durchlief
- Der Token aus `03_generate_secrets.sh` stammt, aber nie an die API übergeben wurde
- Die Datenbank zurückgesetzt wurde, aber die `.env` beibehalten wurde
- Die Token-Validierung fälschlicherweise einen ungültigen Token als gültig markierte

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
- ❌ `(0 rows)` = Token fehlt in DB (Problem bestätigt! Mit Schritt 4 fortfahren)
- ✅ Zeigt Token-Zeile = Token existiert, zu Schritt 9 für n8n Update springen

---

**4. Prüfen welcher Token in .env ist:**
```bash
cd ~/ai-launchkit
OLD_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Aktueller Token in .env: $OLD_TOKEN"
```

---

**5. Regenerierung ERZWINGEN durch Löschen des Tokens in .env:**

Dies ist der kritische Schritt! Wenn das Init-Script fälschlicherweise denkt, der Token sei gültig, müssen wir ihn zuerst löschen.

```bash
cd ~/ai-launchkit

# Token-Wert löschen (Key-Name behalten)
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env

# Verifizieren dass er gelöscht ist
sudo grep "VEXA_API_KEY=" .env | head -1
# Sollte zeigen: VEXA_API_KEY=""
```

---

**6. Init-Script ausführen um NEUEN Token zu generieren:**
```bash
cd ~/ai-launchkit
sudo bash scripts/05a_init_vexa.sh
```

**Erwartete Ausgabe:**
```
[INFO] Initializing Vexa with default user and API token...
[SUCCESS] Admin API is ready
[SUCCESS] User created with ID: 1
[INFO] No valid token in .env - generating new API token for user...
[SUCCESS] API token created and saved
[SUCCESS] Vexa initialization complete
```

**Wichtige Meldung:** Sollte "**generating new API token**" sagen, NICHT "keeping it"!

---

**7. Den NEUEN Token abrufen:**
```bash
cd ~/ai-launchkit
NEW_TOKEN=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')
echo "Neuer Token: $NEW_TOKEN"
```

---

**8. Verifizieren dass Token JETZT in Datenbank ist:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id, created_at FROM api_tokens;"
```

**MUSS zeigen:**
```
                  token                   | user_id |        created_at         
------------------------------------------+---------+---------------------------
 5StNZ1MCYkSwoihUD0oDVElaitwJmEBN16QK01CN |       1 | 2025-10-13 18:14:18
(1 row)
```

✅ Token ist jetzt in der Datenbank!

**Wenn immer noch `(0 rows)`:** Etwas ist ernsthaft falsch - zum Abschnitt "Kompletter Neustart" am Ende gehen.

---

**9. Token in ALLEN n8n Workflows aktualisieren:**

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

**10. Workflow testen:**
```bash
# Test vom Server aus:
cd ~/ai-launchkit
API_KEY=$(sudo grep "VEXA_API_KEY=" .env | head -1 | cut -d= -f2 | tr -d '"')

curl -X POST http://localhost:8056/bots \
  -H "X-API-Key: $API_KEY" \
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
- `403 Forbidden` → Token IMMER NOCH ungültig - Schritte 5-8 wiederholen ODER zu "Kompletter Neustart"
- `Connection refused` → Firewall-Problem (siehe Problem 3)

---

### Problem 2B: Init-Script sagt "keeping token" aber Token ist nicht in DB

**Spezialfall Symptome:**
```
[INFO] Existing API token found - keeping it to maintain workflow compatibility
[SUCCESS] Vexa initialization complete
```

ABER beim Prüfen der Datenbank:
```bash
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;"
# Zeigt: 0
```

**Das bedeutet:** Die Validierungsprüfung ist fälschlicherweise durchgelaufen, aber der Token wurde nie in die Datenbank eingefügt.

**Lösung:**

**Regenerierung ERZWINGEN durch vorheriges Löschen des Tokens (gleich wie Schritt 5 oben):**

```bash
cd ~/ai-launchkit

# 1. Token in .env löschen
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env

# 2. Init-Script nochmal ausführen
sudo bash scripts/05a_init_vexa.sh

# 3. Verifizieren dass Token in DB ist
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id FROM api_tokens;"

# 4. Sollte jetzt 1 Zeile zeigen!
```

**Warum das funktioniert:** Durch Löschen des Token-Wertes wird die Validierungsprüfung des Init-Scripts fehlschlagen (kein Token zum Validieren), wodurch es gezwungen wird, einen frischen Token zu generieren und in die Datenbank einzufügen.

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

**5. Vexa API vom Server aus testen:**
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
3. **Dann:** Token-Regenerierung erzwingen durch Löschen in .env (Problem 2/2B)
4. **Final:** n8n Workflows mit korrekter URL UND gültigem Token aktualisieren

**Begründung:** Setup muss vollständig sein bevor Tokens generiert werden können, und die Firewall muss offen sein damit Tests funktionieren.

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
echo "Vexa Konfiguration:"
echo "============================================"
echo "Server IP: $SERVER_IP"
echo "API Key: $API_KEY"
echo "Admin Token: $ADMIN_TOKEN"
echo "============================================"

# 2. Container Status
echo ""
echo "Prüfe Vexa Container..."
sudo docker ps | grep vexa | awk '{print $2}'

# 3. User in DB prüfen
echo ""
echo "Prüfe User in Datenbank..."
curl -s http://localhost:8057/admin/users \
  -H "X-Admin-API-Key: $ADMIN_TOKEN" | jq -r '.[].email'

# 4. Token in DB prüfen
echo ""
echo "Prüfe Tokens in Datenbank..."
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT LEFT(token, 20) || '...' as token, user_id FROM api_tokens;"

# 5. Firewall prüfen
echo ""
echo "Prüfe Firewall..."
sudo ufw status | grep 8056

# 6. API Test
echo ""
echo "Teste API mit Bot-Erstellung..."
curl -X POST http://$SERVER_IP:8056/bots \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"google_meet","native_meeting_id":"final-test-123"}' | jq .

echo ""
echo "============================================"
echo "Wenn Sie oben eine Bot JSON-Antwort mit"
echo "'status': 'requested' sehen, funktioniert alles!"
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
**Lösung:** Tokens neu generieren mit Problem 2, Schritt 5

### Port 8056 erscheint nicht in `docker ps`
**Problem:** Vexa nutzt internen Port, wird nicht exposed
**Lösung:** Das ist korrekt so! Caddy/Firewall leiten Traffic weiter

### Init-Script sagt "keeping token" aber 403 Fehler in n8n
**Problem:** Das ist Problem 2B - Token-Validierung ist fälschlicherweise durchgelaufen
**Lösung:** Token in .env zuerst löschen:
```bash
sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env
sudo bash scripts/05a_init_vexa.sh
```

---

## Vorbeugende Maßnahmen für zukünftige Updates

**1. API Token vor Update sichern:**
```bash
sudo grep "VEXA_API_KEY=" .env | head -1 > ~/vexa_token_backup_$(date +%Y%m%d).txt
```

**2. Token nach jedem Update vergleichen:**
```bash
# Backup anzeigen
cat ~/vexa_token_backup_*.txt | tail -1

# Aktuellen Token anzeigen
sudo grep "VEXA_API_KEY=" .env | head -1

# Sollten identisch sein!
```

**3. Verifizieren dass Token nach Updates in Datenbank ist:**
```bash
cd ~/ai-launchkit/vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;"
# Sollte zeigen: 1 (nicht 0!)
```

**4. Firewall-Regeln bleiben erhalten:**
- Port 8056 wird bei Updates NICHT geschlossen
- Bei Problemen: Regel erneut hinzufügen (siehe Problem 3)

**5. Quick-Check Script erstellen:**
```bash
cat > ~/check_vexa.sh << 'EOF'
#!/bin/bash
echo "Prüfe Vexa Status..."
cd ~/ai-launchkit

# Container Status
echo "1. Container:"
sudo docker ps | grep vexa | wc -l
echo "   (Sollte 5 sein)"

# Firewall
echo "2. Firewall:"
sudo ufw status | grep 8056

# Token in DB
echo "3. Tokens in DB:"
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;" | grep -A 1 count

echo "Fertig!"
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

# 6. Verifizieren dass Token in DB ist
cd vexa
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT token, user_id FROM api_tokens;"
# MUSS 1 Zeile zeigen!

# 7. Neuen Token für n8n abrufen
cd ~/ai-launchkit
sudo grep "VEXA_API_KEY=" .env | head -1

# 8. Firewall sicherstellen
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

# Token Status
echo "Token in .env:" >> ~/vexa_system_info.txt
sudo grep "VEXA_API_KEY=" .env | head -1 >> ~/vexa_system_info.txt
echo "Tokens in DB:" >> ~/vexa_system_info.txt
sudo docker exec vexa_dev-postgres-1 psql -U postgres -d vexa \
  -c "SELECT COUNT(*) FROM api_tokens;" >> ~/vexa_system_info.txt 2>&1

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
- [ ] Wenn Token NICHT in DB: .env Token löschen → `sudo sed -i 's/^VEXA_API_KEY=.*/VEXA_API_KEY=""/' .env`
- [ ] Init-Script ausgeführt? → `sudo bash scripts/05a_init_vexa.sh`
- [ ] Verifizieren dass Token JETZT in DB ist → Sollte 1 Zeile zeigen, nicht 0!
- [ ] Problem 3: Firewall offen? → `sudo ufw status | grep 8056`
- [ ] Port freigeben? → `sudo ufw allow 8056/tcp`
- [ ] n8n URLs aktualisiert? → Server-IP statt localhost
- [ ] n8n Token aktualisiert? → Neuen Token aus `.env`
- [ ] End-to-End Test erfolgreich? → Siehe "Vollständiger End-to-End Test"

**Wenn alle Punkte ✅ sind: Vexa ist einsatzbereit!** 🎉

---

**Wichtigste Erkenntnis für Problem 2/2B:** Wenn Sie "keeping token" sehen, aber der Token nicht funktioniert, IMMER zuerst den Token in .env löschen bevor Sie das Init-Script nochmal ausführen!

**Key takeaway for Problem 2/2B:** If you see "keeping token" but the token doesn't work, ALWAYS clear the token in .env first before running the init script again!


### What is Vexa?

Vexa is a real-time meeting transcription service that drops AI bots into online meetings (Google Meet & Microsoft Teams) to capture live conversations with speaker identification. Unlike post-meeting transcription, Vexa bots join meetings as participants and provide real-time transcripts with sub-second latency via WebSocket streaming. Perfect for automated meeting notes, sales call analysis, and compliance recording.

⚠️ **Important:** If you experience installation or update issues with Vexa, see the [Vexa Troubleshooting Guide](https://github.com/freddy-schuetz/ai-launchkit/blob/main/vexa-troubleshooting-workarounds.md)

### Features

- **Real-Time Transcription** - Sub-second latency via WebSocket streaming
- **Google Meet & Teams Bots** - Automated bot joins meetings as participant
- **Speaker Identification** - Track who said what in real-time
- **99 Languages** - Multilingual transcription with auto-detection
- **REST & WebSocket APIs** - Choose between polling or streaming
- **Privacy-First** - All data stays on your server, zero external dependencies

### Initial Setup

**Vexa runs on a separate Docker network** and requires special configuration.

**Access URLs:**
- **User API:** `http://localhost:8056` (from n8n)
- **Admin API:** `http://localhost:8057` (requires admin token)
- **Not publicly accessible** (internal API only)

**API Authentication:**

During installation, Vexa generates:
1. **User API Key** - Shown in installation report, used for bot control
2. **Admin Token** - For user management (check `.env` file)

**Get Your API Key:**

```bash
# View your Vexa API key from installation logs
cd ~/ai-launchkit
grep "VEXA_API_KEY" .env

# Or check installation report
cat installation-report-*.txt | grep -A5 "Vexa"
```

**Configure Whisper Model:**

Before installation, edit `.env` to choose the Whisper model:

```bash
# Default is 'base' - good balance
VEXA_WHISPER_MODEL=base

# Options: tiny, base, small, medium, large
# See Model Selection Guide below
```

### n8n Integration Setup

**⚠️ Critical:** Vexa uses a separate Docker network. From n8n, always use:
- **API URL:** `http://localhost:8056`
- **NOT** `http://vexa:8056` (won't work!)

**Internal URL:** `http://localhost:8056`

**Available Endpoints:**
- `POST /bots` - Start transcription bot in meeting
- `GET /transcripts/{platform}/{meeting_id}` - Get transcript
- `DELETE /bots/{meeting_id}` - Stop bot (auto-stops when meeting ends)
- `GET /` - Health check

### Example Workflows

#### Example 1: Auto-Transcribe Google Meet Meetings

```javascript
// Complete workflow: Calendar → Bot Join → Transcript → Summary → Email

// 1. Google Calendar Trigger Node
Event: Event Starting
Time Before: 2 minutes

// 2. IF Node - Check if Google Meet link exists
Condition: {{$json.hangoutLink}} exists

// 3. Code Node - Extract Meeting ID
// Google Meet URL: https://meet.google.com/abc-defg-hij
// Meeting ID is: abc-defg-hij

const meetUrl = $input.item.json.hangoutLink;
const meetingId = meetUrl.split('/').pop();

return {
  meeting_id: meetingId,
  meeting_title: $input.item.json.summary,
  attendees: $input.item.json.attendees.map(a => a.email)
};

// 4. HTTP Request Node - Start Vexa Bot
Method: POST
URL: http://localhost:8056/bots
Send Headers: ON
Headers:
  X-API-Key: {{$env.VEXA_API_KEY}}
Send Body: JSON
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// Response:
{
  "id": 1,
  "status": "requested",
  "bot_container_id": "vexa_bot_abc123",
  "platform": "google_meet",
  "native_meeting_id": "abc-defg-hij"
}

// 5. Wait Node - Meeting Duration
Wait: {{$('Calendar Trigger').json.duration}} minutes
// Or add buffer: + 10 minutes

// 6. HTTP Request Node - Get Transcript
Method: GET
URL: http://localhost:8056/transcripts/google_meet/{{$('Code Node').json.meeting_id}}
Headers:
  X-API-Key: {{$env.VEXA_API_KEY}}

// Response:
{
  "transcript": [
    {
      "start": 0.5,
      "end": 3.2,
      "text": "Good morning everyone, thanks for joining.",
      "speaker": "Speaker 1"
    },
    {
      "start": 3.5,
      "end": 6.8,
      "text": "Happy to be here.",
      "speaker": "Speaker 2"
    }
  ],
  "full_text": "Good morning everyone...",
  "speakers": ["Speaker 1", "Speaker 2"],
  "language": "en"
}

// 7. Code Node - Format Transcript
const transcript = $input.item.json.transcript;

const formatted = transcript.map(seg => {
  const time = new Date(seg.start * 1000).toISOString().substr(14, 5);
  return `[${time}] ${seg.speaker}: ${seg.text}`;
}).join('\n\n');

return {
  formatted_transcript: formatted,
  full_text: $input.item.json.full_text,
  speaker_count: $input.item.json.speakers.length
};

// 8. OpenAI Node - Generate Meeting Summary
Model: gpt-4o-mini
Prompt: |
  Create detailed meeting notes from this transcript:
  
  {{$json.full_text}}
  
  Include:
  - Key discussion points
  - Decisions made
  - Action items with owners
  - Follow-up questions

// 9. Google Docs Node - Create Meeting Notes
Title: Meeting Notes - {{$('Calendar Trigger').json.summary}} - {{$now.format('YYYY-MM-DD')}}
Content: |
  # Meeting: {{$('Calendar Trigger').json.summary}}
  **Date:** {{$now.format('YYYY-MM-DD HH:mm')}}
  **Attendees:** {{$('Code Node').json.attendees.join(', ')}}
  **Duration:** {{$('Calendar Trigger').json.duration}} minutes
  **Speakers Identified:** {{$('Code Node').json.speaker_count}}
  
  ---
  
  ## AI Summary
  {{$('OpenAI').json.summary}}
  
  ---
  
  ## Full Transcript with Timestamps
  {{$('Code Node').json.formatted_transcript}}

// 10. Gmail Node - Email Notes to Attendees
To: {{$('Code Node').json.attendees.join(',')}}
Subject: Meeting Notes - {{$('Calendar Trigger').json.summary}}
Body: |
  Hi team,
  
  Meeting notes are ready!
  
  View document: {{$('Google Docs').json.document_url}}
  
  Key takeaways:
  {{$('OpenAI').json.key_points}}
  
  Best regards
```

#### Example 2: Microsoft Teams Meeting Transcription

```javascript
// Transcribe Teams meetings with passcode support

// 1. Webhook Trigger - Receive Teams meeting info
// Input: {
//   "meeting_id": "12345678",
//   "passcode": "ABC123",
//   "title": "Client Call",
//   "duration": 30
// }

// 2. HTTP Request - Start Vexa Bot in Teams
Method: POST
URL: http://localhost:8056/bots
Headers:
  X-API-Key: {{$env.VEXA_API_KEY}}
Body: {
  "platform": "teams",
  "native_meeting_id": "{{$json.meeting_id}}",
  "passcode": "{{$json.passcode}}"  // Required for Teams
}

// Response includes bot_container_id

// 3. Wait Node - Meeting duration + buffer
Wait: {{$json.duration + 5}} minutes

// 4. HTTP Request - Get Transcript
Method: GET
URL: http://localhost:8056/transcripts/teams/{{$json.meeting_id}}
Headers:
  X-API-Key: {{$env.VEXA_API_KEY}}

// 5. Process transcript (same as Example 1)
```

#### Example 3: Sales Call Analysis Pipeline

```javascript
// Automated sales call intelligence

// 1. Schedule Trigger - Check for scheduled sales calls
Cron: Every 5 minutes
// Or: CRM webhook when call is scheduled

// 2. Salesforce Node - Get upcoming calls
Query: SELECT Id, Meeting_Link__c, Account_Name__c 
       FROM Event 
       WHERE StartDateTime = NEXT_HOUR 
       AND Type = 'Sales Call'

// 3. Loop Node - Process each call
Items: {{$json}}

// 4. Code Node - Extract Google Meet ID
const meetUrl = $item.Meeting_Link__c;
const meetingId = meetUrl.split('/').pop();
return { meeting_id: meetingId, account: $item.Account_Name__c };

// 5. HTTP Request - Start Vexa Bot
Method: POST
URL: http://localhost:8056/bots
Headers:
  X-API-Key: {{$env.VEXA_API_KEY}}
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// 6. Wait - 35 minutes (typical call duration)
Wait: 35 minutes

// 7. HTTP Request - Get Transcript
Method: GET
URL: http://localhost:8056/transcripts/google_meet/{{$json.meeting_id}}

// 8. OpenAI Node - Extract Sales Intelligence
Model: gpt-4o
Prompt: |
  Analyze this sales call transcript:
  
  {{$json.full_text}}
  
  Extract and return JSON:
  {
    "pain_points": ["list of customer pain points"],
    "objections": ["list of objections raised"],
    "budget_mentioned": true/false,
    "decision_timeline": "timeframe mentioned",
    "competitors_mentioned": ["competitor names"],
    "next_steps": ["agreed action items"],
    "sentiment": "positive/neutral/negative",
    "deal_probability": "high/medium/low",
    "key_quotes": ["important statements"]
  }

// 9. Code Node - Calculate Talk Ratio
const transcript = $input.item.json.transcript;

// Assume first speaker is sales rep
const repSpeaker = transcript[0].speaker;
const repTime = transcript
  .filter(s => s.speaker === repSpeaker)
  .reduce((sum, s) => sum + (s.end - s.start), 0);

const totalTime = transcript[transcript.length - 1].end;
const repTalkRatio = (repTime / totalTime * 100).toFixed(1);

return {
  rep_talk_ratio: repTalkRatio,
  customer_talk_ratio: (100 - repTalkRatio).toFixed(1),
  // Good: 30-40% rep, 60-70% customer
  quality_score: repTalkRatio < 45 ? 'Good' : 'Needs Improvement'
};

// 10. Salesforce Node - Update Opportunity
Update Record:
  Object: Opportunity
  Record ID: {{$('Salesforce').json.OpportunityId}}
  Fields:
    Pain_Points__c: {{$('OpenAI').json.pain_points.join(', ')}}
    Objections__c: {{$('OpenAI').json.objections.join(', ')}}
    Deal_Probability__c: {{$('OpenAI').json.deal_probability}}
    Rep_Talk_Ratio__c: {{$('Code Node').json.rep_talk_ratio}}
    Call_Sentiment__c: {{$('OpenAI').json.sentiment}}
    Next_Steps__c: {{$('OpenAI').json.next_steps.join('\n')}}

// 11. Slack Node - Alert Sales Manager if Issues
IF: {{$('Code Node').json.rep_talk_ratio > 60}} OR {{$('OpenAI').json.sentiment === 'negative'}}

Channel: #sales-management
Message: |
  ⚠️ Sales Call Requires Review
  
  **Account:** {{$('Loop').json.account}}
  **Issue:** Rep talked {{$('Code Node').json.rep_talk_ratio}}% (should be <45%)
  **Sentiment:** {{$('OpenAI').json.sentiment}}
  
  **Key Objections:**
  {{$('OpenAI').json.objections.join('\n- ')}}
  
  **Recommended Actions:**
  - Coach on listening skills
  - Review objection handling
  - Consider manager follow-up call

// 12. Gmail - Send Summary to Sales Rep
To: sales.rep@company.com
Subject: Call Summary - {{$('Loop').json.account}}
Body: |
  Your call has been analyzed:
  
  **Performance:**
  - Talk Ratio: {{$('Code Node').json.rep_talk_ratio}}% ✅/⚠️
  - Sentiment: {{$('OpenAI').json.sentiment}}
  
  **Customer Pain Points:**
  {{$('OpenAI').json.pain_points.join('\n- ')}}
  
  **Next Steps:**
  {{$('OpenAI').json.next_steps.join('\n- ')}}
  
  **Key Quotes:**
  {{$('OpenAI').json.key_quotes.join('\n- ')}}
```

#### Example 4: Compliance Recording System

```javascript
// Automatic compliance recording with alerting

// 1. Webhook - Meeting scheduled with compliance flag
// Input: { "meeting_id": "abc-def-ghi", "requires_compliance": true }

// 2. IF Node - Check compliance requirement
If: {{$json.requires_compliance}} === true

// 3. HTTP Request - Start Vexa Bot
Method: POST
URL: http://localhost:8056/bots
Body: {
  "platform": "google_meet",
  "native_meeting_id": "{{$json.meeting_id}}"
}

// 4. Email - Notify participants of recording
To: {{$json.participants}}
Subject: Meeting Recording Notice
Body: |
  This meeting will be recorded for compliance purposes.
  
  A transcription bot will join automatically.
  By remaining in the meeting, you consent to recording.

// 5. Wait - Meeting duration
// 6. Get Transcript
// 7. Store in secure database

// 8. Code Node - Scan for compliance keywords
const transcript = $input.item.json.full_text.toLowerCase();
const flags = [];

const keywords = {
  'legal': ['lawsuit', 'attorney', 'legal action', 'court'],
  'financial': ['insider', 'confidential', 'material information'],
  'hr': ['harassment', 'discrimination', 'hostile environment']
};

for (const [category, words] of Object.entries(keywords)) {
  for (const word of words) {
    if (transcript.includes(word)) {
      flags.push({ category, keyword: word });
    }
  }
}

return { compliance_flags: flags, flag_count: flags.length };

// 9. IF Node - Alert if flags found
If: {{$json.flag_count > 0}}

// 10. Email - Compliance team alert
To: compliance@company.com
Priority: High
Subject: Compliance Review Required
Body: |
  Meeting transcript flagged for review:
  
  **Flags:** {{$json.flag_count}}
  **Categories:** {{$json.compliance_flags.map(f => f.category).join(', ')}}
  
  Review transcript immediately.

// 11. Database - Store with metadata
Table: compliance_transcripts
Fields:
  - meeting_id
  - transcript
  - flags
  - review_status: 'pending'
  - recorded_at: timestamp
```

### Model Selection Guide

Choose Whisper model based on your needs:

| Model | RAM | Speed | Quality | Best For |
|-------|-----|-------|---------|----------|
| **tiny** | ~1GB | Fastest | Good | Testing, development |
| **base** | ~1.5GB | Fast | Better | **Recommended default** |
| **small** | ~3GB | Medium | Good | Accents, multiple languages |
| **medium** | ~5GB | Slow | Great | High accuracy needs |
| **large** | ~10GB | Slowest | Best | Maximum quality (overkill for most) |

**Real-Time Performance:**
- **tiny/base:** Best for live transcription (<1s latency)
- **small/medium:** Slight delay but better accuracy
- **large:** Not recommended for real-time (too slow)

**Configure before installation:**
```bash
# Edit .env file
VEXA_WHISPER_MODEL=base  # Change here
VEXA_WHISPER_DEVICE=cpu   # Or 'cuda' for GPU
```

### Troubleshooting

**Issue 1: Bot Not Joining Meeting**

```bash
# Check Vexa service status
docker ps | grep vexa

# Should show containers:
# - vexa-api
# - vexa-bot-manager

# Check bot logs
docker logs vexa-api --tail 100

# Common errors:
# - "Meeting not found" → Check meeting ID format
# - "Meeting not started" → Meeting must be active
# - "Access denied" → Check Google Meet lobby settings
```

**Solution:**
- **Google Meet:** Enable "Let people join before host" in Google Workspace settings
- **Meeting must be active:** Bot cannot join meetings that haven't started yet
- **Check meeting ID:** For `meet.google.com/abc-defg-hij`, use only `abc-defg-hij`
- **Lobby settings:** Disable lobby mode or start meeting before bot joins
- **Teams passcode:** Always required for Teams meetings with lobby

**Issue 2: "Separate Docker Network" Connection Error**

```bash
# Vexa runs in separate network - use localhost, not service name
# ❌ WRONG: http://vexa:8056
# ✅ CORRECT: http://localhost:8056

# Test connectivity from n8n
docker exec n8n curl http://localhost:8056/

# Should return: {"message": "Vexa API"}

# If connection fails, check port mapping
docker port vexa-api 8056
```

**Solution:**
- Always use `http://localhost:8056` from n8n
- Do NOT use `http://vexa:8056` (different network)
- Vexa is not in the main Docker Compose network
- This is by design for security isolation

**Issue 3: Transcript Empty or Incomplete**

```bash
# Check if bot successfully joined
docker logs vexa-bot-manager | grep "Joined meeting"

# Check Whisper processing
docker logs vexa-api | grep -i "whisper\|transcription"

# Check meeting duration
# Bot needs at least 30 seconds of audio to generate transcript
```

**Solution:**
- Wait at least 30 seconds after meeting starts
- Ensure participants are speaking (silence = no transcript)
- Check if bot was removed from meeting by host
- Verify Whisper model is downloaded (first run takes time)
- For very short meetings, transcript may be minimal

**Issue 4: API Key Authentication Failed**

```bash
# Find your Vexa API key
cd ~/ai-launchkit
grep "VEXA_API_KEY" .env

# Or check admin API for users
curl -H "Authorization: Bearer $(grep VEXA_ADMIN_TOKEN .env | cut -d= -f2)" \
  http://localhost:8057/admin/users

# Regenerate API key if needed
docker exec vexa-api python3 manage.py create-user
```

**Solution:**
- Check API key in `.env` file: `VEXA_API_KEY=...`
- Include header: `X-API-Key: YOUR_KEY` in all requests
- Case-sensitive: ensure exact key match
- If lost, regenerate via admin API or reinstall

**Issue 5: High Memory Usage**

```bash
# Check container memory
docker stats vexa-api vexa-bot-manager --no-stream

# Whisper models use RAM:
# tiny: ~1GB
# base: ~1.5GB
# small: ~3GB
# medium: ~5GB
# large: ~10GB

# Check current model
grep VEXA_WHISPER_MODEL .env
```

**Solution:**
- Use smaller Whisper model (base instead of large)
- Bot containers are created per meeting (cleanup happens automatically)
- Monitor server RAM: `free -h`
- Each active bot uses 1.5-5GB depending on model
- Limit concurrent meetings if RAM constrained
- Bots auto-cleanup when meetings end

**Issue 6: Vexa Installation Failed**

```bash
# If you experienced installation issues, see the workaround guide:
# https://github.com/freddy-schuetz/ai-launchkit/blob/main/vexa-troubleshooting-workarounds.md

# Common issues during install:
# - Docker network conflicts
# - Port 8056/8057 already in use
# - Whisper model download timeout

# Check Vexa logs during installation
tail -f /var/log/ai-launchkit-install.log | grep -i vexa
```

**Solution:**
- Follow [Vexa Troubleshooting Guide](https://github.com/freddy-schuetz/ai-launchkit/blob/main/vexa-troubleshooting-workarounds.md)
- Most issues resolve with the documented workarounds
- If problems persist, Vexa is optional and can be skipped

### Meeting Platform Support

| Platform | Status | Meeting ID Format | Requirements |
|----------|--------|-------------------|--------------|
| **Google Meet** | ✅ Ready | `abc-defg-hij` | Extract from meet.google.com URL |
| **Microsoft Teams** | ✅ Ready | Numeric + passcode | Requires meeting passcode |
| **Zoom** | ⏳ Coming Soon | - | Planned for future release |

**Google Meet Setup:**
1. Extract meeting ID from URL: `https://meet.google.com/abc-defg-hij` → Use `abc-defg-hij`
2. Enable "Let people join before host" in Google Workspace settings
3. Disable lobby mode or start meeting before bot joins
4. Bot appears as "Vexa Transcription Bot" participant

**Microsoft Teams Setup:**
1. Get meeting ID (numeric) and passcode from Teams
2. Include both in API request: `{"native_meeting_id": "12345", "passcode": "ABC123"}`
3. Ensure lobby is disabled or meeting is started
4. Bot appears as participant in Teams

### API Reference

**Start Transcription Bot:**
```bash
POST http://localhost:8056/bots
Headers: X-API-Key: YOUR_KEY
Body: {
  "platform": "google_meet",  # or "teams"
  "native_meeting_id": "abc-defg-hij",
  "passcode": "ABC123"  # Teams only
}

Response: {
  "id": 1,
  "status": "requested",
  "bot_container_id": "vexa_bot_abc123",
  "platform": "google_meet",
  "native_meeting_id": "abc-defg-hij"
}
```

**Get Transcript (Polling):**
```bash
GET http://localhost:8056/transcripts/{platform}/{meeting_id}
Headers: X-API-Key: YOUR_KEY

Response: {
  "transcript": [
    {
      "start": 0.5,
      "end": 3.2,
      "text": "Hello everyone",
      "speaker": "Speaker 1"
    }
  ],
  "full_text": "Complete transcript...",
  "speakers": ["Speaker 1", "Speaker 2"],
  "language": "en"
}
```

**Stop Bot (Optional):**
```bash
DELETE http://localhost:8056/bots/{meeting_id}
Headers: X-API-Key: YOUR_KEY

# Note: Bots automatically leave when meeting ends
```

**Health Check:**
```bash
GET http://localhost:8056/
# Returns: {"message": "Vexa API"}
```

**Admin API (User Management):**
```bash
GET http://localhost:8057/admin/users
Headers: Authorization: Bearer YOUR_ADMIN_TOKEN

# Create new API key
POST http://localhost:8057/admin/users/{user_id}/tokens
```

### Resources

- **GitHub:** https://github.com/Vexa-ai/vexa
- **Troubleshooting Guide:** https://github.com/freddy-schuetz/ai-launchkit/blob/main/vexa-troubleshooting-workarounds.md
- **Whisper Model Info:** https://github.com/openai/whisper#available-models-and-languages
- **Language Support:** 99 languages supported

### Best Practices

**When to Use Vexa:**

✅ **Perfect For:**
- Automated meeting notes (Google Meet, Teams)
- Sales call recording and analysis
- Compliance recording requirements
- Real-time transcription needs
- Multi-speaker meeting capture
- CRM integration workflows
- Quality assurance monitoring
- Remote team collaboration

❌ **Not Ideal For:**
- Pre-recorded audio files (use Scriberr instead)
- Zoom meetings (not yet supported)
- Meetings you didn't organize (privacy/consent issues)
- Very short meetings (<1 minute)
- Meetings where bot participant is not allowed

**Privacy & Consent:**

⚠️ **Legal Requirements:**
- Always inform participants that meeting is being recorded
- Check local laws (some require all-party consent)
- Bot appears as visible participant in meeting
- Consider adding recording notice to calendar invites
- Store transcripts securely and comply with GDPR/privacy laws

**Optimal Configuration:**

1. **Model Selection:**
   - Development/Testing: `tiny` or `base`
   - Production: `base` (best balance)
   - High Accuracy: `small` or `medium`
   - Avoid: `large` (overkill, too slow for real-time)

2. **Meeting Setup:**
   - Disable lobby mode when possible
   - Start meeting before bot joins (especially Teams)
   - Enable "join before host" for Google Meet
   - Test bot with sample meeting before production

3. **Resource Planning:**
   - 1.5-3GB RAM per active bot (base/small model)
   - Plan for concurrent meetings
   - Monitor server resources during peak times
   - Consider auto-scaling for large deployments

4. **Integration Strategy:**
   - Use calendar webhooks to auto-start bots
   - Implement retry logic for failed bot joins
   - Poll transcript endpoint every 30-60 seconds
   - Store transcripts in database for backup
   - Cache transcripts to avoid re-processing

**Vexa vs Scriberr vs Faster-Whisper:**

| Feature | Vexa | Scriberr | Faster-Whisper |
|---------|------|----------|----------------|
| **Use Case** | Live meeting bots | Post-recording diarization | Single speaker transcription |
| **Platforms** | Google Meet, Teams | Pre-recorded files, YouTube | Any audio file |
| **Speaker ID** | Real-time | Post-processing | No |
| **Latency** | <1 second | Minutes (processing) | Seconds to minutes |
| **Best For** | Automated meeting notes | Detailed analysis | Voice commands, simple transcription |
