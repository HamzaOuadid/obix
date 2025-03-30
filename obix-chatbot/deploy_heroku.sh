#!/bin/bash

# Bash script to deploy Angular frontend to Heroku
echo -e "\e[32mDeploying OBIX Chatbot Frontend to Heroku...\e[0m"

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo -e "\e[31mHeroku CLI not found. Please install it first: https://devcenter.heroku.com/articles/heroku-cli\e[0m"
    exit 1
fi

# Check if logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    echo -e "\e[33mPlease login to Heroku first\e[0m"
    heroku login
fi

# Create Heroku app if it doesn't exist
APP_NAME="obix-chatbot-frontend"
if ! heroku apps:info $APP_NAME &> /dev/null; then
    echo -e "\e[33mCreating Heroku app: $APP_NAME\e[0m"
    heroku create $APP_NAME
else
    echo -e "\e[33mUsing existing Heroku app: $APP_NAME\e[0m"
fi

# Set environment variables
echo -e "\e[33mSetting environment variables...\e[0m"
heroku config:set NPM_CONFIG_PRODUCTION=false -a $APP_NAME
heroku config:set NODE_ENV=production -a $APP_NAME

# Make sure backend URL is set correctly in environment.prod.ts
echo -e "\e[33mChecking environment configuration...\e[0m"
ENV_FILE="./src/environments/environment.prod.ts"
BACKEND_URL="https://obix-chatbot.herokuapp.com/api"

# Confirm backend URL is correct
echo -e "\e[33mBackend API URL is set to: $BACKEND_URL\e[0m"
echo -e "\e[36mIs this correct? (y/n)\e[0m"
read -r CONFIRMATION
if [ "$CONFIRMATION" != "y" ]; then
    echo -e "\e[33mPlease edit the apiUrl in $ENV_FILE before continuing.\e[0m"
    exit 1
fi

# Initialize git if not already done
if [ ! -d .git ]; then
    echo -e "\e[33mInitializing Git repository...\e[0m"
    git init
    git add .
    git commit -m "Initial commit for Heroku deployment"
fi

# Add Heroku remote
git remote remove heroku 2> /dev/null
heroku git:remote -a $APP_NAME

# Push to Heroku
echo -e "\e[33mPushing to Heroku... This may take a while.\e[0m"
git push heroku master

echo -e "\e[32mDeployment complete! Your app should be available at: https://$APP_NAME.herokuapp.com/\e[0m" 