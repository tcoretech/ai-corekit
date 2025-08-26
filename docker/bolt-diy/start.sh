# Unser finales start.sh
cat > docker/bolt-diy/start.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "==============================================="
echo "Starting bolt.diy"
echo "==============================================="
echo "External Access: https://${BOLT_HOSTNAME:-localhost}"
echo "Internal Port: 5173"
echo "Mode: Development Server (Standard for bolt.diy)"
echo ""
echo "NOTE: bolt.diy typically runs in dev mode even in"
echo "      production due to WebContainers API requirements."
echo "      This is normal and works well behind Caddy."
echo "==============================================="

# Start Vite dev server (standard for bolt.diy deployments)
exec pnpm run dev --host 0.0.0.0
EOF

chmod +x docker/bolt-diy/start.sh
