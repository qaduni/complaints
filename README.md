# Complaints Management Web Application

A Flask-based web application for submitting and managing complaints.  
Designed for Arabic-speaking users with RTL layout support.  

This application is intended for universities and organizations to allow people to submit complaints anonymously, track their status, and for admins to manage them securely.

---

## ✨ Features

- **Complaint tracking** — Each submission gets a unique tracking token.
- **Admin dashboard** — Manage complaints and admin accounts.
- **Status management** — Update and filter complaint statuses.
- **Data export** — Export complaints as `.xlsx` Excel files.
- **Arabic interface** — Full right-to-left layout support.
- **Security**:
  - CSRF protection on all forms.
  - Rate limiting on public submissions and login.
  - Secure session management for admin routes.

---

## Note

You can run these commands directly on your server terminal to install, update, or uninstall the app.

## 🚀 Installation

### Auto Install

Run the following command to install the website and configure it automatically:

For HTTPS:

```bash
curl -sSL https://raw.githubusercontent.com/qaduni/complaints/master/scripts/deploy_app.sh | \
sudo bash -s -- <domain_or_subdomain> <ssl_cert_path> <ssl_cert_key_path>
```

For HTTP:

```bash
curl -sSL https://raw.githubusercontent.com/qaduni/complaints/master/scripts/deploy_app.sh | \
sudo bash -s -- <domain_or_subdomain>
```

### Manual Install

For those how want to do things by hand.

1. Create app user.

    ```bash
    sudo useradd --create-home --shell /bin/bash complaints_user
    ```

2. Install dependencies.

    ```bash
    sudo apt-get update
    sudo apt-get install -y software-properties-common git nginx redis-server
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.13 python3.13-venv
    ```

3. Clone the project repository.

    ```bash
    sudo git clone https://github.com/qaduni/complaints.git /opt/complaints_app
    sudo chown -R complaints_user:complaints_user /opt/complaints_app
    ```

4. Create and activate Python virtual environment.

    ```bash
    sudo -u complaints_user python3.13 -m venv /opt/complaints_app/venv
    ```

5. Install Python dependencies.

    ```bash
    sudo -u complaints_user /opt/complaints_app/venv/bin/pip install --upgrade pip wheel setuptools

    sudo -u complaints_user /opt/complaints_app/venv/bin/pip install -r /opt/complaints_app/requirements.txt
    ```

6. Create systemd service file for Gunicorn.

    Create `/etc/systemd/system/complaints_app.service` using vim or nano and put this text:

    ```bash
    [Unit]
    Description=Gunicorn instance to serve complaints_app
    After=network.target

    [Service]
    User=complaints_user
    Group=www-data
    WorkingDirectory=/opt/complaints_app
    Environment="PATH=/opt/complaints_app/venv/bin"
    ExecStart=/opt/complaints_app/venv/bin/gunicorn --workers 3 --bind unix:/opt/complaints_app/complaints_app.sock -m 007 wsgi:app
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    ```

    Then reload systemd and start the service:

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable complaints_app
    sudo systemctl start complaints_app
    ```

7. Configure Nginx.

    Create `/etc/nginx/sites-available/complaints_app` using vim or nano and put this text:

    For HTTP:

    ```bash
    server {
        listen 80;
        server_name your.subdomain.com;

        location / {
            include proxy_params;
            proxy_pass http://unix:/opt/complaints_app/complaints_app.sock;
        }

        location /static {
            alias /opt/complaints_app/app/static;
        }
    }
    ```

    For HTTPS:

    ```bash
    server {
          listen 80;
          server_name your.subdomain.com;

          # Redirect all HTTP to HTTPS
          return 301 https://\$host\$request_uri;
      }

      server {
          listen 443 ssl;
          server_name your.subdomain.com;

          ssl_certificate /etc/letsencrypt/live/your.subdomain.com/fullchain.pem;
          ssl_certificate_key /etc/letsencrypt/live/your.subdomain.com/privkey.pem;

          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_prefer_server_ciphers on;
          ssl_ciphers HIGH:!aNULL:!MD5;

          location / {
              include proxy_params;
              proxy_pass http://unix:/opt/complaints_app/complaints_app.sock;
          }

          location /static {
              alias /opt/complaints_app/app/static;
          }
      }
    ```

    Enable the site and reload Nginx:

    ```bash
    sudo ln -s /etc/nginx/sites-available/complaints_app /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl reload nginx
    ```

8. Adjust permissions.

    ```bash
    sudo chown -R complaints_user:www-data /opt/complaints_app
    sudo chmod -R 750 /opt/complaints_app
    sudo chmod 770 /opt/complaints_app/complaints_app.sock
    ```

9. Verify.
    - Visit `http://your.subdomain.com` to check the app.

    - Check logs if issues:

      - Gunicorn: sudo journalctl -u complaints_app

      - Nginx: /var/log/nginx/error.log

## ⬆️ Updating the Website

Update the website without affecting existing data or configuration.

```bash
curl -sSL https://raw.githubusercontent.com/qaduni/complaints/master/scripts/update_app.sh | sudo bash
```

## 🗑 Uninstallation

Remove the website and all configurations:

```bash
curl -sSL https://raw.githubusercontent.com/qaduni/complaints/master/scripts/uninstall_app.sh | sudo bash
```

## 📖 Usage

1. Public Access

    - Open the landing page to submit a complaint.

    - After submission, save the tracking link to monitor complaint status.

2. Admin Access

    - Visit /admin/login to sign in.

    - Default Username `admin` and Password is `admin123`.

    - Manage complaints and admin accounts from the dashboard.

    - Export complaints to Excel when needed.

## 🔒 Security Notes

- All forms are protected against CSRF attacks.

- Public submissions and logins are rate-limited to prevent abuse.

- Admin sessions are secured with HttpOnly cookies.

- Passwords are hashed with bcrypt before storage.

- Unique tracking tokens are generated securely.
