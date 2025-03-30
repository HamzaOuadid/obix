# Deploying OBIX Chatbot to Digital Ocean

This guide provides step-by-step instructions for deploying the OBIX Chatbot application to a Digital Ocean Droplet. The deployment will include:

1. Setting up a Ubuntu droplet
2. Configuring PostgreSQL database
3. Deploying the Django backend with Gunicorn
4. Deploying the Angular frontend
5. Setting up Nginx as a reverse proxy

## Prerequisites

- Digital Ocean account
- Domain name (optional but recommended)
- SSH key for secure access
- Git installed on your local machine

## Step 1: Creating a Digital Ocean Droplet

1. **Create a new droplet**:
   - Log in to your Digital Ocean account
   - Click "Create" and select "Droplets"
   - Choose Ubuntu 22.04 LTS
   - Select a plan (Basic is fine, at least 2GB RAM recommended)
   - Choose a datacenter region close to your users
   - Add your SSH key
   - Give your droplet a name (e.g., "obix-chatbot")
   - Click "Create Droplet"

2. **Connect to your droplet**:
   ```bash
   ssh root@your_droplet_ip
   ```

3. **Update system packages**:
   ```bash
   apt update && apt upgrade -y
   ```

4. **Set up a non-root user** (optional but recommended):
   ```bash
   adduser obixuser
   usermod -aG sudo obixuser
   ```

## Step 2: Installing Dependencies

1. **Install required packages**:
   ```bash
   apt install -y python3 python3-pip python3-venv nginx postgresql postgresql-contrib git
   ```

2. **Install Node.js and npm** (for Angular frontend):
   ```bash
   curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   apt install -y nodejs
   ```

## Step 3: Setting Up PostgreSQL Database

1. **Configure PostgreSQL**:
   ```bash
   sudo -u postgres psql
   ```

2. **Create database and user**:
   ```sql
   CREATE DATABASE obix_chatbot_db;
   CREATE USER obix_user WITH PASSWORD 'strong_password';
   ALTER ROLE obix_user SET client_encoding TO 'utf8';
   ALTER ROLE obix_user SET default_transaction_isolation TO 'read committed';
   ALTER ROLE obix_user SET timezone TO 'UTC';
   GRANT ALL PRIVILEGES ON DATABASE obix_chatbot_db TO obix_user;
   \q
   ```

3. **Allow permissions on public schema**:
   ```bash
   sudo -u postgres psql -c "GRANT ALL ON SCHEMA public TO obix_user;" obix_chatbot_db
   ```

## Step 4: Deploying Django Backend

1. **Clone the repository**:
   ```bash
   mkdir -p /var/www
   cd /var/www
   git clone https://github.com/HamzaOuadid/obix.git
   ```

2. **Set up virtual environment**:
   ```bash
   cd /var/www/obix/obix-chatbot-backend
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   pip install gunicorn psycopg2-binary
   ```

4. **Create .env file**:
   ```bash
   cp .env.example .env
   nano .env
   ```

5. **Update .env file with appropriate values**:
   ```
   SECRET_KEY=your_secret_key
   DEBUG=False
   ALLOWED_HOSTS=your_droplet_ip,your_domain.com,localhost,127.0.0.1
   DATABASE_URL=postgres://obix_user:strong_password@localhost:5432/obix_chatbot_db
   GEMINI_API_KEY=your_gemini_api_key
   MISTRAL_API_KEY=your_mistral_api_key
   ```

6. **Run migrations**:
   ```bash
   python manage.py migrate
   ```

7. **Collect static files**:
   ```bash
   python manage.py collectstatic
   ```

8. **Set up Gunicorn systemd service**:
   ```bash
   sudo nano /etc/systemd/system/obix-backend.service
   ```

9. **Add the following content**:
   ```
   [Unit]
   Description=OBIX Chatbot Backend
   After=network.target

   [Service]
   User=root
   WorkingDirectory=/var/www/obix/obix-chatbot-backend
   ExecStart=/var/www/obix/obix-chatbot-backend/venv/bin/gunicorn debt_chatbot.wsgi:application --workers 3 --bind 127.0.0.1:8000
   Restart=on-failure
   Environment="PATH=/var/www/obix/obix-chatbot-backend/venv/bin"
   EnvironmentFile=/var/www/obix/obix-chatbot-backend/.env

   [Install]
   WantedBy=multi-user.target
   ```

