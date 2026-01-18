# 🔐 Vaultwarden - Password Manager

### What is Vaultwarden?

Vaultwarden is a lightweight, self-hosted password manager that's 100% compatible with Bitwarden clients. Written in Rust, it provides the same features as the official Bitwarden server but with significantly lower resource requirements. Perfect for managing all your AI CoreKit service credentials, API keys, and team passwords securely.

With 40+ services in AI CoreKit generating unique passwords and API keys, credential management becomes critical. Vaultwarden provides a central, encrypted vault accessible via browser extensions, mobile apps, and desktop clients.

### Features

- ✅ **100% Bitwarden Compatible** - Works with all official Bitwarden clients
- ✅ **Lightweight & Fast** - Only 50-200MB RAM vs 2GB+ for official Bitwarden
- ✅ **Browser Integration** - Auto-fill passwords for all services (Chrome, Firefox, Safari, Edge)
- ✅ **Mobile Apps** - iOS and Android apps with biometric unlock
- ✅ **Team Sharing** - Organizations for secure credential sharing
- ✅ **2FA Support** - TOTP, WebAuthn, YubiKey, Duo, Email
- ✅ **Password Generator** - Create strong, unique passwords
- ✅ **Security Reports** - Identify weak, reused, or compromised passwords
- ✅ **Emergency Access** - Trusted contacts for account recovery
- ✅ **Send Feature** - Securely share text/files with expiration

### Initial Setup

**First Steps After Installation:**

1. **Access Admin Panel:** Navigate to `https://vault.yourdomain.com/admin`
2. **Enter Admin Token:** Found in installation report or `.env` file as `VAULTWARDEN_ADMIN_TOKEN`
   ```bash
   # Get admin token from .env
   grep "VAULTWARDEN_ADMIN_TOKEN" .env
   ```
3. **Configure SMTP:** Uses your configured mail system (Mailpit or Docker-Mailserver)
   - For Mailpit (development): Already configured automatically
   - For Docker-Mailserver: Update SMTP settings in admin panel
4. **Disable Public Signups (Security):** In admin panel, disable signups after creating your account
5. **Create First User:** Navigate to `https://vault.yourdomain.com` and click "Create Account"
6. **Install Browser Extension:** Available for Chrome, Firefox, Safari, Edge, Opera

**Create Your First Account:**

1. Go to `https://vault.yourdomain.com`
2. Click **"Create Account"**
3. Enter email and create a **strong master password** (this cannot be reset!)
4. Verify email (if SMTP is configured)
5. Login and start adding passwords

### Automatic Credential Import

AI CoreKit automatically generates a Bitwarden-compatible JSON file with all your service credentials:

```bash
# Generate and download credentials (after installation)
sudo bash ./scripts/download_credentials.sh
```

**What this script does:**
1. Generates a JSON file with all service passwords, API keys, and tokens
2. Opens port 8889 temporarily (60 seconds)
3. Displays a download link for your browser
4. Automatically deletes the file after download for security

**Import into Vaultwarden:**

1. Download the file using the link provided by the script
2. Open Vaultwarden: `https://vault.yourdomain.com`
3. Go to **Tools** → **Import Data**
4. Select Format: **Bitwarden (json)**
5. Choose the downloaded file
6. Click **Import Data**

All credentials will be organized in an "AI CoreKit Services" folder with:
- Service URLs
- Usernames/emails
- Passwords
- API tokens
- Admin credentials
- SMTP settings

### Client Configuration

**Browser Extensions:**

1. Install official Bitwarden extension from:
   - Chrome Web Store: Search "Bitwarden"
   - Firefox Add-ons: Search "Bitwarden"
   - Safari Extensions: Available in Mac App Store
   - Edge Add-ons: Search "Bitwarden"
2. Click extension icon
3. Click **"Settings"** (gear icon)
4. Enter Server URL: `https://vault.yourdomain.com`
5. Click **"Save"**
6. Login with your credentials
7. Enable auto-fill in extension settings

**Mobile Apps:**

1. Download Bitwarden from:
   - iOS: App Store - "Bitwarden Password Manager"
   - Android: Play Store - "Bitwarden Password Manager"
2. Open app and tap **"Self-hosted"** during setup
3. Enter Server URL: `https://vault.yourdomain.com`
4. Login with your credentials
5. Enable biometric unlock (Face ID, Touch ID, Fingerprint)

