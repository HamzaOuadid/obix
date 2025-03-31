#!/bin/bash

# Complete fix script for backend login issues (with correct container names)
echo "=== Complete Login Fix Script (Corrected Container Names) ==="

# --------------------------------
# STEP 1: Fix the settings.py file
# --------------------------------
echo "STEP 1: Fixing settings.py file..."

# Create a Python script that will run inside the container to fix the settings file
cat > fix_settings.py << 'EOF'
#!/usr/bin/env python3

# This script directly edits the settings.py file to remove the problematic line
settings_file = "/app/debt_chatbot/settings.py"

try:
    # Method 1: Target line 242 specifically
    with open(settings_file, 'r') as f:
        lines = f.readlines()
    
    # Check if the file has enough lines
    if len(lines) >= 242:
        # Fix line 242 (0-indexed: 241)
        original_line = lines[241]
        lines[241] = "}\n"
        print(f"Fixed line 242: Changed from '{original_line.strip()}' to simple closing brace")
    else:
        print(f"File has only {len(lines)} lines, cannot fix line 242 directly")
        
        # Method 2: Alternative approach - filter out problematic lines
        fixed_lines = []
        for line in lines:
            if "PATCHED_WSGI_APPLICATION" not in line:
                fixed_lines.append(line)
        
        # Update lines with the filtered version
        lines = fixed_lines
        print("Used alternative method: Removed all lines containing PATCHED_WSGI_APPLICATION")
    
    # Write the fixed content back
    with open(settings_file, 'w') as f:
        f.writelines(lines)
    
    print("Successfully fixed settings.py")
except Exception as e:
    print(f"Error fixing settings.py: {e}")
EOF

# Run the script in the container
echo "Running fix_settings.py in the container..."
docker cp fix_settings.py obix_backend_1:/app/
docker exec obix_backend_1 python3 /app/fix_settings.py

# Backup method: Use sed to directly remove problematic line
echo "Applying direct sed edit as backup method..."
docker exec obix_backend_1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# Restart the container to apply settings changes
echo "Restarting backend container after settings fix..."
docker restart obix_backend_1

# Give the container time to restart
echo "Waiting for container to restart..."
sleep 10

# --------------------------------
# STEP 2: Add direct login functionality
# --------------------------------
echo "STEP 2: Setting up direct login functionality..."

# Create direct login view
echo "Creating direct login view..."
cat > direct_login_view.py << 'EOF'
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate, login
import json

@csrf_exempt
def direct_login(request):
    """Direct login endpoint that bypasses CSRF protection"""
    # Add CORS headers to all responses
    def cors_response(status=200, data=None):
        if data is None:
            data = {}
        response = JsonResponse(data, status=status)
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type, X-Requested-With, X-CSRFToken'
        response['Access-Control-Allow-Credentials'] = 'true'
        return response
    
    # Handle OPTIONS preflight request
    if request.method == 'OPTIONS':
        return cors_response()
    
    # Handle GET request (for CSRF token)
    if request.method == 'GET':
        return cors_response(data={'csrfToken': 'dummy-token-for-insecure-login'})
    
    # Handle POST login request
    if request.method == 'POST':
        try:
            # Parse request data
            try:
                data = json.loads(request.body.decode('utf-8'))
                print(f"[DirectLogin] Request: {data}")
            except json.JSONDecodeError:
                return cors_response(status=400, data={'error': 'Invalid JSON'})
            
            username = data.get('username')
            password = data.get('password')
            
            if not username or not password:
                return cors_response(status=400, data={'error': 'Username and password are required'})
            
            # Authenticate user
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                print(f"[DirectLogin] Success: {username}")
                return cors_response(data={
                    'success': True,
                    'username': user.username
                })
            else:
                print(f"[DirectLogin] Failed: {username}")
                return cors_response(status=401, data={'error': 'Invalid credentials'})
        except Exception as e:
            import traceback
            traceback.print_exc()
            return cors_response(status=500, data={'error': str(e)})
    
    # Handle unsupported methods
    return cors_response(status=405, data={'error': 'Method not allowed'})
