#!/bin/bash
# Report for kopia

echo
echo "================================= Kopia Backup ========================"
echo
echo "Host: ${KOPIA_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  Web UI: https://${KOPIA_HOSTNAME:-<hostname_not_set>}"
echo "  Internal API: http://kopia:51515"
echo
echo "Kopia Server Credentials:"
echo "  Username: ${KOPIA_UI_USERNAME:-admin}"
echo "  Password: ${KOPIA_UI_PASSWORD:-<not_set_in_env>}"
echo
echo "Repository Configuration:"
echo "  Encryption Password: ${KOPIA_PASSWORD:-<not_set_in_env>}"
echo "  Storage Backend: Nextcloud WebDAV"
echo "  Nextcloud URL: ${NEXTCLOUD_WEBDAV_URL:-<not_configured>}"
echo "  Nextcloud User: ${NEXTCLOUD_USERNAME:-<not_configured>}"
echo
echo "Backup Sources:"
echo "  - Docker Volumes: /data/docker-volumes (read-only)"
echo "  - Shared Directory: /data/shared (read-only)"
echo "  - AI CoreKit Config: /data/ai-corekit (read-only)"
echo
echo "First Steps:"
echo "  1. Access https://${KOPIA_HOSTNAME:-<hostname_not_set>}"
echo "  2. Login with Kopia UI credentials"
echo "  3. Create WebDAV repository to Nextcloud"
echo "  4. Configure backup policies"
echo "  5. Create first snapshots"
echo
echo "CLI Commands:"
echo "  docker exec kopia kopia snapshot create /data/docker-volumes"
echo "  docker exec kopia kopia snapshot list"
echo "  docker exec kopia kopia policy set /data --compression=pgzip"
echo
echo "Documentation: https://kopia.io/docs/"
