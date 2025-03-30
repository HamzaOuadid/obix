FROM node:20-slim AS build

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy project files
COPY . .

# Build the app
RUN npm run build

# Runtime stage
FROM node:20-slim

WORKDIR /app

# Copy server.js and package.json
COPY --from=build /app/server.js ./
COPY --from=build /app/package.json ./

# Copy the built app
COPY --from=build /app/dist ./dist

# Install only production dependencies
RUN npm install --only=production

# Set environment variables
ENV PORT=10000
ENV NODE_ENV=production

# Expose the port
EXPOSE $PORT

# Start the app
CMD ["node", "server.js"] 