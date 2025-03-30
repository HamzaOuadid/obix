#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Cleaning up repository =====${NC}"

# Files to keep
KEEP_FILES=(
  "README.md"
  "digital-ocean-setup.sh"
  "fix-linux-deployment.sh"
  "docker-compose.yml"
  ".env"
  ".env.example"
  ".gitignore"
  "LICENSE"
  "start.sh"
  "cleanup-repo.sh"
)

# These directories should be kept
KEEP_DIRS=(
  "obix-chatbot-backend"
  "obix-chatbot"
  "nginx"
  ".git"
)

# Delete unnecessary files
echo -e "${YELLOW}Deleting unnecessary files...${NC}"

# First list the files to be deleted
echo -e "${YELLOW}The following files will be deleted:${NC}"
for file in *; do
  if [[ -f "$file" && ! " ${KEEP_FILES[@]} " =~ " ${file} " ]]; then
    echo "  - $file"
  fi
done

# Confirm deletion
read -p "Proceed with deletion? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Deletion aborted${NC}"
  exit 1
fi

# Execute deletion
for file in *; do
  if [[ -f "$file" && ! " ${KEEP_FILES[@]} " =~ " ${file} " ]]; then
    rm -f "$file"
    echo -e "${GREEN}Deleted: $file${NC}"
  fi
done

echo -e "${GREEN}===== Repository cleaned up =====${NC}"

# Commit changes
echo -e "${YELLOW}Do you want to commit and push these changes? (y/n)${NC}"
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git add .
  git commit -m "Clean up repository by removing unnecessary files"
  git push
  echo -e "${GREEN}Changes committed and pushed${NC}"
else
  echo -e "${YELLOW}Changes not committed. You can manually commit and push later.${NC}"
fi 