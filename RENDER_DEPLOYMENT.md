# OBIX Chatbot Deployment Guide for Render

This guide provides detailed instructions for deploying the OBIX Chatbot application on [Render](https://render.com/), a cloud platform that makes it easy to deploy web services.

## Prerequisites

1. GitHub account
2. Render account (sign up at [render.com](https://render.com/))
3. Google Gemini API key
4. Mistral API key

## Step 1: Prepare GitHub Repository

1. Create a new private repository on GitHub
2. Push both the frontend and backend code to this repository with the following structure:
   ```
   obix-chatbot/              # Frontend Angular code
   ├── render.yaml            # Frontend render configuration
   ├── ... (other files)
   
   obix-chatbot-backend/      # Backend Django code
   ├── render.yaml            # Backend render configuration
   ├── ... (other files)
   
   RENDER_DEPLOYMENT.md       # This deployment guide
   ```

## Step 2: Deploy Using Blueprints (Recommended)

Render Blueprints allow you to deploy multiple services from a single repository. Here's how to deploy both services at once:

1. In your Render dashboard, click "New +" then select "Blueprint"
2. Connect your GitHub account if not already connected
3. Select the repository containing your code
4. Render will detect the `render.yaml` files and present the services to be created
5. For the backend service, manually set the following environment variables:
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `MISTRAL_API_KEY`: Your Mistral API key
6. Review the configuration and click "Apply" to create all the services
7. Render will provision a PostgreSQL database and deploy both the frontend and backend services

## Step 3: Manual Deployment (Alternative)

If you prefer to deploy services manually or the Blueprint doesn't work as expected:

### Backend Deployment:

1. In your Render dashboard, click "New +" then select "Web Service"
2. Connect to your GitHub repository
3. Select the backend directory (`obix-chatbot-backend`)
4. Configure the service:
   - Name: `obix-chatbot-backend`
   - Environment: `Python 3`
   - Region: Choose the closest one to your users
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `gunicorn debt_chatbot.wsgi:application --log-file -`
   - Set environment variables:
     - `PYTHON_VERSION`: `3.10.0`
     - `SECRET_KEY`: Generate a random string
     - `DEBUG`: `false`
     - `ALLOWED_HOSTS`: `*.onrender.com,localhost,127.0.0.1`
     - `GEMINI_API_KEY`: Your Google Gemini API key
     - `MISTRAL_API_KEY`: Your Mistral API key
5. Create a PostgreSQL database:
   - Click "New +" then select "PostgreSQL"
   - Configure your database name and user
   - Once created, note the internal connection URL
6. Add the database connection URL to the backend service:
   - Go to your backend service dashboard
   - Add the environment variable `DATABASE_URL` with the internal connection string
7. Deploy the service and wait for it to build

### Frontend Deployment:

1. In your Render dashboard, click "New +" then select "Web Service"
2. Connect to your GitHub repository
3. Select the frontend directory (`obix-chatbot`)
4. Configure the service:
   - Name: `obix-chatbot-frontend`
   - Environment: `Node`
   - Region: Choose the same region as your backend
   - Build Command: `npm install && npm run build`
   - Start Command: `node server.js`
   - Set environment variables:
     - `NODE_VERSION`: `20.11.0`
     - `API_URL`: URL of your backend (e.g., `https://obix-chatbot-backend.onrender.com`)
     - `PORT`: `10000`
5. Deploy the service and wait for it to build

## Step 4: Verify Deployment

1. Check both services' logs for any errors
2. Access the frontend application at the URL provided by Render
3. Test the chat functionality to ensure the frontend can communicate with the backend

## Step 5: Set Up Custom Domain (Optional)

If you have a custom domain:

1. In your Render dashboard, navigate to the frontend service
2. Go to "Settings" > "Custom Domain"
3. Follow the instructions to configure your domain with the provided DNS records

## Troubleshooting

### Common Issues:

1. **Backend returns 500 errors:**
   - Check the backend logs for specific error messages
   - Verify that all environment variables are set correctly
   - Make sure the database connection is working

2. **Frontend displays but chat doesn't work:**
   - Check browser console for network errors
   - Verify the API URL is correct in the frontend environment
   - Make sure CORS is properly configured in the backend

3. **Database connection issues:**
   - Check that the DATABASE_URL format is correct
   - Verify the database is running and accessible from the backend service

### Getting Support:

- For Render-specific issues, consult the [Render documentation](https://render.com/docs)
- For application-specific issues, check the application logs or contact the development team

## Security Considerations

- Keep your GitHub repository private
- Never commit API keys or sensitive credentials to the repository
- Use environment variables for all sensitive configuration
- Enable Render's automatic HTTPS for all services 