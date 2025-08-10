#!/usr/bin/env bash
set -euo pipefail

APP_NAME="complaints_app"
APP_DIR="/opt/$APP_NAME"
APP_USER="complaints_user"

echo "[*] Updating app in $APP_DIR"

if [[ ! -d "$APP_DIR/.git" ]]; then
  echo "Error: Git repo not found in $APP_DIR"
  exit 1
fi

# Pull latest changes
sudo -u "$USER" git -C "$APP_DIR" pull

# Activate venv and install any new requirements
if [[ -f "$APP_DIR/requirements.txt" ]]; then
  echo "[*] Installing/updating Python dependencies"
  "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"
fi

# Adjust ownership if needed
sudo chown -R $APP_USER:www-data "$APP_DIR"

# Restart Gunicorn service
echo "[*] Restarting $APP_NAME service"
sudo systemctl restart $APP_NAME

echo "[✓] Update completed."
