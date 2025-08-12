from flask import Blueprint, render_template, redirect, url_for, flash, request, send_file
from flask_login import login_user, logout_user, login_required, current_user
from flask_bcrypt import generate_password_hash
from app.forms import LoginForm, AddUserForm
from app.models import AdminUser, Complaint
from app import db, bcrypt, login_manager, limiter
from sqlalchemy import func
from openpyxl import Workbook
from io import BytesIO

admin_bp = Blueprint("admin", __name__)

@login_manager.user_loader
def load_user(user_id):
    return AdminUser.query.get(int(user_id))

@admin_bp.route("/login", methods=["GET", "POST"])
@limiter.limit("5 per hour")
def login():
    if current_user.is_authenticated:
        return redirect(url_for("admin.dashboard"))
    form = LoginForm()
    if form.validate_on_submit():
        user = AdminUser.query.filter_by(username=form.username.data).first()
        if user and bcrypt.check_password_hash(user.password_hash, form.password.data):
            login_user(user)
            return redirect(url_for("admin.dashboard"))
        flash("اسم المستخدم أو كلمة المرور غير صحيحة", "danger")
    return render_template("admin/login.html", form=form)

@admin_bp.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("admin.login"))

@admin_bp.route("/dashboard", methods=["GET", "POST"])
@login_required
def dashboard():
    # Handle new admin user creation
    form = AddUserForm()
    if form.validate_on_submit():
        if AdminUser.query.filter_by(username=form.username.data).first():
            flash('اسم المستخدم موجود بالفعل', 'danger')
        else:
            new_user = AdminUser(username=form.username.data, password_hash=generate_password_hash(form.password.data))
            db.session.add(new_user)
            db.session.commit()
            flash('تمت إضافة المستخدم بنجاح', 'success')
        return redirect(url_for('admin.dashboard'))

    # Complaint statistics
    counts = dict(db.session.query(Complaint.status, func.count(Complaint.id))
              .group_by(Complaint.status)
              .all())

    total = sum(counts.values())
    waiting = counts.get("waiting", 0)
    in_process = counts.get("in process", 0)
    complete = counts.get("complete", 0)

    # Complaint filtering & pagination
    page = request.args.get("page", 1, type=int)
    status = request.args.get("status")
    q = request.args.get("q", "").strip()
    cquery = Complaint.query
    if status:
        cquery = cquery.filter_by(status=status)
    if q:
        cquery = cquery.filter(
            Complaint.title.ilike(f"%{q}%") | Complaint.content.ilike(f"%{q}%")
        )
    complaints = cquery.order_by(Complaint.created_at.desc()).paginate(page=page, per_page=10)

    # Admin users list
    users = AdminUser.query.all()

    return render_template(
        "admin/dashboard.html",
        total=total,
        waiting=waiting,
        in_process=in_process,
        complete=complete,
        complaints=complaints,
        users=users,
        form=form
    )

@admin_bp.route("/complaints/update/<int:id>", methods=["POST"])
@login_required
def update_complaint(id):
    status = request.form.get("status")
    complaint = Complaint.query.get_or_404(id)
    complaint.status = status
    db.session.commit()
    flash("تم تحديث حالة الشكوى", "success")
    return redirect(url_for('admin.dashboard', page=request.args.get('page',1)))

@admin_bp.route('/users/delete/<int:user_id>', methods=['POST'])
@login_required
def delete_user(user_id):
    if user_id == current_user.id:
        flash('لا يمكن حذف المستخدم الحالي', 'danger')
    else:
        user = AdminUser.query.get_or_404(user_id)
        db.session.delete(user)
        db.session.commit()
        flash('تم حذف المستخدم', 'success')
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/export')
@login_required
def export_complaints():
    complaints = Complaint.query.all()

    wb = Workbook()
    ws = wb.active
    ws.title = "الشكاوى"

    # Header row
    ws.append(["ID", "العنوان", "المحتوى", "الحالة", "تاريخ الإرسال"])

    # Data rows
    for c in complaints:
        ws.append([
            c.id,
            c.title,
            c.content,
            c.status,
            c.created_at.strftime("%Y-%m-%d %H:%M")
        ])

    # Save to in-memory bytes buffer
    output = BytesIO()
    wb.save(output)
    output.seek(0)

    return send_file(
        output,
        download_name="complaints.xlsx",
        as_attachment=True,
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )