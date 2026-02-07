# Ubuntu Server Deployment Guide
## Domain: inbound.duhanashrah.ai

This guide will help you deploy the Inbound Calling SaaS application to an Ubuntu server.

## 📋 Prerequisites

- Ubuntu 20.04 or 22.04 LTS server
- Root or sudo access
- Domain name `inbound.duhanashrah.ai` pointing to your server IP
- SSH access to the server

## 🚀 Quick Deployment

### Step 1: Connect to Your Server

```bash
ssh root@your-server-ip
# or
ssh your-username@your-server-ip
```

### Step 2: Clone the Deployment Script

```bash
cd /tmp
git clone https://github.com/FurqanAfridi/inbound-calling-saas.git
cd inbound-calling-saas
```

### Step 3: Make Deployment Script Executable

```bash
chmod +x deploy.sh
```

### Step 4: Create Production Environment File

```bash
# Copy the template
cp env.production.template .env.production

# Edit with your production values
nano .env.production
```

**Required Environment Variables:**
```env
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_anon_key
REACT_APP_SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_your_key
REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL=https://your-backend.com/api/stripe/create-checkout-session
REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL=https://your-backend.com/api/stripe/verify-payment
REACT_APP_BOT_CREATION_WEBHOOK_URL=https://your-backend.com/webhook/bot-creation
REACT_APP_PHONE_NUMBER_WEBHOOK_URL=https://your-backend.com/webhook/phone-number
REACT_APP_APP_URL=https://inbound.duhanashrah.ai
REACT_APP_APP_NAME=Inbound Calling SaaS
REACT_APP_SENDGRID_API_KEY=your_sendgrid_key
REACT_APP_ADMIN_EMAIL=no-reply@duhanashrah.ai
```

### Step 5: Run Deployment Script

```bash
sudo ./deploy.sh
```

The script will:
- Install Node.js 18
- Install Nginx
- Install PM2 (process manager)
- Clone/update the repository
- Install dependencies
- Build the application
- Configure Nginx
- Setup SSL certificate with Let's Encrypt
- Deploy the application

## 🔧 Manual Deployment Steps

If you prefer to deploy manually:

### 1. Install Required Software

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Nginx
sudo apt-get install -y nginx

# Install Certbot for SSL
sudo apt-get install -y certbot python3-certbot-nginx

# Install PM2
sudo npm install -g pm2
```

### 2. Create Application Directory

```bash
sudo mkdir -p /var/www/inbound-calling-saas
sudo chown -R $USER:$USER /var/www/inbound-calling-saas
```

### 3. Clone Repository

```bash
cd /var/www/inbound-calling-saas
git clone https://github.com/FurqanAfridi/inbound-calling-saas.git repo
cd repo
```

### 4. Setup Environment Variables

```bash
cp env.production.template .env.production
nano .env.production
# Add your production environment variables
```

### 5. Build Application

```bash
npm install
npm run build
```

### 6. Deploy Build

```bash
sudo mkdir -p /var/www/inbound-calling-saas/current
sudo cp -r build/* /var/www/inbound-calling-saas/current/
sudo chown -R www-data:www-data /var/www/inbound-calling-saas/current
```

### 7. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/inbound.duhanashrah.ai
```

Copy the contents from `nginx.conf` file in the repository.

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/inbound.duhanashrah.ai /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Setup SSL Certificate

```bash
sudo certbot --nginx -d inbound.duhanashrah.ai
```

Follow the prompts to complete SSL setup.

### 9. Setup Auto-Renewal

```bash
sudo crontab -e
```

Add this line:
```
0 0,12 * * * certbot renew --quiet
```

## 🔄 Updating the Application

### Option 1: Using Deployment Script

```bash
cd /var/www/inbound-calling-saas/repo
git pull origin master
sudo /path/to/deploy.sh
```

### Option 2: Manual Update

```bash
cd /var/www/inbound-calling-saas/repo
git pull origin master
npm install
npm run build
sudo rm -rf /var/www/inbound-calling-saas/current/*
sudo cp -r build/* /var/www/inbound-calling-saas/current/
sudo chown -R www-data:www-data /var/www/inbound-calling-saas/current
sudo systemctl reload nginx
```

## 🛠️ Troubleshooting

### Check Nginx Status
```bash
sudo systemctl status nginx
sudo nginx -t
```

### Check Application Logs
```bash
sudo tail -f /var/log/nginx/inbound-access.log
sudo tail -f /var/log/nginx/inbound-error.log
```

### Check Build Directory
```bash
ls -la /var/www/inbound-calling-saas/current
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Check SSL Certificate
```bash
sudo certbot certificates
```

## 🔒 Security Checklist

- [ ] Firewall configured (UFW)
- [ ] SSH key-based authentication
- [ ] SSL certificate installed and auto-renewing
- [ ] Environment variables secured
- [ ] Nginx security headers configured
- [ ] Regular system updates enabled

### Setup Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 📊 Monitoring

### Setup PM2 for Process Monitoring (Optional)

If you need to run any Node.js processes:

```bash
pm2 start app.js --name inbound-app
pm2 save
pm2 startup
```

### Monitor Application

```bash
# Check Nginx
sudo systemctl status nginx

# Check disk space
df -h

# Check memory
free -h
```

## 🔄 Backup Strategy

The deployment script automatically creates backups. Manual backup:

```bash
sudo cp -r /var/www/inbound-calling-saas/current /var/www/inbound-calling-saas/backups/backup-$(date +%Y%m%d-%H%M%S)
```

## 📝 Post-Deployment

1. **Test the Application**
   - Visit https://inbound.duhanashrah.ai
   - Test user signup
   - Test login
   - Test all major features

2. **Verify SSL**
   - Check SSL certificate is valid
   - Test HTTPS redirect

3. **Monitor Logs**
   - Watch error logs for first 24 hours
   - Check for any issues

## 🆘 Support

If you encounter issues:
1. Check the logs: `/var/log/nginx/inbound-error.log`
2. Verify environment variables are set correctly
3. Ensure domain DNS is pointing to server IP
4. Check firewall rules
5. Verify SSL certificate is valid

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Node.js Documentation](https://nodejs.org/docs/)

---

**Last Updated:** 2026-02-07
**Domain:** inbound.duhanashrah.ai