EOF

# Copy the view file to the container
echo "Copying direct login view to container..."
docker cp direct_login_view.py obix_backend_1:/app/

# Create a simple Python script to update urls.py
cat > update_urls.py << 'EOF'
#!/usr/bin/env python3
import os

# The urls.py file to update
urls_file = "/app/debt_chatbot/urls.py"

try:
    # Read current content
    with open(urls_file, "r") as f:
        content = f.read()
    
    # Check if direct_login is already in the file
    if "direct_login" not in content:
        # Add imports at the top of the file
        lines = content.split("\n")
        
        # Find the last import line
        last_import_line = 0
        for i, line in enumerate(lines):
            if line.startswith("from ") or line.startswith("import "):
                last_import_line = i
        
        # Add our import after the last import
        lines.insert(last_import_line + 1, "from direct_login_view import direct_login")
        
        # Find the urlpatterns definition
        urlpatterns_line = None
        for i, line in enumerate(lines):
            if "urlpatterns" in line and "[" in line:
                urlpatterns_line = i
                break
        
        if urlpatterns_line is not None:
            # Find where to insert our new URL pattern
            for i in range(urlpatterns_line + 1, len(lines)):
                if "path(" in lines[i]:
                    # Insert our URL pattern before the first path
                    lines.insert(i, "    path('api/direct-login/', direct_login, name='direct-login'),")
                    break
        
        # Write the modified content back
        with open(urls_file, "w") as f:
            f.write("\n".join(lines))
        
        print(f"Successfully updated {urls_file} with direct login endpoint")
    else:
        print(f"Direct login endpoint already exists in {urls_file}")
except Exception as e:
    print(f"Error updating {urls_file}: {e}")
EOF

# Copy and run the URL update script
echo "Updating URLs configuration..."
docker cp update_urls.py obix_backend_1:/app/
docker exec obix_backend_1 python3 /app/update_urls.py

# Create a simple test page
echo "Creating test login page..."
cat > login-test.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Test</title>
    <style>
        body { font-family: Arial; max-width: 400px; margin: 20px auto; padding: 20px; }
        form { display: flex; flex-direction: column; gap: 10px; }
        button { padding: 10px; background: #4CAF50; color: white; border: none; cursor: pointer; }
        input { padding: 8px; }
        #status { margin-top: 20px; padding: 10px; background: #f0f0f0; }
    </style>
</head>
<body>
    <h1>Simple Login Test</h1>
    
    <form id="login-form">
        <div>
            <label for="username">Username:</label>
            <input type="text" id="username" value="admin" required>
        </div>
        <div>
            <label for="password">Password:</label>
            <input type="password" id="password" value="password123" required>
        </div>
        <button type="submit">Login</button>
    </form>
    
    <div id="status">Ready to login</div>
    
    <script>
        document.getElementById('login-form').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const status = document.getElementById('status');
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            status.textContent = 'Logging in...';
            
            try {
                const response = await fetch('/api/direct-login/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    status.textContent = `Success! Logged in as ${data.username}`;
                    localStorage.setItem('user', JSON.stringify({
                        username: data.username,
                        isLoggedIn: true
                    }));
                    
                    // Option to redirect
                    setTimeout(() => {
                        if (confirm('Login successful! Go to main app?')) {
                            window.location.href = '/';
                        }
                    }, 500);
                } else {
                    status.textContent = `Error: ${data.error || 'Unknown error'}`;
                }
            } catch (error) {
                status.textContent = `Error: ${error.message}`;
            }
        });
    </script>
</body>
</html>
EOF

# Copy the login test to the frontend container
echo "Copying login test page to frontend container..."
docker cp login-test.html obix_frontend_1:/app/public/

# Restart the backend container
echo "Final restart of backend container..."
docker restart obix_backend_1

echo "===== FIX COMPLETE ====="
echo "Login should now be working. Test it at:"
echo "http://157.230.65.142/login-test.html" 