#!/bin/bash
# Report for gitea

echo
echo "================================= Gitea Git Server ===================="
echo
echo "Host: ${GITEA_HOSTNAME:-<hostname_not_set>}"
echo "SSH Port: ${GITEA_SSH_PORT:-2222}"
echo
echo "Access:"
echo "  Web UI: https://${GITEA_HOSTNAME:-<hostname_not_set>}"
echo "  SSH: ssh://git@${GITEA_HOSTNAME}:${GITEA_SSH_PORT}"
echo "  Internal: http://gitea:3000"
echo
echo "Initial Setup:"
echo "  1. Visit https://${GITEA_HOSTNAME}/install"
echo "  2. Database is pre-configured (PostgreSQL)"
echo "  3. Set Site Title and your domain"
echo "  4. Create admin account (first user = admin)"
echo
echo "SSH Clone Example:"
echo "  git clone ssh://git@${GITEA_HOSTNAME}:${GITEA_SSH_PORT}/username/repo.git"
echo
echo "n8n Integration:"
echo "  Webhooks: http://n8n:5678/webhook/gitea"
echo "  API: http://gitea:3000/api/v1"
echo
echo "Documentation: https://docs.gitea.com"
