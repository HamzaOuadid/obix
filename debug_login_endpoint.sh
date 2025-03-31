#!/bin/bash

# Script to debug the direct login endpoint
echo "=== DEBUG LOGIN ENDPOINT ==="

# Step 1: Check if the direct_login_view.py file exists
echo "Checking for direct login view..."
docker exec obix_backend_1 bash -c "ls -la /app/direct_login_view.py" || echo "direct_login_view.py not found!"

# Step 2: Examine the URLs configuration
echo "Checking if the API endpoint is properly configured in URLs..."
docker exec obix_backend_1 bash -c "grep -A 10 'urlpatterns' /app/debt_chatbot/urls.py" || echo "Could not find urlpatterns in urls.py"

# Step 3: Test the login endpoint directly with curl
echo "Testing login endpoint with curl..."
# Generate a JSON payload
cat > login_data.json << 'EOF'
{
    "username": "admin",
    "password": "password123"
}
EOF

# Try to get the backend IP address
echo "Getting backend container IP address..."
BACKEND_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' obix_backend_1)
echo "Backend IP: $BACKEND_IP"

# Test with curl if we got an IP
if [ -n "$BACKEND_IP" ]; then
    echo "Sending direct request to backend..."
    docker exec obix_backend_1 bash -c "apt-get update && apt-get install -y curl"
    docker exec obix_backend_1 bash -c "curl -X POST -H 'Content-Type: application/json' -d @/tmp/login_data.json http://localhost:8000/api/direct-login/"
    echo ""
fi

# Step 4: Create a direct test script
cat > test_login.py << 'EOF'
import os
import sys
import json
import requests
from urllib.parse import urljoin

# Configuration
base_url = "http://localhost:8000"  # If running inside container
api_endpoint = "/api/direct-login/"
username = "admin"
password = "password123"

# Test function
def test_login():
    url = urljoin(base_url, api_endpoint)
    payload = {
        "username": username,
        "password": password
    }
    
    print(f"Sending POST to {url} with data: {payload}")
    
    try:
        response = requests.post(
            url, 
            json=payload,
            headers={"Content-Type": "application/json"},
        )
        
        print(f"Status code: {response.status_code}")
        print(f"Response headers: {response.headers}")
        
        try:
            print(f"Response body: {response.json()}")
        except:
            print(f"Response text: {response.text}")
            
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    success = test_login()
    sys.exit(0 if success else 1)
EOF

# Step 5: Run the test script inside the container
echo "Running test script inside container..."
docker cp test_login.py obix_backend_1:/tmp/
docker exec obix_backend_1 bash -c "pip install requests && python3 /tmp/test_login.py"

# Step 6: Check for common auth middlewares that might interfere
echo "Checking for auth middlewares..."
docker exec obix_backend_1 bash -c "grep -A 20 'MIDDLEWARE' /app/debt_chatbot/settings.py"

# Step 7: Check CSRF configuration
echo "Checking CSRF configuration..."
docker exec obix_backend_1 bash -c "grep -A 5 'CSRF' /app/debt_chatbot/settings.py" || echo "No CSRF settings found"

# Step 8: Create a simple wrapper for the direct_login view for debugging
cat > debug_login_view.py << 'EOF'
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
import traceback

@csrf_exempt
def debug_login(request):
    """Debug login endpoint that just echoes the request"""
    try:
        response_data = {
            'method': request.method,
            'path': request.path,
            'headers': dict(request.headers),
        }
        
        if request.method == 'POST':
            try:
                body = request.body.decode('utf-8')
                response_data['body'] = body
                try:
                    json_data = json.loads(body)
                    response_data['json'] = json_data
                except:
                    response_data['json_parse_error'] = 'Could not parse JSON'
            except:
                response_data['body_error'] = 'Could not decode body'
        
        return JsonResponse({
            'success': True,
            'request_info': response_data
        })
    except Exception as e:
        traceback_str = traceback.format_exc()
        return JsonResponse({
            'success': False,
            'error': str(e),
            'traceback': traceback_str
        })
EOF

# Step 9: Install the debug view
echo "Installing debug login view..."
docker cp debug_login_view.py obix_backend_1:/app/

# Step 10: Add debug view to URLs
echo "Adding debug view to URLs..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"
with open('/app/debt_chatbot/urls.py', 'r') as f:
    content = f.read()

if 'from debug_login_view import debug_login' not in content:
    # Add import
    import_pos = content.find('from direct_login_view import direct_login')
    if import_pos > -1:
        content = content[:import_pos] + 'from debug_login_view import debug_login\\n' + content[import_pos:]
    
    # Add URL pattern
    pattern_pos = content.find('path(\\\"api/direct-login/\\\"')
    if pattern_pos > -1:
        pattern_end = content.find(',', pattern_pos)
        insert_pos = content.find('\\n', pattern_end)
        content = content[:insert_pos] + '\\n    path(\\\"api/debug-login/\\\", debug_login, name=\\\"debug-login\\\"),' + content[insert_pos:]
    
    with open('/app/debt_chatbot/urls.py', 'w') as f:
        f.write(content)
    print('Debug login view added to URLs')
else:
    print('Debug login view already in URLs')
\""

# Step 11: Restart the backend
echo "Restarting backend..."
docker restart obix_backend_1

# Step 12: Clean up
rm -f test_login.py debug_login_view.py login_data.json

echo "=== DEBUG SETUP COMPLETE ==="
echo "You can test the debug endpoint at:"
echo "http://157.230.65.142/api/debug-login/"
echo "This will show you information about the request without requiring authentication."
echo "Use this to help diagnose any issues with the login process." 