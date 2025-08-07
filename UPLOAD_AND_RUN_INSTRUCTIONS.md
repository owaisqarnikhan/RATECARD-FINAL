# Upload and Run Instructions for AWS EC2 Deployment

## 🚀 Complete Step-by-Step Guide for Windows Users

### Prerequisites
- AWS EC2 instance running Ubuntu 22.04 LTS
- Your SSH key pair (.pem file) downloaded
- Your EC2 instance's public IP address

---

## Method 1: Upload via SCP (Recommended for First Deployment)

### Step 1: Prepare Your Project for Upload

**On your Windows machine (PowerShell):**

```powershell
# Navigate to your project directory
cd "D:\Rate card Final\Backup-1\07-08-2025\RATECARD-FINAL"

# Create a compressed archive excluding unnecessary files
tar -czf ratecard-app.tar.gz --exclude='node_modules' --exclude='.git' --exclude='dist' --exclude='logs' --exclude='.env' *
```

### Step 2: Upload to EC2

**Replace the following placeholders:**
- `your-key.pem` → Path to your SSH key file
- `your-ec2-ip` → Your EC2 instance's public IP

```powershell
# Upload the compressed file to EC2
scp -i "C:\path\to\your-key.pem" ratecard-app.tar.gz ubuntu@your-ec2-ip:/home/ubuntu/

# Example:
# scp -i "C:\Users\user\Downloads\my-key.pem" ratecard-app.tar.gz ubuntu@54.123.45.67:/home/ubuntu/
```

### Step 3: Connect to EC2 and Extract

```powershell
# Connect to your EC2 instance
ssh -i "C:\path\to\your-key.pem" ubuntu@your-ec2-ip

# Example:
# ssh -i "C:\Users\user\Downloads\my-key.pem" ubuntu@54.123.45.67
```

**Once connected to EC2 (Ubuntu terminal):**

```bash
# Create project directory and extract files
mkdir -p /home/ubuntu/ratecard
cd /home/ubuntu/ratecard
tar -xzf ../ratecard-app.tar.gz
rm ../ratecard-app.tar.gz

# Verify files are extracted
ls -la
```

### Step 4: Run the Deployment Script

```bash
# Make the deployment script executable
chmod +x deploy-to-aws.sh

# Run the deployment script (this will take 10-15 minutes)
sudo ./deploy-to-aws.sh
```

---

## Method 2: Upload via Git (Recommended for Updates)

### Step 1: Push Your Code to Git Repository

**On your Windows machine:**

```powershell
# If not already a git repository
git init
git add .
git commit -m "Initial commit for deployment"

# Add your GitHub/GitLab repository
git remote add origin https://github.com/yourusername/your-repo.git
git push -u origin main
```

### Step 2: Clone on EC2

**Connect to EC2:**
```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@your-ec2-ip
```

**On EC2 (Ubuntu terminal):**
```bash
# Clone your repository
cd /home/ubuntu
git clone https://github.com/yourusername/your-repo.git ratecard
cd ratecard

# Run deployment script
chmod +x deploy-to-aws.sh
sudo ./deploy-to-aws.sh
```

---

## Method 3: Direct File Transfer via SFTP

### Using WinSCP (GUI Method)

1. **Download WinSCP** from https://winscp.net/
2. **Configure Connection:**
   - Protocol: SFTP
   - Host name: Your EC2 public IP
   - User name: ubuntu
   - Private key: Browse to your .pem file
3. **Connect and Upload:**
   - Navigate to your project folder locally
   - Upload all files to `/home/ubuntu/ratecard/`

### Using PowerShell SFTP

```powershell
# Install Posh-SSH module (if not already installed)
Install-Module -Name Posh-SSH -Force

# Create SFTP session
$session = New-SFTPSession -ComputerName "your-ec2-ip" -Credential (Get-Credential ubuntu) -KeyFile "C:\path\to\your-key.pem"

# Upload files
Set-SFTPFolder -SessionId $session.SessionId -RemotePath "/home/ubuntu/ratecard" -LocalFolder "D:\Rate card Final\Backup-1\07-08-2025\RATECARD-FINAL"

# Close session
Remove-SFTPSession -SessionId $session.SessionId
```

