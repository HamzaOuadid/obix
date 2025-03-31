#!/bin/bash

# Simple direct fix for settings.py
echo "=== Direct Settings Fix ==="

# Create a Python script that will run inside the container to fix the settings file
cat > fix_settings.py << 'EOF'
#!/usr/bin/env python3
import os

# This script directly edits the settings.py file to remove the problematic line
settings_file = "/app/debt_chatbot/settings.py"

try:
    # Read the current content
    with open(settings_file, "r") as f:
        lines = f.readlines()
    
    # Write back excluding any line with PATCHED_WSGI_APPLICATION
    with open(settings_file, "w") as f:
        for line in lines:
            if "PATCHED_WSGI_APPLICATION" not in line:
                f.write(line)
    
    print("Successfully fixed settings.py by removing PATCHED_WSGI_APPLICATION")
except Exception as e:
    print(f"Error fixing settings.py: {e}")
EOF

# Run the script in the container
echo "Running fix_settings.py in the container..."
docker cp fix_settings.py debt-backend-1:/app/
docker exec -it debt-backend-1 python3 /app/fix_settings.py

# Restart the container
echo "Restarting backend container..."
docker restart debt-backend-1

echo "Settings file fixed. The backend should start successfully now." 