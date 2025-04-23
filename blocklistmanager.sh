#install-blocklist-manager.sh
#!/bin/bash

# Stop any existing services that might be running
systemctl stop blocklist-manager.service 2>/dev/null || true

# Install necessary packages
apt update
apt install -y nginx python3 python3-pip python3-flask

# Install required Python packages
pip3 install flask flask-login werkzeug

# Create directory structure
mkdir -p /var/www/blocklist-manager/templates
mkdir -p /var/www/blocklist-manager/static/css
mkdir -p /var/www/blocklist-manager/static/js

# Create the Flask application
cat > /var/www/blocklist-manager/app.py << 'EOF'
from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import check_password_hash, generate_password_hash
import re
import os

app = Flask(__name__)
app.secret_key = 'n38dj2j0dj20dj209jd029jd029j209djw9'  # Change this to a random secure key

# Configure Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Simple user class for authentication
class User(UserMixin):
    def __init__(self, id, username, password_hash):
        self.id = id
        self.username = username
        self.password_hash = password_hash

# Hardcoded user (in production, use a database)
users = {
    '<yourusername>': User(1, '<yourusername>', generate_password_hash('<yourpass>'))
}

@login_manager.user_loader
def load_user(user_id):
    for user in users.values():
        if user.id == int(user_id):
            return user
    return None

@app.route('/', methods=['GET'])
def home():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if username in users and check_password_hash(users[username].password_hash, password):
            login_user(users[username])
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password')
    
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/dashboard', methods=['GET', 'POST'])
@login_required
def dashboard():
    blocklist_file = '/var/www/blocklists/blocked.txt'
    current_domains = []
    
    # Read current blocklist if it exists
    if os.path.exists(blocklist_file):
        with open(blocklist_file, 'r') as f:
            current_domains = f.read().splitlines()
    
    if request.method == 'POST':
        domain_input = request.form.get('domains', '')
        
        # Process the input
        domains = process_domain_input(domain_input)
        
        # Merge with existing domains
        all_domains = current_domains + domains
        
        # Filter duplicates and sort
        all_domains = sorted(list(set(all_domains)))
        
        # Save to file
        with open(blocklist_file, 'w') as f:
            f.write('\n'.join(all_domains))
        
        flash('Blocklist has been updated successfully!')
        current_domains = all_domains
    
    # Pair up domains for display (base domain and wildcard)
    domain_pairs = []
    i = 0
    while i < len(current_domains):
        if i+1 < len(current_domains) and current_domains[i+1] == f'*.{current_domains[i]}':
            domain_pairs.append((current_domains[i], current_domains[i+1]))
            i += 2
        else:
            # Handle odd cases where we might not have pairs
            domain_pairs.append((current_domains[i], None))
            i += 1
    
    return render_template('dashboard.html', domain_pairs=domain_pairs)

@app.route('/delete_entry', methods=['POST'])
@login_required
def delete_entry():
    blocklist_file = '/var/www/blocklists/blocked.txt'
    
    # Get the index to delete
    index = request.form.get('index', type=int)
    
    if index is None:
        flash('Invalid index specified')
        return redirect(url_for('dashboard'))
    
    # Read current blocklist
    current_domains = []
    if os.path.exists(blocklist_file):
        with open(blocklist_file, 'r') as f:
            current_domains = f.read().splitlines()
    
    # Convert to pairs for processing
    domain_pairs = []
    i = 0
    while i < len(current_domains):
        if i+1 < len(current_domains) and current_domains[i+1] == f'*.{current_domains[i]}':
            domain_pairs.append((current_domains[i], current_domains[i+1]))
            i += 2
        else:
            domain_pairs.append((current_domains[i], None))
            i += 1
    
    # Check if index is valid
    if 0 <= index < len(domain_pairs):
        # Remove the pair
        removed_pair = domain_pairs.pop(index)
        flash(f'Removed domain: {removed_pair[0]}')
        
        # Flatten the pairs back to a list
        new_domains = []
        for domain, wildcard in domain_pairs:
            new_domains.append(domain)
            if wildcard:
                new_domains.append(wildcard)
        
        # Save the updated list
        with open(blocklist_file, 'w') as f:
            f.write('\n'.join(new_domains))
    else:
        flash('Invalid index: Out of range')
    
    return redirect(url_for('dashboard'))

def process_domain_input(input_text):
    # Split by multiple delimiters (newlines, commas, or spaces)
    # First replace commas with spaces
    cleaned_input = re.sub(r',', ' ', input_text)
    
    # Now split by lines and spaces
    raw_domains = []
    for line in cleaned_input.split('\n'):
        line = line.strip()
        if line:
            raw_domains.extend(line.split())
    
    # Process each domain
    result = []
    for domain in raw_domains:
        if not domain:
            continue
            
        # Remove protocol (http:// or https://)
        domain = re.sub(r'^https?://', '', domain)
        
        # Remove www. prefix
        domain = re.sub(r'^www\.', '', domain)
        
        # Remove any path component
        domain = domain.split('/')[0]
        
        # If we have a valid domain, add it and its wildcard
        if domain and '.' in domain:
            result.append(domain)
            result.append(f'*.{domain}')
    
    return result

