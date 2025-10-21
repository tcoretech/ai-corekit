cat > scripts/seafile-init.sh << 'EOF'
#!/bin/bash
# Fix for Seafile HTTPS/CSRF Bug - extract Hostname from SERVICE_URL
if [ -f /shared/seafile/conf/seahub_settings.py ]; then
  # Set SERVICE_URL to https
  sed -i 's|SERVICE_URL = "http://|SERVICE_URL = "https://|g' /shared/seafile/conf/seahub_settings.py
  
  # Extract Hostname from SERVICE_URL
  HOSTNAME=$(grep "SERVICE_URL" /shared/seafile/conf/seahub_settings.py | sed 's/.*https:\/\/\([^"]*\).*/\1/')
  
  # Set or update CSRF_TRUSTED_ORIGINS
  if grep -q "CSRF_TRUSTED_ORIGINS" /shared/seafile/conf/seahub_settings.py; then
    sed -i "s|CSRF_TRUSTED_ORIGINS = .*|CSRF_TRUSTED_ORIGINS = ['https://$HOSTNAME']|" /shared/seafile/conf/seahub_settings.py
  else
    echo "CSRF_TRUSTED_ORIGINS = ['https://$HOSTNAME']" >> /shared/seafile/conf/seahub_settings.py
  fi
fi
EOF

chmod +x scripts/seafile-init.sh
