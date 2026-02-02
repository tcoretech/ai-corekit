#!/bin/bash
# Report for homepage

echo
echo "================================= Homepage Dashboard =================="
echo
echo "Host: ${HOMEPAGE_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  External (HTTPS): https://${HOMEPAGE_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://homepage:3000"
echo
echo "⚠️  Note: Homepage has NO authentication by design!"
echo "  It's meant as a public dashboard for your services"
echo
echo "Configuration:"
echo "  Config Directory: ./homepage_config/"
echo "  Services: Edit homepage_config/services.yaml"
echo "  Bookmarks: Edit homepage_config/bookmarks.yaml"
echo "  Settings: Edit homepage_config/settings.yaml"
echo
echo "Docker Integration:"
echo "  Homepage can show container status"
echo "  Docker socket is mounted read-only"
echo
echo "Documentation: https://gethomepage.dev"
