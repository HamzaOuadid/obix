#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== DEPLOYING DATABASE_URL FIX =====${NC}"

# Navigate to project directory (adjust if needed)
cd ~/obix

# Pull the latest changes
echo -e "${YELLOW}Pulling latest changes from Git...${NC}"
git pull

# Check if git pull was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Git pull failed. Please check your repository and credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}Git pull successful.${NC}"

# Restart the containers to apply changes
echo -e "${YELLOW}Restarting Docker containers...${NC}"
docker-compose down
docker-compose up -d

# Check if docker-compose up was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Docker-compose up failed. Please check your configuration.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker containers restarted successfully.${NC}"

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
sleep 10

# Check the backend logs for errors
echo -e "${YELLOW}Checking backend logs...${NC}"
docker-compose logs backend | grep -i "warning\|error" || echo -e "${GREEN}No warnings or errors found in backend logs.${NC}"

echo -e "${GREEN}===== DEPLOYMENT COMPLETE =====${NC}"
echo -e "${GREEN}You can now access the application at http://$(hostname -I | awk '{print $1}')${NC}" 