@echo off
echo ======================================
echo DEBT Chatbot Environment Setup
echo ======================================

echo.
echo Checking Python installation...
python --version 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo Python is not installed or not in PATH!
    echo Please install Python 3.8 or higher and try again.
    exit /b 1
)

echo.
echo Checking Node.js installation...
node --version 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo Node.js is not installed or not in PATH!
    echo Please install Node.js 16 or higher and try again.
    exit /b 1
)

echo.
echo Setting up Python virtual environment...
python -m venv venv
call venv\Scripts\activate

echo.
echo Upgrading pip...
python -m pip install --upgrade pip

echo.
echo Installing backend dependencies...
cd debt-chatbot-backend
pip install -r requirements.txt

echo.
echo Uninstalling Mistral and installing Google's Gemini API library...
pip uninstall -y mistralai
pip install google-generativeai

echo.
echo Applying database migrations...
python manage.py migrate

echo.
echo Setting up frontend dependencies...
cd ..\debt-chatbot
npm install

echo.
echo ======================================
echo Setup complete!
echo ======================================
echo.
echo To start the backend server:
echo   1. Activate the virtual environment: venv\Scripts\activate
echo   2. Navigate to backend directory: cd debt-chatbot-backend
echo   3. Run: python manage.py runserver
echo.
echo To start the frontend:
echo   1. Navigate to frontend directory: cd debt-chatbot
echo   2. Run: npm start
echo.
echo Press any key to exit...
pause > nul 