if __name__ == '__main__':
    # Make sure the directory exists
    os.makedirs(os.path.dirname('/var/www/blocklists/blocked.txt'), exist_ok=True)
    
    # Make sure the file exists
    if not os.path.exists('/var/www/blocklists/blocked.txt'):
        with open('/var/www/blocklists/blocked.txt', 'w') as f:
            f.write('')
    
    app.run(host='0.0.0.0', port=5050, debug=False)
EOF

# Create login template
cat > /var/www/blocklist-manager/templates/login.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blocklist Manager - Login</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <div class="login-container">
            <h1>Blocklist Manager</h1>
            <form method="post">
                {% with messages = get_flashed_messages() %}
                    {% if messages %}
                        <div class="flash-messages">
                            {% for message in messages %}
                                <p>{{ message }}</p>
                            {% endfor %}
                        </div>
                    {% endif %}
                {% endwith %}
                
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <button type="submit" class="btn-login">Login</button>
            </form>
        </div>
    </div>
</body>
</html>
EOF

# Create dashboard template with deletion and search features
cat > /var/www/blocklist-manager/templates/dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blocklist Manager - Dashboard</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container dashboard">
        <header>
            <h1>Blocklist Manager</h1>
            <a href="{{ url_for('logout') }}" class="btn-logout">Logout</a>
        </header>
        
        {% with messages = get_flashed_messages() %}
            {% if messages %}
                <div class="flash-messages">
                    {% for message in messages %}
                        <p>{{ message }}</p>
                    {% endfor %}
                </div>
            {% endif %}
        {% endwith %}
        
        <div class="main-content">
            <div class="input-section">
                <h2>Add domains to blocklist</h2>
                <form method="post">
                    <div class="form-instructions">
                        <p>Input the websites you want to block. Do not add any bullet, numbers. You may add the list in this format:
                        https://domain.com or domain.com. separate it with space, or separate it with ',' or separate it with a new line</p>
                        
                        <p class="tip"><strong>Tip:</strong> If you are copying and pasting a list in new line format from ChatGPT or other sources, 
                        paste it using CTRL+SHIFT+V or COMMAND+SHIFT+V for proper formatting.</p>
                    </div>
                    
                    <textarea name="domains" id="domains" rows="15" placeholder="Enter domains here..."></textarea>
                    
                    <button type="submit" class="btn-submit">Update Blocklist</button>
                </form>
            </div>
            
            <div class="current-blocklist">
                <h2>Current Blocklist</h2>
                <div class="blocklist-header">
                    <div class="blocklist-stats">
                        <p>Total domains: {{ domain_pairs|length }}</p>
                    </div>
                    <div class="search-container">
                        <input type="text" id="domain-search" placeholder="Search domains..." onkeyup="filterDomains()">
                        <button id="clear-search" onclick="clearSearch()">Clear</button>
                    </div>
                </div>
                <div class="domain-list-container">
                    {% if domain_pairs %}
                        <table class="domain-table" id="domain-table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Domain</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                {% for domain, wildcard in domain_pairs %}
                                <tr>
                                    <td class="line-number">{{ loop.index }}</td>
                                    <td class="domain-cell">
                                        {{ domain }}<br>
                                        {% if wildcard %}<span class="wildcard">{{ wildcard }}</span>{% endif %}
                                    </td>
                                    <td class="action-cell">
                                        <form method="post" action="{{ url_for('delete_entry') }}">
                                            <input type="hidden" name="index" value="{{ loop.index0 }}">
                                            <button type="submit" class="btn-delete">Remove</button>
                                        </form>
                                    </td>
                                </tr>
                                {% endfor %}
                            </tbody>
                        </table>
                        <div id="no-results" class="no-results" style="display: none;">
                            No domains match your search
                        </div>
                    {% else %}
                        <p>No domains in blocklist.</p>
                    {% endif %}
                </div>
            </div>
        </div>
    </div>
    
    <script src="{{ url_for('static', filename='js/script.js') }}"></script>
</body>
</html>
EOF

