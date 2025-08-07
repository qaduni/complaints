from flask import Blueprint, render_template, redirect, url_for, flash, request
from app.forms import ComplaintForm
from app.models import Complaint
from app import db, limiter
import uuid

public_bp = Blueprint("public", __name__)

@public_bp.route("/", methods=["GET", "POST"])
@limiter.limit("20 per minute")
def index():
    form = ComplaintForm()
    if form.validate_on_submit():
        token = str(uuid.uuid4().hex[:12])
        complaint = Complaint(
            title=form.title.data,
            content=form.content.data,
            token=token
        )
        db.session.add(complaint)
        db.session.commit()
        track_url = url_for("public.track_complaint", token=token, _external=True)
        flash(f"تم إرسال شكوتك بنجاح. قم بنسخ رابط التتبع و الاحتفاظ به لكي تتمكن من تتبع شكوتك. رابط التتبع : {track_url}", "sucess")
        return redirect(url_for("public.index"))
    return render_template("index.html", form=form)

@public_bp.route("/track/<token>")
@limiter.limit("20 per minute")
def track_complaint(token):
    complaint = Complaint.query.filter_by(token=token).first_or_404()
    return render_template("track.html", complaint=complaint)
