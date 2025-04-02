# OBIX Chatbot Security Guide

This document provides security guidelines for configuring and deploying the OBIX Chatbot application.

## Environment Variables

The application uses environment variables for storing sensitive information. You should set the following variables in your production environment:

- `SECRET_KEY`: A secret key for Django. This should be a random string at least 50 characters long.
- `DEBUG`: Set to "False" for production environments.
- `GEMINI_API_KEY`: Your Google Gemini API key.
- `MISTRAL_API_KEY`: Your Mistral API key (if used).

## Configuration File

A `.env` file can be used for local development, but should NEVER be committed to version control. This file should be added to `.gitignore`.

Example `.env` file:
```
SECRET_KEY=your-secret-key-here
DEBUG=False
GEMINI_API_KEY=your-gemini-api-key-here
MISTRAL_API_KEY=your-mistral-api-key-here
```

## Security Features

The application includes the following security features:

1. **Content Security Policy**: A CSP middleware that helps prevent XSS attacks.
2. **CSRF Protection**: Enhanced CSRF protection with secure cookie settings.
3. **Object-Level Permissions**: Users can only access their own conversations.
4. **Authentication Required**: All API endpoints require authentication.
5. **Rate Limiting**: API rate limiting to prevent abuse.
6. **Secure Headers**: HTTP security headers including HSTS, X-Frame-Options, etc.
7. **HTTPS Enforcement**: Redirects HTTP to HTTPS in production.
8. **Proper Logging**: Sensitive information is not exposed in logs.

## Security Checklist Before Deployment

- [ ] No hardcoded secrets in the codebase
- [ ] Environment variables correctly set
- [ ] Debug mode disabled
- [ ] Database connection uses SSL in production
- [ ] HTTPS enforced
- [ ] API keys have appropriate permissions
- [ ] Default admin password changed
- [ ] `.env` file not in version control
- [ ] Logs directory has appropriate permissions
- [ ] Rate limiting configured

## Security Incident Response

In case of a security incident:

1. Revoke compromised API keys
2. Reset any compromised credentials
3. Document the incident
4. Apply necessary patches

## Regular Security Maintenance

- Update dependencies regularly
- Monitor Django security advisories
- Review access logs for suspicious activity
- Conduct periodic security reviews

For security concerns or to report a vulnerability, please contact the project maintainers. 