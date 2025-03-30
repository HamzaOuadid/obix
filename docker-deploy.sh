#!/bin/bash

# Exit on any error
set -e

echo "OBIX Chatbot Docker Deployment Script"
echo "====================================="

# Ensure directory structure exists
mkdir -p nginx/conf
mkdir -p nginx/certbot/conf
mkdir -p nginx/certbot/www

# Check if .env file exists, if not create it from example
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Creating .env file from .env.example..."
        cp .env.example .env
        echo "Please edit .env file with your actual values before continuing."
        exit 1
    else
        echo "Error: .env.example file not found."
        exit 1
    fi
fi

# Ask for domain name
read -p "Enter your domain name (without www, e.g. example.com): " DOMAIN_NAME

# Update Nginx configuration with the provided domain
echo "Updating Nginx configuration with domain: $DOMAIN_NAME"
sed -i "s/example.com/$DOMAIN_NAME/g" nginx/conf/app.conf

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed."
fi

# Pull the latest code
echo "Pulling the latest code from git repository..."
git pull

# Start the containers (without SSL initially)
echo "Starting containers..."
docker-compose up -d

# Set up SSL certificates
echo "Setting up SSL certificates with Let's Encrypt..."
echo "Stopping nginx container to free port 80..."
docker-compose stop nginx

echo "Obtaining SSL certificate..."
docker run --rm -it \
    -v ./nginx/certbot/conf:/etc/letsencrypt \
    -v ./nginx/certbot/www:/var/www/certbot \
    -p 80:80 \
    certbot/certbot certonly --standalone \
    -d $DOMAIN_NAME -d www.$DOMAIN_NAME \
    --email admin@$DOMAIN_NAME --agree-tos --no-eff-email

echo "Restarting all containers..."
docker-compose up -d

echo "Deployment completed successfully!"
echo "Your application should now be accessible at https://$DOMAIN_NAME"
echo "Backend API is available at https://$DOMAIN_NAME/api/" 