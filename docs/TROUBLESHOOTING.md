# 🔧 Troubleshooting Guide

This guide covers common issues and solutions for AI CoreKit.

## Table of Contents
- [Installation Troubleshooting](#installation-troubleshooting)
- [Update Troubleshooting](#update-troubleshooting)
- [General Troubleshooting](#general-troubleshooting)
- [Database Issues](#database-issues)
- [Performance Tuning](#performance-tuning)

---

## Installation Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
sudo systemctl status docker

# Check specific service logs
corekit logs [service-name] --tail 50

# Common issues:
# - Not enough RAM: Reduce services or upgrade server
# - Port conflicts: Check if ports 80/443 are free
# - DNS not ready: Wait 15 minutes for propagation
```

### SSL Certificate Errors

```bash
# Caddy might take a few minutes to get certificates
# Check Caddy logs:
corekit logs caddy --tail 50

# If problems persist:
# 1. Verify DNS is correct
# 2. Check firewall allows 80/443
# 3. Restart Caddy
corekit restart caddy
```

### Firewall Configuration

AI CoreKit does **not** configure the firewall automatically during `corekit init` to prevent accidental SSH lockouts.

**To configure firewall with safety checks:**
```bash
corekit system --close-ports
```

This command will:
- Require multiple confirmations
- Auto-detect your SSH port
- Preserve SSH, HTTP (80), and HTTPS (443) access
- Block all other incoming connections by default

**If you need to allow additional ports for services:**
```bash
# Allow a specific port
sudo ufw allow <port>/tcp

# Check firewall status
sudo ufw status

# Examples for common services:
# Jitsi: sudo ufw allow 10000/udp
# LiveKit: sudo ufw allow 50000:50100/udp
# Custom SSH: sudo ufw allow 2222/tcp
```

**If locked out after firewall configuration:**
- Use physical/console access to your server
- Run: `sudo ufw disable` to disable the firewall
- Reconfigure with correct ports before re-enabling

### Docker Issues

```bash
# Restart Docker daemon
sudo systemctl restart docker

# Reset Docker network (if needed)
docker network prune -f

# Restart all services
cd ai-corekit
corekit restart
```

---

## Update Troubleshooting

### Services Won't Start After Update

```bash
# Check logs for specific error
corekit logs [service-name] --tail 100

# Common fixes:
# 1. Recreate service
corekit up --force-recreate [service-name]

# 2. Clear cache and restart
corekit down
docker system prune -f
corekit up

# 3. Restore from backup if needed
```

### Database Connection Errors

```bash
# PostgreSQL not starting
corekit logs postgres --tail 100

# Common causes:
# - Incompatible data format (see PostgreSQL section)
# - Corrupted data (restore from backup)
# - Insufficient disk space (check with df -h)
```

### Port Conflicts After Update

```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting service
sudo systemctl stop [service-name]

# Or change port in .env
nano .env
# Change PORT_VARIABLE to different port
```

---

## General Troubleshooting

### Server Requirements Check

Before troubleshooting, ensure your server meets the minimum requirements:

```bash
# Check OS version
lsb_release -a
# Should show: Ubuntu 24.04 LTS (64-bit)

# Check RAM
free -h
# Minimum: 4GB total RAM
# Recommended: 8GB+ for multiple services

# Check disk space
df -h
# Minimum: 30GB free on /
# Recommended: 50GB+ for logs and data

# Check CPU cores
nproc
# Minimum: 2 cores
# Recommended: 4+ cores

# Check if virtualization enabled (for Docker)
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Check Docker version
docker --version
# Should be Docker version 20.10+ or higher

docker compose version
# Should be Docker Compose version v2.0+ or higher
```

### Checking Service Health

**View All Running Containers:**
```bash
# See all containers and their status
docker ps -a
# Status should be "Up" for running services
```

**Check Specific Service Logs:**
```bash
# View last 50 lines of logs
docker logs [service-name] --tail 50

# Follow logs in real-time
docker logs [service-name] --follow

# Search logs for errors
docker logs [service-name] 2>&1 | grep -i error
```

**Restart Services:**
```bash
# Restart a specific service
docker compose restart [service-name]

# Restart all services
docker compose restart

# Stop and start (more thorough than restart)
docker compose stop [service-name]
docker compose start [service-name]
```

### Common Diagnostic Commands

**Check Environment Variables:**
```bash
# View .env file
cat .env

# Verify variables are loaded in container
docker exec n8n env | grep N8N_
```

**Test Network Connectivity:**
```bash
# Ping between containers
docker exec n8n ping postgres
docker exec n8n ping supabase-db
docker exec caddy ping n8n
```

**Check DNS Configuration:**
```bash
# Verify A record for your domain
nslookup yourdomain.com

# Should point to your VPS IP
```

**Verify SSL Certificates:**
```bash
# Check Caddy's certificate status
docker exec caddy caddy list-certificates
```

**Monitor Resource Usage:**
```bash
# Real-time resource monitoring
docker stats
```

---

## Database Issues

### PostgreSQL Connection Troubleshooting

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Test connection from host
docker exec -it postgres psql -U postgres -c "SELECT version();"

# Test connection from another container
docker exec n8n psql -h postgres -U postgres -c "SELECT 1;"

# Check PostgreSQL logs for errors
docker logs postgres --tail 100
```

### Supabase Database Connection

```bash
# Check all Supabase components
docker ps | grep supabase

# Critical components:
# - supabase-db (PostgreSQL)
# - supabase-kong (API Gateway)
# - supabase-auth
# - supabase-rest
# - supabase-storage

# Restart Supabase stack
docker compose stop supabase-db supabase-kong supabase-auth supabase-rest supabase-storage
docker compose start supabase-db
# Wait 10 seconds for DB to be ready
sleep 10
docker compose start supabase-kong supabase-auth supabase-rest supabase-storage
```

---

## Log Collection for Support

If you need to create a GitHub issue or ask for help, collect diagnostic information:

```bash
# Create diagnostic report
mkdir ~/corekit-diagnostics
cd ~/corekit-diagnostics

# 1. System information
uname -a > system-info.txt
lsb_release -a >> system-info.txt
free -h >> system-info.txt
df -h >> system-info.txt
docker --version >> system-info.txt
docker compose version >> system-info.txt

# 2. Container status
docker ps -a > container-status.txt

# 3. Other logs
docker logs caddy --tail 200 > caddy-logs.txt 2>&1
docker logs n8n --tail 200 > n8n-logs.txt 2>&1
docker logs postgres --tail 200 > postgres-logs.txt 2>&1

# Create archive
cd ~
tar -czf corekit-diagnostics.tar.gz corekit-diagnostics/
```
