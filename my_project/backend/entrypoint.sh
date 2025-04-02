#!/bin/bash

set -e

# Function to handle PostgreSQL connection retries
function postgres_ready() {
  python << END
import sys
import psycopg2
import os
import time

host = os.environ.get("POSTGRES_HOST", "db")
port = os.environ.get("POSTGRES_PORT", "5432")
user = os.environ.get("POSTGRES_USER", "obix_user")
password = os.environ.get("POSTGRES_PASSWORD", "postgres")
dbname = os.environ.get("POSTGRES_DB", "obix_db")

retry_count = 10
retry_interval = 3  # seconds

for i in range(retry_count):
    try:
        psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        sys.exit(0)
    except psycopg2.OperationalError:
        if i < retry_count - 1:
            print(f"PostgreSQL not ready yet. Retrying in {retry_interval} seconds... ({i+1}/{retry_count})")
            time.sleep(retry_interval)
        else:
            print("Maximum retry attempts reached. PostgreSQL is not available.")
            sys.exit(1)
END
}

echo "Waiting for PostgreSQL..."
postgres_ready

echo "PostgreSQL is up - executing database migrations"
python manage.py migrate

echo "Collecting static files"
python manage.py collectstatic --noinput

# Create a superuser (will do nothing if already exists)
python manage.py createsuperuser --noinput || echo "Superuser already exists"

# Execute the command passed to the entrypoint
exec "$@" 