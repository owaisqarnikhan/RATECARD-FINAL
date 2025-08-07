#!/bin/bash

# AWS EC2 Ubuntu Deployment Script for Rate Card Application
# This script sets up the entire application on a fresh Ubuntu server

set -e  # Exit on any error

echo "🚀 Starting Rate Card Application Deployment on AWS EC2..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x (LTS)
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install additional dependencies
echo "📦 Installing system dependencies..."
sudo apt-get install -y git nginx postgresql postgresql-contrib certbot python3-certbot-nginx ufw build-essential

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 5000
sudo ufw --force enable

# Install PM2 for process management
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Setup PostgreSQL
echo "🗄️ Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
echo "🗄️ Creating database..."
sudo -u postgres psql << EOF
CREATE DATABASE ratecard_bayg;
CREATE USER bayg_user WITH PASSWORD 'bayg123';
GRANT ALL PRIVILEGES ON DATABASE ratecard_bayg TO bayg_user;
ALTER USER bayg_user CREATEDB;
\q
EOF

# Clone the project (assuming you'll upload it manually or via git)
# For now, we'll assume the project is already in /home/ubuntu/ratecard

# Navigate to project directory
cd /home/ubuntu/ratecard

# Install dependencies
echo "📦 Installing project dependencies..."
npm install

# Create production environment file
echo "⚙️ Creating production environment file..."
cat > .env.production << EOF
# Production Database Configuration
DATABASE_URL="postgresql://bayg_user:bayg123@localhost:5432/ratecard_bayg"

# Production Configuration
NODE_ENV=production
PORT=5000

# Session Secret (CHANGE THIS TO A SECURE RANDOM STRING)
SESSION_SECRET="$(openssl rand -base64 32)"

# SMTP Configuration (Configure with your email provider)
SMTP_HOST=""
SMTP_PORT=""
SMTP_USER=""
SMTP_PASS=""
EOF

# Copy production env to main env file
cp .env.production .env

# Build the application
echo "🏗️ Building application..."
npm run build

# Create PM2 ecosystem file
echo "⚙️ Creating PM2 ecosystem file..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ratecard-app',
    script: './dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '1G',
    watch: false,
    ignore_watch: ['node_modules', 'logs', 'uploads']
  }]
}
EOF

# Create logs directory
mkdir -p logs

# Configure Nginx
echo "🌐 Configuring Nginx..."
sudo tee /etc/nginx/sites-available/ratecard << EOF
server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Main application
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Static files
    location /uploads {
        alias /home/ubuntu/ratecard/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate max-age=0;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
}
EOF

# Enable the site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/ratecard /etc/nginx/sites-enabled/

# Test and reload Nginx
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl enable nginx

# Set proper permissions
echo "🔒 Setting proper permissions..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/ratecard
chmod +x /home/ubuntu/ratecard/deploy-to-aws.sh

# Run database migrations
echo "🗄️ Running database setup..."
npm run db:push

# Start the application with PM2
echo "🚀 Starting application with PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

echo "✅ Deployment completed successfully!"
echo ""
echo "🎉 Your Rate Card application is now running on:"
echo "   - Local: http://localhost:5000"
echo "   - Public: http://$(curl -s http://checkip.amazonaws.com):80"
echo ""
echo "📋 Important next steps:"
echo "   1. Configure your domain name (if you have one)"
echo "   2. Set up SSL certificate with: sudo certbot --nginx"
echo "   3. Update SMTP settings in .env for email functionality"
echo "   4. Configure your AWS security groups to allow HTTP (80) and HTTPS (443)"
echo "   5. Consider setting up automated backups for your database"
echo ""
echo "📊 Monitor your application:"
echo "   - PM2 status: pm2 status"
echo "   - Application logs: pm2 logs ratecard-app"
echo "   - Nginx logs: sudo tail -f /var/log/nginx/error.log"
EOF
