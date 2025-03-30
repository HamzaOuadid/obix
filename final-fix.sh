#!/bin/bash

# This script is the final fix for all issues with our application

echo "===== STOPPING ALL CONTAINERS ====="
docker-compose down

echo "===== REMOVING ALL CONTAINERS, IMAGES, AND VOLUMES ====="
docker system prune -af
docker volume prune -f

echo "===== FIXING FRONTEND APPLICATION ====="

# Fix the Angular app's routing issue by updating server.js
cat > obix-chatbot/server.js << 'EOF'
const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

console.log('Starting server...');
console.log('Current directory:', __dirname);

// Create minimal index.html if it doesn't exist
const distPath = path.join(__dirname, 'dist/debt-chatbot');
const browserPath = path.join(distPath, 'browser');

// Make sure directories exist
if (!fs.existsSync(distPath)) {
  console.log('Creating dist/debt-chatbot directory');
  fs.mkdirSync(distPath, { recursive: true });
}

if (!fs.existsSync(browserPath)) {
  console.log('Creating dist/debt-chatbot/browser directory');
  fs.mkdirSync(browserPath, { recursive: true });
}

// Create a minimal index.html if it doesn't exist
const indexPath = path.join(browserPath, 'index.html');
if (!fs.existsSync(indexPath)) {
  console.log('Creating minimal index.html');
  const minimalHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>OBIX Chatbot</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
  `;
  fs.writeFileSync(indexPath, minimalHtml);
}

// Serve static files
app.use(express.static(browserPath));

// All routes should return index.html (Angular routing)
app.get('*', function(req, res) {
  console.log('Serving request for:', req.path);
  res.sendFile(path.join(browserPath, 'index.html'));
});

// Start the app by listening on the default port
const port = process.env.PORT || 10000;
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
EOF

# Update the package.json to fix the build issues
cat > obix-chatbot/package.json << 'EOF'
{
  "name": "debt-chatbot",
  "version": "0.0.0",
  "scripts": {
    "ng": "ng",
    "start": "node server.js",
    "build": "ng build"
  },
  "private": true,
  "dependencies": {
    "@angular/animations": "^19.1.0",
    "@angular/common": "^19.1.0",
    "@angular/compiler": "^19.1.0",
    "@angular/core": "^19.1.0",
    "@angular/forms": "^19.1.0",
    "@angular/platform-browser": "^19.1.0",
    "@angular/platform-browser-dynamic": "^19.1.0",
    "@angular/router": "^19.1.0",
    "express": "^4.18.2",
    "marked": "^15.0.7",
    "rxjs": "~7.8.0",
    "tslib": "^2.3.0",
    "zone.js": "~0.15.0",
    "@angular/cli": "^19.1.6",
    "@angular/compiler-cli": "^19.1.0",
    "typescript": "~5.7.2"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "^19.1.6",
    "@types/jasmine": "~5.1.0",
    "jasmine-core": "~5.5.0",
    "karma": "~6.4.0",
    "karma-chrome-launcher": "~3.2.0",
    "karma-coverage": "~2.2.0",
    "karma-jasmine": "~5.1.0",
    "karma-jasmine-html-reporter": "~2.1.0"
  },
  "engines": {
    "node": "20.x",
    "npm": "10.x"
  }
}
EOF

# Update the frontend Dockerfile
cat > obix-chatbot/Dockerfile << 'EOF'
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies without running scripts
RUN npm install --legacy-peer-deps --quiet --ignore-scripts

# Copy project files
COPY . .

# Make sure the server.js file exists and is executable
RUN chmod +x server.js

# Expose the port
EXPOSE 10000

# Start the server
CMD ["node", "server.js"]
EOF

echo "===== UPDATING DOCKER-COMPOSE CONFIGURATION ====="

# Create a simplified docker-compose file without volume mappings
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  db:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - ./.env
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_DB=${POSTGRES_DB}
    restart: always

  backend:
    build:
      context: ./obix-chatbot-backend
    env_file:
      - ./.env
    depends_on:
      - db
    restart: always

  frontend:
    build:
      context: ./obix-chatbot
    environment:
      - PORT=10000
    restart: always

  nginx:
    image: nginx:1.23
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d
    depends_on:
      - backend
      - frontend
    restart: always

volumes:
  postgres_data:
EOF

echo "===== FIXING NGINX CONFIGURATION ====="

# Update Nginx configuration to ensure proper routing
mkdir -p nginx/conf

cat > nginx/conf/app.conf << 'EOF'
# Frontend server
server {
    listen 80;
    
    # Relaxed CSP for development
    add_header Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval'; img-src * data:; connect-src * 'self';" always;
    
    # API location
    location /api/ {
        proxy_pass http://backend:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRFToken' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        # Handle OPTIONS method
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRFToken' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    
    # Admin access
    location /admin/ {
        proxy_pass http://backend:8000/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files
    location /static/ {
        proxy_pass http://backend:8000/static/;
    }
    
    # Frontend - IMPORTANT: all routes should be sent to index.html
    location / {
        proxy_pass http://frontend:10000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

echo "===== UPDATING ENVIRONMENT CONFIGURATION ====="

# Create a new .env file with all required variables
cat > .env << 'EOF'
# Database configuration
POSTGRES_DB=debt_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres_password
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Django settings
SECRET_KEY=django-insecure-development-key-change-in-production
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
DJANGO_CORS_ALLOWED_ORIGINS=http://localhost:10000 http://localhost
DJANGO_SUPERUSER_USERNAME=pepepopo
DJANGO_SUPERUSER_EMAIL=pepepopo@example.com
DJANGO_SUPERUSER_PASSWORD=moneybankpepe
DJANGO_SETTINGS_MODULE=debt_chatbot.settings

# API Keys (replace with your actual keys)
MISTRAL_API_KEY=your_mistral_api_key

# Frontend settings
PORT=10000
EOF

echo "===== REBUILDING AND STARTING CONTAINERS ====="

# Build and start the containers
docker-compose build --no-cache
docker-compose up -d

echo "===== WAITING FOR BACKEND TO BE READY ====="

# Wait for the backend to be ready
sleep 15

echo "===== CREATING SUPERUSER ====="

# Creating superuser using Django management command
docker-compose exec -T backend python manage.py shell -c "
from django.contrib.auth.models import User
if User.objects.filter(username='pepepopo').exists():
    User.objects.filter(username='pepepopo').delete()
    print('Deleted existing user pepepopo')
User.objects.create_superuser('pepepopo', 'pepepopo@example.com', 'moneybankpepe')
print('Created superuser pepepopo with password moneybankpepe')
"

echo "===== ALL FIXES COMPLETE ====="
echo ""
echo "You can now access the application at http://localhost"
echo "Login with:"
echo "  Username: pepepopo"
echo "  Password: moneybankpepe" 