---

## 🔧 After Upload: Run the Application

### Step 1: Connect to Your EC2 Instance

```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@your-ec2-ip
```

### Step 2: Navigate to Project Directory

```bash
cd /home/ubuntu/ratecard
```

### Step 3: Run Deployment Script

```bash
# Make script executable
chmod +x deploy-to-aws.sh

# Run deployment (will install all dependencies and configure everything)
sudo ./deploy-to-aws.sh
```

**The script will automatically:**
- ✅ Update Ubuntu and install Node.js, PostgreSQL, Nginx
- ✅ Create database and user
- ✅ Install project dependencies
- ✅ Build the application
- ✅ Configure Nginx reverse proxy
- ✅ Set up PM2 process management
- ✅ Start the application

---

## 🎯 Verification Steps

### Step 1: Check Application Status

```bash
# Check PM2 status
pm2 status

# Check application logs
pm2 logs ratecard-app

# Check if app is running on port 5000
curl http://localhost:5000
```

### Step 2: Check Services

```bash
# Check Nginx status
sudo systemctl status nginx

# Check PostgreSQL status
sudo systemctl status postgresql

# Check if ports are open
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :5000
```

### Step 3: Access Your Application

Open your browser and go to:
- `http://your-ec2-public-ip` (through Nginx)
- `http://your-ec2-public-ip:5000` (direct access for testing)

---

## 🚨 Troubleshooting Common Issues

### Issue 1: Permission Denied for SSH Key

```powershell
# On Windows, set correct permissions for .pem file
icacls "C:\path\to\your-key.pem" /inheritance:r
icacls "C:\path\to\your-key.pem" /grant:r "$env:USERNAME:R"
```

### Issue 2: Connection Timeout

- Check EC2 Security Groups allow port 22 (SSH)
- Verify you're using the correct public IP
- Ensure EC2 instance is running

### Issue 3: Application Not Starting

```bash
# Check detailed logs
pm2 logs ratecard-app --lines 100

# Check if dependencies installed correctly
npm list

# Manually try to start
cd /home/ubuntu/ratecard
npm run build
npm start
```

### Issue 4: Database Connection Issues

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Try connecting to database
sudo -u postgres psql -d ratecard_bayg

# Check if database user exists
sudo -u postgres psql -c "\du"
```

---

## 🔄 For Future Updates

### Quick Update Process:

**Method 1: Git Updates**
```bash
cd /home/ubuntu/ratecard
git pull origin main
npm install
npm run build
pm2 restart ratecard-app
```

**Method 2: File Upload Updates**
```powershell
# On Windows - create new archive
tar -czf ratecard-update.tar.gz --exclude='node_modules' --exclude='.git' --exclude='dist' *

# Upload
scp -i "your-key.pem" ratecard-update.tar.gz ubuntu@your-ec2-ip:/home/ubuntu/

# On EC2
cd /home/ubuntu/ratecard
tar -xzf ../ratecard-update.tar.gz
npm install
npm run build
pm2 restart ratecard-app
```

---

## 📊 Monitoring Your Application

### Essential Commands:

```bash
# Application status
pm2 status
pm2 monit

# View logs
pm2 logs ratecard-app
pm2 logs ratecard-app --lines 50

# System resources
htop          # Interactive process viewer
df -h         # Disk usage
free -h       # Memory usage

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Application URLs:
- **Main Application:** `http://your-ec2-public-ip`
- **Health Check:** `http://your-ec2-public-ip/health`
- **Direct App Access:** `http://your-ec2-public-ip:5000` (for testing)

---

**🎉 Your Rate Card application should now be running successfully on AWS EC2!**

**Next Steps:**
1. Test all application features
2. Set up SSL certificate if you have a domain
3. Configure email settings in `.env`
4. Set up automated backups
5. Monitor application performance
