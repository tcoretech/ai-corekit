#!/bin/bash
# Report for vikunja

echo
echo "================================= Vikunja ============================="
echo
echo "Host: ${VIKUNJA_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access URL: https://${VIKUNJA_HOSTNAME:-<hostname_not_set>}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "First Steps:"
echo "  1. Open the URL above in your browser"
echo "  2. Click 'Register' to create your first account"
echo "  3. This first account will have admin privileges"
echo "  4. Start creating projects and tasks"
echo
echo "n8n Integration:"
echo "  Base URL: http://vikunja:3456/api/v1"
echo "  Auth: Get API token from User Settings after login"
echo "  Docs: https://vikunja.io/docs/api/"
echo
echo "Mobile Apps:"
echo "  iOS: App Store - 'Vikunja Cloud'"
echo "  Android: Play Store - 'Vikunja'"
echo "  PWA: Use the web app on mobile (installable)"
echo
echo "Import Your Data:"
echo "  From: Todoist, Trello, Microsoft To-Do, Asana (CSV)"
echo "  Go to: Settings -> Import after login"
echo
echo "CalDAV Support:"
echo "  URL: https://${VIKUNJA_HOSTNAME:-<hostname>}/dav"
echo "  For calendar apps like Thunderbird, Apple Calendar"
echo
echo "Documentation: https://vikunja.io/docs"
echo "Community: https://community.vikunja.io"
