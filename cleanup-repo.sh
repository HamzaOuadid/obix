#!/bin/bash

# This script cleans up the repository before committing

# Remove unnecessary files and directories
echo "Cleaning up repository..."

# Convert line endings to LF for shell scripts
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

# Make all shell scripts executable
find . -name "*.sh" -type f -exec chmod +x {} \;

# Remove node_modules directories
echo "Removing node_modules directories..."
find . -name "node_modules" -type d -exec rm -rf {} +

# Remove Docker volumes and temporary files
echo "Removing Docker volumes and temporary files..."
find . -name "__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -type f -exec rm -f {} \;
find . -name ".DS_Store" -type f -exec rm -f {} \;

# Clean up any temp or dist files
echo "Cleaning up temporary and build files..."
find . -name "dist" -type d -exec rm -rf {} +
find . -name ".angular" -type d -exec rm -rf {} +

echo "Cleanup completed successfully!" 