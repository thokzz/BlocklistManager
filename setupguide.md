# BlockList Manager - Setup Guide

This guide will walk you through setting up your own instance of the BlockList Manager web application. The process is designed to be simple even for those with minimal server administration experience.

## Prerequisites

Before starting, you'll need:

- A Linux server (Ubuntu/Debian recommended)
- Root or sudo access to that server
- Basic familiarity with the command line
- A domain name (optional, for production deployments)

## Quick Start Installation

### 1. Prepare Your Server

Make sure your system is up to date:

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Download the Installation Script

You can download the installation script directly from the repository:

```bash
wget https://raw.githubusercontent.com/[your-username]/blocklist-manager/main/install-blocklist-manager.sh
```

### 3. Make the Script Executable

```bash
chmod +x install-blocklist-manager.sh
```

### 4. Run the Installation Script

```bash
sudo ./install-blocklist-manager.sh
```

During installation, you'll be prompted to create an admin username and password. These credentials will be used to log in to the application.

### 5. Verify the Installation

After the installation completes, you should see a success message with information about the installation. Verify that both services are running:

```bash
sudo systemctl status nginx
sudo systemctl status blocklist-manager
```

### 6. Access the Application

Open a web browser and navigate to:

```
http://[your-server-ip]:8080
```

You should see the login page. Enter the credentials you created during installation to access the dashboard.

## Manual Installation Process

If you prefer to install the components manually or want to understand the process better, follow these steps:

### 1. Install Required Packages

```bash
sudo apt update
sudo apt install -y nginx python3 python3-pip python3-flask
sudo pip3 install flask flask-login werkzeug
```

### 2. Create Directory Structure

```bash
sudo mkdir -p /var/www/blocklist-manager/templates
sudo mkdir -p /var/www/blocklist-manager/static/css
sudo mkdir -p /var/www/blocklist-manager/static/js
sudo mkdir -p /var/www/blocklists
```

### 3. Create the Application Files

You'll need to create several files for the application to work:

- **app.py**: The main Flask application
- **login.html**: The template for the login page
- **dashboard.html**: The template for the main dashboard
- **style.css**: The CSS styles for the application
- **script.js**: The JavaScript functionality

You can find the contents of these files in the GitHub repository or in the installation script.

### 4. Configure Nginx

Create a new Nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/blocklist-manager
```

Enable the site and disable the default if necessary:

```bash
sudo ln -sf /etc/nginx/sites-available/blocklist-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 5. Create a Systemd Service

```bash
sudo nano /etc/systemd/system/blocklist-manager.service
```

### 6. Set Permissions

```bash
sudo chown -R www-data:www-data /var/www/blocklist-manager
sudo chmod -R 755 /var/www/blocklist-manager
sudo chown -R www-data:www-data /var/www/blocklists
sudo chmod -R 755 /var/www/blocklists
```

### 7. Start the Services

```bash
sudo systemctl daemon-reload
sudo systemctl enable blocklist-manager.service
sudo systemctl start blocklist-manager.service
sudo systemctl restart nginx
```

## Configuration Options

### Changing the Port

If you want to run the application on a different port than 8080, you'll need to modify two files:

1. Edit the Nginx configuration at `/etc/nginx/sites-available/blocklist-manager`:
   ```
   Change "listen 8080;" to your preferred port
   ```

2. If you want to change the internal port (5050), edit `/var/www/blocklist-manager/app.py`:
   ```python
   # Find this line at the bottom of the file
   app.run(host='0.0.0.0', port=5050, debug=False)
   # Change 5050 to your preferred port
   ```

Remember to update both Nginx and the app.py file, then restart both services:

```bash
sudo systemctl restart nginx
sudo systemctl restart blocklist-manager
```

### Changing the Login Credentials

To change the login credentials after installation:

1. Edit the application file:
   ```bash
   sudo nano /var/www/blocklist-manager/app.py
   ```

2. Find and modify the users dictionary:
   ```python
   users = {
       'your_new_username': User(1, 'your_new_username', generate_password_hash('your_new_password'))
   }
   ```

3. Restart the application:
   ```bash
   sudo systemctl restart blocklist-manager
   ```

### Adding HTTPS Support

For production use, it's recommended to secure your application with HTTPS. You can use Let's Encrypt to obtain a free SSL certificate:

1. Install Certbot:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. Obtain and install a certificate:
   ```bash
   sudo certbot --nginx -d yourdomain.com
   ```

3. Follow the prompts to complete the setup.

## Troubleshooting

### Application Not Starting

If the application doesn't start, check the service status:

```bash
sudo systemctl status blocklist-manager
```

View the application logs:

```bash
sudo journalctl -u blocklist-manager -n 50
```

### Web Interface Not Loading

If you can't access the web interface, check:

1. Nginx status:
   ```bash
   sudo systemctl status nginx
   ```

2. Firewall settings:
   ```bash
   sudo ufw status
   ```

3. If the firewall is active, allow the port:
   ```bash
   sudo ufw allow 8080/tcp
   ```

4. Verify the port is open:
   ```bash
   sudo netstat -tuln | grep 8080
   ```

### Permission Issues

If you encounter permission errors in the logs:

```bash
sudo chown -R www-data:www-data /var/www/blocklists
sudo chmod -R 755 /var/www/blocklists
```

## Integration with DNS or Firewall Systems

The BlockList Manager creates a simple text file at `/var/www/blocklists/blocked.txt` which contains all your blocked domains. This file can be integrated with various DNS blocking or firewall systems:

- **Pi-hole**: You can add this as a custom blocklist
- **AdGuard Home**: Import as a blocklist URL
- **Bind DNS**: Use as a response policy zone (RPZ) source
- **iptables**: Create firewall rules from the domains

For specific integration instructions with your preferred system, please refer to that system's documentation.

## Backup and Restore

### Backing Up Your Blocklist

To backup your blocklist, simply copy the blocklist file:

```bash
sudo cp /var/www/blocklists/blocked.txt ~/blocklist-backup-$(date +%Y%m%d).txt
```

### Restoring Your Blocklist

To restore a previous backup:

```bash
sudo cp ~/blocklist-backup-YYYYMMDD.txt /var/www/blocklists/blocked.txt
sudo chown www-data:www-data /var/www/blocklists/blocked.txt
```

## Updating the Application

To update the application, you can run the installation script again, which will reinstall all components while preserving your blocklist:

```bash
sudo ./install-blocklist-manager.sh
```

---

If you encounter any issues not covered in this guide, please open an issue on the GitHub repository.

*Created by [Your Name] with AI assistance from ChatGPT 4.0 and Claude 3.7 Sonnet*
