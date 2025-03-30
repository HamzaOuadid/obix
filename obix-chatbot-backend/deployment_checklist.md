# OBIX Chatbot Deployment Checklist

This document provides a checklist to ensure the application is properly configured for production deployment.

## Security Configuration ✅

- [x] Removed hardcoded API keys from all files
- [x] Environment variables properly set up in `.env` file
- [x] Debug mode set to False by default
- [x] Added proper SECRET_KEY handling
- [x] Configured HTTPS settings with HSTS
- [x] Enhanced CSRF protection
- [x] Implemented object-level permissions
- [x] Added rate limiting
- [x] Created proper logging configuration

## Database Configuration ✅

- [x] Migrations created
- [x] User field added to Conversation model
- [x] Migration script to associate conversations with users

## Deployment Steps

### Heroku Deployment

1. Install Heroku CLI
2. Login to Heroku: `heroku login`
3. Create app: `heroku create obix-chatbot`
4. Set environment variables:
   ```
   heroku config:set SECRET_KEY=your_secret_key
   heroku config:set DEBUG=False
   heroku config:set GEMINI_API_KEY=your_gemini_api_key
   heroku config:set MISTRAL_API_KEY=your_mistral_api_key
   ```
5. Push to Heroku: `git push heroku master`
6. Run migrations: `heroku run python manage.py migrate`
7. Run migration script: `heroku run python scripts/migrate_conversations.py`
8. Create superuser: `heroku run python manage.py createsuperuser`

### Manual Deployment

1. Set up a virtual environment
2. Install dependencies: `pip install -r requirements.txt`
3. Set environment variables in `.env` file
4. Run migrations: `python manage.py migrate`
5. Run migration script: `python scripts/migrate_conversations.py`
6. Create superuser: `python manage.py createsuperuser`
7. Collect static files: `python manage.py collectstatic`
8. Run with Gunicorn: `gunicorn debt_chatbot.wsgi:application`

## Post-Deployment Verification

- [ ] Verify authentication works properly
- [ ] Verify object-level permissions function correctly
- [ ] Test chat functionality
- [ ] Verify rate limiting is properly configured
- [ ] Check that logs are being generated correctly
- [ ] Ensure HTTPS is enforced

## Security Best Practices

- [ ] Update dependencies regularly
- [ ] Monitor logs for suspicious activity
- [ ] Regularly backup the database
- [ ] Review access logs
- [ ] Conduct periodic security reviews

## Crisis Management

1. If API keys are compromised:
   - Revoke old keys
   - Generate new keys
   - Update environment variables

2. If an exploit is discovered:
   - Temporarily disable affected functionality
   - Apply fixes
   - Test thoroughly before re-enabling 