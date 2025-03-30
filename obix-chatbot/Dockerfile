FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies and Angular CLI
RUN npm ci --silent && \
    npm install -g @angular/cli@17.2.3

# Copy project files
COPY . .

# Build app
RUN npm run build --prod || echo "Building with development environment" && ng build

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 