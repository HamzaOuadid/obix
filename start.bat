@echo off
echo OBIX Chatbot Startup Script

REM Check if Docker is installed
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Docker is required but not found!
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if .env file exists, create if not
if not exist .env (
    echo Creating .env file...
    (
        echo # Database configuration
        echo POSTGRES_DB=debt_db
        echo POSTGRES_USER=postgres
        echo POSTGRES_PASSWORD=postgres_password
        echo POSTGRES_HOST=db
        echo POSTGRES_PORT=5432
        echo.
        echo # Django settings
        echo SECRET_KEY=django-insecure-development-key-change-in-production
        echo DEBUG=True
        echo DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
        echo DJANGO_CORS_ALLOWED_ORIGINS=http://localhost:10000 http://localhost
        echo DJANGO_SUPERUSER_USERNAME=admin
        echo DJANGO_SUPERUSER_EMAIL=admin@example.com
        echo DJANGO_SUPERUSER_PASSWORD=admin_password_change_me
        echo.
        echo # API Keys (replace with your actual keys)
        echo MISTRAL_API_KEY=your_mistral_api_key
        echo.
        echo # Frontend settings
        echo PORT=10000
    ) > .env
    echo .env file created. Please edit it with your API keys.
    echo Press any key to continue or Ctrl+C to abort and update keys manually
    pause
)

REM Clean up existing containers and volumes to avoid ContainerConfig errors
echo Cleaning up existing containers...
docker-compose down
docker system prune -f --volumes

REM Build and start the containers
echo Building and starting containers...
docker-compose build --no-cache
docker-compose up -d

REM Wait for backend container to be ready
echo Waiting for backend to be ready...
timeout /t 15 /nobreak

REM Apply migrations
echo Applying database migrations...
docker-compose exec backend python manage.py migrate || echo Migration failed, but continuing...

REM Display information
echo.
echo Application is running!
echo Frontend: http://localhost
echo Backend API: http://localhost/api
echo Admin panel: http://localhost/admin
echo Default admin credentials:
echo   Username: admin
echo   Password: admin_password_change_me (change this in .env file)
echo.
echo To stop the application, run: docker-compose down
echo.
pause 