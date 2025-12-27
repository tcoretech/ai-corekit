# 🔧 Gitea - Git Server

### What is Gitea?

Gitea is a lightweight, self-hosted Git service similar to GitHub or GitLab but with minimal resource requirements. It provides a complete DevOps platform with built-in CI/CD (Gitea Actions), package registry, project management tools, and code review features. Perfect for teams wanting full control over their code without external dependencies.

### Features

- **Git Hosting:** Full Git server with SSH and HTTPS support
- **Web UI:** Clean, responsive interface similar to GitHub
- **CI/CD:** Built-in Gitea Actions (GitHub Actions compatible)
- **Package Registry:** Host Docker, npm, PyPI, Maven packages
- **Code Review:** Pull requests with review tools
- **Issue Tracking:** Built-in issue tracker with labels and milestones
- **Wiki:** Project documentation support
- **Organizations:** Team and permission management
- **Webhooks:** Integration with external services
- **API:** Comprehensive REST API
- **2FA:** Two-factor authentication support
- **LFS:** Git Large File Storage support

### Initial Setup

**First Login to Gitea:**

1. Navigate to `https://git.yourdomain.com`
2. Initial setup wizard appears on first visit
3. Database settings are pre-configured - don't change
4. Modify these settings:
   - **Site Title:** Your Company Git
   - **SSH Server Port:** 2222 (important!)
   - **Gitea Base URL:** https://git.yourdomain.com
   - **Admin Account:** Create admin user (optional but recommended)
5. Click "Install Gitea"

**Post-Installation:**
```bash
# Add SSH key to your account
# Profile → Settings → SSH/GPG Keys → Add Key

# Clone via SSH (note port 2222)
git clone ssh://git@git.yourdomain.com:2222/username/repo.git

# Clone via HTTPS
git clone https://git.yourdomain.com/username/repo.git
```

### n8n Integration

**Create Gitea Webhook in Repository:**

1. Go to Repository → Settings → Webhooks
2. Add Webhook → Gitea
3. Target URL: `https://n8n.yourdomain.com/webhook/gitea`
4. Trigger Events: Choose what triggers the webhook
5. Active: ✓

**n8n Webhook Setup:**
```javascript
// Webhook Trigger
// Webhook URL: https://n8n.yourdomain.com/webhook/gitea

// Received data structure:
{
  "ref": "refs/heads/main",
  "commits": [...],
  "repository": {
    "name": "repo-name",
    "full_name": "user/repo-name",
    "clone_url": "..."
  },
  "pusher": {
    "email": "user@example.com",
    "username": "username"
  }
}
```

### Example Workflows

#### Example 1: Auto-Deploy on Push
```javascript
// Auto-deploy when code is pushed to main branch

// 1. Webhook Trigger - Gitea webhook

// 2. IF Node - Check if main branch
{{ $json.ref === 'refs/heads/main' }}

// 3. SSH Node - Pull and deploy
ssh user@server << 'EOF'
  cd /var/www/project
  git pull origin main
  docker compose up -d --build
  echo "Deployment complete"
EOF

// 4. Gitea API - Create deployment status
Method: POST
URL: https://git.yourdomain.com/api/v1/repos/{{$json.repository.full_name}}/statuses/{{$json.after}}
Headers:
  Authorization: token YOUR_GITEA_TOKEN
Body:
{
  "state": "success",
  "target_url": "https://app.yourdomain.com",
  "description": "Deployed successfully",
  "context": "continuous-deployment"
}

// 5. Slack Notification
Message: |
  ✅ Deployment Successful
  Repository: {{$json.repository.full_name}}
  Branch: main
  Deployed by: {{$json.pusher.username}}
```

#### Example 2: Issue Management Automation
```javascript
// Auto-assign issues and notify team

// 1. Webhook Trigger - Issue opened

// 2. Code Node - Determine assignee
const labels = $json.issue.labels;
let assignee = 'default-user';

if (labels.some(l => l.name === 'bug')) {
  assignee = 'qa-team';
} else if (labels.some(l => l.name === 'feature')) {
  assignee = 'dev-team';
} else if (labels.some(l => l.name === 'docs')) {
  assignee = 'docs-team';
}

return { assignee };

// 3. Gitea API - Assign issue
Method: PATCH
URL: https://git.yourdomain.com/api/v1/repos/{{$json.repository.full_name}}/issues/{{$json.issue.number}}
Headers:
  Authorization: token YOUR_GITEA_TOKEN
Body:
{
  "assignees": ["{{$node['Determine Assignee'].json.assignee}}"]
}

// 4. Send to Linear/Jira
// Create corresponding ticket in project management tool

// 5. Discord/Slack Notification
Channel: #issues
Message: |
  🐛 New Issue: {{$json.issue.title}}
  Repository: {{$json.repository.full_name}}
  Assigned to: {{$node['Determine Assignee'].json.assignee}}
  Link: {{$json.issue.html_url}}
```

