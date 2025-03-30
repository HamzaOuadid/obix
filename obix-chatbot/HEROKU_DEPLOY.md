# Deploying DEBT Chatbot Frontend to Heroku

This guide explains how to deploy the DEBT Chatbot Angular frontend application to Heroku.

## Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- Git
- A Heroku account
- Node.js and npm

## Deployment Steps

1. **Login to Heroku CLI**

   ```bash
   heroku login
   ```

2. **Navigate to the frontend directory**

   ```bash
   cd debt-chatbot
   ```

3. **Initialize Git repository** (if not already done)

   ```bash
   git init
   git add .
   git commit -m "Initial commit for Heroku deployment"
   ```

4. **Create a Heroku app**

   ```bash
   heroku create debt-chatbot-frontend
   ```

5. **Set build configuration**

   ```bash
   heroku config:set NPM_CONFIG_PRODUCTION=false
   heroku config:set NODE_ENV=production
   ```

6. **Push to Heroku**

   ```bash
   git push heroku main
   ```

7. **Open the app**

   ```bash
   heroku open
   ```

## Important Notes

- The frontend application is configured to communicate with the backend API at `https://debt-chatbot.herokuapp.com/api`
- If you used a different name for your backend app, update the `apiUrl` in `src/environments/environment.prod.ts`
- Make sure your backend CORS settings include your frontend Heroku app URL

## Troubleshooting

- **Build Errors**: Check the logs with `heroku logs --tail`
- **API Connection Issues**: Ensure the backend URL is correct in the environment files
- **Routing Issues**: Make sure the server.js file correctly routes all requests to the Angular app

## Additional Resources

- [Heroku Node.js Deployment Guide](https://devcenter.heroku.com/articles/deploying-nodejs)
- [Angular Deployment Guide](https://angular.io/guide/deployment) 