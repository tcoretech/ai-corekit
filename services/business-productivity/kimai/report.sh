#!/bin/bash
# Report for kimai

echo
echo "================================= Kimai Time Tracking =================="
echo
echo "🌐 Access URL: https://${KIMAI_HOSTNAME:-<hostname_not_set>}"
echo
echo "👤 Kimai Admin Account:"
echo "  Email: ${KIMAI_ADMIN_EMAIL:-<not_set_in_env>}"
echo "  Password: ${KIMAI_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "🔌 Integration Endpoints:"
echo "  External API: https://${KIMAI_HOSTNAME:-<hostname_not_set>}/api"
echo "  Internal (n8n): http://kimai:8001/api"
echo
echo "👥 User Management:"
echo "  - First user is Super Admin"
echo "  - Add users: Settings → Users"
echo "  - Roles: User, Teamlead, Admin, Super-Admin"
echo
echo "📱 Mobile Apps:"
echo "  iOS: https://apps.apple.com/app/kimai-mobile/id1463807227"
echo "  Android: https://play.google.com/store/apps/details?id=de.cloudrizon.kimai"
echo
echo "📚 Documentation: https://www.kimai.org/documentation/"
echo "🔧 API Docs: https://${KIMAI_HOSTNAME:-<hostname_not_set>}/api/doc"
