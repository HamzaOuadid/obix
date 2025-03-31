#!/bin/bash

# Fix the syntax error in settings.py
echo "Fixing syntax error in settings.py..."

# Use sed to fix the syntax error on line 242
docker exec -it debt-backend-1 bash -c "
  # Create a backup of the original settings file
  cp /app/debt_chatbot/settings.py /app/debt_chatbot/settings.py.bak
  
  # Fix the syntax error by removing the PATCHED_WSGI_APPLICATION line
  sed -i '/PATCHED_WSGI_APPLICATION/d' /app/debt_chatbot/settings.py
  
  echo 'Syntax error fixed in settings.py'
  
  # Restart the Django application
  echo 'Restarting backend container...'
"

# Restart the backend container
docker-compose restart backend

echo "Settings file fixed. The backend should start successfully now." 