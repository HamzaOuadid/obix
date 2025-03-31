from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView
from mistral_api.views import get_csrf_token
from direct_login_view import direct_login

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/get-csrf-token/', get_csrf_token, name='get-csrf-token-direct'),
    path('api/direct-login/', direct_login, name='direct-login'),
    path('api/', include('mistral_api.urls')),
    path('', TemplateView.as_view(template_name='base.html'), name='home'),
] 