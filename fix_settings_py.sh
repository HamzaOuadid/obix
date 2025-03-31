#!/bin/bash

# Extremely direct settings.py fix - just the essentials
echo "Applying direct fix to settings.py..."

# Direct path to the settings file
SETTINGS_FILE="/app/debt_chatbot/settings.py"

# Method 1: Fix line 242 directly
docker exec obix_backend_1 bash -c "sed -i '242s/.*PATCHED_WSGI_APPLICATION.*/}/' $SETTINGS_FILE"

# Method 2: As a backup, remove any line with PATCHED_WSGI_APPLICATION
docker exec obix_backend_1 bash -c "sed -i '/PATCHED_WSGI_APPLICATION/d' $SETTINGS_FILE"

# Restart the backend
echo "Restarting backend..."
docker restart obix_backend_1

echo "Fix applied. Check 'docker logs obix_backend_1'" 