# OBIX Chatbot

A debt assistance chatbot application built with Django and Angular, containerized with Docker.

## Overview

This application provides a user-friendly interface for interacting with a debt assistance chatbot powered by Mistral API. It consists of a Django backend, Angular frontend, PostgreSQL database, and Nginx for serving the application.

## Requirements

- Docker
- Docker Compose
- Git

## Quick Start

### On Linux

```bash
# Clone the repository
git clone https://github.com/HamzaOuadid/obix.git
cd obix

# Make the deployment script executable
chmod +x fix-linux-deployment.sh

# Run the deployment script (requires root privileges)
sudo ./fix-linux-deployment.sh
```

### On Digital Ocean Droplet

```bash
# Download and run the setup script
curl -O https://raw.githubusercontent.com/HamzaOuadid/obix/master/digital-ocean-setup.sh
chmod +x digital-ocean-setup.sh
sudo ./digital-ocean-setup.sh
```

### On Windows

```powershell
# Clone the repository
git clone https://github.com/HamzaOuadid/obix.git
cd obix

# Run the start script
.\start.bat
```

## Accessing the Application

After deployment, you can access the application at:

- Frontend: http://localhost (or your server IP)
- Admin panel: http://localhost/admin (or your server IP/admin)

Default admin credentials:
- Username: admin
- Password: admin_password_change_me

## Project Structure

```
obix/
├── docker-compose.yml       # Docker Compose configuration
├── .env                     # Environment variables
├── obix-chatbot/            # Frontend Angular application
├── obix-chatbot-backend/    # Backend Django application
└── nginx/                   # Nginx configuration
```

## Configuration

All configuration is managed through the `.env` file. Important settings include:

- `MISTRAL_API_KEY`: Your API key for the Mistral language model
- `DJANGO_SUPERUSER_*`: Admin credentials
- `SECRET_KEY`: Django secret key
- Database credentials

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues:

```bash
# Check logs
docker-compose logs

# Reset database
docker-compose down -v
docker-compose up -d
```

### Frontend Build Issues

If the frontend fails to build:

```bash
# Update the frontend Dockerfile
cat > obix-chatbot/Dockerfile << EOF
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps --quiet --ignore-scripts
COPY . .
RUN mkdir -p /app/dist/debt-chatbot/browser
RUN [ -f /app/dist/debt-chatbot/browser/index.html ] || echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>OBIX Chatbot</title></head><body><app-root></app-root></body></html>' > /app/dist/debt-chatbot/browser/index.html
EXPOSE 10000
CMD ["node", "server.js"]
EOF

# Rebuild frontend
docker-compose build --no-cache frontend
docker-compose up -d
```

### Line Ending Issues on Linux

If shell scripts fail with "bad interpreter" errors:

```bash
# Fix line endings
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;
```

## Digital Ocean Specific Notes

For Digital Ocean deployments:

1. Use at least a 1GB RAM droplet
2. The setup script automatically configures swap space
3. It may take several minutes for the application to fully initialize

## Security Considerations

For production deployment:

1. Update the `SECRET_KEY` in `.env`
2. Change default admin credentials
3. Set `DEBUG=False` in production
4. Configure proper HTTPS with a valid SSL certificate
5. Update `DJANGO_ALLOWED_HOSTS` with your domain name

## License

See [LICENSE](LICENSE) file for details.

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

# OBIX Chatbot Frontend Fix

This repository contains scripts to fix the blank page issue with the OBIX Chatbot frontend.

## Issue Description

The frontend container builds successfully but displays a blank page when accessed through the browser. This is likely due to:

1. Missing or incorrect Angular build output
2. Issues with the `server.js` file not properly handling the Angular build directory structure
3. NGINX configuration issues with proxying to the frontend

## Fix Options

### Option 1: Debug and fix the existing frontend

Run the `fix-blank-page.bat` script to:
1. Check logs from frontend and nginx containers
2. Examine the directory structure in the frontend container
3. Create basic frontend assets in the correct location
4. Update the server.js file to better handle directory structures
5. Restart the frontend container

```
.\fix-blank-page.bat
```

### Option 2: Create a simplified frontend container

Run the `direct-frontend-fix.bat` script to:
1. Stop and remove the existing frontend container
2. Create a simplified Node.js Express application
3. Build a new Docker image with the simplified application
4. Run the container and update NGINX configuration

```
.\direct-frontend-fix.bat
```

### Option 3: Run a standalone server without Docker

This provides a direct Express server that can be run on the server without Docker:

1. Copy the `direct-server-minimal.js` file to the server
2. Install dependencies: `npm install express`
3. Run the server: `node direct-server-minimal.js`
4. Access the server at http://[server-ip]:10000

```bash
# On the server
npm install express
node direct-server-minimal.js
```

Then update NGINX to proxy to this service:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:10000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:10000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Login Credentials

Use the following credentials to log in:
- Username: **pepepopo**
- Password: **moneybankpepe**

## Troubleshooting

If you still see a blank page:
1. Clear your browser cache or use incognito/private browsing mode
2. Check developer console for JavaScript errors
3. Try accessing the frontend directly at http://[server-ip]:10000
4. Check container logs for errors: `docker-compose logs frontend`
5. Check NGINX logs: `docker-compose logs nginx` 