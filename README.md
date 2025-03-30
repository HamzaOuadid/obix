# DEBT - OBIX Chatbot

A chat interface that uses AI to answer questions related to the OBIX system and its functionality.

## Project Structure

- `obix-chatbot/` - Angular frontend application
- `obix-chatbot-backend/` - Django backend API
- `nginx/` - Nginx configuration for serving the application
- `docker-compose.yml` - Docker Compose configuration for local development

## Prerequisites

- Docker and Docker Compose
- Git

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DEBT
   ```

2. Create a `.env` file in the root directory with the following variables:
   ```
   # Database
   POSTGRES_DB=debt_db
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=password

   # Django
   DEBUG=True
   SECRET_KEY=your_secret_key
   DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
   
   # API Keys
   MISTRAL_API_KEY=your_mistral_api_key
   ```

3. Build and start the containers:
   ```bash
   docker-compose build
   docker-compose up -d
   ```

4. Create a superuser for the Django admin:
   ```bash
   docker-compose exec backend python manage.py createsuperuser
   ```

5. Access the application:
   - Frontend: http://localhost
   - Backend API: http://localhost/api
   - Django Admin: http://localhost/admin

## Development

### Frontend

The Angular frontend is located in the `obix-chatbot/` directory. To make changes:

1. Modify the files in the `obix-chatbot/` directory
2. Rebuild the frontend container:
   ```bash
   docker-compose build frontend
   docker-compose up -d frontend
   ```

### Backend

The Django backend is located in the `obix-chatbot-backend/` directory. To make changes:

1. Modify the files in the `obix-chatbot-backend/` directory
2. Rebuild the backend container:
   ```bash
   docker-compose build backend
   docker-compose up -d backend
   ```

## Troubleshooting

### Checking Logs

To check logs for troubleshooting:

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs frontend
docker-compose logs backend
docker-compose logs nginx
```

### Common Issues

1. **502 Bad Gateway**: Check if the backend service is running correctly
2. **Missing CSRF Token**: Make sure the browser is sending requests to the correct API endpoint
3. **Database Connection Issues**: Verify the database container is running and the connection settings are correct

## License

This project is proprietary software. © OBIX 2023-2024. All rights reserved. 