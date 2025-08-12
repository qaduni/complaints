#!/usr/bin/env bash
set -euo pipefail

APP_NAME="complaints_app"
APP_USER="complaints_user"
APP_DIR="/opt/$APP_NAME"

echo "[+] Updating git repo"
git -C "$APP_DIR" pull

echo "[+] Upgrading pip packages"
sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install --upgrade -r "$APP_DIR/requirements.txt"

echo "[+] Restarting Gunicorn service"
systemctl restart "$APP_NAME"

echo "[+] Reloading Nginx"
nginx -t
systemctl reload nginx

echo "[✓] Update complete."
