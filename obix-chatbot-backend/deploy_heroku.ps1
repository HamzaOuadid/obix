# PowerShell script to deploy Django backend to Heroku
Write-Host "Deploying OBIX Chatbot Backend to Heroku..." -ForegroundColor Green

# Check if Heroku CLI is installed
$herokuCheck = Get-Command heroku -ErrorAction SilentlyContinue
if (-not $herokuCheck) {
    Write-Host "Heroku CLI not found. Please install it first: https://devcenter.heroku.com/articles/heroku-cli" -ForegroundColor Red
    exit 1
}

# Check if logged in to Heroku
$loginCheck = heroku auth:whoami
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Heroku first using 'heroku login'" -ForegroundColor Yellow
    heroku login
}

# Load environment variables from .env file
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Variable -Name $key -Value $value
        }
    }
} else {
    Write-Host "Warning: .env file not found. Make sure to set environment variables manually." -ForegroundColor Yellow
}

# Create Heroku app if it doesn't exist
$appName = "obix-chatbot"
$appCheck = heroku apps:info $appName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Heroku app: $appName" -ForegroundColor Yellow
    heroku create $appName
} else {
    Write-Host "Using existing Heroku app: $appName" -ForegroundColor Yellow
}

# Add PostgreSQL addon
Write-Host "Setting up PostgreSQL..." -ForegroundColor Yellow
heroku addons:create heroku-postgresql:hobby-dev -a $appName

# Set environment variables
Write-Host "Setting environment variables..." -ForegroundColor Yellow
$secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | ForEach-Object {[char]$_})
heroku config:set SECRET_KEY=$secretKey -a $appName
heroku config:set DEBUG=False -a $appName

# Only set GEMINI_API_KEY if it exists in the current environment
if (Test-Path Variable:GEMINI_API_KEY) {
    heroku config:set GEMINI_API_KEY=$GEMINI_API_KEY -a $appName
} else {
    Write-Host "Warning: GEMINI_API_KEY not found in environment. Please set it manually on Heroku." -ForegroundColor Yellow
}

# Only set MISTRAL_API_KEY if it exists in the current environment
if (Test-Path Variable:MISTRAL_API_KEY) {
    heroku config:set MISTRAL_API_KEY=$MISTRAL_API_KEY -a $appName
} else {
    Write-Host "Warning: MISTRAL_API_KEY not found in environment. Please set it manually on Heroku." -ForegroundColor Yellow
}

# Check if git is initialized
if (-not (Test-Path .git)) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit for Heroku deployment"
}

# Create logs directory for logging
if (-not (Test-Path "logs")) {
    Write-Host "Creating logs directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "logs" | Out-Null
    New-Item -ItemType File -Path "logs/.gitkeep" | Out-Null
    git add logs/.gitkeep
    git commit -m "Add logs directory"
}

# Add Heroku remote
git remote remove heroku
heroku git:remote -a $appName

# Push to Heroku
Write-Host "Pushing to Heroku... This may take a while." -ForegroundColor Yellow
git push heroku master

# Run migrations
Write-Host "Running migrations..." -ForegroundColor Yellow
heroku run python manage.py migrate -a $appName

# Run the conversation migration script
Write-Host "Migrating existing conversations to admin user..." -ForegroundColor Yellow
heroku run python scripts/migrate_conversations.py -a $appName

# Create a Django superuser if needed
Write-Host "Would you like to create a Django superuser? (y/n)" -ForegroundColor Yellow
$createSuperuser = Read-Host
if ($createSuperuser -eq "y") {
    heroku run python manage.py createsuperuser -a $appName
}

Write-Host "Deployment complete! Your app should be available at: https://$appName.herokuapp.com/" -ForegroundColor Green
Write-Host "IMPORTANT: Make sure to change the default admin password if the migration script created one." -ForegroundColor Red 