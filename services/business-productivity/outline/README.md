# 📚 Outline - Team Wiki

### What is Outline?

Outline is a modern, fast, and collaborative wiki and knowledge base for teams. It features a beautiful editor, real-time collaboration, powerful search, and integrations with Slack and other tools. With our self-hosted setup, it includes Dex as the identity provider, making it completely independent of external authentication services.

### Features

- **Real-time Collaboration:** Multiple users can edit simultaneously
- **Markdown Support:** Write in Markdown with live preview
- **Slash Commands:** Quick formatting with / commands
- **Collections:** Organize documents in nested structures
- **Search:** Full-text search across all documents
- **Permissions:** Granular access control
- **Templates:** Document templates for consistency
- **API Access:** Complete REST API
- **Export:** PDF, Markdown, HTML export
- **Dark Mode:** Built-in dark theme
- **Mobile Apps:** iOS and Android apps available
- **Self-hosted Auth:** Using Dex identity provider

### Initial Setup

**First Login to Outline:**

1. Navigate to `https://outline.yourdomain.com`
2. Click "Continue with Login"
3. You'll be redirected to Dex login page
4. Login with admin credentials:
   - Email: Check `DEX_ADMIN_EMAIL` in `.env`
   - Password: Check `DEX_ADMIN_PASSWORD` in `.env`
5. After first login, create your workspace:
   - Workspace name
   - Workspace URL (subdomain)

**Create Your First Collection:**

1. Click "New Collection"
2. Name your collection (e.g., "Engineering", "Product")
3. Set permissions (Private/Public)
4. Start creating documents

### User Management with Dex

**Add New Users:**

1. Edit Dex configuration:
```bash
nano dex/config.yaml
```

2. Add user to staticPasswords:
```yaml
staticPasswords:
- email: "admin@example.com"
  hash: "$2a$10$..."  # existing admin
  username: "admin"
  userID: "08a8684b-db88-4b73-90a9-3cd1661f5466"
- email: "newuser@example.com"
  hash: "$2a$10$..."  # generate with: htpasswd -bnBC 10 "" password | tr -d ':\n'
  username: "newuser"
  userID: "generate-uuid-here"
```

3. Restart Dex:
```bash
corekit restart dex
```

### n8n Integration

**Generate API Token:**

1. Click on your avatar → Settings
2. Go to API Tokens
3. Create New Token
4. Name: "n8n Integration"
5. Copy token

**n8n HTTP Request Setup:**
```javascript
// Base configuration for all Outline API calls
Method: GET/POST/PATCH
URL: http://outline:3000/api/[endpoint]
Headers:
  Authorization: Bearer YOUR_TOKEN
  Content-Type: application/json
```

### Example Workflows

#### Example 1: Auto-Documentation from Issues
```javascript
// Create documentation from resolved GitHub/Gitea issues

// 1. Trigger - Issue closed with 'documented' label

// 2. HTTP Request - Search if doc exists
Method: POST
URL: http://outline:3000/api/documents.search
Headers:
  Authorization: Bearer YOUR_TOKEN
Body:
{
  "query": "{{$json.issue.title}}"
}

// 3. IF - Check if document exists
{{ $json.data.length === 0 }}

// 4. HTTP Request - Create document
Method: POST
URL: http://outline:3000/api/documents.create
Body:
{
  "collectionId": "your-collection-id",
  "title": "{{$json.issue.title}}",
  "text": "# {{$json.issue.title}}\n\n## Problem\n{{$json.issue.body}}\n\n## Solution\n{{$json.issue.solution}}\n\n## References\n- Issue: #{{$json.issue.number}}\n- Author: {{$json.issue.user.login}}\n- Date: {{$now.format('yyyy-MM-dd')}}",
  "publish": true
}

// 5. HTTP Request - Add to correct collection
Method: POST
URL: http://outline:3000/api/documents.move
Body:
{
  "id": "{{$node['Create Document'].json.data.id}}",
  "collectionId": "{{$json.issue.labels.includes('bug') ? 'bugs-collection-id' : 'features-collection-id'}}"
}

// 6. Comment on Issue
Method: POST
URL: your-git-server/api/issues/{{$json.issue.number}}/comments
Body:
{
  "body": "📚 Documentation created: {{$node['Create Document'].json.data.url}}"
}
```

