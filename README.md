# Complaints Management Web Application

A simple Flask-based web application to submit and manage complaints.  
Supports Arabic language with RTL layout and includes:

- Public complaint submission without requiring email or phone.
- Complaint status tracking via unique token.
- Admin dashboard for managing complaints and admin users.
- Complaint status updates and filtering.
- User management for admin users.
- Export complaints to Excel.
- Secure login with session management and CSRF protection.
- Rate limiting to prevent abuse.

---

## Features

- Submit complaints anonymously.
- Track complaint status with a unique token link.
- Admin login with user management (add/delete admins).
- View, filter, and update complaint statuses.
- Export complaint data as an Excel file.
- Arabic interface with right-to-left support.
- CSRF protection and rate limiting on forms.

---

## Requirements

- Python 3.11+
- [`uv` Package Manager](https://docs.astral.sh/uv/getting-started/installation/)

---

## Installation

    Use the complaints-manager to install the website and configuration.
    ```bash
    curl -sSL https://raw.githubusercontent.com/qaduni/complaints/master/complaints-manager.sh | sudo bash -s -- install
    ```

## Running & Stopping The Website

    Also use the complaints-manager to run:
    ```bash
    sudo bash complaints-manager.sh run
    ```
    Or to stop the website:
    ```bash
    sudo bash complaints-manager.sh stop
    ```

## Uninstall

    To uninstall the website and all the configuration run this command:
    ```bash
    sudo bash complaints-manager.sh uninstall
    ```

## Usage

- Open the landing page to submit complaints.

- Use the link shown after submission to track complaint status.

- Access /admin/login to sign in to the admin dashboard.

- Manage complaints and admin users from the dashboard.

## Security Notes

- CSRF protection enabled on all forms.

- Rate limiting applied to public complaint submission and login.

- Admin routes protected by login sessions.
