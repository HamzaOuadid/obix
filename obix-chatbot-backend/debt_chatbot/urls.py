from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView
from mistral_api.views import get_csrf_token, ChatView
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Define a simple direct login handler
@csrf_exempt
def direct_login(request):
    """Simplified login handler"""
    if request.method == 'OPTIONS':
        response = JsonResponse({})
        response['Access-Control-Allow-Origin'] = request.headers.get('Origin', '*')
        response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type, X-Requested-With, X-CSRFToken'
        response['Access-Control-Allow-Credentials'] = 'true'
        return response
        
    response = JsonResponse({'status': 'ok', 'message': 'Login endpoint available'})
    response['Access-Control-Allow-Origin'] = request.headers.get('Origin', '*')
    response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, X-Requested-With, X-CSRFToken'
    response['Access-Control-Allow-Credentials'] = 'true'
    return response

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/csrf/', get_csrf_token),
    path('api/chat/', ChatView.as_view()),
    path('api/direct-login/', direct_login, name='direct-login'),
    path('api/', include('mistral_api.urls')),
    path('', TemplateView.as_view(template_name='base.html'), name='home'),
] 