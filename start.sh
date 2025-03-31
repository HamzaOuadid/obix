#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo "Docker and Docker Compose are required to run this application"
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if .env file exists, create if not
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env 2>/dev/null || cat > .env << EOF
# Database configuration
POSTGRES_DB=debt_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres_password
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Django settings
SECRET_KEY=django-insecure-development-key-change-in-production
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
DJANGO_CORS_ALLOWED_ORIGINS=http://localhost:10000 http://localhost
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@example.com
DJANGO_SUPERUSER_PASSWORD=admin_password_change_me

# API Keys (replace with your actual keys)
MISTRAL_API_KEY=your_mistral_api_key

# Frontend settings
PORT=10000
EOF
    echo ".env file created. Please edit it with your API keys."
    echo "Press Enter to continue or Ctrl+C to abort and update keys manually"
    read
fi

# Clean up existing containers and volumes to avoid ContainerConfig errors
echo "Cleaning up existing containers..."
docker-compose down 
docker system prune -f --volumes

# Build and start the containers
echo "Building and starting containers..."
docker-compose build --no-cache
docker-compose up -d

# Wait for backend container to be ready
echo "Waiting for backend to be ready..."
sleep 15

# Check for migrations
echo "Applying database migrations..."
docker-compose exec backend python manage.py migrate || echo "Migration failed, but continuing..."

echo "Application is running!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost/api"
echo "Admin panel: http://localhost/admin"
echo "Default admin credentials (if created):"
echo "  Username: admin"
echo "  Password: admin_password_change_me (change this in .env file)"

echo "To stop the application, run: docker-compose down" 