#### Example 3: Release Automation
```javascript
// Automate release process with changelog

// 1. Webhook Trigger - Tag created

// 2. Gitea API - Get commits since last tag
Method: GET
URL: https://git.yourdomain.com/api/v1/repos/{{$json.repository.full_name}}/commits
Query Parameters:
  since: {{$json.previous_tag_date}}

// 3. Code Node - Generate changelog
const commits = $input.all();
let changelog = '# Release ' + $json.ref.replace('refs/tags/', '') + '\n\n';

const features = commits.filter(c => c.json.commit.message.startsWith('feat:'));
const fixes = commits.filter(c => c.json.commit.message.startsWith('fix:'));

if (features.length > 0) {
  changelog += '## Features\n';
  features.forEach(f => {
    changelog += `- ${f.json.commit.message.replace('feat: ', '')}\n`;
  });
}

if (fixes.length > 0) {
  changelog += '\n## Bug Fixes\n';
  fixes.forEach(f => {
    changelog += `- ${f.json.commit.message.replace('fix: ', '')}\n`;
  });
}

return { changelog };

// 4. Gitea API - Create release
Method: POST
URL: https://git.yourdomain.com/api/v1/repos/{{$json.repository.full_name}}/releases
Body:
{
  "tag_name": "{{$json.ref.replace('refs/tags/', '')}}",
  "name": "Release {{$json.ref.replace('refs/tags/', '')}}",
  "body": "{{$node['Generate Changelog'].json.changelog}}",
  "draft": false,
  "prerelease": false
}

// 5. Trigger Docker build
// Webhook to CI/CD system or Docker Hub
```

### Gitea Actions (CI/CD)

Enable in `app.ini`:
```ini
[actions]
ENABLED = true
```

Example `.gitea/workflows/ci.yml`:
```yaml
name: CI Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          npm install
          npm test
      
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .
          docker push myapp:${{ github.sha }}
```

### API Examples
```javascript
// Get user repositories
Method: GET
URL: https://git.yourdomain.com/api/v1/user/repos
Headers:
  Authorization: token YOUR_TOKEN

// Create repository
Method: POST
URL: https://git.yourdomain.com/api/v1/user/repos
Body:
{
  "name": "new-repo",
  "description": "Repository description",
  "private": false,
  "auto_init": true,
  "gitignores": "Node",
  "license": "MIT"
}

// Create issue
Method: POST
URL: https://git.yourdomain.com/api/v1/repos/owner/repo/issues
Body:
{
  "title": "Issue title",
  "body": "Issue description",
  "labels": [1, 2],
  "assignees": ["username"]
}
```

### Backup Strategy
```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/backup/gitea/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Database backup
docker exec gitea-db pg_dump -U gitea gitea > $BACKUP_DIR/gitea-db.sql

# Repository backup
docker exec gitea gitea dump -c /data/gitea/conf/app.ini -w /tmp
docker cp gitea:/tmp/gitea-dump-*.zip $BACKUP_DIR/

# Clean old backups (keep 30 days)
find /backup/gitea -type d -mtime +30 -exec rm -rf {} +
```

### Troubleshooting

#### SSH Connection Refused
```bash
# Check SSH port binding
docker ps | grep gitea
# Should show 0.0.0.0:2222->22/tcp

# Test SSH
ssh -T -p 2222 git@git.yourdomain.com

# Fix: Ensure using port 2222
git remote set-url origin ssh://git@git.yourdomain.com:2222/user/repo.git
```

#### Slow Performance
```bash
# Increase cache in app.ini
docker exec -it gitea vi /data/gitea/conf/app.ini

[cache]
ENABLED = true
ADAPTER = redis
HOST = redis:6379

# Restart
docker compose restart gitea
```

### Tips

1. **SSH Port:** Always use 2222 for SSH to avoid conflicts
2. **Backup:** Regular backups of database and repositories
3. **Actions:** Enable Gitea Actions for CI/CD
4. **Mirrors:** Can mirror from GitHub/GitLab automatically
5. **LFS:** Enable for large file support
6. **API Token:** Create tokens for automation
7. **Templates:** Create repo templates for consistency

### Resources

- **Documentation:** https://docs.gitea.com
- **API Reference:** https://docs.gitea.com/api/v1
- **Actions:** https://docs.gitea.com/usage/actions/overview
- **GitHub:** https://github.com/go-gitea/gitea
- **Community:** https://discourse.gitea.io
