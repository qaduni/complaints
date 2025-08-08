# Complaints Management Web Application

A Flask-based web application for submitting and managing complaints.  
Designed for Arabic-speaking users with RTL layout support.  

This application is intended for universities and organizations to allow people to submit complaints anonymously, track their status, and for admins to manage them securely.

---

## ✨ Features

- **Anonymous complaint submission** — No email or phone required.
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

## 📋 Requirements

- Python **3.11+**
- [`uv` Package Manager](https://docs.astral.sh/uv/getting-started/installation/)

---

## 🚀 Installation

Run the following command to install the website and configure it automatically:

```bash
curl -sSL https://github.com/qaduni/complaints/blob/master/complaints-manager.sh | sudo bash -s -- install
```

## ▶️ Running the Website

Start the website with:

```bash
sudo bash complaints-manager.sh run
```

## ⏹ Stopping the Website

Stop the running instance with:

```bash
    sudo bash complaints-manager.sh stop
```

## 🗑 Uninstallation

Remove the website and all configurations:

```bash
sudo bash complaints-manager.sh uninstall
```

## 📖 Usage

1. Public Access

    - Open the landing page to submit a complaint.

    - After submission, save the tracking link to monitor complaint status.

2. Admin Access

    - Visit /admin/login to sign in.

    - Manage complaints and admin accounts from the dashboard.

    - Export complaints to Excel when needed.

## 🔒 Security Notes

- All forms are protected against CSRF attacks.

- Public submissions and logins are rate-limited to prevent abuse.

- Admin sessions are secured with HttpOnly cookies.

- Passwords are hashed with bcrypt before storage.

- Unique tracking tokens are generated securely.
