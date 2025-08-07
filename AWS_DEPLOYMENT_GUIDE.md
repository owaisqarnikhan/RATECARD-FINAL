# AWS EC2 Deployment Guide - Rate Card Application

This guide will walk you through deploying your Rate Card application on AWS EC2 with Ubuntu Server.

## 📋 Prerequisites

- AWS Account with EC2 access
- Basic knowledge of SSH and terminal commands
- Your application code ready for deployment

## 🚀 Step 1: Launch EC2 Instance

### 1.1 Create EC2 Instance
1. Log into AWS Console → EC2 Service
2. Click "Launch Instance"
3. **Configuration:**
   - **Name:** `ratecard-production-server`
   - **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance Type:** `t3.small` or higher (t2.micro might be too small)
   - **Key Pair:** Create new or use existing SSH key pair
   - **Security Group:** Create with these rules:
     - SSH (22) - Your IP only
     - HTTP (80) - Anywhere (0.0.0.0/0)
     - HTTPS (443) - Anywhere (0.0.0.0/0)
     - Custom TCP (5000) - Anywhere (for testing)
   - **Storage:** 20 GB gp3 (minimum recommended)

### 1.2 Connect to Instance
```bash
# Replace with your key file and instance IP
ssh -i "your-key.pem" ubuntu@your-ec2-ip-address
```

## 📦 Step 2: Upload Your Application

### Option A: Using SCP (Recommended for first deployment)
```bash
# On your local machine, create a zip of your project
# Exclude node_modules and other unnecessary files
tar -czf ratecard-app.tar.gz --exclude='node_modules' --exclude='.git' --exclude='dist' .

# Upload to EC2
scp -i "your-key.pem" ratecard-app.tar.gz ubuntu@your-ec2-ip:/home/ubuntu/

# On EC2 server, extract
ssh -i "your-key.pem" ubuntu@your-ec2-ip
mkdir -p /home/ubuntu/ratecard
cd /home/ubuntu/ratecard
tar -xzf ../ratecard-app.tar.gz
rm ../ratecard-app.tar.gz
```

### Option B: Using Git (Recommended for updates)
```bash
# On EC2 server
cd /home/ubuntu
git clone https://github.com/yourusername/your-repo.git ratecard
cd ratecard
```

## 🔧 Step 3: Run Deployment Script

The deployment script will automatically:
- Install Node.js, PostgreSQL, Nginx, PM2
- Configure the database
- Build your application  
- Set up reverse proxy
- Configure process management
- Set up security and firewall

```bash
# Make the script executable and run it
chmod +x deploy-to-aws.sh
sudo ./deploy-to-aws.sh
```

## 🔒 Step 4: Security Configuration

### 4.1 Update Security Groups
In AWS Console → EC2 → Security Groups:
- Remove port 5000 access (only needed for testing)
- Ensure only ports 22, 80, 443 are open

### 4.2 Set Up SSL Certificate (Optional but Recommended)
```bash
# Replace yourdomain.com with your actual domain
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 4.3 Configure Environment Variables
```bash
# Edit the production environment file
nano /home/ubuntu/ratecard/.env

# Update these important settings:
# - SESSION_SECRET: Use a strong, unique secret
# - SMTP settings if you need email functionality
# - Any API keys or external service credentials
```

## 📊 Step 5: Monitor and Maintain

### Application Management
```bash
# Check application status
pm2 status

# View logs
pm2 logs ratecard-app

# Restart application
pm2 restart ratecard-app

# Stop application
pm2 stop ratecard-app

# Start application
pm2 start ratecard-app
```

### System Monitoring
```bash
# Check Nginx status
sudo systemctl status nginx

# Check PostgreSQL status
sudo systemctl status postgresql

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Check disk usage
df -h

# Check memory usage
free -h

# Check system resources
htop
```

### Database Management
```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Connect to your application database
sudo -u postgres psql -d ratecard_bayg

# Backup database
pg_dump -U bayg_user -h localhost ratecard_bayg > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database (if needed)
psql -U bayg_user -h localhost ratecard_bayg < backup_file.sql
```

## 🔄 Step 6: Application Updates

For future updates to your application:

```bash
# Method 1: Git updates (if using git)
cd /home/ubuntu/ratecard
git pull origin main
npm install  # Install any new dependencies
npm run build  # Rebuild the application
pm2 restart ratecard-app

# Method 2: File upload updates
# Upload new files via SCP, then:
cd /home/ubuntu/ratecard
npm install
npm run build
pm2 restart ratecard-app
```

## 🚨 Troubleshooting

### Common Issues and Solutions

1. **Application won't start:**
   ```bash
   pm2 logs ratecard-app  # Check logs for errors
   pm2 restart ratecard-app  # Try restarting
   ```

2. **Database connection issues:**
   ```bash
   sudo systemctl status postgresql  # Check if PostgreSQL is running
   sudo -u postgres psql -l  # List databases
   ```

3. **Nginx issues:**
   ```bash
   sudo nginx -t  # Test Nginx configuration
   sudo systemctl restart nginx  # Restart Nginx
   ```

4. **Out of disk space:**
   ```bash
   df -h  # Check disk usage
   sudo apt autoremove  # Remove unnecessary packages
   pm2 flush  # Clear PM2 logs
   ```

5. **High memory usage:**
   ```bash
   pm2 restart ratecard-app  # Restart to clear memory
   # Consider upgrading to a larger instance type
   ```

## 📈 Performance Optimization

### For Production Use:
1. **Upgrade EC2 Instance:** Consider t3.medium or larger for production
2. **Database Optimization:** Consider AWS RDS for PostgreSQL instead of local DB
3. **CDN Setup:** Use AWS CloudFront for static assets
4. **Load Balancer:** Use AWS ALB if you need multiple instances
5. **Monitoring:** Set up AWS CloudWatch for monitoring and alerts

## 🔄 Automated Backups

Create a backup script:
```bash
# Create backup script
cat > /home/ubuntu/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
pg_dump -U bayg_user -h localhost ratecard_bayg > "$BACKUP_DIR/db_$DATE.sql"

# Application backup
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" -C /home/ubuntu ratecard

# Keep only last 7 days of backups
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/ubuntu/backup.sh

# Add to crontab for daily backups at 2 AM
echo "0 2 * * * /home/ubuntu/backup.sh >> /home/ubuntu/backup.log 2>&1" | crontab -
```

## 🎯 Success Verification

Your deployment is successful when:
- ✅ You can access the application via your EC2 public IP
- ✅ The application loads without errors
- ✅ Database connections work
- ✅ File uploads work (if applicable)
- ✅ All features function as expected
- ✅ PM2 shows the application as online
- ✅ Nginx serves the application correctly

## 📞 Support

If you encounter issues:
1. Check the application logs: `pm2 logs ratecard-app`
2. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Check system resources: `htop` and `df -h`
4. Verify database connectivity: `sudo -u postgres psql -d ratecard_bayg`

---

**🎉 Congratulations! Your Rate Card application should now be running on AWS EC2!**

Access it at: `http://your-ec2-public-ip`
