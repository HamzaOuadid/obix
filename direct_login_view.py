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
