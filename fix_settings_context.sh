#!/bin/bash

# Fix for settings.py examining the context around API_KEY
echo "=== FIXING SETTINGS.PY CONTEXT ==="

# Target file path
SETTINGS_FILE="/app/debt_chatbot/settings.py"

# Step 1: Create a backup
echo "Creating backup..."
docker exec obix_backend_1 bash -c "cp $SETTINGS_FILE ${SETTINGS_FILE}.bak3"

# Step 2: Show a larger context around the problematic line
echo "Showing context around line 189..."
docker exec obix_backend_1 bash -c "sed -n '180,200p' $SETTINGS_FILE"

# Step 3: Extract the problematic section to a local file for inspection
echo "Extracting problematic section..."
docker exec obix_backend_1 bash -c "sed -n '180,200p' $SETTINGS_FILE" > problematic_section.txt

# Step 4: Create a fixed version of this section
cat > fixed_section.txt << 'EOF'
# Mistral AI API settings
MISTRAL_AI_API = {
    'API_KEY': os.getenv('MISTRAL_API_KEY', ''),
    'API_URL': os.getenv('MISTRAL_API_URL', 'https://api.mistral.ai/v1'),
    'MODEL': os.getenv('MISTRAL_MODEL', 'mistral-tiny'),
}

# Channel layer settings
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer',
    }
}
EOF

# Step 5: Insert the fixed section back into the settings file
echo "Replacing problematic section..."
docker cp fixed_section.txt obix_backend_1:/tmp/
docker exec obix_backend_1 bash -c "sed -n '1,179p' $SETTINGS_FILE > /tmp/settings_part1"
docker exec obix_backend_1 bash -c "cat /tmp/fixed_section.txt > /tmp/settings_part2"
docker exec obix_backend_1 bash -c "sed -n '201,\$p' $SETTINGS_FILE > /tmp/settings_part3"
docker exec obix_backend_1 bash -c "cat /tmp/settings_part1 /tmp/settings_part2 /tmp/settings_part3 > $SETTINGS_FILE"

# Step 6: Verify the fix
echo "Checking Python syntax..."
docker exec obix_backend_1 bash -c "python3 -m py_compile $SETTINGS_FILE && echo 'Syntax check passed!' || echo 'Syntax check failed!'"

# Step 7: Restart the container
echo "Restarting container..."
docker restart obix_backend_1

# Step 8: Clean up temporary files
rm -f problematic_section.txt fixed_section.txt
docker exec obix_backend_1 bash -c "rm -f /tmp/settings_part1 /tmp/settings_part2 /tmp/settings_part3 /tmp/fixed_section.txt"

echo "Fix applied. Check container logs to see if it starts successfully."
echo "Run: docker logs obix_backend_1" 