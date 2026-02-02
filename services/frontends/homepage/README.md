# 🏠 Homepage - Service Dashboard

### What is Homepage?

Homepage is a modern, fully customizable dashboard that provides a unified view of all your services, Docker containers, and system resources. Unlike traditional dashboards that require authentication, Homepage is designed as a public-facing or internal dashboard that automatically discovers and displays your running services with real-time status updates, making it perfect for quick system overviews and service monitoring.

### Features

- **Automatic Service Discovery:** Detects running Docker containers
- **Real-time Status Monitoring:** Shows service health and availability
- **Resource Widgets:** CPU, RAM, disk usage at a glance
- **Docker Integration:** Container stats and management
- **Customizable Layout:** Organize services by categories
- **Search Integration:** Built-in search with SearXNG support
- **Weather Widget:** Local weather information
- **No Authentication:** Designed for quick access (use behind VPN if needed)
- **Responsive Design:** Works on mobile and desktop
- **Custom CSS/JS:** Full customization support

### Initial Setup

**First Access to Homepage:**

1. Navigate to `https://dashboard.yourdomain.com`
2. No login required - dashboard is publicly accessible
3. Services are auto-populated by `generate_homepage_config.sh`
4. Customize layout by editing config files

**Manual Service Configuration:**
```bash
# Edit services configuration
nano homepage_config/services.yaml

# Edit general settings
nano homepage_config/settings.yaml

# Edit widgets
nano homepage_config/widgets.yaml

# Restart to apply changes
corekit restart homepage
```

### Configuration Files

#### services.yaml Structure
```yaml
- Category Name:
    - Service Name:
        href: https://service.yourdomain.com
        icon: service-icon.svg
        description: Service description
        widget:
          type: docker
          container: container-name
          
    - Another Service:
        href: https://another.yourdomain.com
        icon: si-github
        description: Another description
```

#### widgets.yaml Configuration
```yaml
# System Resources
- resources:
    cpu: true
    memory: true
    disk: /
    uptime: true

# Docker Stats
- docker:
    type: docker
    socket: /var/run/docker.sock

# Search Widget
- search:
    provider: searxng
    url: http://searxng:8080
    target: _blank

# Weather (optional)
- weather:
    latitude: 51.5074
    longitude: -0.1278
    units: metric
```

#### settings.yaml Options
```yaml
title: AI CoreKit Dashboard
theme: dark
color: slate
layout: grid
headerStyle: boxed

providers:
  searxng:
    url: http://searxng:8080

hideVersion: true
disableCollapse: false
```

### Auto-Configuration Script

The `generate_homepage_config.sh` script automatically:
- Detects all running containers
- Creates service entries with correct URLs
- Groups services by category
- Updates on every run
```bash
# Regenerate configuration
sudo bash scripts/generate_homepage_config.sh

# Run after adding new services
sudo bash scripts/update.sh
```

### Custom Icons

Homepage supports multiple icon sources:

1. **Simple Icons:** Use `si-` prefix (e.g., `si-github`)
2. **Material Design Icons:** Use `mdi-` prefix
3. **Custom SVG:** Place in `homepage_config/icons/`
4. **Service Icons:** Built-in icons for popular services

### Docker Integration
```yaml
# In services.yaml - add widget to show container stats
- Service Name:
    widget:
      type: docker
      container: container-name
      server: docker-socket  # defined in docker.yaml
```

### Troubleshooting

#### Services Not Showing
```bash
# Regenerate configuration
sudo bash scripts/generate_homepage_config.sh

# Check if service is running
docker ps | grep service-name

# Check Homepage logs
docker logs homepage --tail 50
```

#### Host Validation Error
```bash
# Already fixed in docker-compose.yml with:
HOMEPAGE_ALLOWED_HOSTS=*

# If still issues, check Caddy
docker logs caddy | grep dashboard
```

#### Docker Stats Not Working
```bash
# Verify socket mount
docker exec homepage ls -la /var/run/docker.sock

# Check docker.yaml config
cat homepage_config/docker.yaml
```

### Tips

1. **Security:** Since no auth, use behind VPN or add basic auth in Caddy
2. **Categories:** Organize services logically for better overview
3. **Icons:** Use Simple Icons for consistent look
4. **Updates:** Run generate script after adding services
5. **Custom CSS:** Add custom styles in `custom.css`

### Resources

- **Documentation:** https://gethomepage.dev/latest/
- **Icons:** https://github.com/walkxcode/dashboard-icons
- **GitHub:** https://github.com/gethomepage/homepage
- **Simple Icons:** https://simpleicons.org/
