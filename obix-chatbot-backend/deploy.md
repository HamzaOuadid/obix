# OBIX Chatbot Deployment Guide

This guide provides detailed instructions on how to deploy the OBIX Chatbot application to various hosting platforms.

## Prerequisites

- Python 3.10+
- pip
- Git
- A hosting platform account (Heroku, AWS, Google Cloud, etc.)

## Application Overview

The OBIX Chatbot is a Django-based REST API that provides conversational AI capabilities. It has been secured with various security features:

- Environment variables for sensitive information
- HTTPS and HSTS configuration
- CSRF protection
- Object-level permissions
- Rate limiting
- Content Security Policy
- Proper logging

## Deployment Options

### 1. Heroku Deployment

Requirements:
- Verified Heroku account
- Heroku CLI

Steps:
```bash
# Login to Heroku
heroku login

# Create a new Heroku app
heroku create obix-chatbot

# Set environment variables
heroku config:set SECRET_KEY=your-secret-key
heroku config:set DEBUG=False
heroku config:set GEMINI_API_KEY=your-gemini-api-key
heroku config:set MISTRAL_API_KEY=your-mistral-api-key

# Push code to Heroku
git push heroku master

# Run migrations
heroku run python manage.py migrate

# Run the conversation migration script
heroku run python scripts/migrate_conversations.py

# Create an admin user
heroku run python manage.py createsuperuser
```

### 2. Docker Deployment

Requirements:
- Docker
- Docker Compose (optional)

Steps:
```bash
# Build the Docker image
docker build -t obix-chatbot .

# Run the container
docker run -p 8000:8000 \
  -e SECRET_KEY=your-secret-key \
  -e DEBUG=False \
  -e GEMINI_API_KEY=your-gemini-api-key \
  -e MISTRAL_API_KEY=your-mistral-api-key \
  obix-chatbot

# Alternatively, use docker-compose
docker-compose up -d
```

### 3. Manual Deployment

Requirements:
- A VPS or cloud instance
- Python 3.10+
- Nginx or Apache

Steps:
```bash
# Create a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export SECRET_KEY=your-secret-key
export DEBUG=False
export GEMINI_API_KEY=your-gemini-api-key
export MISTRAL_API_KEY=your-mistral-api-key

# Run migrations
python manage.py migrate

# Run the conversation migration script
python scripts/migrate_conversations.py

# Create an admin user
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Run with Gunicorn
gunicorn debt_chatbot.wsgi:application --bind 0.0.0.0:8000
```

## Configuration Files

### Nginx Configuration

A secure Nginx configuration is provided in `nginx.conf`. This includes:
- HTTP/2 support
- Security headers
- SSL configuration
- Static file caching

### Docker Configuration

A Docker configuration is provided in `Dockerfile` and `docker-compose.yml`. This includes:
- Python 3.10 runtime
- Non-root user for security
- Volume for logs
- Entrypoint script for initialization

## Post-Deployment Verification

After deployment, verify that:
1. The application is accessible via HTTPS
2. Authentication works properly
3. Object-level permissions are enforced
4. Rate limiting is functioning
5. Logs are being properly generated

## Troubleshooting

Common issues:
- **Database migrations fail**: Check database connection string
- **Static files not found**: Ensure collectstatic was run
- **API errors**: Verify API keys are set correctly
- **CORS errors**: Check CORS settings for frontend domain

## Security Maintenance

Regular maintenance tasks:
- Update dependencies regularly
- Monitor logs for suspicious activity
- Perform periodic security reviews
- Backup database regularly

## Conclusion

The OBIX Chatbot has been configured with security best practices and is ready for deployment to production environments. Choose the deployment method that best fits your infrastructure and scaling needs. 