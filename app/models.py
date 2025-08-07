from . import db
from datetime import datetime
from flask_login import UserMixin

class Complaint(db.Model):
    __tablename__ = 'complaint'
    
    id = db.Column(db.Integer, primary_key=True)
    token = db.Column(db.String(64), unique=True, nullable=False)
    title = db.Column(db.String(255), nullable=False)
    content = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(32), default="waiting")
    created_at = db.Column(db.DateTime, default=datetime.now)

class AdminUser(db.Model, UserMixin):
    __tablename__ = 'admin_user'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
