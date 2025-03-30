#!/bin/bash

# This script creates a new superuser with the specified credentials

# Navigate to project directory
cd ~/obix || exit

# Create a temporary Python script to create the user
cat > create_user.py << 'EOF'
from django.contrib.auth.models import User

# Check if user already exists and delete if it does
if User.objects.filter(username='pepepopo').exists():
    User.objects.filter(username='pepepopo').delete()
    print("Deleted existing user 'pepepopo'")

# Create the superuser
User.objects.create_superuser(
    username='pepepopo',
    email='pepepopo@example.com',
    password='moneybankpepe'
)
print("Created new superuser 'pepepopo' with password 'moneybankpepe'")
EOF

# Execute the script inside the backend container
echo "Creating new admin user..."
docker-compose exec backend python -c "$(cat create_user.py)"

# Clean up
rm create_user.py

echo "User creation complete! You can now log in with:"
echo "Username: pepepopo"
echo "Password: moneybankpepe" 