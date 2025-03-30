#!/bin/bash

# This script fixes the 'ContainerConfig' error by completely removing all existing containers and volumes

echo "===== STOPPING ALL CONTAINERS ====="
docker-compose down

echo "===== REMOVING ALL CONTAINERS AND VOLUMES ====="
docker system prune -af
docker volume prune -f

echo "===== REBUILDING FROM SCRATCH ====="
# First create a simpler docker-compose.yml without volumes for the frontend
cat > docker-compose.simple.yml << 'EOF'
version: '3.8'

services:
  db:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - ./.env
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_DB=${POSTGRES_DB}
    restart: always

  backend:
    build:
      context: ./obix-chatbot-backend
    env_file:
      - ./.env
    depends_on:
      - db
    restart: always

  frontend:
    build:
      context: ./obix-chatbot
    environment:
      - PORT=10000
    restart: always

  nginx:
    image: nginx:1.23
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d
    depends_on:
      - backend
      - frontend
    restart: always

volumes:
  postgres_data:
EOF

# Build and run using the simple configuration
docker-compose -f docker-compose.simple.yml build --no-cache
docker-compose -f docker-compose.simple.yml up -d

echo "===== CREATING ADMIN USER ====="
# Create admin user with proper Django settings
docker-compose -f docker-compose.simple.yml exec backend python -c "
from django.contrib.auth.models import User;
from django.contrib.auth import get_user_model;
User = get_user_model();
if User.objects.filter(username='pepepopo').exists():
    User.objects.filter(username='pepepopo').delete();
    print('Deleted existing user pepepopo');
User.objects.create_superuser('pepepopo', 'pepepopo@example.com', 'moneybankpepe');
print('Created superuser pepepopo with password moneybankpepe');
"

echo "===== SETUP COMPLETE ====="
echo "You can now access the application at http://localhost"
echo "Login with:"
echo "  Username: pepepopo"
echo "  Password: moneybankpepe" 