10. **Enable and start the service**:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable obix-backend
    sudo systemctl start obix-backend
    ```

11. **Check status**:
    ```bash
    sudo systemctl status obix-backend
    ```

## Step 5: Deploying Angular Frontend

1. **Navigate to the frontend directory**:
   ```bash
   cd /var/www/obix/obix-chatbot
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Update environment configuration**:
   ```bash
   nano src/environments/environment.prod.ts
   ```

4. **Ensure API URL points to your backend**:
   ```typescript
   export const environment = {
     production: true,
     apiUrl: 'http://your_domain_or_ip/api'
   };
   ```

5. **Build the project**:
   ```bash
   npm run build --prod
   ```

6. **Set up frontend server**:
   ```bash
   npm install -g pm2
   pm2 start server.js --name "obix-frontend"
   pm2 startup
   pm2 save
   ```

## Step 6: Configuring Nginx

1. **Create backend configuration**:
   ```bash
   sudo nano /etc/nginx/sites-available/obix-backend
   ```

2. **Add the following content**:
   ```
   server {
       listen 80;
       server_name api.your_domain.com;  # Or use your IP if no domain

       location /static/ {
           root /var/www/obix/obix-chatbot-backend;
       }

       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

3. **Create frontend configuration**:
   ```bash
   sudo nano /etc/nginx/sites-available/obix-frontend
   ```

4. **Add the following content**:
   ```
   server {
       listen 80;
       server_name your_domain.com;  # Or use your IP if no domain

       location / {
           proxy_pass http://127.0.0.1:10000;  # Default port in the server.js
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

5. **Enable the configurations**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/obix-backend /etc/nginx/sites-enabled/
   sudo ln -s /etc/nginx/sites-available/obix-frontend /etc/nginx/sites-enabled/
   sudo rm /etc/nginx/sites-enabled/default  # Remove default config
   ```

6. **Test Nginx configuration**:
   ```bash
   sudo nginx -t
   ```

7. **Restart Nginx**:
   ```bash
   sudo systemctl restart nginx
   ```

## Step 7: Setting Up Firewall

1. **Allow Nginx and SSH**:
   ```bash
   sudo ufw allow 'Nginx Full'
   sudo ufw allow 'OpenSSH'
   sudo ufw enable
   ```

## Step 8: Setting Up SSL with Let's Encrypt

If you have a domain name:

1. **Install Certbot**:
   ```bash
   apt install -y certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate**:
   ```bash
   certbot --nginx -d your_domain.com -d api.your_domain.com
   ```

3. **Follow the prompts** to complete the SSL setup.

## Step 9: Monitoring and Maintenance

1. **View backend logs**:
   ```bash
   sudo journalctl -u obix-backend
   ```

2. **View frontend logs**:
   ```bash
   pm2 logs obix-frontend
   ```

3. **Restart services after updates**:
   ```bash
   # For backend
   cd /var/www/obix
   git pull
   cd obix-chatbot-backend
   source venv/bin/activate
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py collectstatic --noinput
   sudo systemctl restart obix-backend

   # For frontend
   cd /var/www/obix
   git pull
   cd obix-chatbot
   npm install
   npm run build --prod
   pm2 restart obix-frontend
   ```

## Troubleshooting

1. **Backend service not starting**:
   - Check logs: `sudo journalctl -u obix-backend`
   - Verify .env file and database connection
   - Ensure Gunicorn is installed in the virtual environment

2. **Frontend not loading**:
   - Check PM2 logs: `pm2 logs obix-frontend`
   - Verify the build process completed successfully
   - Check Nginx configuration and error logs: `sudo cat /var/log/nginx/error.log`

3. **Database connection issues**:
   - Verify PostgreSQL is running: `sudo systemctl status postgresql`
   - Check database credentials in .env file
   - Ensure database permissions are set correctly

4. **Nginx errors**:
   - Check configuration: `sudo nginx -t`
   - Look at error logs: `sudo cat /var/log/nginx/error.log`
   - Verify firewall settings: `sudo ufw status` 