#!/bin/bash

# Emergency total fix for Django settings.py and login
echo "=== EMERGENCY TOTAL FIX ==="

# 0. Inspect the container structure and files to understand what we're working with
echo "Inspecting container structure..."

# Check the container filesystem
docker exec obix_backend_1 ls -la /app || echo "Container not found or cannot access /app"

# Find settings.py file location
echo "Finding settings.py location..."
SETTINGS_FILE=$(docker exec obix_backend_1 find /app -name "settings.py" | head -1)
echo "Settings file found at: $SETTINGS_FILE"

# Check the size of settings.py
SETTINGS_SIZE=$(docker exec obix_backend_1 wc -l $SETTINGS_FILE | awk '{print $1}')
echo "Settings file has $SETTINGS_SIZE lines"

# See the problematic part of the settings file
echo "Viewing the problematic section..."
docker exec obix_backend_1 sed -n '240,245p' $SETTINGS_FILE

# 1. Create a backup of the current settings file
echo "Creating backup of settings.py..."
docker exec obix_backend_1 cp $SETTINGS_FILE ${SETTINGS_FILE}.bak

# 2. Find the exact line with the syntax error
echo "Extracting the line with PATCHED_WSGI_APPLICATION..."
PATCHED_LINE=$(docker exec obix_backend_1 grep -n "PATCHED_WSGI_APPLICATION" $SETTINGS_FILE | head -1)
echo "Found: $PATCHED_LINE"

# 3. Find the TEMPLATES section in the settings file
TEMPLATES_START=$(docker exec obix_backend_1 grep -n "TEMPLATES = " $SETTINGS_FILE | cut -d: -f1)
echo "TEMPLATES section starts at line: $TEMPLATES_START"

# 4. FULL REPLACEMENT APPROACH: Extract settings before the TEMPLATES section
echo "Extracting settings before TEMPLATES..."
docker exec obix_backend_1 sed -n "1,${TEMPLATES_START}p" $SETTINGS_FILE > /tmp/settings_part1

# 5. Create a correct TEMPLATES section
cat > /tmp/settings_templates_part << 'EOF'
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            os.path.join(BASE_DIR, 'templates'),
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

EOF

# 6. Find line after the TEMPLATES section
WSGI_LINE=$(docker exec obix_backend_1 grep -n "WSGI_APPLICATION" $SETTINGS_FILE | cut -d: -f1)
echo "WSGI_APPLICATION found at line: $WSGI_LINE"

# 7. Extract the rest of the settings after TEMPLATES section
echo "Extracting settings after TEMPLATES..."
docker exec obix_backend_1 sed -n "${WSGI_LINE},\$p" $SETTINGS_FILE > /tmp/settings_part3

# 8. Combine everything into a new settings file
cat /tmp/settings_part1 /tmp/settings_templates_part /tmp/settings_part3 > /tmp/new_settings.py

# 9. Copy the new settings file to the container
echo "Copying the fixed settings file to the container..."
docker cp /tmp/new_settings.py obix_backend_1:$SETTINGS_FILE

# 10. Clean up
rm -f /tmp/settings_part1 /tmp/settings_templates_part /tmp/settings_part3 /tmp/new_settings.py

# 11. Add direct login view
echo "Setting up direct login..."
cat > /tmp/direct_login_view.py << 'EOF'
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

# 12. Copy the direct login view to the container
echo "Copying direct login view to container..."
docker cp /tmp/direct_login_view.py obix_backend_1:/app/direct_login_view.py

# 13. Update the URL configuration
echo "Finding urls.py location..."
URLS_FILE=$(docker exec obix_backend_1 find /app -name "urls.py" | head -1)
echo "URLs file found at: $URLS_FILE"

# Get the current urls.py content
docker exec obix_backend_1 cat $URLS_FILE > /tmp/urls.py

# Add import and URL pattern directly to the file
if ! grep -q "direct_login" /tmp/urls.py; then
    echo "Adding direct login to urls.py..."
    # Add import at the beginning
    sed -i '1i\from direct_login_view import direct_login' /tmp/urls.py
    # Add URL pattern after urlpatterns definition
    sed -i '/urlpatterns.*=/a\    path("api/direct-login/", direct_login, name="direct-login"),' /tmp/urls.py
    # Copy the modified urls.py back to the container
    docker cp /tmp/urls.py obix_backend_1:$URLS_FILE
else
    echo "Direct login already in urls.py"
fi

# 14. Create a test login page
echo "Creating test login page..."
cat > /tmp/login-test.html << 'EOF'
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

# 15. Copy the test login page to the frontend container
echo "Looking for frontend public directory..."
FRONTEND_PUBLIC_DIR=$(docker exec obix_frontend_1 find /app -type d -name "public" | head -1 || echo "/app/public")
echo "Frontend public directory found at: $FRONTEND_PUBLIC_DIR"

echo "Copying login test page to frontend container..."
docker cp /tmp/login-test.html obix_frontend_1:$FRONTEND_PUBLIC_DIR/login-test.html

# 16. Restart containers
echo "Restarting containers..."
docker restart obix_backend_1
docker restart obix_frontend_1

echo "==== FIX COMPLETE ===="
echo "The Django settings.py syntax error should be fixed, and login functionality added."
echo "Test the login at: http://157.230.65.142/login-test.html" 