#!/bin/bash

# Script to check and set up Django login credentials
echo "=== DJANGO LOGIN CREDENTIAL CHECKER ==="

# Step 1: Check if Django admin exists
echo "Checking for existing admin users..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"from django.contrib.auth.models import User; print('Admin users:', User.objects.filter(is_superuser=True).count())\""

# Step 2: List admin users
echo "Listing admin users (if any)..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"from django.contrib.auth.models import User; print('\\n'.join([f'{user.username} (Active: {user.is_active})' for user in User.objects.filter(is_superuser=True)]))\""

# Step 3: Create a new admin superuser
echo "Creating admin superuser..."
docker exec -it obix_backend_1 bash -c "python3 /app/manage.py createsuperuser"

# Step 4: Alternatively, create admin user non-interactively
echo "If the interactive creation didn't work, you can try this non-interactive method:"
echo "Creating admin user (non-interactive)..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"
from django.contrib.auth.models import User;
username = 'admin';
email = 'admin@example.com';
password = 'password123';
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password);
    print(f'Created superuser {username} with password {password}');
else:
    user = User.objects.get(username=username);
    user.set_password(password);
    user.is_active = True;
    user.save();
    print(f'Reset password for user {username} to {password}');
\""

# Step 5: Verify user creation
echo "Verifying admin users after creation..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"from django.contrib.auth.models import User; print('Admin users now:', User.objects.filter(is_superuser=True).count())\""

# Step 6: Test authentication directly
echo "Testing authentication directly..."
docker exec obix_backend_1 bash -c "python3 /app/manage.py shell -c \"
from django.contrib.auth import authenticate;
user = authenticate(username='admin', password='password123');
print('Authentication result:', 'Success' if user else 'Failed');
print('User details:', user.username if user else 'None');
\""

echo "=== CREDENTIALS SETUP COMPLETE ==="
echo "You should now be able to log in with:"
echo "Username: admin"
echo "Password: password123"
echo "Try logging in again at: http://157.230.65.142/login-test.html" 