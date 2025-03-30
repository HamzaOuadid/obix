#!/bin/bash

# Entrypoint script for Docker/Heroku deployment

# Create logs directory if it doesn't exist
mkdir -p logs
chmod 755 logs

# Run database migrations
python manage.py migrate --noinput

# Create superuser if DJANGO_SUPERUSER variables are set
if [[ -n "$DJANGO_SUPERUSER_USERNAME" ]] && [[ -n "$DJANGO_SUPERUSER_PASSWORD" ]] && [[ -n "$DJANGO_SUPERUSER_EMAIL" ]]; then
    python manage.py createsuperuser \
        --noinput \
        --username $DJANGO_SUPERUSER_USERNAME \
        --email $DJANGO_SUPERUSER_EMAIL
fi

# Run the command
exec "$@" 