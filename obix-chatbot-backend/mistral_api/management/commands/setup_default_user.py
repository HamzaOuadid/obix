from django.core.management.base import BaseCommand
from django.contrib.auth.models import User

class Command(BaseCommand):
    help = 'Creates the default user'

    def handle(self, *args, **kwargs):
        if not User.objects.filter(username='pepe').exists():
            User.objects.create_user('pepe', password='moneybankpepe')
            self.stdout.write(self.style.SUCCESS('Successfully created default user')) 