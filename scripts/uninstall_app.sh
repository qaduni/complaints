#!/usr/bin/env bash
set -euo pipefail

APP_NAME="complaints_app"
APP_USER="complaints_user"
APP_DIR="/opt/$APP_NAME"
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
NGINX_ENABLED="/etc/nginx/sites-enabled/$APP_NAME"
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"

echo "[+] Stopping and disabling $APP_NAME service"
systemctl stop "$APP_NAME" || true
systemctl disable "$APP_NAME" || true

echo "[+] Removing systemd service file"
rm -f "$SERVICE_FILE"
systemctl daemon-reload

echo "[+] Removing Nginx config and disabling site"
rm -f "$NGINX_CONF" "$NGINX_ENABLED"
nginx -t
systemctl reload nginx

echo "[+] Removing app directory $APP_DIR"
rm -rf "$APP_DIR"

echo "[+] Deleting user $APP_USER"
userdel -r "$APP_USER" || true

echo "[✓] Uninstallation complete."
