# Build stage
FROM node:20-alpine as build

# Set work directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy project files
COPY . .

# Build app
RUN npm run build --prod

# Production stage
FROM node:20-alpine

# Set work directory
WORKDIR /app

# Install serve globally
RUN npm install -g serve

# Copy built assets from build stage
COPY --from=build /app/dist /app/dist
COPY --from=build /app/server.js /app/server.js

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 