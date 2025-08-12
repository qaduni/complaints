#!/usr/bin/env bash
set -euo pipefail

APP_NAME="complaints_app"
APP_USER="complaints_user"
APP_HOME="/home/$APP_USER"
APP_DIR="/opt/$APP_NAME"
PYTHON_VERSION="3.13"
REPO_URL="https://github.com/qaduni/complaints.git"
DOMAIN_NAME="${1:-}"

if [[ -z "$DOMAIN_NAME" ]]; then
    echo "Usage: $0 <domain_or_subdomain>"
    exit 1
fi

log() { echo -e "\n[+] $1"; }

# 1. Create app user if not exists (with home and bash shell)
if id "$APP_USER" &>/dev/null; then
    log "User $APP_USER exists"
else
    log "Creating user $APP_USER with home $APP_HOME"
    useradd --create-home --shell /bin/bash "$APP_USER"
fi

# 2. Add deadsnakes PPA if needed and install Python 3.13
if ! command -v python3.13 &>/dev/null; then
    log "Adding deadsnakes PPA and installing Python $PYTHON_VERSION"
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update
    apt-get install -y python3.13 python3.13-venv git nginx redis-server
else
    log "Python 3.13 already installed"
fi

# 3. Ensure pip for Python 3.13 is installed
if ! command -v pip3.13 &>/dev/null; then
    log "Installing pip for Python 3.13"
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13
else
    log "pip3.13 already installed"
fi

# 4. Clone or update the repo (clone as root, then chown)
if [[ -d "$APP_DIR/.git" ]]; then
    log "Updating existing repo in $APP_DIR"
    git -C "$APP_DIR" pull
else
    log "Cloning repo $REPO_URL to $APP_DIR"
    git clone "$REPO_URL" "$APP_DIR"
fi

log "Setting ownership of $APP_DIR to $APP_USER"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"

# 5. Setup python virtual environment (if not exists)
if [[ ! -d "$APP_DIR/venv" ]]; then
    log "Creating Python virtual environment"
    sudo -u "$APP_USER" python3.13 -m venv "$APP_DIR/venv"
else
    log "Virtual environment already exists"
fi

# 6. Upgrade pip and install requirements
log "Upgrading pip and installing requirements"
sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install --upgrade pip wheel setuptools

if [[ -f "$APP_DIR/requirements.txt" ]]; then
    sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"
else
    log "No requirements.txt found, installing flask and gunicorn"
    sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install flask gunicorn
fi

# 7. Create systemd service file (idempotent)
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
if [[ -f "$SERVICE_FILE" ]]; then
    log "Backing up existing systemd service file"
    cp "$SERVICE_FILE" "$SERVICE_FILE.bak_$(date +%F_%T)"
fi

log "Creating systemd service file $SERVICE_FILE"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Gunicorn instance to serve $APP_NAME
After=network.target

[Service]
User=$APP_USER
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind unix:$APP_DIR/$APP_NAME.sock -m 007 wsgi:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 8. Setup Nginx config (backup if exists)
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
if [[ -f "$NGINX_CONF" ]]; then
    log "Backing up existing Nginx config"
    cp "$NGINX_CONF" "$NGINX_CONF.bak_$(date +%F_%T)"
fi

log "Creating Nginx config"
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        include proxy_params;
        proxy_pass http://unix:$APP_DIR/$APP_NAME.sock;
    }

    location /static {
        alias $APP_DIR/app/static;
    }
}
EOF

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/

# 9. Fix permissions for app dir and socket
log "Setting permissions on app directory"
chown -R "$APP_USER":www-data "$APP_DIR"
chmod -R 750 "$APP_DIR"
chmod 770 "$APP_DIR/$APP_NAME.sock" 2>/dev/null || true  # ignore if socket not created yet

# 10. Reload and enable services, but do NOT restart Redis
log "Reloading systemd daemon"
systemctl daemon-reload

log "Enabling and restarting Gunicorn service"
systemctl enable "$APP_NAME"
systemctl restart "$APP_NAME"

log "Testing Nginx configuration"
nginx -t

log "Restarting Nginx"
systemctl reload nginx

log "[✓] Deployment completed. Visit: http://$DOMAIN_NAME"
