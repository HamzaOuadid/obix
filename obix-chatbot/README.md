# DebtChatbot

This project was generated using [Angular CLI](https://github.com/angular/angular-cli) version 19.1.6.

## Development server

To start a local development server, run:

```bash
ng serve
```

Once the server is running, open your browser and navigate to `http://localhost:4200/`. The application will automatically reload whenever you modify any of the source files.

## Code scaffolding

Angular CLI includes powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in the `dist/` directory. By default, the production build optimizes your application for performance and speed.

## Running unit tests

To execute unit tests with the [Karma](https://karma-runner.github.io) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.

## Deployment to Render

This project is configured for easy deployment to [Render](https://render.com/). To deploy:

1. Push this repository to GitHub
2. Create a new Render account or sign in to an existing one
3. Click "New +" and select "Blueprint" from the dropdown
4. Connect your GitHub account and select the repository
5. Render will automatically detect the `render.yaml` file and configure a Node.js web service for the frontend

6. Click "Apply" to create the services

7. Once deployed, your frontend will be available at:
   - https://obix-chatbot-frontend.onrender.com

### Manual Deployment (Without Blueprint)

If you want to deploy manually:

1. Create a new Web Service in Render
2. Connect your GitHub repository
3. Use the following settings:
   - Environment: Node
   - Build Command: `npm install && npm run build`
   - Start Command: `node server.js`
   - Environment Variables:
     - `API_URL`: URL of your backend API (e.g., https://obix-chatbot-backend.onrender.com)
     - `PORT`: 10000 (or any port Render allows)

4. Click "Create Web Service"

### Important Notes

- Make sure the backend API is deployed and working before deploying the frontend
- After deployment, verify that the frontend can communicate with the backend API
