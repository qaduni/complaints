# Complaints Management Web Application

A Flask-based web application for submitting and managing complaints.  
Designed for Arabic-speaking users with RTL layout support.  

This application is intended for universities and organizations to allow people to submit complaints anonymously, track their status, and for admins to manage them securely.

![Python 3.14](https://img.shields.io/badge/python-3.14-blue?logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)

---

## ✨ Features

- **Complaint tracking** — Each submission gets a unique tracking token.
- **Admin dashboard** — Manage complaints and admin accounts.
- **Status management** — Update and filter complaint statuses.
- **Data export** — Export complaints as `.xlsx` Excel files.
- **Arabic interface** — Full right-to-left layout support.
- **Built-in Nginx** — Reverse proxy with SSL support included.
- **Security**:
  - CSRF protection on all forms.
  - Rate limiting on public submissions and login.
  - Secure session management for admin routes.

---

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/qaduni/complaints.git
cd complaints
```

### 2. Configure Environment Variables

Copy the example environment file and edit it:

```bash
cp .env.example .env
```

Open `.env` and update these values:

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY` | Random key for security | Generate with `python -c "import secrets; print(secrets.token_hex(32))"` |
| `DASHBOARD_USERNAME` | Admin login username | `admin` |
| `DASHBOARD_PASSWORD` | Admin login password | `your-secure-password` |
| `DOMAIN` | Your domain name | `localhost` for local, `example.com` for production |
| `CERTBOT_EMAIL` | Email for SSL certificates | Only needed for production |

> ⚠️ **Important**: Always change `SECRET_KEY` and `DASHBOARD_PASSWORD` before deploying!

### 3. Build and Start

```bash
docker compose up -d --build
```

### 4. Access the Application

| Page | URL |
|------|-----|
| **Public Page** | http://localhost |
| **Admin Login** | http://localhost/admin/login |

---

## 🔧 Docker Commands

| Action | Command |
|--------|---------|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| View logs | `docker compose logs -f` |
| Rebuild | `docker compose up -d --build` |
| Full rebuild | `docker compose build --no-cache && docker compose up -d` |

---

## 🌐 Production Deployment (HTTPS)

### 1. Configure Your Domain

Update your `.env` file:

```bash
DOMAIN=complaints.yourdomain.com
CERTBOT_EMAIL=admin@yourdomain.com
```

### 2. Point DNS to Your Server

Create an A record:
- **Type**: A
- **Name**: complaints (or your subdomain)
- **Value**: Your server's IP address

### 3. Start the Application

```bash
docker compose up -d --build
```

### 4. Enable SSL

```bash
chmod +x init-letsencrypt.sh
./init-letsencrypt.sh
```

Your site is now accessible at `https://your-domain.com`

> 📝 Certificates auto-renew every 12 hours via the Certbot container.

---

## 💾 Data Persistence

| Data | Location |
|------|----------|
| SQLite Database | `./instance/db.sqlite3` |
| Redis Data | Docker volume `redis_data` |
| SSL Certificates | `./certbot/conf/` |

### Backup Database

```bash
cp ./instance/db.sqlite3 ./backup/db-$(date +%Y%m%d).sqlite3
```

---

## 📖 Usage

### Public Users
- Submit complaints on the landing page
- Save the tracking link to monitor status

### Admin Users
- Login at `/admin/login`
- Manage complaints and admin accounts
- Export complaints to Excel

---

## 🔒 Security

- CSRF protection on all forms
- Rate limiting (10 login attempts per minute)
- HttpOnly session cookies
- Bcrypt password hashing
- Secure tracking tokens

---

## 🐛 Troubleshooting

### Container keeps restarting
```bash
docker compose logs app
```

### Missing environment variables
Make sure `.env` file exists and contains all required variables from `.env.example`.

### Port 80 already in use
Stop other web servers or change the port in `docker-compose.yml`:
```yaml
ports:
  - "8080:80"
```

---

## ⬆️ Updating

```bash
git pull origin master
docker compose up -d --build
```

---

## 🗑 Uninstalling

```bash
# Stop and remove containers
docker compose down

# Remove all data (database, Redis, certificates)
docker compose down -v
rm -rf instance/ certbot/
```
