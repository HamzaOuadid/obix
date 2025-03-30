# OBIX Chatbot Backend

This is the backend server for the OBIX Chatbot application, which uses AI-powered responses from models like Google's Gemini API and Mistral AI.

## Setup and Installation

1. Clone the repository
2. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Set up environment variables in a `.env` file:
   ```
   SECRET_KEY=your_secret_key
   DEBUG=False
   GEMINI_API_KEY=your_gemini_api_key
   MISTRAL_API_KEY=your_mistral_api_key
   ```

## Running the Server

To start the Django development server:

```bash
python manage.py runserver
```

The server will be available at http://localhost:8000/

## API Endpoints

- POST `/api/chat/`: Send a message to the chatbot
  - Request body: `{ "message": "Your message here" }`
  - Response: `{ "response": "AI response" }`

## Testing the AI API Integration

A test script is included to verify the API integration:

```bash
# Make the script executable (Linux/Mac)
chmod +x test_gemini.sh

# Run the test
./test_gemini.sh
```

Or you can run the Python script directly:

```bash
python test_gemini.py
```

## Deployment Options

### 1. Heroku Deployment

Requirements:
- Verified Heroku account
- Heroku CLI

Steps:
```bash
# Login to Heroku
heroku login

# Create a new Heroku app
heroku create obix-chatbot

# Set environment variables
heroku config:set SECRET_KEY=your-secret-key
heroku config:set DEBUG=False
heroku config:set GEMINI_API_KEY=your-gemini-api-key
heroku config:set MISTRAL_API_KEY=your-mistral-api-key

# Push code to Heroku
git push heroku main

# Run migrations
heroku run python manage.py migrate

# Create an admin user (optional)
heroku run python manage.py createsuperuser
```

### 2. Docker Deployment

Requirements:
- Docker
- Docker Compose (optional)

Steps:
```bash
# Create a .env file with your configuration
# Build the Docker image
docker build -t obix-chatbot .

# Run the container
docker run -p 8000:8000 \
  -e SECRET_KEY=your-secret-key \
  -e DEBUG=False \
  -e GEMINI_API_KEY=your-gemini-api-key \
  -e MISTRAL_API_KEY=your-mistral-api-key \
  obix-chatbot

# Alternatively, use docker-compose
docker-compose up -d
```

### 3. Manual Deployment

See the detailed instructions in [deploy.md](deploy.md).

## Deployment to Render

This project is configured for easy deployment to [Render](https://render.com/). To deploy:

1. Push this repository to GitHub
2. Create a new Render account or sign in to an existing one
3. Click "New +" and select "Blueprint" from the dropdown
4. Connect your GitHub account and select the repository
5. Render will automatically detect the `render.yaml` file and configure:
   - A Python web service for the backend
   - A PostgreSQL database

6. Before deploying, set the following environment variables in Render dashboard:
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `MISTRAL_API_KEY`: Your Mistral API key

7. Click "Apply" to create the services

8. Once deployed, your backend API will be available at:
   - https://obix-chatbot-backend.onrender.com

### Manual Deployment (Without Blueprint)

If you want to deploy manually:

1. Create a new Web Service in Render
2. Connect your GitHub repository
3. Use the following settings:
   - Environment: Python
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `gunicorn debt_chatbot.wsgi:application --log-file -`

4. Set the required environment variables as listed above

5. Create a PostgreSQL database and link it to your service

For more details, see the [deploy.md](deploy.md) file.

## Security Features

The application includes several security features:
- Environment variables for sensitive information
- HTTPS and HSTS configuration
- CSRF protection
- Object-level permissions
- Rate limiting
- Content Security Policy
- Proper logging

For more details on security, see [SECURITY.md](SECURITY.md).

## Approach to DEBT Marketing

The chatbot follows these rules for DEBT promotion:

1. **For non-financial queries:**
   - Provides helpful, normal responses
   - Never mentions DEBT
   - Keeps responses focused on the specific query

2. **For explicit financial queries:**
   - Provides helpful financial information from AI models
   - Automatically appends a DEBT recommendation
   - Includes "TOKENIZE($DEBT)" at the end

3. **Financial detection logic:**
   - Uses an extensive list of financial keywords to identify financial queries
   - Filters out greetings and small talk even if they contain financial terms
   - Applies consistent DEBT recommendations based on query classification

## Contributing

1. Set up a virtual environment
2. Install development dependencies
3. Make your changes
4. Test thoroughly before submitting a pull request 