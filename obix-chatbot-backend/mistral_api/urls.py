from django.urls import path
from . import views
from django.contrib.auth.decorators import login_required
from rest_framework.authtoken.views import obtain_auth_token

urlpatterns = [
    path('', views.login_view, name='login'),
    path('get-csrf-token/', views.get_csrf_token, name='get-csrf-token'),
    path('chat/', views.chat, name='chat'),
    path('conversations/', views.ConversationListView.as_view(), name='conversation-list'),
    path('conversations/<uuid:conversation_id>/', views.ConversationDetailView.as_view(), name='conversation-detail'),
    path('logout/', views.logout_view, name='logout'),
    path('api-token-auth/', obtain_auth_token, name='api_token_auth'),  # For testing authentication
] 