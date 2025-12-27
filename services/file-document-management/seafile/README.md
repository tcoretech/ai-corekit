# 🌊 Seafile - Professional File Sync & Share Platform

### What is Seafile?

Seafile is a professional open-source file sync and share platform that provides a self-hosted alternative to Dropbox, Google Drive, and OneDrive. It offers reliable file synchronization, team collaboration features, version control, and encryption, making it perfect for businesses that need full control over their data. With desktop and mobile clients, WebDAV support, and extensive API, Seafile seamlessly integrates into any workflow.

### Features

- **File Sync** - Real-time synchronization across all devices with selective sync
- **Version Control** - Complete file history with easy rollback to previous versions
- **Team Libraries** - Shared folders with granular permission management
- **File Locking** - Prevent editing conflicts with automatic file locking
- **WebDAV Support** - Mount as network drive on Windows/Mac/Linux
- **Mobile Apps** - iOS and Android apps with offline access and auto-upload
- **End-to-End Encryption** - Client-side encryption for sensitive data
- **Office Integration** - Edit documents online with OnlyOffice/Collabora
- **Full-Text Search** - Search inside documents, PDFs, and Office files
- **Activity Stream** - Track all file changes and team activities

### Initial Setup

**First Login to Seafile:**

1. Navigate to `https://files.yourdomain.com`
2. Login with:
   - **Email:** Your configured admin email
   - **Password:** Check your `.env` file for `SEAFILE_ADMIN_PASSWORD`
3. Complete first-time setup:
   - Create your first library (folder)
   - Install desktop client from dashboard
   - Configure sync folders

**Desktop Client Setup:**

1. Download from `https://www.seafile.com/en/download/`
2. Add account:
   - **Server:** `https://files.yourdomain.com`
   - **Email:** Your admin email
   - **Password:** Your admin password
3. Select libraries to sync
4. Choose local folders for synchronization

**Generate API Token for n8n:**

1. Go to **Avatar** → **Settings**
2. Navigate to **Web API** → **Auth Token**
3. Click **Generate**
4. Copy and save the token securely

### n8n Integration Setup

**Install Seafile Community Node:**

1. In n8n, go to **Settings** → **Community Nodes**
2. Install: `n8n-nodes-seafile`
3. Restart n8n: `docker compose restart n8n`

**Configure Seafile Credentials:**

1. Add **Seafile** node to workflow
2. Create new credentials:
   - **Server URL:** `http://seafile:80` (internal)
   - **API Token:** Your generated token
   - Save credentials

### Example Workflows

#### Example 1: Automatic Document Backup

```javascript
// Daily backup of important documents to Seafile

// 1. Schedule Trigger - Daily at 2 AM
Cron Expression: 0 2 * * *

// 2. Read Binary Files - Get documents from local folder
File Path: /data/shared/documents/*.pdf

// 3. Seafile Node - Upload to backup library
Operation: Upload File
Library: Backups
Path: /{{$now.format('YYYY-MM-DD')}}/
File: {{$binary}}

// 4. Seafile Node - Create sharing link
Operation: Create Share Link
Path: /{{$now.format('YYYY-MM-DD')}}/
Expiration: 30 days

// 5. Send Email - Backup confirmation
To: admin@company.com
Subject: Daily Backup Complete
Body: |
  Backup completed successfully!
  Files: {{$items.length}} documents
  Location: {{$json.share_link}}
```

#### Example 2: Paperless Integration Bridge

```javascript
// Move documents from Seafile to Paperless for OCR processing

// 1. Seafile Node - List new files
Operation: List Directory
Library: Inbox
Path: /scans/

// 2. Loop Over Items
// For each file in the directory

// 3. Seafile Node - Download file
Operation: Download File
File ID: {{$json.id}}

// 4. Move Binary Data
// Prepare for Paperless

// 5. HTTP Request - Send to Paperless
Method: POST
URL: http://paperless:8000/api/documents/post_document/
Headers:
  Authorization: Token {{$credentials.paperless_token}}
Body: Binary file

// 6. Seafile Node - Move processed file
Operation: Move File
Source: /scans/{{$json.name}}
Destination: /processed/{{$now.format('YYYY-MM')}}/
```

#### Example 3: Team Collaboration Automation

```javascript
// Auto-create project folders with templates

// 1. Webhook Trigger - New project created
// From your project management system

// 2. Seafile Node - Create library
Operation: Create Library
Name: Project-{{$json.project_name}}
Description: {{$json.project_description}}

// 3. Seafile Node - Create folder structure
Paths: [
  "/Documents",
  "/Designs",
  "/Meeting Notes",
  "/Resources"
]

// 4. Seafile Node - Copy template files
Source Library: Templates
Destination: Project-{{$json.project_name}}

// 5. Seafile Node - Share with team
Operation: Share Library
Users: {{$json.team_members}}
Permission: rw

// 6. Send notifications to team
// Via email/Slack
```

### Mobile & WebDAV Access

**Mobile Apps:**
- **iOS:** [Seafile Pro](https://apps.apple.com/app/seafile-pro/id639202512)
- **Android:** [Seafile](https://play.google.com/store/apps/details?id=com.seafile.seadroid2)

**WebDAV Configuration:**

Windows:
```
URL: https://files.yourdomain.com/seafdav
Username: your-email@domain.com
Password: your-password
```

Mac Finder:
```
Go → Connect to Server
Server: https://files.yourdomain.com/seafdav
```

Linux:
```bash
# Install davfs2
sudo apt-get install davfs2

# Mount
sudo mount -t davfs https://files.yourdomain.com/seafdav /mnt/seafile
```

### Troubleshooting

**Cannot Login:**
```bash
# Check if Seafile is running
docker ps | grep seafile

# Check logs for errors
docker logs seafile --tail 100

# Reset admin password
docker exec -it seafile /opt/seafile/seafile-server-latest/reset-admin.sh
```

**Sync Issues:**
```bash
# Check seafile service status
docker exec seafile /opt/seafile/seafile-server-latest/seafile.sh status

# Restart services
docker compose restart seafile seafile-db

# Check database connection
docker logs seafile-mariadb --tail 50
```

**Storage Space:**
```bash
# Check used space
docker exec seafile df -h /shared

# Clean up deleted files (garbage collection)
docker exec seafile /opt/seafile/seafile-server-latest/seaf-gc.sh
```

### Performance Optimization

**For Large Deployments:**
- Enable memcached for better performance
- Configure Nginx for static file serving
- Use S3/MinIO for object storage backend
- Enable Elasticsearch for full-text search

**Backup Best Practices:**
- Regular database backups (MariaDB)
- Sync data directory to external storage
- Test restore procedures quarterly

### Resources

- **Official Documentation:** https://manual.seafile.com/
- **API Documentation:** https://manual.seafile.com/develop/web_api_v2.1/
- **Community Forum:** https://forum.seafile.com/
- **GitHub:** https://github.com/haiwen/seafile
- **Desktop Clients:** https://www.seafile.com/en/download/
- **n8n Community Node:** https://www.npmjs.com/package/n8n-nodes-seafile
