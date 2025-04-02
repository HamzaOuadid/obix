#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y python3-pip python3-dev nginx

# Install Python dependencies
pip3 install -r requirements.txt
pip3 install gunicorn

# Create necessary directories
mkdir -p staticfiles mediafiles
python3 manage.py collectstatic --noinput

# Set up systemd service
cp obix-chatbot.service /etc/systemd/system/
systemctl daemon-reload
systemctl start obix-chatbot
systemctl enable obix-chatbot

# Configure Nginx
cat > /etc/nginx/sites-available/obix-chatbot << EOF
server {
    listen 80;
    server_name 157.230.65.142;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /root/obix/obix-chatbot-backend;
    }

    location /media/ {
        root /root/obix/obix-chatbot-backend;
    }

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Enable the Nginx site
ln -s /etc/nginx/sites-available/obix-chatbot /etc/nginx/sites-enabled
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo "Deployment complete!" 