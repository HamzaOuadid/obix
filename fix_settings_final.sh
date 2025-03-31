#!/bin/bash

# Aggressive fix for settings.py
echo "Applying aggressive fix to settings.py..."

# Create a script to fix the end of the settings file
cat > fix_end.py << 'EOF'
#!/usr/bin/env python3

# Fix the end of settings.py by replacing the problematic closing brace
settings_file = '/app/debt_chatbot/settings.py'

try:
    # Read file content
    with open(settings_file, 'r') as f:
        lines = f.readlines()
    
    # Find where the TEMPLATES dictionary ends and where the problem might be
    problem_area_start = 0
    for i, line in enumerate(lines):
        if "'DIRS': [" in line:
            problem_area_start = i
            break
    
    # Keep content until the problematic section
    fixed_content = lines[:problem_area_start]
    
    # Add the correct DIRS configuration
    fixed_content.append("    'DIRS': [\n")
    fixed_content.append("        os.path.join(BASE_DIR, 'templates'),\n")
    fixed_content.append("    ],\n")
    
    # Add the remaining valid configuration
    fixed_content.append("    'APP_DIRS': True,\n")
    fixed_content.append("    'OPTIONS': {\n")
    fixed_content.append("        'context_processors': [\n")
    fixed_content.append("            'django.template.context_processors.debug',\n")
    fixed_content.append("            'django.template.context_processors.request',\n")
    fixed_content.append("            'django.contrib.auth.context_processors.auth',\n")
    fixed_content.append("            'django.contrib.messages.context_processors.messages',\n")
    fixed_content.append("        ],\n")
    fixed_content.append("    },\n")
    fixed_content.append("},\n")
    
    # Add remaining settings after TEMPLATES
    for i, line in enumerate(lines):
        if line.strip().startswith("WSGI_APPLICATION ="):
            fixed_content.extend(lines[i:])
            break
    
    # Write the fixed content back
    with open(settings_file, 'w') as f:
        f.writelines(fixed_content)
    
    print("Successfully fixed settings.py")
except Exception as e:
    print(f"Error: {e}")
EOF

# Copy the fix script to the container
echo "Copying aggressive fix script to container..."
docker cp fix_end.py debt-backend-1:/app/

# Run the fix script
echo "Running aggressive fix script in container..."
docker exec debt-backend-1 python3 /app/fix_end.py

# Simpler alternative approach: just use sed to directly edit the closing brace
echo "Applying direct sed edit as backup method..."
docker exec debt-backend-1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# Restart the backend container
echo "Restarting backend container..."
docker restart debt-backend-1

echo "Aggressive fix applied. The backend should restart successfully now." 