# PowerShell script to deploy Angular frontend to Heroku
Write-Host "Deploying OBIX Chatbot Frontend to Heroku..." -ForegroundColor Green

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

# Create Heroku app if it doesn't exist
$appName = "obix-chatbot-frontend"
$appCheck = heroku apps:info $appName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Heroku app: $appName" -ForegroundColor Yellow
    heroku create $appName
} else {
    Write-Host "Using existing Heroku app: $appName" -ForegroundColor Yellow
}

# Set environment variables
Write-Host "Setting environment variables..." -ForegroundColor Yellow
heroku config:set NPM_CONFIG_PRODUCTION=false -a $appName
heroku config:set NODE_ENV=production -a $appName

# Make sure backend URL is set correctly in environment.prod.ts
Write-Host "Checking environment configuration..." -ForegroundColor Yellow
$envFile = ".\src\environments\environment.prod.ts"
$backendUrl = "https://obix-chatbot.herokuapp.com/api"

# Confirm backend URL is correct
Write-Host "Backend API URL is set to: $backendUrl" -ForegroundColor Yellow
Write-Host "Is this correct? (y/n)" -ForegroundColor Cyan
$confirmation = Read-Host
if ($confirmation -ne "y") {
    Write-Host "Please edit the apiUrl in $envFile before continuing." -ForegroundColor Yellow
    exit 1
}

# Check if git is initialized
if (-not (Test-Path .git)) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit for Heroku deployment"
}

# Add Heroku remote
git remote remove heroku
heroku git:remote -a $appName

# Push to Heroku
Write-Host "Pushing to Heroku... This may take a while." -ForegroundColor Yellow
git push heroku master

Write-Host "Deployment complete! Your app should be available at: https://$appName.herokuapp.com/" -ForegroundColor Green 