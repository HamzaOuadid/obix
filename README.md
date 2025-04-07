# DEBT Chatbot

A chatbot application built with Django backend and Angular frontend using Google's Gemini AI model.

## Setup

1. Clone the repository
2. Run the setup script:
   ```
   setup.bat
   ```
   This will install all dependencies for both backend and frontend.

3. Configure environment variables:
   - Copy `debt-chatbot-backend/.env.sample` to `debt-chatbot-backend/.env`
   - Add your Gemini API key to the `.env` file (you can get one from https://aistudio.google.com/)

## Running the application

Run the application using the provided script:
```
run.bat
```

This will start both the backend server and frontend development server.

- Backend server: http://localhost:8000
- Frontend: http://localhost:4200

## Manual startup

If you prefer to start the servers manually:

### Backend
```
venv\Scripts\activate
cd debt-chatbot-backend
python manage.py runserver
```

### Frontend
```
cd debt-chatbot
npm start
``` 