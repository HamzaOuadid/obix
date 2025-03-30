#!/bin/bash

# Bash script to deploy Django backend to Heroku
echo -e "\e[32mDeploying OBIX Chatbot Backend to Heroku...\e[0m"

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

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo -e "\e[33mLoaded environment variables from .env file\e[0m"
else
    echo -e "\e[33mWarning: .env file not found. Make sure to set environment variables manually.\e[0m"
fi

# Create Heroku app if it doesn't exist
APP_NAME="obix-chatbot"
if ! heroku apps:info $APP_NAME &> /dev/null; then
    echo -e "\e[33mCreating Heroku app: $APP_NAME\e[0m"
    heroku create $APP_NAME
else
    echo -e "\e[33mUsing existing Heroku app: $APP_NAME\e[0m"
fi

# Add PostgreSQL addon
echo -e "\e[33mSetting up PostgreSQL addon...\e[0m"
heroku addons:create heroku-postgresql:hobby-dev -a $APP_NAME

# Set environment variables
echo -e "\e[33mSetting environment variables...\e[0m"
SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)
heroku config:set SECRET_KEY=$SECRET_KEY -a $APP_NAME
heroku config:set DEBUG=False -a $APP_NAME

# Only set API keys if they exist in the environment
if [ -n "$GEMINI_API_KEY" ]; then
    heroku config:set GEMINI_API_KEY=$GEMINI_API_KEY -a $APP_NAME
else
    echo -e "\e[33mWarning: GEMINI_API_KEY not found in environment. Please set it manually on Heroku.\e[0m"
fi

if [ -n "$MISTRAL_API_KEY" ]; then
    heroku config:set MISTRAL_API_KEY=$MISTRAL_API_KEY -a $APP_NAME
else
    echo -e "\e[33mWarning: MISTRAL_API_KEY not found in environment. Please set it manually on Heroku.\e[0m"
fi

# Initialize git if not already done
if [ ! -d .git ]; then
    echo -e "\e[33mInitializing Git repository...\e[0m"
    git init
    git add .
    git commit -m "Initial commit for Heroku deployment"
fi

# Create logs directory for logging
if [ ! -d "logs" ]; then
    echo -e "\e[33mCreating logs directory...\e[0m"
    mkdir -p logs
    touch logs/.gitkeep
    git add logs/.gitkeep
    git commit -m "Add logs directory"
fi

# Add Heroku remote
git remote remove heroku 2> /dev/null
heroku git:remote -a $APP_NAME

# Push to Heroku
echo -e "\e[33mPushing to Heroku... This may take a while.\e[0m"
git push heroku master

# Run migrations
echo -e "\e[33mRunning database migrations...\e[0m"
heroku run python manage.py migrate -a $APP_NAME

# Run the conversation migration script
echo -e "\e[33mMigrating existing conversations to admin user...\e[0m"
heroku run python scripts/migrate_conversations.py -a $APP_NAME

# Create a Django superuser if needed
echo -e "\e[33mWould you like to create a Django superuser? (y/n)\e[0m"
read -r create_superuser
if [[ "$create_superuser" == "y" ]]; then
    heroku run python manage.py createsuperuser -a $APP_NAME
fi

echo -e "\e[32mDeployment complete! Your app should be available at: https://$APP_NAME.herokuapp.com/\e[0m"
echo -e "\e[31mIMPORTANT: Make sure to change the default admin password if the migration script created one.\e[0m" 