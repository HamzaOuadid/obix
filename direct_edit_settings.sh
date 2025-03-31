#!/bin/bash

# Direct Edit of settings.py - Using the known file path
echo "=== DIRECT SETTINGS EDIT ==="

# Use the known file path without any find commands
SETTINGS_FILE="/app/debt_chatbot/settings.py"
echo "Target file: $SETTINGS_FILE"

# Step 1: Show the container's running status
echo "Checking container status..."
docker ps | grep obix_backend_1

# Step 2: Check if the file exists
echo "Checking if settings file exists..."
docker exec obix_backend_1 bash -c "ls -la $SETTINGS_FILE"
if [ $? -ne 0 ]; then
  echo "ERROR: Settings file not found at $SETTINGS_FILE"
  exit 1
fi

# Step 3: Show the problematic line around line 242
echo "Showing problematic content at line 242..."
docker exec obix_backend_1 bash -c "sed -n '240,245p' $SETTINGS_FILE"

# Step 4: Create a backup of the settings file
echo "Creating backup..."
docker exec obix_backend_1 bash -c "cp $SETTINGS_FILE ${SETTINGS_FILE}.bak"

# Step 5: Direct edit to fix the file - multiple approaches
echo "Applying fixes using multiple methods..."

# Method 1: Use sed to fix the problematic line
echo "Method 1: Using sed to fix line 242..."
docker exec obix_backend_1 bash -c "sed -i '242s/.*PATCHED_WSGI_APPLICATION.*/}/' $SETTINGS_FILE"

# Method 2: Use sed to remove entire line containing PATCHED_WSGI_APPLICATION
echo "Method 2: Removing line with PATCHED_WSGI_APPLICATION..."
docker exec obix_backend_1 bash -c "sed -i '/PATCHED_WSGI_APPLICATION/d' $SETTINGS_FILE"

# Method 3: Use cat with grep to create a new file without the problematic line
echo "Method 3: Using grep to filter the file..."
docker exec obix_backend_1 bash -c "grep -v 'PATCHED_WSGI_APPLICATION' ${SETTINGS_FILE}.bak > ${SETTINGS_FILE}.new && mv ${SETTINGS_FILE}.new $SETTINGS_FILE"

# Step 6: Verify the fix
echo "Verifying the fix..."
docker exec obix_backend_1 bash -c "grep -n 'PATCHED_WSGI_APPLICATION' $SETTINGS_FILE || echo 'PATCHED_WSGI_APPLICATION removed successfully'"

# Step 7: Check for syntax errors in the file
echo "Checking Python syntax..."
docker exec obix_backend_1 bash -c "python3 -m py_compile $SETTINGS_FILE && echo 'Syntax check passed' || echo 'Syntax check failed'"

# Step 8: Restart the container
echo "Restarting backend container..."
docker restart obix_backend_1

echo "Edit complete. Check the container logs to see if it starts successfully."
echo "Run: docker logs obix_backend_1" 