#!/bin/bash

# Minimal sed-based fix for settings.py
echo "Fixing settings.py using sed..."

# Use sed to remove the problematic line
docker exec debt-backend-1 bash -c "sed -i '/PATCHED_WSGI_APPLICATION/d' /app/debt_chatbot/settings.py"

# Verify the fix
echo "Verifying fix:"
docker exec debt-backend-1 grep -n "PATCHED_WSGI_APPLICATION" /app/debt_chatbot/settings.py || echo "Line successfully removed"

# Restart the backend container
echo "Restarting backend container..."
docker restart debt-backend-1

echo "Fix applied. Check backend logs to confirm successful startup." 