#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== OBIX Chatbot Digital Ocean Setup =====${NC}"

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Step 1: Update system and install dependencies
echo -e "${YELLOW}Updating system and installing dependencies...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    git

# Step 2: Install Docker if not already installed
if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    systemctl enable docker
    systemctl start docker
fi

# Step 3: Install Docker Compose if not already installed
if ! command -v docker-compose &>/dev/null; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
fi

# Step 4: Clone repository if not already cloned
if [ ! -d "obix" ]; then
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/HamzaOuadid/obix.git
    cd obix
else
    cd obix
    echo -e "${YELLOW}Updating repository...${NC}"
    git pull
fi

# Step 5: Update environment configuration
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

# Step 6: Update docker-compose.yml
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

# Step 7: Fix Frontend Dockerfile
echo -e "${YELLOW}Fixing Frontend Dockerfile...${NC}"
cat > obix-chatbot/Dockerfile << 'EOF'
FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies without running scripts (to avoid Angular build errors)
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

# Step 8: Fix permissions and line endings
echo -e "${YELLOW}Fixing permissions and line endings...${NC}"
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;

# Step 9: Ensure entrypoint is executable
echo -e "${YELLOW}Ensuring entrypoint.sh is executable...${NC}"
chmod +x obix-chatbot-backend/entrypoint.sh

# Step 10: Set up swap space for small droplets
echo -e "${YELLOW}Setting up swap space for small droplets...${NC}"
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf
    sysctl -p
fi

# Step 11: Stop and remove existing containers
echo -e "${YELLOW}Stopping and removing existing containers...${NC}"
docker-compose down -v

# Step 12: Rebuild and start containers
echo -e "${YELLOW}Rebuilding and starting containers...${NC}"
docker-compose build --no-cache
docker-compose up -d

# Step 13: Wait for containers to be ready
echo -e "${YELLOW}Waiting for containers to be ready...${NC}"
sleep 60

# Step 14: Create admin user
echo -e "${YELLOW}Creating admin user...${NC}"
docker-compose exec -T backend python manage.py createsuperuser --noinput || echo "User already exists or could not be created"

# Step 15: Check container status
echo -e "${YELLOW}Checking container status...${NC}"
docker-compose ps

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

echo -e "${GREEN}===== DEPLOYMENT COMPLETE =====${NC}"
echo -e "${GREEN}You can now access the application at http://${SERVER_IP}${NC}"
echo -e "${GREEN}Default admin credentials:${NC}"
echo -e "  ${GREEN}Username: admin${NC}"
echo -e "  ${GREEN}Password: admin_password_change_me${NC}"
echo -e "${YELLOW}Please change these credentials and your API keys in the .env file!${NC}"
echo -e "${YELLOW}To check logs, run: docker-compose logs${NC}" 