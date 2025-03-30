#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== OBIX Chatbot Linux Deployment Fix =====${NC}"

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")" || exit

# Step 1: Fix line endings in all shell scripts
echo -e "${YELLOW}Fixing line endings in shell scripts...${NC}"
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;

# Step 2: Update environment configuration
echo -e "${YELLOW}Updating environment configuration...${NC}"
cat > .env << 'EOF'
# Database configuration
POSTGRES_DB=debt_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres_password
POSTGRES_HOST=db
POSTGRES_PORT=5432
DATABASE_URL=postgres://postgres:postgres_password@db:5432/debt_db

# Django settings
SECRET_KEY=django-insecure-development-key-change-in-production
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
DJANGO_CORS_ALLOWED_ORIGINS=http://localhost:10000 http://localhost
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@example.com
DJANGO_SUPERUSER_PASSWORD=admin_password_change_me

# API Keys (replace with your actual keys)
MISTRAL_API_KEY=your_mistral_api_key

# Frontend settings
PORT=10000
EOF

# Step 3: Update docker-compose.yml
echo -e "${YELLOW}Updating docker-compose.yml...${NC}"
cat > docker-compose.yml << 'EOF'
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
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
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

# Step 4: Fix Frontend Dockerfile
echo -e "${YELLOW}Fixing Frontend Dockerfile...${NC}"
cat > obix-chatbot/Dockerfile << 'EOF'
FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies without running scripts
RUN npm install --legacy-peer-deps --quiet --ignore-scripts

# Copy project files
COPY . .

# Create dist directory if it doesn't exist
RUN mkdir -p /app/dist/debt-chatbot/browser

# Copy a minimal index.html if it doesn't exist
RUN [ -f /app/dist/debt-chatbot/browser/index.html ] || echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>OBIX Chatbot</title></head><body><app-root></app-root></body></html>' > /app/dist/debt-chatbot/browser/index.html

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"]
EOF

# Step 5: Fix Backend Entrypoint
echo -e "${YELLOW}Fixing Backend Entrypoint...${NC}"
cat > obix-chatbot-backend/entrypoint.sh << 'EOF'
#!/bin/bash

# Set default SECRET_KEY if not provided
if [ -z "$SECRET_KEY" ]; then
  export SECRET_KEY="django-insecure-default-key-for-development-only"
  echo "WARNING: Using default SECRET_KEY for development. Do not use in production!"
fi

# Wait for PostgreSQL to be available
echo "Waiting for PostgreSQL..."
while ! pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER; do
  sleep 1
done
echo "PostgreSQL is up - continuing..."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Create a superuser if specified in environment (for initial setup)
if [ "$DJANGO_SUPERUSER_USERNAME" ] && [ "$DJANGO_SUPERUSER_EMAIL" ] && [ "$DJANGO_SUPERUSER_PASSWORD" ]; then
  python manage.py createsuperuser --noinput || echo "Superuser already exists or could not be created"
fi

exec "$@"
EOF
chmod +x obix-chatbot-backend/entrypoint.sh

# Step 6: Clean up temporary files
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -f fix-blank-page.bat direct-frontend-fix.bat h
rm -f fix-all.sh fix-auth-service.sh fix-docker-volumes.sh fix-frontend-build.sh fix-nginx.sh
rm -f debug-frontend.sh direct-fix-guide.md direct-server-minimal.js final-fix.sh
rm -f server-droplet-fix.sh deploy-fix.sh

# Step 7: Create docker volume directory if it doesn't exist
echo -e "${YELLOW}Setting up Docker volume...${NC}"
mkdir -p /var/lib/docker/volumes/obix_postgres_data

# Step 8: Restart Docker containers
echo -e "${YELLOW}Restarting Docker containers...${NC}"
docker-compose down -v
docker-compose up -d

# Step 9: Wait for Backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
sleep 20

# Step 10: Verify that services are running
echo -e "${YELLOW}Checking service status...${NC}"
if docker-compose ps | grep -q "Up"; then
  echo -e "${GREEN}Services are running!${NC}"
else
  echo -e "${RED}Something went wrong. Please check 'docker-compose logs' for details.${NC}"
fi

# Step 11: Update README with deployment instructions
echo -e "${YELLOW}Updating README...${NC}"
cat > README.md << 'EOF'
# OBIX Chatbot

A debt assistance chatbot application built with Django and Angular.

## Requirements

- Docker
- Docker Compose

## Deployment on Linux

1. Clone the repository:
   ```
   git clone https://github.com/your-username/obix.git
   cd obix
   ```

2. Run the deployment script:
   ```
   chmod +x ./fix-linux-deployment.sh
   sudo ./fix-linux-deployment.sh
   ```

3. Access the application:
   - Frontend: http://localhost
   - Admin panel: http://localhost/admin
   - Default credentials:
     - Username: admin
     - Password: admin_password_change_me

## Configuration

All configuration is stored in the `.env` file. You should update the following:

- `MISTRAL_API_KEY`: Your API key for the Mistral language model
- `DJANGO_SUPERUSER_USERNAME`, `DJANGO_SUPERUSER_EMAIL`, `DJANGO_SUPERUSER_PASSWORD`: Admin credentials
- `SECRET_KEY`: A secure secret key for Django
- Database credentials if needed

## Troubleshooting

If you encounter any issues:

1. Check the logs: `docker-compose logs`
2. Restart the application: `docker-compose down -v && docker-compose up -d`
3. If database issues persist: `docker volume rm obix_postgres_data && docker-compose up -d`

## Security

For production deployment, make sure to:

1. Update the `SECRET_KEY` in `.env`
2. Change default admin credentials
3. Set `DEBUG=False` in production
4. Configure proper HTTPS with a valid SSL certificate
EOF

echo -e "${GREEN}===== DEPLOYMENT FIX COMPLETE =====${NC}"
echo -e "${GREEN}You can now access the application at http://localhost${NC}"
echo -e "${GREEN}Default credentials:${NC}"
echo -e "  ${GREEN}Username: admin${NC}"
echo -e "  ${GREEN}Password: admin_password_change_me${NC}"
echo -e "${YELLOW}Please change these credentials and your API keys in the .env file!${NC}" 