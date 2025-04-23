# BlocklistManager
A web-based application for managing domain blocklists with an intuitive user interface. This application allows users to add, view, search, and remove domains from a centralized blocklist file.


## Project Overview

BlockList Manager is a simple yet powerful web application that allows users to manage lists of blocked domains through a clean, user-friendly interface. The application is designed to help system administrators and privacy-conscious users maintain domain blocklists that can be integrated with DNS filtering systems, firewalls, or other network security tools.

**Created by:** [Your Name]

**Tech Stack:**
- Backend: Python with Flask
- Frontend: HTML, CSS, JavaScript
- Web Server: Nginx
- Authentication: Flask-Login

## Features

- **User Authentication**: Secure login system to protect blocklist management
- **Domain Management**: Add multiple domains at once using various formats
- **Smart Domain Processing**: Automatically adds wildcards for each domain
- **Search Functionality**: Easily find domains in large blocklists
- **Responsive Design**: Works on desktop and mobile devices

## How It Works

The BlockList Manager allows administrators to:

1. **Login** to the secure dashboard
2. **Add domains** to be blocked (with flexible input formats)
3. **View and search** the current blocklist
4. **Remove domains** from the blocklist as needed

The application automatically creates both direct domain and wildcard entries for comprehensive blocking.

## Origins & Development Process

**💡 This project was created with NO prior coding experience!**

I developed this application with assistance from AI tools:
- ChatGPT 4.0
- Claude 3.7 Sonnet

As someone without a formal programming background, I used AI tools to help me understand and implement:
- The Flask web framework
- Authentication systems
- Front-end development with HTML/CSS
- Database-free file storage systems
- Search and filtering functionalities

This project demonstrates how modern AI tools can empower anyone to build useful software applications regardless of their technical background.

## Installation Guide

### Prerequisites

- Ubuntu/Debian Linux server
- sudo privileges
- Basic command line knowledge

### Automatic Installation

1. **Download the installation script**

```bash
wget https://raw.githubusercontent.com/[your-username]/blocklist-manager/main/install-blocklist-manager.sh
```

2. **Make the script executable**

```bash
chmod +x install-blocklist-manager.sh
```

3. **Run the installation script**

```bash
sudo ./install-blocklist-manager.sh
```

4. **Access the application**

Open your browser and navigate to:
```
http://[your-server-ip]:8080
```

5. **Login with your credentials**

Use the username and password you configured during installation.

### Manual Installation

If you prefer to install the components manually, follow these steps:

1. **Install required packages**

```bash
sudo apt update
sudo apt install -y nginx python3 python3-pip python3-flask
sudo pip3 install flask flask-login werkzeug
```

2. **Create directory structure**

```bash
sudo mkdir -p /var/www/blocklist-manager/templates
sudo mkdir -p /var/www/blocklist-manager/static/css
sudo mkdir -p /var/www/blocklist-manager/static/js
sudo mkdir -p /var/www/blocklists
```

3. **Create application files**

Create the following files with your preferred text editor:

- `/var/www/blocklist-manager/app.py` - The main Flask application
- `/var/www/blocklist-manager/templates/login.html` - Login page template
- `/var/www/blocklist-manager/templates/dashboard.html` - Dashboard template
- `/var/www/blocklist-manager/static/css/style.css` - CSS styles
- `/var/www/blocklist-manager/static/js/script.js` - JavaScript functionality

4. **Configure Nginx**

Create a new Nginx site configuration:

```bash
sudo nano /etc/nginx/sites-available/blocklist-manager
```

Enable the site:

```bash
sudo ln -sf /etc/nginx/sites-available/blocklist-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

5. **Create systemd service**

```bash
sudo nano /etc/systemd/system/blocklist-manager.service
```

6. **Set permissions**

```bash
sudo chown -R www-data:www-data /var/www/blocklist-manager
sudo chmod -R 755 /var/www/blocklist-manager
sudo chown -R www-data:www-data /var/www/blocklists
sudo chmod -R 755 /var/www/blocklists
```

7. **Start services**

```bash
sudo systemctl daemon-reload
sudo systemctl enable blocklist-manager.service
sudo systemctl start blocklist-manager.service
sudo systemctl restart nginx
```

## Customization

### Changing the Login Credentials

Edit the `app.py` file and modify the following section:

```python
# Replace with your desired username and password
users = {
    'admin': User(1, 'admin', generate_password_hash('your-secure-password'))
}
```

### Changing the Port

To change the port from 8080, edit:

1. Nginx configuration file (`/etc/nginx/sites-available/blocklist-manager`)
2. Update the `listen 8080;` line to your desired port

### Custom Styling

Modify the CSS file at `/var/www/blocklist-manager/static/css/style.css` to customize the appearance.

## Security Considerations

- The application uses password hashing for security
- Default credentials should be changed immediately after installation
- Consider adding HTTPS using Let's Encrypt for production use
- This application is designed for internal networks by default

## Troubleshooting

### Application Not Starting

Check the service status:

```bash
sudo systemctl status blocklist-manager
```

View the logs:

```bash
sudo journalctl -u blocklist-manager -n 50
```

### Web Interface Not Accessible

Check if Nginx is running:

```bash
sudo systemctl status nginx
```

Verify the port is open:

```bash
sudo netstat -tuln | grep 8080
```

## Future Improvements

- Email notifications when blocklist changes
- User management system for multiple administrators
- Import/export functionality for blocklists
- Integration with popular DNS filtering systems
- Dark mode support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- This project was created using AI assistance from ChatGPT and Claude
- Special thanks to the Flask and Nginx communities for their documentation
- Icons provided by [placeholder] 

---

**Note**: This project was developed as a learning experience and portfolio piece. While functional, additional security measures should be implemented before using in production environments.
