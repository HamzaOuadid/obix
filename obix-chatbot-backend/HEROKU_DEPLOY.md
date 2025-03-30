# Deploying DEBT Chatbot Backend to Heroku

This guide explains how to deploy the DEBT Chatbot backend Django application to Heroku.

## Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- Git
- A Heroku account

## Deployment Steps

1. **Login to Heroku CLI**

   ```bash
   heroku login
   ```

2. **Navigate to the backend directory**

   ```bash
   cd debt-chatbot-backend
   ```

3. **Initialize Git repository** (if not already done)

   ```bash
   git init
   git add .
   git commit -m "Initial commit for Heroku deployment"
   ```

4. **Create a Heroku app**

   ```bash
   heroku create debt-chatbot
   ```

5. **Add PostgreSQL addon**

   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

6. **Set environment variables**

   ```bash
   heroku config:set SECRET_KEY=your_secret_key
   heroku config:set DEBUG=False
   heroku config:set GEMINI_API_KEY=AIzaSyA53Q5ntPOItolX3GBUYLPVztRXzFxXgF8
   ```

7. **Push to Heroku**

   ```bash
   git push heroku main
   ```

8. **Run database migrations**

   ```bash
   heroku run python manage.py migrate
   ```

9. **Create a superuser** (optional)

   ```bash
   heroku run python manage.py createsuperuser
   ```

10. **Open the app**

    ```bash
    heroku open
    ```

## Troubleshooting

- **Application Error**: Check the logs with `heroku logs --tail`
- **Database Issues**: Make sure migrations ran successfully
- **Static Files**: Ensure `STATIC_ROOT` is set correctly in settings.py

## Additional Resources

- [Heroku Django Deployment Guide](https://devcenter.heroku.com/articles/django-app-configuration)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/5.0/howto/deployment/checklist/) 