#!/bin/bash

# Container inspection script
echo "=== CONTAINER INSPECTION SCRIPT ==="

# Step 1: Check if the container is running
echo "Checking if containers are running..."
docker ps -a

# Step 2: Examine the container filesystem
echo -e "\nExamining container filesystem structure..."
docker exec obix_backend_1 ls -la / || echo "Cannot access root directory"
docker exec obix_backend_1 ls -la /app || echo "Cannot access /app directory"

# Step 3: Find Python files
echo -e "\nFinding Python files..."
docker exec obix_backend_1 find / -name "*.py" -type f | head -20 2>/dev/null || echo "Find command failed"

# Step 4: Find Django settings
echo -e "\nFinding Django settings.py files..."
docker exec obix_backend_1 find / -name "settings.py" -type f 2>/dev/null || echo "No settings.py found"

# Step 5: Check Django project structure
echo -e "\nChecking for Django project structure..."
docker exec obix_backend_1 find / -name "manage.py" -type f 2>/dev/null || echo "No manage.py found"
docker exec obix_backend_1 find / -name "urls.py" -type f 2>/dev/null || echo "No urls.py found"

# Step 6: Read startup logs
echo -e "\nReading recent container logs..."
docker logs --tail 50 obix_backend_1 | grep -i error

# Step 7: Check environment variables
echo -e "\nChecking environment variables..."
docker exec obix_backend_1 env | grep -E 'DJANGO|PYTHON|APP|PATH' || echo "No relevant environment variables"

# Step 8: Check container processes
echo -e "\nChecking running processes in container..."
docker exec obix_backend_1 ps aux || echo "Cannot list processes"

echo -e "\nInspection complete. Use this information to determine the correct paths for your fix." 