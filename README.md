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

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)

---

## 🚀 Quick Start with Docker

### 1. Clone the Repository

```bash
git clone https://github.com/qaduni/complaints.git
cd complaints
```

### 2. Configure Environment Variables

Edit the `docker-compose.yml` file to set your environment variables:

```yaml
environment:
  - SECRET_KEY=your-secure-random-key-here
  - DATABASE_URL=sqlite:////app/instance/db.sqlite3
  - DASHBOARD_USERNAME=admin
  - DASHBOARD_PASSWORD=your-secure-password
  - REDIS_URL=redis://redis:6379
```

> ⚠️ **Important**: Change `SECRET_KEY` and `DASHBOARD_PASSWORD` to secure values before deploying to production!

### 3. Build and Start the Application

```bash
docker compose up -d --build
```

This command will:
- Build the application image
- Start the Flask app container on port 8000
- Start the Redis container for rate limiting

### 4. Verify the Application is Running

```bash
docker compose ps
```

You should see both containers running:
```
NAME               STATUS
complaints-app     Up
complaints-redis   Up
```

### 5. Access the Application

- **Public Page**: http://localhost:8000
- **Admin Login**: http://localhost:8000/admin/login

---

## 🔧 Docker Commands Reference

### Start the Application

```bash
docker compose up -d
```

### Stop the Application

```bash
docker compose down
```

### View Logs

```bash
# View all logs
docker compose logs

# View app logs only
docker compose logs app

# Follow logs in real-time
docker compose logs -f app
```

### Rebuild After Code Changes

```bash
docker compose up -d --build
```

### Full Rebuild (No Cache)

```bash
docker compose build --no-cache
docker compose up -d
```

### Restart the Application

```bash
docker compose restart
```

---

## ⬆️ Updating the Application

To update the application to the latest version:

```bash
# Pull the latest code
git pull origin master

# Rebuild and restart containers
docker compose up -d --build
```

---

## 🗑 Uninstalling

To completely remove the application and its data:

```bash
# Stop and remove containers, networks
docker compose down

# Remove volumes (this deletes all data!)
docker compose down -v

# Remove the Docker image
docker rmi complaints-app
```

---

## 💾 Data Persistence

The application stores data in the following locations:

| Data | Location | Docker Volume |
|------|----------|---------------|
| SQLite Database | `./instance/db.sqlite3` | Mounted from host |
| Redis Data | `/data` | `redis_data` volume |

### Backup the Database

```bash
# Copy the database file
cp ./instance/db.sqlite3 ./backup/db-$(date +%Y%m%d).sqlite3
```

### Restore from Backup

```bash
# Stop the app
docker compose stop app

# Restore the database
cp ./backup/db-YYYYMMDD.sqlite3 ./instance/db.sqlite3

# Start the app
docker compose start app
```

---

## 🌐 Production Deployment with Nginx

For production, use Nginx as a reverse proxy in front of the Docker container.

### Sample Nginx Configuration

```nginx
server {
    listen 80;
    server_name your.domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### With HTTPS (SSL/TLS)

```nginx
server {
    listen 80;
    server_name your.domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your.domain.com;

    ssl_certificate /etc/letsencrypt/live/your.domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your.domain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 📖 Usage

1. **Public Access**

    - Open the landing page to submit a complaint.
    - After submission, save the tracking link to monitor complaint status.

2. **Admin Access**

    - Visit `/admin/login` to sign in.
    - Default Username: `admin` (configurable via `DASHBOARD_USERNAME`)
    - Default Password: `change-me-now` (configurable via `DASHBOARD_PASSWORD`)
    - Manage complaints and admin accounts from the dashboard.
    - Export complaints to Excel when needed.

---

## 🔒 Security Notes

- All forms are protected against CSRF attacks.
- Public submissions and logins are rate-limited to prevent abuse.
- Admin sessions are secured with HttpOnly cookies.
- Passwords are hashed with bcrypt before storage.
- Unique tracking tokens are generated securely.

---

## 🐛 Troubleshooting

### Container keeps restarting

Check the logs for errors:
```bash
docker compose logs app
```

### Database connection errors

Ensure the `DATABASE_URL` uses an absolute path:
```yaml
- DATABASE_URL=sqlite:////app/instance/db.sqlite3
```

### Permission issues

Make sure the `instance` directory exists and is writable:
```bash
mkdir -p instance
```

### Port already in use

Change the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "8080:8000"  # Use port 8080 instead
```
