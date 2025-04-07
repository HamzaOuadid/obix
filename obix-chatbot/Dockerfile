FROM node:20-alpine AS build

# Set work directory for build
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies with --legacy-peer-deps to avoid Angular CLI issues
# --ignore-scripts prevents the postinstall script from running during initial install
RUN npm install --legacy-peer-deps --ignore-scripts

# Copy project files
COPY . .

# Run the build
RUN npm run build

FROM node:20-alpine AS runtime

# Set work directory
WORKDIR /app

# Copy server-related files
COPY server.js /app/
COPY package.json /app/

# Copy env.js to the correct location (should be in the assets folder)
COPY src/assets/env.js /app/dist/env.js

# Install only the express server dependencies
RUN npm install --production=true express

# Copy the built application from the previous stage
COPY --from=build /app/dist /app/dist

# Expose the port the app runs on
EXPOSE 10000

# Start server
CMD ["node", "server.js"] 