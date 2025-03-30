# OBIX Chatbot Project

Welcome to the OBIX Chatbot project! This repository contains a full-stack chatbot application consisting of a Django backend and an Angular frontend.

## Project Structure

- `obix-chatbot/`: Angular frontend application
- `obix-chatbot-backend/`: Django backend API
- `render.yaml`: Deployment configuration for Render

## Quick Start

### Local Development

1. **Backend Setup**:
   ```bash
   cd obix-chatbot-backend
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py runserver
   ```

2. **Frontend Setup**:
   ```bash
   cd obix-chatbot
   npm install
   ng serve
   ```

3. Access the application at `http://localhost:4200`

## Deployment to Render

This project is configured for easy deployment to Render using the root `render.yaml` file.

Quick deployment steps:

1. Push this repository to GitHub (private repository recommended)
2. Create a Render account at [render.com](https://render.com/)
3. In Render dashboard, click "New" > "Blueprint"
4. Connect to your GitHub repository
5. Set required environment variables:
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `MISTRAL_API_KEY`: Your Mistral API key
6. Click "Apply" to create all services

The deployment will create:
- Backend Django API service
- Frontend Angular web service
- PostgreSQL database

## Features

- Angular frontend with modern UI
- Django backend with RESTful API
- Integration with Gemini and Mistral AI
- Secure authentication
- PostgreSQL database
- Comprehensive CORS and security settings

## License

This project is proprietary software. © OBIX 2023-2024. All rights reserved. 