#### Example 2: Knowledge Base Sync
```javascript
// Sync Outline with external knowledge base

// 1. Schedule Trigger - Daily at 2 AM

// 2. HTTP Request - Get all collections
Method: GET
URL: http://outline:3000/api/collections.list
Headers:
  Authorization: Bearer YOUR_TOKEN

// 3. Loop through collections

// 4. HTTP Request - Get documents in collection
Method: POST
URL: http://outline:3000/api/documents.list
Body:
{
  "collectionId": "{{$json.id}}",
  "limit": 100
}

// 5. Loop through documents

// 6. Code Node - Check for updates
const lastSync = new Date($json.lastSyncedAt || 0);
const lastUpdate = new Date($json.updatedAt);

if (lastUpdate > lastSync) {
  return {
    json: {
      ...$json,
      needsSync: true
    }
  };
}

// 7. HTTP Request - Export document
Method: POST
URL: http://outline:3000/api/documents.export
Body:
{
  "id": "{{$json.id}}",
  "format": "markdown"
}

// 8. Upload to external system
// GitHub, GitLab, Confluence, etc.

// 9. HTTP Request - Update sync timestamp
Method: POST
URL: http://outline:3000/api/documents.update
Body:
{
  "id": "{{$json.id}}",
  "lastSyncedAt": "{{$now.toISO()}}"
}
```

#### Example 3: AI-Enhanced Documentation
```javascript
// Use AI to improve and expand documentation

// 1. Trigger - Document created or updated

// 2. HTTP Request - Get document content
Method: POST
URL: http://outline:3000/api/documents.info
Body:
{
  "id": "{{$json.documentId}}"
}

// 3. OpenAI Node - Analyze and suggest improvements
Prompt: |
  Analyze this documentation and suggest improvements:
  
  {{$json.data.text}}
  
  Provide:
  1. Missing sections
  2. Clarity improvements
  3. Additional examples
  4. Related topics

// 4. Code Node - Parse AI suggestions
const suggestions = $json.choices[0].message.content;
const sections = suggestions.split('\n\n');

return {
  json: {
    documentId: $('Get Document').json.data.id,
    suggestions: sections,
    improvementScore: calculateScore(suggestions)
  }
};

// 5. IF - Significant improvements available
{{ $json.improvementScore > 0.7 }}

// 6. HTTP Request - Create draft with improvements
Method: POST
URL: http://outline:3000/api/documents.create
Body:
{
  "collectionId": "{{$('Get Document').json.data.collectionId}}",
  "parentDocumentId": "{{$('Get Document').json.data.id}}",
  "title": "{{$('Get Document').json.data.title}} (AI Enhanced)",
  "text": "{{$node['Format Improvements'].json.enhancedText}}",
  "publish": false
}

// 7. Notification
Send notification to document author about AI suggestions
```

### API Examples

#### Document Operations
```javascript
// List documents
Method: POST
URL: http://outline:3000/api/documents.list
Body:
{
  "collectionId": "collection-id",
  "limit": 25,
  "offset": 0
}

// Create document
Method: POST
URL: http://outline:3000/api/documents.create
Body:
{
  "collectionId": "collection-id",
  "title": "Document Title",
  "text": "# Document Content\n\nMarkdown content here",
  "publish": true
}

// Update document
Method: POST
URL: http://outline:3000/api/documents.update
Body:
{
  "id": "document-id",
  "title": "Updated Title",
  "text": "Updated content"
}

// Search documents
Method: POST
URL: http://outline:3000/api/documents.search
Body:
{
  "query": "search terms",
  "collectionId": "optional-collection-id",
  "limit": 10
}
```

#### Collection Management
```javascript
// Create collection
Method: POST
URL: http://outline:3000/api/collections.create
Body:
{
  "name": "New Collection",
  "description": "Collection description",
  "color": "#4285F4",
  "private": false
}

// Update permissions
Method: POST
URL: http://outline:3000/api/collections.update
Body:
{
  "id": "collection-id",
  "permission": "read_write"  // or "read"
}
```

