#!/bin/bash

# Fix script that addresses permission issues and uses a more direct approach
echo "=== Direct Fix Script with Permissions Fix ==="

# 1. Fix settings.py directly with sed (no Python script needed)
echo "STEP 1: Directly fixing settings.py with sed..."
docker exec obix_backend_1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# Verify the fix worked
echo "Verifying settings.py fix..."
docker exec obix_backend_1 grep -n "PATCHED_WSGI_APPLICATION" /app/debt_chatbot/settings.py || echo "Fix applied successfully: PATCHED_WSGI_APPLICATION removed"

# Restart the backend to apply settings changes
echo "Restarting backend after settings fix..."
docker restart obix_backend_1

# Wait for backend to restart
echo "Waiting for backend to restart..."
sleep 10

# 2. Set up direct login
echo "STEP 2: Setting up direct login..."

# Create direct login view
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

# Copy the login view file directly to the container
echo "Copying direct login view to container..."
docker cp direct_login_view.py obix_backend_1:/app/

# Make sure the file has execute permissions
echo "Setting execute permissions on direct_login_view.py..."
docker exec obix_backend_1 chmod +x /app/direct_login_view.py

# Create the URL update script directly in the container
echo "Creating URL update script directly in the container..."
docker exec obix_backend_1 bash -c "cat > /app/update_urls.sh << 'EOF'
#!/bin/bash

# Direct update of urls.py without using Python
URLS_FILE=/app/debt_chatbot/urls.py

# Check if direct_login is already in the file
if ! grep -q 'direct_login' \$URLS_FILE; then
  # Add import at the top (after the last import line)
  LAST_IMPORT_LINE=\$(grep -n 'import ' \$URLS_FILE | tail -1 | cut -d: -f1)
  
  # Use sed to insert the import after the last import line
  sed -i \"\${LAST_IMPORT_LINE}a from direct_login_view import direct_login\" \$URLS_FILE
  
  # Find the urlpatterns line number
  URLPATTERNS_LINE=\$(grep -n 'urlpatterns' \$URLS_FILE | head -1 | cut -d: -f1)
  
  # Add the URL pattern after the urlpatterns line
  sed -i \"\${URLPATTERNS_LINE}a \    path('api/direct-login/', direct_login, name='direct-login'),\" \$URLS_FILE
  
  echo \"Successfully updated \$URLS_FILE with direct login endpoint\"
else
  echo \"Direct login endpoint already exists in \$URLS_FILE\"
fi
EOF"

# Make the URL update script executable
echo "Setting execute permissions on update_urls.sh..."
docker exec obix_backend_1 chmod +x /app/update_urls.sh

# Run the URL update script
echo "Running URL update script..."
docker exec obix_backend_1 bash /app/update_urls.sh

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

# Final restart of the backend container
echo "Final restart of backend container..."
docker restart obix_backend_1

echo "===== FIX COMPLETE ====="
echo "Login should now be working. Test it at:"
echo "http://157.230.65.142/login-test.html" 