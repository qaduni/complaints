#!/usr/bin/env bash
set -euo pipefail

APP_NAME="complaints_app"
APP_DIR="/opt/$APP_NAME"
APP_USER="complaints_user"

echo "[*] Stopping and disabling $APP_NAME service"
sudo systemctl stop $APP_NAME
sudo systemctl disable $APP_NAME
sudo rm -f /etc/systemd/system/$APP_NAME.service

echo "[*] Stopping and removing Redis server..."
systemctl stop redis-server
systemctl disable redis-server
apt-get purge -y redis-server
apt-get autoremove -y

echo "[*] Removing Nginx site config"
sudo rm -f /etc/nginx/sites-enabled/$APP_NAME
sudo rm -f /etc/nginx/sites-available/$APP_NAME
sudo systemctl reload nginx

echo "[*] Removing application files from $APP_DIR"
sudo rm -rf "$APP_DIR"

echo "[*] Removing app user $APP_USER"
sudo userdel "$APP_USER" || echo "User $APP_USER does not exist, skipping."

echo "[✓] Uninstallation complete."
