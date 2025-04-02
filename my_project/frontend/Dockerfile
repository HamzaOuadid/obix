# Build stage
FROM node:18-alpine as build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies with legacy peer deps for Angular compatibility
RUN npm install --legacy-peer-deps --quiet

# Copy the rest of the application
COPY . .

# Build the application for production
RUN npm run build -- --configuration production

# Runtime stage
FROM nginx:1.23-alpine

# Copy custom nginx configuration
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Remove default nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy built artifacts from build stage
COPY --from=build /app/dist/debt-chatbot/browser /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"] 