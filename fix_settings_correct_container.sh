#!/bin/bash

# Fix for settings.py using the correct container name
echo "=== Settings.py Fix Script (Corrected Container Name) ==="

# Create a Python script to fix the settings file
cat > fix_settings.py << 'EOF'
#!/usr/bin/env python3

# Fix settings.py by removing the problematic line
settings_file = '/app/debt_chatbot/settings.py'

try:
    # Read file content
    with open(settings_file, 'r') as f:
        lines = f.readlines()
    
    # Fix line 242 (index 241) if it exists
    if len(lines) >= 242:
        # Replace the problematic line with just a closing brace
        lines[241] = "}\n"
        print(f"Fixed line 242: Replaced with simple closing brace")
    else:
        print(f"File has only {len(lines)} lines, cannot fix line 242")
    
    # Write the fixed content back
    with open(settings_file, 'w') as f:
        f.writelines(lines)
    
    print("Successfully wrote fixed settings.py")
except Exception as e:
    print(f"Error: {e}")
EOF

# Copy the fix script to the container (using correct container name)
echo "Copying fix script to container obix_backend_1..."
docker cp fix_settings.py obix_backend_1:/app/

# Run the fix script in the container
echo "Running fix script in container..."
docker exec obix_backend_1 python3 /app/fix_settings.py

# Alternative: Use sed to directly remove the problematic part
echo "Applying direct sed edit as backup method..."
docker exec obix_backend_1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# Restart the backend container
echo "Restarting backend container..."
docker restart obix_backend_1

echo "Fix applied. The backend should restart successfully now." 