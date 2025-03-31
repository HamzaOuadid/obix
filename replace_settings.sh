#!/bin/bash

# Brute force fix by creating a fixed version of settings.py
echo "Creating fixed settings.py file..."

# Get the original file and create a fixed version by filtering out the problematic line
docker exec debt-backend-1 cat /app/debt_chatbot/settings.py > original_settings.py

# Create a fixed version by removing the problematic line
grep -v "PATCHED_WSGI_APPLICATION" original_settings.py > fixed_settings.py

# Copy the fixed file back to the container
echo "Copying fixed settings.py to container..."
docker cp fixed_settings.py debt-backend-1:/app/debt_chatbot/settings.py

# Verify the fix
echo "Verifying fix..."
docker exec debt-backend-1 grep -c "PATCHED_WSGI_APPLICATION" /app/debt_chatbot/settings.py || echo "Fix verified: problematic line removed"

# Restart the backend container
echo "Restarting backend container..."
docker restart debt-backend-1

# Clean up temporary files
rm original_settings.py fixed_settings.py

echo "Fix applied. The backend should restart successfully now." 