#!/bin/bash
# Fix für Seafile HTTPS/CSRF Bug
if [ -f /shared/seafile/conf/seahub_settings.py ]; then
  # SERVICE_URL auf https setzen
  sed -i "s|SERVICE_URL = \"http://|SERVICE_URL = \"https://|g" /shared/seafile/conf/seahub_settings.py
  
  # Hostname aus SERVICE_URL extrahieren
  HOSTNAME=$(grep "SERVICE_URL" /shared/seafile/conf/seahub_settings.py | sed "s/.*https:\/\/\([^\"]*\).*/\1/")
  
  # CSRF_TRUSTED_ORIGINS setzen oder updaten
  if grep -q "CSRF_TRUSTED_ORIGINS" /shared/seafile/conf/seahub_settings.py; then
    sed -i "s|CSRF_TRUSTED_ORIGINS = .*|CSRF_TRUSTED_ORIGINS = [\"https://$HOSTNAME\"]|" /shared/seafile/conf/seahub_settings.py
  else
    echo "CSRF_TRUSTED_ORIGINS = [\"https://$HOSTNAME\"]" >> /shared/seafile/conf/seahub_settings.py
  fi
fi
