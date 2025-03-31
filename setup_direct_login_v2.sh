#!/bin/bash

# Setup direct login endpoint on the Django server after fixing settings.py
echo "Setting up direct login endpoint..."

# Create direct login view file
cat > direct_login_view.py << 'EOF'
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate, login
import json

@csrf_exempt
def direct_login(request):
    """
    Direct login endpoint that bypasses CSRF protection and handles CORS.
    """
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
    
    # Log request information
    print(f"[DirectLogin] Received {request.method} request to {request.path}")
    
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
                if request.body:
                    data = json.loads(request.body.decode('utf-8'))
                    print(f"[DirectLogin] Received data: {data}")
                else:
                    data = {}
            except json.JSONDecodeError:
                print(f"[DirectLogin] Invalid JSON body: {request.body}")
                return cors_response(status=400, data={'error': 'Invalid JSON'})
            
            username = data.get('username')
            password = data.get('password')
            
            if not username or not password:
                print(f"[DirectLogin] Missing username or password")
                return cors_response(status=400, data={'error': 'Username and password are required'})
            
            # Authenticate user
            print(f"[DirectLogin] Authenticating user: {username}")
            user = authenticate(request, username=username, password=password)
            if user is not None:
                print(f"[DirectLogin] Authentication successful for {username}")
                login(request, user)
                return cors_response(data={
                    'success': True,
                    'username': user.username
                })
            else:
                print(f"[DirectLogin] Authentication failed for {username}")
                return cors_response(status=401, data={'error': 'Invalid credentials'})
                
        except Exception as e:
            print(f"[DirectLogin] Error: {str(e)}")
            import traceback
            traceback.print_exc()
            return cors_response(status=500, data={'error': str(e)})
    
    # Handle unsupported methods
    print(f"[DirectLogin] Unsupported method: {request.method}")
    return cors_response(status=405, data={'error': 'Method not allowed'})
EOF

# Copy the view file to the container
echo "Copying direct login view to backend container..."
docker cp direct_login_view.py debt-backend-1:/app/

# Create a simple test page for the login
cat > login-test.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 500px;
            margin: 0 auto;
            padding: 20px;
        }
        form {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        input {
            padding: 8px;
        }
        button {
            padding: 10px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }
        #status {
            margin-top: 20px;
            padding: 10px;
            background-color: #f8f8f8;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <h1>Login Test</h1>
    <form id="login-form">
        <input type="text" id="username" placeholder="Username" value="admin" required>
        <input type="password" id="password" placeholder="Password" value="password123" required>
        <button type="submit">Login</button>
    </form>
    <div id="status">Please log in</div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const apiUrl = 'http://157.230.65.142/api';
            const loginForm = document.getElementById('login-form');
            const usernameInput = document.getElementById('username');
            const passwordInput = document.getElementById('password');
            const statusDiv = document.getElementById('status');

            loginForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const username = usernameInput.value;
                const password = passwordInput.value;
                
                try {
                    statusDiv.textContent = 'Logging in...';
                    console.log(`Attempting to login with username: ${username}`);
                    
                    // Make direct login request
                    const response = await fetch(`${apiUrl}/direct-login/`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ username, password }),
                        credentials: 'include'
                    });
                    
                    const data = await response.json();
                    console.log('Login response:', data);
                    
                    if (response.ok) {
                        statusDiv.textContent = `Login successful! Welcome, ${data.username}`;
                        localStorage.setItem('user', JSON.stringify({
                            username: data.username,
                            isLoggedIn: true
                        }));
                        
                        // Redirect to chat page after 2 seconds
                        setTimeout(() => {
                            window.location.href = '/chat';
                        }, 2000);
                    } else {
                        statusDiv.textContent = `Error: ${data.error || 'Unknown error'}`;
                    }
                } catch (error) {
                    console.error('Login error:', error);
                    statusDiv.textContent = `Error: ${error.message}`;
                }
            });
        });
    </script>
</body>
</html>
EOF

# Copy the login test page to the frontend container
echo "Copying login test page to frontend container..."
docker cp login-test.html debt-frontend-1:/app/public/

# Update Django URLs for direct login
echo "Updating Django URLs configuration..."
docker exec -it debt-backend-1 bash -c "
# Create a Python script to update the URLs
cat > /tmp/update_urls.py << 'EOF'
#!/usr/bin/env python3
import os

def update_urls():
    # Find the main Django app URLs file
    urls_file = '/app/debt_chatbot/urls.py'
    if not os.path.exists(urls_file):
        print(f'URLs file not found: {urls_file}')
        return False
    
    # Read the current content
    with open(urls_file, 'r') as f:
        content = f.read()
    
    # Check if direct_login is already imported
    if 'from direct_login_view import direct_login' not in content:
        # Add the import near the top after other imports
        import_line = 'from direct_login_view import direct_login'
        import_position = content.rfind('import')
        if import_position > 0:
            # Find the end of imports
            import_end = content.find('\\n', import_position)
            if import_end > 0:
                new_content = content[:import_end+1] + '\\n' + import_line + content[import_end+1:]
                
                # Now add the URL pattern in urlpatterns
                url_pattern = \"    path('api/direct-login/', direct_login, name='direct-login'),\"
                urlpatterns_pos = new_content.find('urlpatterns = [')
                if urlpatterns_pos > 0:
                    # Find the first entry in urlpatterns
                    first_entry_pos = new_content.find('path(', urlpatterns_pos)
                    if first_entry_pos > 0:
                        # Insert our URL pattern after the first entry
                        first_entry_end = new_content.find('\\n', first_entry_pos)
                        if first_entry_end > 0:
                            final_content = new_content[:first_entry_end+1] + '\\n' + url_pattern + new_content[first_entry_end+1:]
                            with open(urls_file, 'w') as f:
                                f.write(final_content)
                            print(f'Successfully updated {urls_file} with direct login endpoint')
                            return True
        
        print(f'Could not update {urls_file}, needs manual editing')
        return False
    else:
        print(f'Direct login already exists in {urls_file}')
        return True

if __name__ == '__main__':
    update_urls()
EOF

# Run the Python script to update URLs
python3 /tmp/update_urls.py
"

# Restart the backend container to apply changes
echo "Restarting backend container..."
docker-compose restart backend

echo "Direct login endpoint setup complete. Wait a few moments for the server to restart."
echo "You can test the login by visiting: http://157.230.65.142/login-test.html" 