### Backup and Export
```bash
#!/bin/bash
# Backup Outline data

# Export all documents via API
TOKEN="your-outline-token"
BACKUP_DIR="/backup/outline/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Get all collections
curl -H "Authorization: Bearer $TOKEN" \
  http://outline:3000/api/collections.list \
  -o $BACKUP_DIR/collections.json

# Export each collection
for collection_id in $(jq -r '.data[].id' $BACKUP_DIR/collections.json); do
  curl -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"collectionId\": \"$collection_id\", \"format\": \"markdown\"}" \
    http://outline:3000/api/collections.export \
    -o $BACKUP_DIR/collection_$collection_id.zip
done

# Backup PostgreSQL
docker exec outline-postgres pg_dump -U outline outline \
  > $BACKUP_DIR/outline-db.sql

# Backup MinIO data
docker run --rm \
  -v ${PROJECT_NAME:-localai}_outline_minio_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/minio-data.tar.gz /data
```

### Troubleshooting

#### Authentication Failed
```bash
# Check Dex is running
docker ps | grep dex

# Check Dex logs
docker logs dex --tail 50

# Verify redirect URLs in Dex config
grep redirectURIs dex/config.yaml

# Test Dex discovery
curl https://auth.yourdomain.com/.well-known/openid-configuration
```

#### Secret Key Error
```bash
# Ensure SECRET_KEY is 64 hex characters
grep OUTLINE_SECRET_KEY .env | cut -d'"' -f2 | wc -c
# Should output 65 (64 chars + newline)

# Regenerate if needed
sed -i "s/^OUTLINE_SECRET_KEY=.*/OUTLINE_SECRET_KEY=\"$(openssl rand -hex 32)\"/" .env
sed -i "s/^OUTLINE_UTILS_SECRET=.*/OUTLINE_UTILS_SECRET=\"$(openssl rand -hex 32)\"/" .env

# Restart Outline
corekit restart outline
```

#### Database Connection Issues
```bash
# Check PostgreSQL is running
docker ps | grep outline-postgres

# Test connection
docker exec outline-postgres psql -U outline -d outline -c "SELECT 1;"

# Check Outline env
docker exec outline printenv | grep DATABASE_URL
```

#### MinIO S3 Storage Issues
```bash
# Access MinIO admin
# https://outline-s3-admin.yourdomain.com
# Username: minio
# Password: check OUTLINE_MINIO_ROOT_PASSWORD in .env

# Check if bucket exists
docker exec outline-minio mc ls local/outline

# Create bucket if missing
docker exec outline-minio mc mb local/outline
```

#### Dex Config File is a Directory Instead of File

This can happen after updates or manual interventions. Docker remembers mount points and won't automatically switch between file and directory types.

**Symptoms:**
```
error: failed to read /etc/dex/config.yaml: read /etc/dex/config.yaml: is a directory
```

**Solution:**
```bash
# Check if config.yaml is wrongly a directory
ls -la dex/
# If config.yaml shows as directory (drwxr-xr-x), fix it:

# Remove the directory
sudo rm -rf dex/config.yaml

# Regenerate the config file
sudo bash scripts/setup_dex_config.sh

# Verify it's now a file
file dex/config.yaml
# Should output: "dex/config.yaml: ASCII text"

# IMPORTANT: Container must be recreated, not just restarted
corekit stop dex
corekit rm -f dex
corekit up -d dex

# Verify Dex is running
docker logs dex --tail 10
```

**Why this happens:**
- Docker creates directories for missing mount points on first run
- Accidental trailing slash in copy commands (`cp file destination/`)
- Manual `mkdir` instead of file creation
- Docker caches mount point types and requires container recreation to update

### Tips

1. **Collections:** Organize by team or topic
2. **Templates:** Create templates for consistent documentation
3. **Permissions:** Use groups for easier permission management
4. **Search:** Use quotes for exact matches
5. **Markdown:** Learn keyboard shortcuts for faster editing
6. **API:** Use API for automation and integrations
7. **Export:** Regular exports for backup
8. **Slash Commands:** Type / for quick formatting options
9. **Container Recreation:** When changing mount types (file↔directory), always recreate the container, not just restart

### Resources

- **Documentation:** https://docs.getoutline.com
- **API Reference:** https://docs.getoutline.com/developers
- **GitHub:** https://github.com/outline/outline
- **Community:** https://github.com/outline/outline/discussions
- **Keyboard Shortcuts:** https://docs.getoutline.com/s/doc/keyboard-shortcuts
- **Dex Documentation:** https://dexidp.io/docs
