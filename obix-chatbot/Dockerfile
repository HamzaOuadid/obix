FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies with --legacy-peer-deps to avoid Angular CLI issues
RUN npm install --legacy-peer-deps --quiet

# Copy project files
COPY . .

# Ensure the dist directory exists
RUN mkdir -p /app/dist

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 