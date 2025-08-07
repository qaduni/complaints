from app import limiter
from flask import Blueprint

test_bp = Blueprint("test", __name__)

@test_bp.route("/spam")
@limiter.limit("3 per minute")  # 3 requests per minute
def spam():
    return "مسموح لك بثلاث محاولات في الدقيقة"