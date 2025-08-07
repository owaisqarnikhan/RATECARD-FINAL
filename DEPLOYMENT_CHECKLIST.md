# AWS EC2 Deployment Checklist

Use this checklist to ensure a smooth deployment of your Rate Card application.

## ✅ Pre-Deployment Checklist

### AWS Setup
- [ ] AWS account created and configured
- [ ] EC2 instance launched (Ubuntu 22.04 LTS, t3.small or larger)
- [ ] SSH key pair created and downloaded
- [ ] Security groups configured (ports 22, 80, 443, temporarily 5000)
- [ ] Elastic IP assigned (optional but recommended)
- [ ] Domain name configured (optional)

### Local Preparation
- [ ] Application tested locally
- [ ] All dependencies properly defined in package.json
- [ ] Environment variables documented
- [ ] Build process works (`npm run build`)
- [ ] Database migrations tested (`npm run db:push`)

### Security
- [ ] Environment secrets ready (database passwords, session secrets, API keys)
- [ ] HTTPS certificate ready (if using custom domain)
- [ ] Backup strategy planned

## 🚀 Deployment Steps

### Step 1: Connect to Server
- [ ] SSH connection to EC2 instance successful
- [ ] Ubuntu user has proper permissions

### Step 2: Upload Application
Choose one:
- [ ] **Option A:** Files uploaded via SCP
- [ ] **Option B:** Repository cloned from Git

### Step 3: Run Deployment Script
- [ ] deployment script executable (`chmod +x deploy-to-aws.sh`)
- [ ] Script ran successfully without errors
- [ ] All services started (Node.js, PostgreSQL, Nginx, PM2)

### Step 4: Verify Installation
- [ ] Application accessible via public IP
- [ ] Database connection working
- [ ] All features functional
- [ ] File uploads working (if applicable)
- [ ] Authentication working
- [ ] No console errors in browser

### Step 5: Security Hardening
- [ ] Remove port 5000 from security groups
- [ ] SSL certificate installed (if using domain)
- [ ] Environment variables secured
- [ ] Database passwords changed from defaults
- [ ] Session secret updated

### Step 6: Monitoring Setup
- [ ] PM2 status shows application online
- [ ] PM2 startup script configured
- [ ] Log files accessible and rotating properly
- [ ] Nginx access/error logs monitored

## 📊 Post-Deployment Verification

### Functionality Tests
- [ ] Homepage loads correctly
- [ ] User registration/login works
- [ ] Dashboard/admin features accessible
- [ ] File upload/download works
- [ ] Database operations successful
- [ ] Email functionality working (if configured)
- [ ] Payment processing working (if configured)

### Performance Tests
- [ ] Page load times acceptable
- [ ] Application responsive under load
- [ ] Database queries efficient
- [ ] Static files served quickly

### Security Tests
- [ ] HTTPS working (if configured)
- [ ] Security headers present
- [ ] Database not publicly accessible
- [ ] Sensitive files not exposed
- [ ] Rate limiting working

## 🔧 Maintenance Tasks

### Regular Monitoring
- [ ] Set up application health checks
- [ ] Configure log monitoring
- [ ] Set up automated backups
- [ ] Plan for security updates

### Performance Optimization
- [ ] Enable caching where appropriate
- [ ] Optimize database queries
- [ ] Configure CDN for static assets (if needed)
- [ ] Monitor resource usage

## 🚨 Emergency Procedures

### Rollback Plan
- [ ] Previous version backup available
- [ ] Database backup recent and tested
- [ ] Rollback procedure documented
- [ ] Emergency contact information available

### Disaster Recovery
- [ ] Full system backup strategy
- [ ] Database recovery procedure
- [ ] Alternative deployment environment ready
- [ ] Documentation for rebuilding from scratch

## 📞 Support Information

### Key Commands for Troubleshooting
```bash
# Application status
pm2 status
pm2 logs ratecard-app

# System status  
sudo systemctl status nginx postgresql
df -h && free -h

# Database access
sudo -u postgres psql -d ratecard_bayg

# Restart services
pm2 restart ratecard-app
sudo systemctl restart nginx
```

### Important File Locations
- Application: `/home/ubuntu/ratecard/`
- Logs: `/home/ubuntu/ratecard/logs/`
- Nginx config: `/etc/nginx/sites-available/ratecard`
- Environment: `/home/ubuntu/ratecard/.env`
- PM2 config: `/home/ubuntu/ratecard/ecosystem.config.js`

### Expected Resource Usage
- **CPU:** 5-15% idle, 30-60% under load
- **Memory:** 200-500MB idle, 1-2GB under load  
- **Disk:** ~1GB for application + database growth
- **Network:** Varies by usage

---

**✅ Deployment Complete!** 

Your Rate Card application should now be running successfully on AWS EC2.

🌐 **Access URL:** `http://your-ec2-public-ip` or `https://yourdomain.com`
