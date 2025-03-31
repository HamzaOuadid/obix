#!/bin/bash

# Minimal settings fix - no assumptions about paths
echo "=== MINIMAL SETTINGS FIX ==="

# Step 1: Find the path to settings.py in the container
echo "Finding settings.py in container..."
docker exec obix_backend_1 find / -name "settings.py" 2>/dev/null

# Step 2: Manually specify the path to settings.py (try both common locations)
echo "Attempting direct fix at common Django settings locations..."

# Try typical Django project structure
echo "1. Trying /app/debt_chatbot/settings.py"
docker exec obix_backend_1 bash -c "if [ -f /app/debt_chatbot/settings.py ]; then sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py && echo 'Fixed!'; fi"

# Try alternative project structure
echo "2. Trying /app/settings.py"
docker exec obix_backend_1 bash -c "if [ -f /app/settings.py ]; then sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/settings.py && echo 'Fixed!'; fi"

# Try another common location
echo "3. Trying /usr/src/app/debt_chatbot/settings.py"
docker exec obix_backend_1 bash -c "if [ -f /usr/src/app/debt_chatbot/settings.py ]; then sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /usr/src/app/debt_chatbot/settings.py && echo 'Fixed!'; fi"

# Step 3: Restart the backend container
echo "Restarting backend container..."
docker restart obix_backend_1

echo "Fix attempted at multiple potential locations. Check if backend starts correctly."
echo "Run 'docker logs obix_backend_1' to see if the error is resolved." 