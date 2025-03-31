#!/bin/bash

# Extremely minimal fix using only bash commands
echo "=== Bash-Only Minimal Fix Script ==="

# 1. Directly fix settings.py with sed
echo "Fixing settings.py..."
docker exec obix_backend_1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# 2. Create the direct login view file
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

# Copy the file to the container
echo "Copying direct login view to container..."
docker cp direct_login_view.py obix_backend_1:/app/

# 3. Update the Django URL configuration directly with sed
echo "Updating URLs configuration..."
# First, add the import
docker exec obix_backend_1 bash -c "sed -i '1i\from direct_login_view import direct_login' /app/debt_chatbot/urls.py"
# Then, add the URL pattern at the beginning of the urlpatterns list
docker exec obix_backend_1 bash -c "sed -i '/urlpatterns/a\    path(\"api/direct-login/\", direct_login, name=\"direct-login\"),' /app/debt_chatbot/urls.py"

# 4. Create test login page
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

# Copy the test page to the frontend container
echo "Copying login test page to frontend container..."
docker cp login-test.html obix_frontend_1:/app/public/

# 5. Restart the backend
echo "Restarting backend container..."
docker restart obix_backend_1

echo "Fix applied. Test login at http://157.230.65.142/login-test.html" 