from flask_wtf import FlaskForm
from wtforms import EmailField, PasswordField, StringField, SubmitField, TextAreaField
from wtforms.validators import DataRequired, Length, Regexp, ValidationError


def validate_phone_length(form, field):
    phone = field.data.strip()
    if phone.startswith("+"):
        if not (phone.startswith("+964") and len(phone) == 13):
            raise ValidationError(
                "رقم الهاتف مع مفتاح الدولة يجب أن يكون 13 رقمًا ويبدأ بـ +964"
            )
    else:
        if len(phone) != 11:
            raise ValidationError("رقم الهاتف يجب أن يكون 11 رقمًا بدون مفتاح الدولة")


class ComplaintForm(FlaskForm):
    name = StringField(
        "الاسم الكامل",
        validators=[
            DataRequired(message="الاسم الكامل مطلوب."),
            Length(max=100, message="الاسم يجب ألا يتجاوز 100 حرف."),
        ],
    )
    phone = StringField(
        "رقم الموبايل",
        validators=[
            DataRequired(message="رقم الموبايل مطلوب."),
            Regexp(r"^\+?\d+$", message="يجب أن يحتوي رقم الهاتف على أرقام فقط"),
            validate_phone_length,
        ],
    )
    email = EmailField("الايميل (اختياري)", validators=[])
    title = StringField(
        "العنوان", validators=[DataRequired(message="العنوان مطلوب."), Length(max=255)]
    )
    content = TextAreaField(
        "المحتوى", validators=[DataRequired(message="المحتوى مطلوب.")]
    )
    submit = SubmitField("إرسال")


class LoginForm(FlaskForm):
    username = StringField("اسم المستخدم", validators=[DataRequired()])
    password = PasswordField("كلمة المرور", validators=[DataRequired()])
    submit = SubmitField("تسجيل الدخول")


class AddUserForm(FlaskForm):
    username = StringField("اسم المستخدم", validators=[DataRequired()])
    password = PasswordField("كلمة المرور", validators=[DataRequired()])
    submit = SubmitField("إضافة")
