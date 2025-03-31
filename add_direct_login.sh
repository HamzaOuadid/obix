#!/bin/bash

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
docker cp direct_login_view.py debt-backend-1:/app/

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
docker cp update_urls.py debt-backend-1:/app/
docker exec -it debt-backend-1 python3 /app/update_urls.py

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
docker cp login-test.html debt-frontend-1:/app/public/

# Restart the backend container
echo "Restarting backend container..."
docker restart debt-backend-1

echo "Direct login setup complete. Test the login at: http://157.230.65.142/login-test.html" 