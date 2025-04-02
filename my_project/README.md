# OBIX Chatbot Project

A modern web application featuring a Django backend API with Angular frontend, containerized with Docker and served via Nginx. This project implements a chatbot interface using AI models (Mistral and Gemini) for natural language interactions.

## Project Structure

```
my_project/
│── backend/         # Django backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── settings.py
│   ├── .env.example
│
│── frontend/        # Angular frontend
│   ├── Dockerfile
│   ├── src/
│   │   ├── environments/  # Environment-specific settings
│   ├── nginx/       # Frontend Nginx config
│
│── nginx/           # Main Nginx reverse proxy
│   ├── nginx.conf
│   ├── conf.d/app.conf
│
│── docker-compose.yml
│── .env.example
│── README.md
```

## Features

- Django REST API backend with authentication
- Angular frontend with responsive UI
- PostgreSQL database
- Nginx as reverse proxy with proper routing
- Docker and Docker Compose for containerization
- CORS configuration for cross-domain requests
- Environment variables for configuration
- SSL/TLS support for production

## Setup & Configuration

### 1. Local Development Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/obix-chatbot.git
   cd obix-chatbot
   ```

2. Create environment files:
   ```
   cp .env.example .env
   ```

3. Build and start the containers:
   ```
   docker-compose up --build
   ```

4. Access the application:
   - Frontend: http://localhost/
   - Backend API: http://localhost/api/
   - Admin interface: http://localhost/admin/
   - Default admin credentials: See your .env file

### 2. Production Deployment on DigitalOcean

#### Prerequisites
- A DigitalOcean account
- A domain name (for SSL)
- A generated Mistral API key

#### Steps

1. Create a new Droplet on DigitalOcean:
   - Choose Ubuntu 22.04 LTS
   - Select appropriate size (minimum 2GB RAM recommended)
   - Add your SSH key
   - Enable monitoring

2. Connect to your Droplet and install Docker and Docker Compose:
   ```bash
   ssh root@your-droplet-ip
   
   # Update system packages
   apt update && apt upgrade -y
   
   # Install required packages
   apt install -y apt-transport-https ca-certificates curl software-properties-common
   
   # Add Docker's official GPG key
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   
   # Add Docker repository
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
   
   # Install Docker
   apt update
   apt install -y docker-ce docker-ce-cli containerd.io
   
   # Install Docker Compose
   curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   
   # Verify installation
   docker --version
   docker-compose --version
   ```

3. Clone your repository to the Droplet:
   ```bash
   mkdir -p /var/www
   cd /var/www
   git clone https://github.com/yourusername/obix-chatbot.git
   cd obix-chatbot
   ```

4. Create and configure the environment file for production:
   ```bash
   cp .env.example .env
   nano .env
   ```

5. Update the .env file with production values:
   ```
   # Database settings
   POSTGRES_DB=obix_db
   POSTGRES_USER=obix_user
   POSTGRES_PASSWORD=your_secure_postgres_password
   POSTGRES_HOST=db
   POSTGRES_PORT=5432

   # Django settings
   SECRET_KEY=your_secure_django_secret_key
   DEBUG=False
   ALLOWED_HOSTS=your-domain.com,www.your-domain.com

   # CORS settings
   CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
   CSRF_TRUSTED_ORIGINS=https://your-domain.com,https://www.your-domain.com
   
   # Security settings
   SESSION_COOKIE_SECURE=True
   CSRF_COOKIE_SECURE=True
   
   # AI API keys
   MISTRAL_API_KEY=your_actual_mistral_api_key
   GEMINI_API_KEY=your_actual_gemini_api_key
   
   # Superuser settings
   DJANGO_SUPERUSER_USERNAME=admin
   DJANGO_SUPERUSER_EMAIL=admin@your-domain.com
   DJANGO_SUPERUSER_PASSWORD=your_secure_admin_password
   ```

6. Update the Nginx configuration for production:
   ```bash
   nano nginx/conf.d/app.conf
   ```
   
   Change `server_name localhost;` to `server_name your-domain.com www.your-domain.com;`

7. Build and start the application:
   ```bash
   docker-compose up -d --build
   ```

8. Set up firewall rules:
   ```bash
   ufw allow ssh
   ufw allow http
   ufw allow https
   ufw enable
   ```

### 3. Adding SSL with Let's Encrypt (Production)

1. Install Certbot:
   ```bash
   apt install -y certbot python3-certbot-nginx
   ```

2. Obtain SSL certificate:
   ```bash
   certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

3. Follow the prompts and choose to redirect all HTTP traffic to HTTPS.

4. Certbot will automatically modify your Nginx configuration to use SSL.

5. Restart Nginx:
   ```bash
   docker-compose restart nginx
   ```

6. Add auto-renewal cron job:
   ```bash
   crontab -e
   ```
   
   Add the following line:
   ```
   0 3 * * * certbot renew --quiet && docker-compose restart nginx
   ```

## Application Updates

To update your application:

1. Pull latest changes:
   ```bash
   cd /var/www/obix-chatbot
   git pull origin main
   ```

2. Rebuild and restart containers:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

## Troubleshooting

### CORS Issues

If you experience CORS issues:

1. Verify that `CORS_ALLOWED_ORIGINS` in your Django settings includes all the domains your frontend is served from.

2. Check that Nginx is passing the correct headers:
   ```bash
   docker-compose logs nginx
   ```

3. Inspect browser console for specific CORS errors.

4. Update your Nginx configuration:
   ```bash
   docker-compose restart nginx
   ```

### Database Connection Issues

If the backend can't connect to the database:

1. Check database credentials in .env file.

2. Verify database service is running:
   ```bash
   docker-compose ps
   ```

3. Check database logs:
   ```bash
   docker-compose logs db
   ```

4. Reset the database if needed:
   ```bash
   docker-compose down -v # Caution: This deletes all data
   docker-compose up -d
   ```

### Static Files Not Loading

If static files aren't loading properly:

1. Verify the static volume is correctly mounted in docker-compose.yml.

2. Run collectstatic manually:
   ```bash
   docker-compose exec backend python manage.py collectstatic --noinput
   ```

3. Check Nginx configuration for correct static file paths.

## Backups (Production)

To backup your database:

```bash
#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/var/backups/obix-chatbot"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create database backup
docker-compose exec -T db pg_dump -U obix_user obix_db > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Compress backup
gzip "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Remove backups older than 30 days
find $BACKUP_DIR -name "db_backup_*.sql.gz" -type f -mtime +30 -delete
```

Save this script as `/usr/local/bin/backup-obix.sh`, make it executable:
```bash
chmod +x /usr/local/bin/backup-obix.sh
```

Schedule with cron:
```bash
0 2 * * * /usr/local/bin/backup-obix.sh
```

## License

[MIT License](LICENSE) 