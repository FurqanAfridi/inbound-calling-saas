# Quick Deployment Commands
## For Ubuntu Server - inbound.duhanashrah.ai

## Step 1: Install Required Software

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl git nginx nodejs npm build-essential certbot python3-certbot-nginx
```

## Step 2: Install Node.js 18 (if not already installed)

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Step 3: Install PM2 (Optional, for process management)

```bash
sudo npm install -g pm2
```

## Step 4: Navigate to Your Project Directory

```bash
cd /path/to/inbound-calling-saas
# or wherever you cloned the repository
```

## Step 5: Install Dependencies

```bash
npm install
```

## Step 6: Build the Application

```bash
npm run build
```

## Step 7: Create Deployment Directory

```bash
sudo mkdir -p /var/www/inbound-calling-saas/current
```

## Step 8: Copy Build Files

```bash
sudo cp -r build/* /var/www/inbound-calling-saas/current/
sudo chown -R www-data:www-data /var/www/inbound-calling-saas/current
```

## Step 9: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/inbound.duhanashrah.ai
```

**Paste this configuration:**

```nginx
server {
    listen 80;
    server_name inbound.duhanashrah.ai;
    
    root /var/www/inbound-calling-saas/current;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Handle React Router (SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

**Save and exit (Ctrl+X, then Y, then Enter)**

## Step 10: Enable Nginx Site

```bash
sudo ln -s /etc/nginx/sites-available/inbound.duhanashrah.ai /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

## Step 11: Setup SSL Certificate

```bash
sudo certbot --nginx -d inbound.duhanashrah.ai
```

**Follow the prompts:**
- Enter your email
- Agree to terms
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

## Step 12: Setup SSL Auto-Renewal

```bash
sudo crontab -e
```

**Add this line at the end:**
```
0 0,12 * * * certbot renew --quiet
```

**Save and exit**

## Step 13: Configure Firewall (if not already done)

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Step 14: Verify Deployment

```bash
# Check Nginx status
sudo systemctl status nginx

# Check if site is accessible
curl -I http://inbound.duhanashrah.ai
```

## ✅ Done!

Your application should now be live at: **https://inbound.duhanashrah.ai**

---

## 🔄 For Future Updates:

```bash
cd /path/to/inbound-calling-saas
git pull origin master
npm install
npm run build
sudo rm -rf /var/www/inbound-calling-saas/current/*
sudo cp -r build/* /var/www/inbound-calling-saas/current/
sudo chown -R www-data:www-data /var/www/inbound-calling-saas/current
sudo systemctl reload nginx
```
