#!/bin/bash

# Direct settings.py fix without interactive mode
echo "=== Direct Settings Fix ==="

# Create direct Python fix script
cat > direct_fix.py << 'EOF'
#!/usr/bin/env python3

# Fix settings.py directly
settings_file = '/app/debt_chatbot/settings.py'

try:
    # Read the file content
    with open(settings_file, 'r') as f:
        content = f.read()
    
    # Fix the content by removing the problematic line
    fixed_content = ""
    for line in content.split('\n'):
        if 'PATCHED_WSGI_APPLICATION' not in line:
            fixed_content += line + '\n'
    
    # Write the fixed content back
    with open(settings_file, 'w') as f:
        f.write(fixed_content)
    
    print("Successfully fixed settings.py")
except Exception as e:
    print(f"Error: {e}")
EOF

# Copy the fix script to the container without interactive mode
echo "Copying fix script to container..."
docker cp direct_fix.py debt-backend-1:/app/

# Run the fix script without interactive mode
echo "Running fix script in container..."
docker exec debt-backend-1 python3 /app/direct_fix.py

# Show the fixed file to verify
echo "Verifying fix..."
docker exec debt-backend-1 grep -v "PATCHED_WSGI_APPLICATION" /app/debt_chatbot/settings.py | tail -10

# Restart the backend container
echo "Restarting backend..."
docker restart debt-backend-1

echo "Fix applied. The backend should restart successfully now." 