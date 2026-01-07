from flask import Flask
from flask_bcrypt import Bcrypt
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect
from sqlalchemy import inspect
from os import environ
from dotenv import load_dotenv

load_dotenv()

db = SQLAlchemy()
csrf = CSRFProtect()
bcrypt = Bcrypt()
login_manager = LoginManager()
limiter = Limiter(key_func=get_remote_address, storage_uri=environ.get("REDIS_URL"))


def create_app():
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = environ.get("DATABASE_URL")
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = environ.get("SECRET_KEY")

    db.init_app(app)
    csrf.init_app(app)
    bcrypt.init_app(app)
    login_manager.init_app(app)
    limiter.init_app(app)

    # Auto-create tables if missing
    from . import models  # required to register tables
    from .models import AdminUser

    with app.app_context():
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        required_tables = ["complaint", "admin_user"]
        missing = [t for t in required_tables if t not in tables]
        if missing:
            print(f"Creating missing tables: {missing}")
            db.create_all()

        if not AdminUser.query.first():
            default_username = environ.get("DASHBOARD_USERNAME")
            default_password = environ.get("DASHBOARD_PASSWORD")
            hashed = bcrypt.generate_password_hash(default_password).decode("utf-8")
            admin = AdminUser(username=default_username, password_hash=hashed)
            db.session.add(admin)
            db.session.commit()
            print(f"✅ Default admin created: {default_username} / {default_password}")

    from .views.admin import admin_bp
    from .views.errors import errors_bp
    from .views.public import public_bp
    from .views.test import test_bp

    app.register_blueprint(public_bp)
    app.register_blueprint(admin_bp, url_prefix="/admin")
    app.register_blueprint(errors_bp)
    app.register_blueprint(test_bp)

    return app
