#!/bin/bash

# Docker Compose Configuration Inspection
echo "=== DOCKER COMPOSE CONFIGURATION INSPECTION ==="

# Step 1: Find and display the docker-compose file
echo "Looking for docker-compose.yml..."
find . -name "docker-compose*.yml" -type f

# Step 2: Display docker-compose configuration
echo -e "\nShowing docker-compose configuration..."
cat docker-compose.yml

# Step 3: Show all Docker images
echo -e "\nListing Docker images..."
docker images

# Step 4: Show running containers
echo -e "\nShowing running containers..."
docker ps

# Step 5: Check container IDs
echo -e "\nChecking container IDs..."
docker ps -a

# Step 6: Get backend container ID
BACKEND_ID=$(docker ps -a --filter name=obix_backend -q)
echo -e "\nBackend container ID: $BACKEND_ID"

# Step 7: Inspect backend container configuration
echo -e "\nInspecting backend container configuration..."
docker inspect $BACKEND_ID || echo "Could not inspect container"

# Step 8: Check django settings.py file in host directory
echo -e "\nLooking for Django settings.py in host directory..."
find . -name "settings.py" -type f

echo -e "\nInspection complete. Use this information to understand the Docker setup." 