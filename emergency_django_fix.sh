#!/bin/bash

# Emergency Django Settings Fix
echo "=== EMERGENCY DJANGO SETTINGS FIX ==="

# 1. Extract the entire settings.py file for manual patching
echo "Finding and extracting settings.py..."
SETTINGS_FILE=$(docker exec obix_backend_1 find /app -name "settings.py" | head -1)
echo "Settings file found at: $SETTINGS_FILE"

# Create a backup
echo "Creating backup..."
docker exec obix_backend_1 cp $SETTINGS_FILE ${SETTINGS_FILE}.bak

# Extract the file to local system
docker exec obix_backend_1 cat $SETTINGS_FILE > django_settings_original.py

# 2. Edit the file to remove PATCHED_WSGI_APPLICATION
echo "Removing problematic PATCHED_WSGI_APPLICATION line..."
grep -v "PATCHED_WSGI_APPLICATION" django_settings_original.py > django_settings_fixed.py

# 3. Perform additional safety fixes
echo "Applying additional safety fixes..."

# Fix line 242 (the closing brace of TEMPLATES section)
sed -i '242s/.*/}]/' django_settings_fixed.py

# 4. Copy the fixed file back to the container
echo "Copying fixed file to container..."
docker cp django_settings_fixed.py obix_backend_1:$SETTINGS_FILE

# 5. Create a minimal direct login view
echo "Creating direct login view..."
cat > direct_login_view.py << 'EOF'
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate, login
import json

@csrf_exempt
def direct_login(request):
    """Minimal direct login endpoint"""
    # CORS headers
    def cors_response(status=200, data=None):
        if data is None:
            data = {}
        response = JsonResponse(data, status=status)
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    # Handle OPTIONS
    if request.method == 'OPTIONS':
        return cors_response()
    
    # Handle POST login
    if request.method == 'POST':
        try:
            # Parse request data
            data = json.loads(request.body.decode('utf-8'))
            username = data.get('username')
            password = data.get('password')
            
            # Authenticate user
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                return cors_response(data={'success': True, 'username': user.username})
            else:
                return cors_response(status=401, data={'error': 'Invalid credentials'})
        except Exception as e:
            return cors_response(status=500, data={'error': str(e)})
    
    return cors_response(status=405, data={'error': 'Method not allowed'})
EOF

# 6. Copy the view to the container
echo "Copying direct login view to container..."
docker cp direct_login_view.py obix_backend_1:/app/

# 7. Find and update urls.py
echo "Finding urls.py..."
URLS_FILE=$(docker exec obix_backend_1 find /app -name "urls.py" | head -1)
echo "URLs file found at: $URLS_FILE"

# Extract current urls.py
docker exec obix_backend_1 cat $URLS_FILE > django_urls_original.py

# Add the direct login import and URL pattern
echo "from direct_login_view import direct_login" > django_urls_new.py
cat django_urls_original.py >> django_urls_new.py

# Add URL pattern after urlpatterns
sed -i '/urlpatterns/a\    path("api/direct-login/", direct_login, name="direct-login"),' django_urls_new.py

# Copy the updated urls.py back to the container
echo "Copying updated urls.py to container..."
docker cp django_urls_new.py obix_backend_1:$URLS_FILE

# 8. Create a minimal login test page
echo "Creating test login page..."
cat > minimal-login-test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Minimal Login Test</title>
    <style>
        body { font-family: Arial; padding: 20px; max-width: 400px; margin: 0 auto; }
    </style>
</head>
<body>
    <h2>Emergency Login Test</h2>
    <div>
        <label>Username: <input id="username" value="admin"></label><br>
        <label>Password: <input id="password" type="password" value="password123"></label><br>
        <button onclick="login()">Login</button>
    </div>
    <div id="result" style="margin-top: 20px;"></div>

    <script>
        function login() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const result = document.getElementById('result');
            
            result.innerText = 'Logging in...';
            
            fetch('/api/direct-login/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    result.innerText = 'Login successful! User: ' + data.username;
                    localStorage.setItem('user', JSON.stringify({
                        username: data.username,
                        isLoggedIn: true
                    }));
                } else {
                    result.innerText = 'Error: ' + (data.error || 'Unknown error');
                }
            })
            .catch(error => {
                result.innerText = 'Error: ' + error.message;
            });
        }
    </script>
</body>
</html>
EOF

# 9. Copy the test page to the frontend container
echo "Copying test page to frontend container..."
docker cp minimal-login-test.html obix_frontend_1:/app/public/

# 10. Restart the containers
echo "Restarting both containers..."
docker restart obix_backend_1
docker restart obix_frontend_1

# 11. Clean up temporary files
rm -f django_settings_original.py django_settings_fixed.py django_urls_original.py django_urls_new.py

echo "==== EMERGENCY FIX COMPLETE ===="
echo "Django settings should be fixed and minimal login functionality added."
echo "Test the login at: http://157.230.65.142/minimal-login-test.html" 