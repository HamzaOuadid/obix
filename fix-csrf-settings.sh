#!/bin/bash

echo "Fixing CSRF and CORS settings in Django container..."

# Add necessary CSRF settings to Django settings.py
docker exec -it obix_backend_1 bash -c "cat > /tmp/fix_csrf.py << 'EOF'
import re

# Path to settings file
settings_file = '/app/debt_chatbot/settings.py'

with open(settings_file, 'r') as file:
    content = file.read()

# Check if CORS_ALLOW_CREDENTIALS is already set
if 'CORS_ALLOW_CREDENTIALS' not in content:
    print('Adding CORS_ALLOW_CREDENTIALS = True')
    # Find the CORS settings section and add the new setting
    if 'CORS_ALLOWED_ORIGINS' in content:
        content = content.replace('CORS_ALLOWED_ORIGINS', 'CORS_ALLOW_CREDENTIALS = True\n\nCORS_ALLOWED_ORIGINS')
    else:
        # If no CORS section exists, add it to the end of the file
        content += '\n\n# CORS settings\nCORS_ALLOW_CREDENTIALS = True\n'

# Check if CSRF_TRUSTED_ORIGINS is already set
if 'CSRF_TRUSTED_ORIGINS' not in content:
    print('Adding CSRF_TRUSTED_ORIGINS')
    trusted_origins = ['http://localhost:10000', 'http://localhost', 'http://157.230.65.142', 'https://157.230.65.142', 'http://localhost:4200']
    csrf_setting = '\n# CSRF settings\nCSRF_TRUSTED_ORIGINS = ' + str(trusted_origins) + '\n'
    
    # Add near the end of the file
    if '# CORS settings' in content:
        content = content.replace('# CORS settings', '# CSRF settings\nCSRF_TRUSTED_ORIGINS = ' + str(trusted_origins) + '\n\n# CORS settings')
    else:
        content += csrf_setting

# Check if CSRF_COOKIE_SAMESITE is already set
if 'CSRF_COOKIE_SAMESITE' not in content:
    print('Adding CSRF_COOKIE_SAMESITE = "Lax"')
    if 'CSRF_TRUSTED_ORIGINS' in content:
        content = content.replace('CSRF_TRUSTED_ORIGINS', 'CSRF_COOKIE_SAMESITE = "Lax"\nCSRF_COOKIE_SECURE = False\nCSRF_TRUSTED_ORIGINS')
    else:
        content += '\nCSRF_COOKIE_SAMESITE = "Lax"\nCSRF_COOKIE_SECURE = False\n'

# Update SESSION_COOKIE settings for cross-domain access
if 'SESSION_COOKIE_SAMESITE' not in content:
    print('Adding SESSION_COOKIE_SAMESITE = "Lax"')
    content += '\n# Session cookie settings\nSESSION_COOKIE_SAMESITE = "Lax"\nSESSION_COOKIE_SECURE = False\n'

# Write the updated content back to the file
with open(settings_file, 'w') as file:
    file.write(content)

print('CSRF and CORS settings updated successfully')
EOF"

echo "Running the CSRF fix script inside the container..."
docker exec -it obix_backend_1 python /tmp/fix_csrf.py

# Restart the Django container to apply changes
echo "Restarting the backend container..."
docker-compose restart backend

echo "Complete! CSRF and CORS settings have been updated." 