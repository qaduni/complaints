from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length

class ComplaintForm(FlaskForm):
    title = StringField("العنوان", validators=[DataRequired(), Length(max=255)])
    content = TextAreaField("المحتوى", validators=[DataRequired()])
    submit = SubmitField("إرسال")

class LoginForm(FlaskForm):
    username = StringField("اسم المستخدم", validators=[DataRequired()])
    password = PasswordField("كلمة المرور", validators=[DataRequired()])
    submit = SubmitField("تسجيل الدخول")

class AddUserForm(FlaskForm):
    username = StringField("اسم المستخدم", validators=[DataRequired()])
    password = PasswordField("كلمة المرور", validators=[DataRequired()])
    submit = SubmitField("إضافة")