**Desktop Apps:**

1. Download from [bitwarden.com/download](https://bitwarden.com/download/)
2. Install and open application
3. Go to **Settings** → **Server URL**
4. Enter: `https://vault.yourdomain.com`
5. Click **"Save"**
6. Login with your credentials

### Organizing AI CoreKit Credentials

**Recommended Folder Structure:**

```
📁 AI CoreKit Services (root folder from import)
├── 📁 Core Services
│   ├── 🔑 n8n Admin (https://n8n.yourdomain.com)
│   ├── 🔑 Supabase Dashboard
│   ├── 🔑 PostgreSQL Database
│   └── 🔑 Redis (internal)
├── 📁 AI Tools
│   ├── 🔑 OpenAI API Key
│   ├── 🔑 Anthropic API Key
│   ├── 🔑 Groq API Key
│   ├── 🔑 Ollama Admin
│   └── 🔑 Open WebUI
├── 📁 Development
│   ├── 🔑 bolt.diy Access
│   ├── 🔑 ComfyUI Login
│   ├── 🔑 GitHub Tokens
│   └── 🔑 Portainer Admin
├── 📁 Business Tools
│   ├── 🔑 Cal.com Admin
│   ├── 🔑 Vikunja Login
│   ├── 🔑 NocoDB API Token
│   └── 🔑 Leantime Admin
└── 📁 Monitoring
    ├── 🔑 Grafana Admin
    ├── 🔑 Prometheus Access
    └── 🔑 Mailpit Dashboard
```

**Organization Best Practices:**

- Use **folders** to group related services
- Add **custom fields** for API keys, tokens, internal URLs
- Use **tags** for quick filtering (e.g., #production, #staging, #api)
- Enable **favorites** for frequently accessed credentials
- Add **notes** with setup instructions or recovery codes

### Security Features

**Enable Two-Factor Authentication (2FA):**

1. Go to **Settings** → **Two-step Login**
2. Choose method:
   - **Authenticator App** (recommended): Use Google Authenticator, Authy, etc.
   - **Email:** Receive codes via email
   - **WebAuthn:** Use hardware keys (YubiKey, etc.)
   - **Duo:** If you have Duo account
3. Follow setup wizard
4. **Save recovery code** in a safe place (offline!)

**Password Generator:**

- Access via browser extension or vault web interface
- Customize: Length (8-128 chars), uppercase, lowercase, numbers, symbols
- Options: Passphrases (easier to remember), minimum numbers/symbols
- Generated passwords are automatically strong and unique

**Security Reports:**

1. Go to **Tools** → **Reports**
2. Available reports:
   - **Exposed Passwords:** Check against haveibeenpwned.com database
   - **Reused Passwords:** Find passwords used multiple times
   - **Weak Passwords:** Identify passwords below strength threshold
   - **Unsecured Websites:** HTTP sites storing credentials
   - **Inactive 2FA:** Sites offering 2FA that you haven't enabled
   - **Data Breach Report:** Check if your accounts were compromised

**Emergency Access:**

1. Go to **Settings** → **Emergency Access**
2. Click **"Add emergency contact"**
3. Enter trusted contact's email
4. Set wait time (0-90 days)
5. Choose access level: View or Takeover
6. Contact receives invitation to accept

**Send Feature (Secure Sharing):**

1. Click **"Send"** in vault menu
2. Choose type: Text or File (max 500MB)
3. Set options:
   - Deletion date (1 hour to 31 days, or manual)
   - Expiration date
   - Maximum access count
   - Password protection
   - Hide email from recipients
4. Share the generated link

### n8n Integration

While Vaultwarden doesn't have a native n8n node, you can use it programmatically via the API:

**API Authentication:**

1. Login to Vaultwarden web interface
2. Get API credentials by logging in via CLI:
   ```bash
   # Using curl to get auth token
   curl -X POST https://vault.yourdomain.com/identity/connect/token \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=password&username=YOUR_EMAIL&password=YOUR_PASSWORD&scope=api&client_id=web"
   ```

**Example: Retrieve Credentials in n8n Workflow**

```javascript
// This is a conceptual example - requires API token

// 1. HTTP Request - Get Access Token
Method: POST
URL: https://vault.yourdomain.com/identity/connect/token
Headers:
  Content-Type: application/x-www-form-urlencoded
Body (Form):
  grant_type: password
  username: {{$env.VAULTWARDEN_EMAIL}}
  password: {{$env.VAULTWARDEN_PASSWORD}}
  scope: api
  client_id: web

// 2. Set Node - Save token
Keep Only Set: true
Values:
  token: {{$json.access_token}}

// 3. HTTP Request - Get Vault Items
Method: GET
URL: https://vault.yourdomain.com/api/ciphers
Headers:
  Authorization: Bearer {{$json.token}}

// 4. Code Node - Find specific credential
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

**Better Approach:** Store API keys directly in n8n environment variables:
- More secure than fetching from Vaultwarden in every workflow
- Faster execution
- Simpler workflow logic
- Use Vaultwarden as the secure storage, manually update n8n .env when keys change

### Backup & Recovery

**Backup Vaultwarden Data:**

```bash
# Method 1: Backup entire data directory
docker exec vaultwarden tar -czf /tmp/vaultwarden-backup-$(date +%Y%m%d).tar.gz /data
docker cp vaultwarden:/tmp/vaultwarden-backup-$(date +%Y%m%d).tar.gz ./backups/

# Method 2: Backup Docker volume
docker run --rm \
  -v vaultwarden_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/vaultwarden-backup-$(date +%Y%m%d).tar.gz /data

# Verify backup
ls -lh ./backups/vaultwarden-backup-*.tar.gz
```

**Export Vault (User-Level Backup):**

1. Login to Vaultwarden web interface
2. Go to **Tools** → **Export Vault**
3. Choose format:
   - **JSON** (recommended): Full export with folders
   - **CSV**: Simple format, no folders
   - **JSON (Encrypted)**: Password-protected export
4. Click **"Export Vault"**
5. Store export file securely (encrypted storage recommended)

**Restore from Backup:**

```bash
# Stop Vaultwarden
docker stop vaultwarden

# Restore data
docker run --rm \
  -v vaultwarden_data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /data && tar -xzf /backup/vaultwarden-backup-YYYYMMDD.tar.gz --strip-components=1"

# Start Vaultwarden
docker start vaultwarden
```

**Automated Backup Script:**

Create a cron job for automated backups:

```bash
# Create backup script
cat > ~/vaultwarden-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/$(whoami)/vaultwarden-backups"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

# Create backup
docker run --rm \
  -v vaultwarden_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf "/backup/vaultwarden-${DATE}.tar.gz" /data

# Keep only last 30 days
find "$BACKUP_DIR" -name "vaultwarden-*.tar.gz" -mtime +30 -delete

echo "Backup completed: vaultwarden-${DATE}.tar.gz"
EOF

chmod +x ~/vaultwarden-backup.sh

# Add to cron (runs daily at 2 AM)
crontab -e
# Add line:
0 2 * * * /home/$(whoami)/vaultwarden-backup.sh >> /var/log/vaultwarden-backup.log 2>&1
```

### Troubleshooting

**Cannot access admin panel / Forgot admin token:**

```bash
# Get admin token from environment file
grep "VAULTWARDEN_ADMIN_TOKEN" .env

# Or regenerate token
NEW_TOKEN=$(openssl rand -base64 32)
echo "New admin token: $NEW_TOKEN"

# Update .env file
sed -i "s/VAULTWARDEN_ADMIN_TOKEN=.*/VAULTWARDEN_ADMIN_TOKEN=$NEW_TOKEN/" .env

# Restart Vaultwarden
docker compose restart vaultwarden
```

**Email verification not working:**

```bash
# Check Vaultwarden logs
docker logs vaultwarden --tail 100 | grep -i "mail\|smtp"

# Test SMTP configuration
docker exec vaultwarden cat /data/config.json | grep -i smtp

# For Mailpit (development):
# Emails go to http://mail.yourdomain.com - check there

# For Docker-Mailserver:
# Check mailserver logs
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

### Resources

- **Official Documentation:** https://github.com/dani-garcia/vaultwarden/wiki
- **Bitwarden Help Center:** https://bitwarden.com/help/
- **API Documentation:** https://bitwarden.com/help/api/
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
- Assign appropriate permissions (Can View, Can Edit)
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

**Monitoring:**
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
