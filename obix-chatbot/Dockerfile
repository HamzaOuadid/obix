FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --silent

# Copy project files
COPY . .

# Ensure the dist directory exists
RUN mkdir -p /app/dist

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 