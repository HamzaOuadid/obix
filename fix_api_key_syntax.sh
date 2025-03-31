#!/bin/bash

# Fix for API_KEY syntax error in settings.py line 189
echo "=== FIXING API_KEY SYNTAX ERROR ==="

# Target file path
SETTINGS_FILE="/app/debt_chatbot/settings.py"

# Step 1: Create a backup
echo "Creating backup..."
docker exec obix_backend_1 bash -c "cp $SETTINGS_FILE ${SETTINGS_FILE}.bak2"

# Step 2: Show the problematic line
echo "Showing problematic API_KEY line..."
docker exec obix_backend_1 bash -c "sed -n '185,195p' $SETTINGS_FILE"

# Step 3: Fix the syntax error - multiple approaches

# Method 1: Remove trailing comma if it's causing the issue
echo "Method 1: Removing trailing comma..."
docker exec obix_backend_1 bash -c "sed -i '189s/, *$/)/' $SETTINGS_FILE"

# Method 2: Ensure proper dictionary format if this is part of a dictionary
echo "Method 2: Ensuring proper dictionary format..."
docker exec obix_backend_1 bash -c "sed -i '189s/API_KEY = os.getenv/\"API_KEY\": os.getenv/' $SETTINGS_FILE"

# Method 3: Replace the entire line with a known good syntax
echo "Method 3: Replacing entire line..."
docker exec obix_backend_1 bash -c "sed -i '189s/.*API_KEY.*/API_KEY = os.getenv(\"MISTRAL_API_KEY\", \"\")/' $SETTINGS_FILE"

# Step 4: Verify fix
echo "Showing fixed line..."
docker exec obix_backend_1 bash -c "sed -n '189p' $SETTINGS_FILE"

# Step 5: Check Python syntax
echo "Checking Python syntax..."
docker exec obix_backend_1 bash -c "python3 -m py_compile $SETTINGS_FILE && echo 'Syntax check passed!' || echo 'Syntax check failed!'"

# Step 6: Restart container
echo "Restarting container..."
docker restart obix_backend_1

echo "Fix applied. Check container logs to see if it starts successfully."
echo "Run: docker logs obix_backend_1" 