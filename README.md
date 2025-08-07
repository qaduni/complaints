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
- `uv` package manager (or `pip` if preferred)
- SQLite (default database)

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/ORG_NAME/REPO_NAME.git
   cd REPO_NAME

2. Install dependencies (using uv):

    ```bash
    uv install -r requirements.txt

3. Run the application:

    ```bash
    uv run run.py


## Usage

- Open the landing page to submit complaints.

- Use the link shown after submission to track complaint status.

- Access /admin/login to sign in to the admin dashboard.

- Manage complaints and admin users from the dashboard.

## Security Notes

- CSRF protection enabled on all forms.

- Rate limiting applied to public complaint submission and login.

- Admin routes protected by login sessions.
s