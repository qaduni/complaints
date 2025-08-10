#!/usr/bin/env bash
set -euo pipefail

# ======== CONFIG ========
APP_NAME="complaints_app"
APP_USER="complaints_user"
APP_DIR="/opt/$APP_NAME"
PYTHON_VERSION="3.13"
REPO_URL="https://github.com/qaduni/complaints.git"
DOMAIN_NAME="${1:-}"  # passed as first argument

if [[ -z "$DOMAIN_NAME" ]]; then
    echo "Usage: $0 <domain_or_subdomain>"
    echo "Example: $0 complaints.example.com"
    exit 1
fi

# ======== CREATE APP USER ========
if ! id "$APP_USER" >/dev/null 2>&1; then
    echo "[+] Creating app user: $APP_USER"
    sudo useradd --system --no-create-home --shell /bin/false "$APP_USER"
fi

# ======== INSTALL SYSTEM REQUIREMENTS ========
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
echo "[+] Installing Python $PYTHON_VERSION, venv, pip, git, and Nginx"
sudo apt update
sudo apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python3-pip git nginx

# ======== CLONE OR UPDATE REPO ========
if [[ -d "$APP_DIR/.git" ]]; then
    echo "[+] Repo exists, pulling latest changes"
    sudo -u "$USER" git -C "$APP_DIR" pull
else
    echo "[+] Cloning repository into $APP_DIR"
    sudo mkdir -p "$APP_DIR"
    sudo chown "$USER":"$USER" "$APP_DIR"
    git clone "$REPO_URL" "$APP_DIR"
fi

# ======== SETUP PYTHON VENV ========
if [[ ! -d "$APP_DIR/venv" ]]; then
    echo "[+] Creating Python virtual environment"
    python${PYTHON_VERSION} -m venv "$APP_DIR/venv"
fi

# ======== INSTALL APP REQUIREMENTS ========
echo "[+] Installing application requirements"
"$APP_DIR/venv/bin/pip" install --upgrade pip wheel
if [[ -f "$APP_DIR/requirements.txt" ]]; then
    "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"
else
    "$APP_DIR/venv/bin/pip" install flask gunicorn
fi

# Install Redis server if missing
if ! command -v redis-server &> /dev/null; then
    echo "Installing Redis server..."
    apt-get update
    apt-get install -y redis-server
fi

# ======== CREATE SYSTEMD SERVICE ========
echo "[+] Creating systemd service for Gunicorn"
sudo tee /etc/systemd/system/$APP_NAME.service > /dev/null <<EOF
[Unit]
Description=Gunicorn instance for $APP_NAME
After=network.target

[Service]
User=$APP_USER
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind unix:$APP_DIR/$APP_NAME.sock wsgi:app

[Install]
WantedBy=multi-user.target
EOF

# ======== CONFIGURE NGINX ========
echo "[+] Creating Nginx config for $DOMAIN_NAME"
sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        include proxy_params;
        proxy_pass http://unix:$APP_DIR/$APP_NAME.sock;
    }

    location /static {
        alias $APP_DIR/static;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/

# ======== PERMISSIONS ========
echo "[+] Adjusting permissions"
sudo chown -R $APP_USER:www-data "$APP_DIR"

# Optionally configure firewall (UFW example)
if command -v ufw &> /dev/null; then
    ufw allow 6379/tcp
fi

# ======== START SERVICES ========
echo "[+] Starting Redis, Gunicorn and Nginx"
sudo systemctl daemon-reload
systemctl enable redis-server
sudo systemctl enable $APP_NAME
sudo systemctl restart $APP_NAME
sudo systemctl restart nginx
systemctl start redis-server

echo "[✓] Deployment complete!"
echo "Visit: http://$DOMAIN_NAME"
