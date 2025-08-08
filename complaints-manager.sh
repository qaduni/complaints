#!/usr/bin/env bash
# gxsh-manager.sh
# Manage install / run / stop / uninstall for the complaints app
# Designed to be run as root (sudo): curl ... | sudo bash -s -- <command> [repo_url] [subdomain]
set -euo pipefail

# ---------------------------
# Configuration defaults
# ---------------------------
APP_USER="complaints"
APP_DIR="/opt/complaints_app"
VENV_DIR="$APP_DIR/venv"
SERVICE_NAME="complaints.service"
SYSTEMD_FILE="/etc/systemd/system/$SERVICE_NAME"
NGINX_SITE="/etc/nginx/sites-available/complaints"
NGINX_LINK="/etc/nginx/sites-enabled/complaints"
GUNICORN_BIND="127.0.0.1:8000"

# Default repo
DEFAULT_REPO="https://github.com/qaduni/complaints.git"

# ---------------------------
# Helper functions
# ---------------------------
info() { echo -e "\e[34m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
err() { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
confirm() {
  local prompt=${1:-"Continue?"}
  read -r -p "$prompt [y/N]: " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
  err "This script must be run with sudo/root."
  exit 1
fi

# ---------------------------
# CLI parsing
# ---------------------------
CMD="${1:-}"
REPO_URL="${2:-$DEFAULT_REPO}"
SUBDOMAIN="${3:-_}"  # "_" means not set; script will use host IP if not replaced
shift || true

usage() {
  cat <<EOF
Usage: <command> [repo_url] [subdomain]
Commands:
  install [repo_url] [subdomain]   Install the app (git clone, venv, uv install, systemd, nginx)
  run                              Start & enable the service
  stop                             Stop & disable the service
  uninstall                        Stop service and remove files & config (asks confirmation)

Examples:
  sudo bash complaints-manager.sh install https://github.com/qaduni/complaints.git complaints.example.com
  sudo bash complaints-manager.sh run
  sudo bash complaints-manager.sh stop
  sudo bash complaints-manager.sh uninstall
EOF
}

# ---------------------------
# OS utilities
# ---------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }

get_host_ip() {
  # Attempt to detect the machine's private IP
  ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1 || hostname -I | awk '{print $1}'
}

# ---------------------------
# Install function
# ---------------------------
do_install() {
  local repo="$REPO_URL"
  local domain="$SUBDOMAIN"

  info "Starting install..."
  info "Repo: $repo"
  if [[ "$domain" == "_" ]]; then
    HOST_IP="$(get_host_ip)"
    info "No subdomain provided. Using local IP: $HOST_IP"
    domain="$HOST_IP"
  else
    info "Subdomain set to: $domain"
  fi

  # Create system user if not exists
  if id -u "$APP_USER" >/dev/null 2>&1; then
    info "User $APP_USER already exists."
  else
    info "Creating system user $APP_USER..."
    useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"
  fi

  # Create app directory
  if [[ -d "$APP_DIR" ]]; then
    info "App dir $APP_DIR already exists. Pulling latest changes if it's a git repo."
    if [[ -d "$APP_DIR/.git" ]]; then
      git -C "$APP_DIR" fetch --all --tags || true
      git -C "$APP_DIR" reset --hard origin/HEAD || true
    else
      warn "$APP_DIR exists and is not a git repo. Skipping clone."
    fi
  else
    info "Creating $APP_DIR and cloning repo..."
    mkdir -p "$APP_DIR"
    chown "$SUDO_USER":"$SUDO_USER" "$APP_DIR"
    sudo -u "$SUDO_USER" git clone --depth 1 "$repo" "$APP_DIR"
  fi

  # Create virtualenv
  if [[ ! -d "$VENV_DIR" ]]; then
    info "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
  else
    info "Virtualenv already exists at $VENV_DIR"
  fi

  # Activate venv for commands below (use subshell)
  (
    set -e
    source "$VENV_DIR/bin/activate"

    # Ensure pip is available - venv provides pip; but we avoid pip where possible
    if ! command_exists uv; then
      info "uv not found in PATH. Attempting to install uv into virtualenv via pip (bootstrapping)..."
      # pip may not be desired, but it's used only to bootstrap uv
      python -m pip install --upgrade pip setuptools wheel >/dev/null
      python -m pip install uv >/dev/null
      export PATH="$VENV_DIR/bin:$PATH"
    else
      info "uv exists on system PATH; using system uv."
    fi

    # Install requirements using uv
    info "Installing project dependencies via uv..."
    # Prefer uv.lock/uv.project in repo; if none, fallback to requirements.txt if present
    if [[ -f "$APP_DIR/uv.project" || -f "$APP_DIR/uv.lock" ]]; then
      cd "$APP_DIR"
      uv install --no-interaction || uv install
    elif [[ -f "$APP_DIR/requirements.txt" ]]; then
      info "uv files not found; installing requirements.txt using pip inside venv..."
      python -m pip install -r "$APP_DIR/requirements.txt"
    else
      warn "No uv.project/uv.lock or requirements.txt found. Skipping Python dependency install."
    fi

    # Ensure gunicorn is installed (needed for service)
    if ! python -c "import pkgutil, sys; sys.exit(0 if pkgutil.find_loader('gunicorn') else 1)" 2>/dev/null; then
      info "Installing gunicorn into venv..."
      python -m pip install gunicorn >/dev/null
    fi
  )

  # Fix ownership
  chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
  chmod -R 750 "$APP_DIR"

  # Create systemd service
  info "Writing systemd service to $SYSTEMD_FILE"
  cat > "$SYSTEMD_FILE" <<EOF
[Unit]
Description=Gunicorn instance to serve Complaints Flask app
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/gunicorn -w 3 -b $GUNICORN_BIND "app:create_app()"

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "$SERVICE_NAME"

  # Nginx site
  info "Installing nginx site for $domain"
  # Install nginx if missing
  if ! command_exists nginx; then
    info "nginx not found. Installing nginx via apt (Debian/Ubuntu)."
    if command_exists apt-get; then
      apt-get update
      apt-get install -y nginx
    else
      warn "Package manager not found to install nginx automatically. Please install nginx manually."
    fi
  fi

  # Create nginx config
  cat > "$NGINX_SITE" <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://$GUNICORN_BIND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static {
        alias $APP_DIR/app/static;
    }

    client_max_body_size 10M;
}
EOF

  ln -sf "$NGINX_SITE" "$NGINX_LINK"
  nginx -t && systemctl restart nginx

  info "Installation finished. Service: $SERVICE_NAME (listening on $GUNICORN_BIND), nginx serving $domain"
  info "If you used a host IP, access the site at http://$domain/"
  info "If you want SSL (Let's Encrypt), run certbot or provide DNS for subdomain."
}

# ---------------------------
# run / stop / uninstall
# ---------------------------
do_run() {
  info "Starting and enabling service..."
  systemctl enable --now "$SERVICE_NAME"
  systemctl status --no-pager "$SERVICE_NAME" || true
  info "Done."
}

do_stop() {
  info "Stopping and disabling service..."
  systemctl stop "$SERVICE_NAME" || true
  systemctl disable "$SERVICE_NAME" || true
  info "Done."
}

do_uninstall() {
  info "UNINSTALL: This will remove the service, nginx site, and application files."
  if ! confirm "Are you sure you want to completely remove $APP_DIR and associated configs?"; then
    info "Aborting uninstall."
    exit 0
  fi

  info "Stopping service..."
  systemctl stop "$SERVICE_NAME" || true
  systemctl disable "$SERVICE_NAME" || true

  info "Removing systemd unit..."
  rm -f "$SYSTEMD_FILE"
  systemctl daemon-reload

  info "Removing nginx site..."
  rm -f "$NGINX_LINK" "$NGINX_SITE" || true
  if command_exists nginx; then
    nginx -t || true
    systemctl reload nginx || true
  fi

  info "Removing app files at $APP_DIR..."
  rm -rf "$APP_DIR"

  info "Optionally removing system user $APP_USER (will fail if user owns files elsewhere)."
  if id -u "$APP_USER" >/dev/null 2>&1; then
    if confirm "Remove system user $APP_USER as well?"; then
      userdel "$APP_USER" || true
      info "Removed user $APP_USER"
    else
      info "Kept user $APP_USER"
    fi
  fi

  info "Uninstall completed."
}

# ---------------------------
# Dispatch
# ---------------------------
case "$CMD" in
  install)
    do_install
    ;;
  run)
    do_run
    ;;
  stop)
    do_stop
    ;;
  uninstall)
    do_uninstall
    ;;
  *)
    usage
    exit 1
    ;;
esac
