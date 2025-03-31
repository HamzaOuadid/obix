#!/bin/bash
# Script to fix Django ALLOWED_HOSTS directly in the running container

echo "Creating a Python script to update ALLOWED_HOSTS inside the container..."

# Create the Python script inside the container
docker exec obix_backend_1 bash -c "cat > /tmp/fix_hosts.py << 'EOF'
# Script to update Django ALLOWED_HOSTS
import os
import re

# Find the Django settings file
settings_file = '/app/debt_chatbot/settings.py'

print(f'Reading settings file: {settings_file}')
# Read the file
with open(settings_file, 'r') as f:
    content = f.read()

# Check if the IP is already in ALLOWED_HOSTS
if '157.230.65.142' not in content:
    print('Adding IP to ALLOWED_HOSTS...')
    # Replace the ALLOWED_HOSTS array
    pattern = r'ALLOWED_HOSTS = \[[^\]]*\]'
    new_hosts = \"ALLOWED_HOSTS = [\\n    'obix-chatbot-backend.onrender.com',  # Render backend\\n    'obix-chatbot.onrender.com',          # Alternative Render domain\\n    'localhost', \\n    '127.0.0.1',\\n    '157.230.65.142',                     # Digital Ocean Droplet IP\\n]\"
    content = re.sub(pattern, new_hosts, content)

    # Also update CORS_ALLOWED_ORIGINS
    pattern = r'CORS_ALLOWED_ORIGINS = \[[^\]]*\]'
    new_cors = \"CORS_ALLOWED_ORIGINS = [\\n    \\\"http://localhost:4200\\\",  # Angular dev server\\n    \\\"http://127.0.0.1:4200\\\",\\n    \\\"https://obix-chatbot-frontend.onrender.com\\\",  # Render frontend\\n    \\\"https://obix-chatbot.onrender.com\\\",  # Alternative Render domain\\n    \\\"http://157.230.65.142\\\",  # Digital Ocean server\\n    \\\"https://157.230.65.142\\\"  # Digital Ocean server with HTTPS\\n]\"
    content = re.sub(pattern, new_cors, content)

    # Also update CSRF_TRUSTED_ORIGINS
    pattern = r'CSRF_TRUSTED_ORIGINS = \[[^\]]*\]'
    new_csrf = \"CSRF_TRUSTED_ORIGINS = [\\n    \\\"http://localhost:4200\\\", \\n    \\\"http://127.0.0.1:4200\\\",\\n    \\\"https://obix-chatbot-frontend.onrender.com\\\",  # Render frontend\\n    \\\"https://obix-chatbot.onrender.com\\\",  # Alternative Render domain\\n    \\\"http://157.230.65.142\\\",  # Digital Ocean server\\n    \\\"https://157.230.65.142\\\"  # Digital Ocean server with HTTPS\\n]\"
    content = re.sub(pattern, new_csrf, content)

    # Write the file back
    with open(settings_file, 'w') as f:
        f.write(content)
    print('Settings updated successfully')
else:
    print('IP already in ALLOWED_HOSTS')

print('Done!')
EOF"

echo "Running the Python script inside the container..."
docker exec obix_backend_1 python /tmp/fix_hosts.py

echo "Restarting the backend container..."
docker-compose restart backend

echo "Done! The backend should now accept requests from the server IP."
echo "Try logging in again." 