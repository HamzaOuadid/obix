FROM python:3.11-slim

# Set work directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Make the startup script executable
RUN chmod +x startup.sh

# Expose the port the app runs on
EXPOSE 8000

# Command to run the app using the startup script
CMD ["./startup.sh"] 