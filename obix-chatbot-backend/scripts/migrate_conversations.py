#!/usr/bin/env python
"""
Script to migrate existing conversations to a specific user.
This should be run after adding the user field to the Conversation model.
"""
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'debt_chatbot.settings')

# Initialize Django
django.setup()

from django.contrib.auth.models import User
from mistral_api.models import Conversation

def migrate_conversations():
    """
    Migrate all conversations without a user to the admin user.
    If admin user doesn't exist, create it.
    """
    # Get or create admin user
    try:
        admin_user = User.objects.get(username='admin')
        print(f"Found admin user: {admin_user.username}")
    except User.DoesNotExist:
        admin_user = User.objects.create_superuser(
            'admin', 
            'admin@example.com', 
            'changeme_immediately'  # This is a placeholder, should be changed immediately
        )
        print(f"Created admin user: {admin_user.username}")
    
    # Find all conversations without a user
    orphaned_conversations = Conversation.objects.filter(user__isnull=True)
    count = orphaned_conversations.count()
    print(f"Found {count} conversations without a user")
    
    # Assign them to the admin user
    if count > 0:
        orphaned_conversations.update(user=admin_user)
        print(f"Assigned {count} conversations to user: {admin_user.username}")
    
    print("Migration complete!")

if __name__ == "__main__":
    migrate_conversations() 