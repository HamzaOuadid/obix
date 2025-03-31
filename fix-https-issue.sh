#!/bin/bash

# Update the Django views to handle CORS and CSRF properly
cat > django-views-fix.py << 'EOL'
from django.views.decorators.csrf import csrf_exempt
from django.middleware.csrf import get_token
from django.http import JsonResponse

@csrf_exempt
def get_csrf_token(request):
    """
    View to return a CSRF token for clients that need it
    """
    # Handle preflight OPTIONS request
    if request.method == "OPTIONS":
        response = JsonResponse({})
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'X-Requested-With, Content-Type, X-CSRFToken'
        return response
        
    csrf_token = get_token(request)
    print(f"Generated CSRF token for request")
    response = JsonResponse({'csrfToken': csrf_token})
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'X-Requested-With, Content-Type, X-CSRFToken'
    response['Access-Control-Allow-Credentials'] = 'true'
    return response

@csrf_exempt
def login_view(request):
    print(f"Login view accessed. Method: {request.method}")
    
    # Handle preflight OPTIONS request
    if request.method == "OPTIONS":
        response = JsonResponse({})
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'X-Requested-With, Content-Type, X-CSRFToken'
        response['Access-Control-Allow-Credentials'] = 'true'
        return response
EOL

# Copy to backend container and update views
docker cp django-views-fix.py obix_backend_1:/app/
docker exec -it obix_backend_1 bash -c "
python -c \"
import sys
sys.path.append('/app')
from django_views_fix import csrf_exempt, get_csrf_token, login_view
from mistral_api import views

# Update the functions in the views module
views.get_csrf_token = get_csrf_token
views.login_view = login_view
views.csrf_exempt = csrf_exempt
print('Django views updated successfully')
\"
"

# Update Nginx configuration with CORS settings
cat > nginx/conf/app.conf << 'EOL'
# Frontend server
server {
    listen 80;
    server_name 157.230.65.142;

    location / {
        proxy_pass http://frontend:10000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://backend:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Add CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,X-CSRFToken' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Handle OPTIONS preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,X-CSRFToken';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }

    location /admin/ {
        proxy_pass http://backend:8000/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        proxy_pass http://backend:8000/static/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOL

# Fix the frontend JavaScript files to use HTTP instead of HTTPS
docker exec -it obix_frontend_1 /bin/sh -c "
cd /app/dist && 
find . -type f -name '*.js' -exec sed -i 's|https://157.230.65.142/api|http://157.230.65.142/api|g' {} \;
"

# Restart all services
docker-compose restart

echo "All fixes applied. Please clear your browser cache and try again." 