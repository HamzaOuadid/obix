#!/bin/bash

# Set default SECRET_KEY if not provided
if [ -z "$SECRET_KEY" ]; then
  export SECRET_KEY="django-insecure-default-key-for-development-only"
  echo "WARNING: Using default SECRET_KEY for development. Do not use in production!"
fi

# Wait for PostgreSQL to be available
echo "Waiting for PostgreSQL..."
while ! pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER; do
  sleep 1
done
echo "PostgreSQL is up - continuing..."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Create a superuser if specified in environment (for initial setup)
if [ "$DJANGO_SUPERUSER_USERNAME" ] && [ "$DJANGO_SUPERUSER_EMAIL" ] && [ "$DJANGO_SUPERUSER_PASSWORD" ]; then
  python manage.py createsuperuser --noinput || echo "Superuser already exists or could not be created"
fi

exec "$@" 