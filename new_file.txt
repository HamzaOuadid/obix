FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies with --legacy-peer-deps to avoid Angular CLI issues
RUN npm install --legacy-peer-deps --quiet --ignore-scripts

# Copy project files
COPY . .

# Ensure the dist directory exists and create a placeholder index.html if needed
RUN mkdir -p /app/dist/debt-chatbot/browser
RUN [ -f /app/dist/debt-chatbot/browser/index.html ] || echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>OBIX Chatbot</title></head><body><app-root></app-root></body></html>' > /app/dist/debt-chatbot/browser/index.html

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 