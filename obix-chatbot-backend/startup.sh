#!/bin/bash
set -e

echo "Applying database migrations..."
python manage.py migrate

echo "Setting DEBUG environment..."
export DEBUG=1

echo "Setting Gemini API key..."
export GEMINI_API_KEY="AIzaSyA53Q5ntPOItolX3GBUYLPVztRXzFxXgF8"

echo "Setting up CORS for development..."
export CORS_ORIGIN_ALLOW_ALL=True
export DJANGO_SETTINGS_MODULE=debt_chatbot.settings

echo "Starting server with full debug output..."
python -u manage.py runserver 0.0.0.0:8000 