# Create CSS file with styles for the table, line numbers, and search features
cat > /var/www/blocklist-manager/static/css/style.css << 'EOF'
:root {
    --primary-color: #19c37d;
    --primary-hover: #0f9d63;
    --secondary-color: #444654;
    --bg-color: #f7f7f8;
    --text-color: #343541;
    --border-color: #ececf1;
    --input-bg: #ffffff;
    --shadow-color: rgba(0, 0, 0, 0.05);
    --danger-color: #dc3545;
    --danger-hover: #c82333;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
    background-color: var(--bg-color);
    color: var(--text-color);
    line-height: 1.6;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

/* Login Page */
.login-container {
    max-width: 400px;
    margin: 100px auto;
    background-color: var(--input-bg);
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 5px 15px var(--shadow-color);
}

.login-container h1 {
    text-align: center;
    margin-bottom: 30px;
    color: var(--primary-color);
}

.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 5px;
    font-weight: 500;
}

.form-group input {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--border-color);
    border-radius: 5px;
    font-size: 16px;
}

.btn-login {
    width: 100%;
    padding: 12px;
    background-color: var(--primary-color);
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.3s;
}

.btn-login:hover {
    background-color: var(--primary-hover);
}

/* Dashboard */
header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    padding-bottom: 15px;
    border-bottom: 1px solid var(--border-color);
}

header h1 {
    color: var(--primary-color);
}

.btn-logout {
    padding: 8px 15px;
    background-color: var(--secondary-color);
    color: white;
    border: none;
    border-radius: 5px;
    text-decoration: none;
    font-size: 14px;
    transition: opacity 0.3s;
}

.btn-logout:hover {
    opacity: 0.9;
}

.main-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
}

.input-section, .current-blocklist {
    background-color: var(--input-bg);
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 5px 15px var(--shadow-color);
}

.form-instructions {
    margin-bottom: 15px;
    font-size: 14px;
}

.tip {
    margin-top: 10px;
    padding: 10px;
    background-color: #f0f8ff;
    border-left: 4px solid var(--primary-color);
    border-radius: 4px;
}

textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--border-color);
    border-radius: 5px;
    font-size: 14px;
    font-family: monospace;
    resize: vertical;
}

.btn-submit {
    margin-top: 15px;
    padding: 10px 20px;
    background-color: var(--primary-color);
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.3s;
}

.btn-submit:hover {
    background-color: var(--primary-hover);
}

/* Search styles */
.blocklist-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}

.search-container {
    display: flex;
    gap: 8px;
}

#domain-search {
    padding: 8px 12px;
    border: 1px solid var(--border-color);
    border-radius: 5px;
    font-size: 14px;
    width: 200px;
}

#clear-search {
    padding: 8px 12px;
    background-color: var(--secondary-color);
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 14px;
    cursor: pointer;
    transition: opacity 0.3s;
}

#clear-search:hover {
    opacity: 0.9;
}

.domain-list-container {
    margin-top: 15px;
    max-height: 500px;
    overflow-y: auto;
    background-color: #f5f5f5;
    padding: 15px;
    border-radius: 5px;
    font-size: 14px;
}

.domain-table {
    width: 100%;
    border-collapse: collapse;
    font-family: monospace;
}

.domain-table th {
    text-align: left;
    padding: 8px;
    border-bottom: 2px solid var(--border-color);
    background-color: #e9e9e9;
    position: sticky;
    top: 0;
    z-index: 10;
}

.domain-table td {
    padding: 8px;
    border-bottom: 1px solid var(--border-color);
}

.line-number {
    width: 40px;
    color: #888;
    text-align: right;
    padding-right: 15px;
    font-size: 12px;
}

.domain-cell {
    font-family: monospace;
}

.wildcard {
    color: #666;
    font-size: 0.9em;
}

.action-cell {
    width: 80px;
    text-align: center;
}

.btn-delete {
    padding: 4px 8px;
    background-color: var(--danger-color);
    color: white;
    border: none;
    border-radius: 3px;
    font-size: 12px;
    cursor: pointer;
    transition: background-color 0.3s;
}

.btn-delete:hover {
    background-color: var(--danger-hover);
}

.blocklist-stats {
    font-size: 14px;
    color: var(--secondary-color);
}

.flash-messages {
    padding: 10px 15px;
    margin-bottom: 20px;
    background-color: #d4edda;
    color: #155724;
    border-radius: 5px;
}

.no-results {
    text-align: center;
    padding: 20px;
    color: #666;
    font-style: italic;
}

/* Domain entries alternate row colors */
.domain-table tbody tr:nth-child(even) {
    background-color: #f0f0f0;
}

.domain-table tbody tr:hover {
    background-color: #e6e6e6;
}

/* Highlight search matches */
.highlight {
    background-color: #ffff99;
    font-weight: bold;
}

/* Responsive Design */
@media (max-width: 768px) {
    .main-content {
        grid-template-columns: 1fr;
    }
    
    .input-section, .current-blocklist {
        margin-bottom: 20px;
    }
    
    .blocklist-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 10px;
    }
    
    .search-container {
        width: 100%;
    }
    
    #domain-search {
        flex-grow: 1;
    }
    
    .domain-table th:first-child,
    .domain-table td:first-child {
        display: none;
    }
    
    .action-cell {
        width: 60px;
    }
}
EOF

