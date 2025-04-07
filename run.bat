@echo off
echo ======================================
echo DEBT Chatbot Launcher
echo ======================================

echo.
echo Activating virtual environment...
call venv\Scripts\activate

echo.
echo Starting Backend Server...
start cmd /k "cd debt-chatbot-backend && python manage.py runserver"

echo.
echo Starting Frontend Server...
start cmd /k "cd debt-chatbot && npm start"

echo.
echo ======================================
echo Both servers are now running!
echo ======================================
echo.
echo Backend: http://localhost:8000
echo Frontend: http://localhost:4200
echo.
echo Close this window to keep servers running in background.
echo Press Ctrl+C in server windows to stop them. 