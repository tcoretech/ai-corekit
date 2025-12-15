# ✉️ SnappyMail - Webmail Client

### What is SnappyMail?

SnappyMail is a modern, ultra-fast webmail client with only 138KB load time. It provides a complete email interface for Docker-Mailserver with professional features like PGP encryption and multi-account support.

### Features

- **Ultra-fast Performance:** 138KB initial load, 99% Lighthouse score
- **Multiple Accounts:** Manage multiple email accounts in one interface
- **Mobile Responsive:** Works perfectly on all devices
- **PGP Encryption:** Built-in support for encrypted emails
- **2-Factor Authentication:** Enhanced security for webmail access
- **No Database Required:** Simple file-based configuration
- **Dark Mode:** Built-in theme support

### Initial Setup

**Prerequisite:** Docker-Mailserver must be installed (SnappyMail requires IMAP/SMTP).

#### 1. Get Admin Password

```bash
# Display admin password
docker exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt
```

#### 2. Configure Admin Panel

1. Open admin panel: `https://webmail.yourdomain.com/?admin`
2. Username: `admin`
3. Password: (from step 1)

#### 3. Add Domain

In the admin panel:

**Domains → Add Domain:**
```
Domain: yourdomain.com
IMAP Server: mailserver
IMAP Port: 143
IMAP Security: STARTTLS
SMTP Server: mailserver
SMTP Port: 587
SMTP Security: STARTTLS
```

#### 4. User Login

After domain configuration, users can log in:

1. URL: `https://webmail.yourdomain.com`
2. Email: `user@yourdomain.com`
3. Password: (User's Docker-Mailserver password)

### n8n Integration Setup

**SnappyMail is a webmail client without a direct API.** Integration happens via Docker-Mailserver:

**Email Workflow Architecture:**
```
n8n Send Email Node → Docker-Mailserver → SnappyMail (read emails)
```

**IMAP Integration in n8n (retrieve emails):**

1. Email (IMAP) Trigger Node in n8n
2. Configuration:

```
Host: mailserver
Port: 993
User: user@yourdomain.com
Password: [Docker-Mailserver Password]
TLS: Enabled
```

**Internal URLs:**
- IMAP: `mailserver:993` (with TLS) or `mailserver:143` (STARTTLS)
- SMTP: `mailserver:587` (STARTTLS)

### Example Workflows

#### Example 1: Email Management Workflow

```javascript
// SnappyMail Use Case: Manage emails via web UI

// Workflow Architecture:
// 1. Service sends email → Docker-Mailserver
// 2. User opens SnappyMail → Reads email
// 3. User replies → Sent via Docker-Mailserver

// n8n Parallel Workflow:
// 1. IMAP Trigger Node (mailserver:993)
//    → Automatically process new emails
// 2. Code Node - Analyze email
// 3. Conditional Node - Filter by criteria
// 4. Action Nodes - Automated actions
```

#### Example 2: Multi-Account Management

```javascript
// SnappyMail Feature: Manage multiple accounts

// Setup in SnappyMail:
// 1. User Login: user@yourdomain.com
// 2. Settings → Accounts → Add Account
// 3. Add more accounts (support@, sales@, etc.)
// 4. Switch between accounts with one click

// Manage all emails centrally!
```

#### Example 3: Ticket System Integration

```javascript
// 1. IMAP Trigger Node (mailserver:993)
//    Mailbox: support@yourdomain.com
//    → Waits for new support emails

// 2. Code Node - Extract ticket data
const ticketData = {
  from: $json.from.value[0].address,
  subject: $json.subject,
  body: $json.textPlain || $json.textHtml,
  date: $json.date,
  priority: $json.subject.includes('URGENT') ? 'high' : 'normal'
};
return ticketData;

// 3. HTTP Request Node - Create ticket
// POST to ticketing system API
{
  "title": ticketData.subject,
  "description": ticketData.body,
  "customer_email": ticketData.from,
  "priority": ticketData.priority
}

// 4. Send Email Node - Send confirmation
// → Customer receives ticket number
// → Email visible in SnappyMail

// Support team can reply in SnappyMail!
```

### Troubleshooting

**SnappyMail Web UI not accessible:**

```bash
# 1. Check container status
docker ps | grep snappymail
# Should show: STATUS = Up

# 2. Check logs
docker logs snappymail --tail 50

# 3. Get admin password again
docker exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt

# 4. Check Caddy logs
docker logs caddy | grep snappymail

# 5. Restart container
docker compose restart snappymail
```

**Users cannot log in:**

```bash
# 1. Check domain configuration
# → Open admin panel: https://webmail.yourdomain.com/?admin
# → Domains → Check domain
# → Verify IMAP/SMTP settings

# 2. Check user account in Docker-Mailserver
docker exec mailserver setup email list

# 3. Test IMAP/SMTP connection
docker exec snappymail nc -zv mailserver 143
docker exec snappymail nc -zv mailserver 587

# 4. Test authentication
docker exec mailserver doveadm auth test user@yourdomain.com [password]

# 5. Check user-specific logs
docker logs snappymail | grep -i "login\|auth\|imap"
```

**Emails not showing:**

```bash
# 1. Check IMAP connection
docker exec snappymail nc -zv mailserver 143

# 2. Check mailbox in Docker-Mailserver
docker exec mailserver doveadm mailbox list -u user@yourdomain.com

# 3. Test email delivery
# Send test email to user@yourdomain.com

# 4. Check Docker-Mailserver logs
docker logs mailserver | grep user@yourdomain.com

# 5. Clear SnappyMail cache
docker exec snappymail rm -rf /var/lib/snappymail/_data_/_default_/cache/*
docker compose restart snappymail
```

**Performance issues:**

```bash
# 1. Check cache size
docker exec snappymail du -sh /var/lib/snappymail/_data_/_default_/cache/

# 2. Clear cache (if too large)
docker exec snappymail rm -rf /var/lib/snappymail/_data_/_default_/cache/*

# 3. Check container resources
docker stats snappymail --no-stream

# 4. Check logs for errors
docker logs snappymail | grep -i "error\|warning"

# 5. Restart container
docker compose restart snappymail
```

### Resources

- **GitHub:** https://github.com/the-djmaze/snappymail
- **Documentation:** https://snappymail.eu/docs/
- **Demo:** https://snappymail.eu/demo/
- **Admin Guide:** https://snappymail.eu/docs/admin/
- **Web-UI:** `https://webmail.yourdomain.com`
- **Admin Panel:** `https://webmail.yourdomain.com/?admin`