# Create JS file with search functionality
cat > /var/www/blocklist-manager/static/js/script.js << 'EOF'
document.addEventListener('DOMContentLoaded', function() {
    // Add confirmation for delete actions
    const deleteForms = document.querySelectorAll('form[action="/delete_entry"]');
    deleteForms.forEach(form => {
        form.addEventListener('submit', function(e) {
            const confirmed = confirm('Are you sure you want to remove this domain from the blocklist?');
            if (!confirmed) {
                e.preventDefault();
            }
        });
    });
});

// Filter domains based on search input
function filterDomains() {
    const searchInput = document.getElementById('domain-search');
    const filter = searchInput.value.toLowerCase();
    const table = document.getElementById('domain-table');
    const tr = table.getElementsByTagName('tr');
    let visibleCount = 0;
    
    // Loop through all table rows (skip header row)
    for (let i = 1; i < tr.length; i++) {
        const domainCell = tr[i].getElementsByClassName('domain-cell')[0];
        if (domainCell) {
            const domainText = domainCell.textContent || domainCell.innerText;
            if (domainText.toLowerCase().indexOf(filter) > -1) {
                tr[i].style.display = '';
                visibleCount++;
                
                // Highlight the matching text if there's a search term
                if (filter) {
                    highlightText(domainCell, filter);
                } else {
                    // Remove highlighting if search is cleared
                    domainCell.innerHTML = domainCell.innerHTML.replace(/<span class="highlight">([^<]+)<\/span>/g, '$1');
                }
            } else {
                tr[i].style.display = 'none';
            }
        }
    }
    
    // Show "no results" message if needed
    const noResults = document.getElementById('no-results');
    if (visibleCount === 0 && filter !== '') {
        noResults.style.display = 'block';
        table.style.display = 'none';
    } else {
        noResults.style.display = 'none';
        table.style.display = 'table';
    }
    
    // Update stats to show filtered count
    const stats = document.querySelector('.blocklist-stats p');
    const totalDomains = tr.length - 1; // Subtract header row
    if (filter && visibleCount !== totalDomains) {
        stats.textContent = `Showing ${visibleCount} of ${totalDomains} domains`;
    } else {
        stats.textContent = `Total domains: ${totalDomains}`;
    }
}

// Highlight matching text in search results
function highlightText(element, searchText) {
    const innerHTML = element.innerHTML;
    const index = innerHTML.toLowerCase().indexOf(searchText.toLowerCase());
    if (index >= 0) {
        const originalText = innerHTML.substring(index, index + searchText.length);
        const newInnerHTML = innerHTML.replace(
            originalText, 
            `<span class="highlight">${originalText}</span>`
        );
        element.innerHTML = newInnerHTML;
    }
}

// Clear the search box and reset the display
function clearSearch() {
    const searchInput = document.getElementById('domain-search');
    searchInput.value = '';
    filterDomains();
    searchInput.focus();
}
EOF

# Create Nginx configuration
cat > /etc/nginx/sites-available/blocklist-manager << 'EOF'
server {
    listen 8080;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:5050;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /var/www/blocklist-manager/static;
    }
}
EOF

# Enable the site and disable the default if it's enabled
ln -sf /etc/nginx/sites-available/blocklist-manager /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create a systemd service file
cat > /etc/systemd/system/blocklist-manager.service << 'EOF'
[Unit]
Description=Blocklist Manager Web Application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/blocklist-manager
ExecStart=/usr/bin/python3 /var/www/blocklist-manager/app.py
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Set correct permissions
chown -R www-data:www-data /var/www/blocklist-manager
chmod -R 755 /var/www/blocklist-manager

# Make sure the blocklists directory exists
mkdir -p /var/www/blocklists
touch /var/www/blocklists/blocked.txt
chown -R www-data:www-data /var/www/blocklists
chmod -R 755 /var/www/blocklists

# Reload systemd, enable and start services
systemctl daemon-reload
systemctl enable blocklist-manager.service
systemctl start blocklist-manager.service
systemctl restart nginx

# Print status for debugging
echo "==== Nginx Status ===="
systemctl status nginx --no-pager
echo "==== Blocklist Manager Status ===="
systemctl status blocklist-manager --no-pager
echo "==== Ports in Use ===="
netstat -tuln | grep -E ':(8080|5050)'

echo "Blocklist Manager with search feature has been installed and should be running at http://10.0.0.98:8080"
echo "Login with username: <yourusername> and password: <yourpass>"
tokshernandez@toksvm:/scripts$ 
