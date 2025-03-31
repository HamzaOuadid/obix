#!/bin/bash

# Direct fix for line 242 of settings.py
echo "Fixing line 242 of settings.py..."

# Create a Python script to fix exactly line 242
cat > fix_line_242.py << 'EOF'
#!/usr/bin/env python3

# This script directly fixes line 242 of settings.py
settings_file = '/app/debt_chatbot/settings.py'

try:
    # Read all lines
    with open(settings_file, 'r') as f:
        lines = f.readlines()
    
    # Check if we have enough lines
    if len(lines) >= 242:
        # Fix line 242 (0-indexed: 241)
        lines[241] = "}\n"
        print(f"Fixed line 242: Changed to simple closing brace")
    else:
        print(f"File has only {len(lines)} lines, cannot fix line 242")
    
    # Write the fixed content back
    with open(settings_file, 'w') as f:
        f.writelines(lines)
    
    print("Successfully wrote fixed settings.py")
except Exception as e:
    print(f"Error: {e}")
EOF

# Copy the fix script to the container
echo "Copying fix script to container..."
docker cp fix_line_242.py debt-backend-1:/app/

# Run the fix script
echo "Running fix script in container..."
docker exec debt-backend-1 python3 /app/fix_line_242.py

# Restart the backend container
echo "Restarting backend container..."
docker restart debt-backend-1

echo "Line 242 fix applied. The backend should restart successfully now." 