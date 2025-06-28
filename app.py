import os

import pymysql
from flask import Flask, flash, jsonify, redirect, render_template, request, session
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)

# إعداد الاتصال بقاعدة البيانات MySQL باستخدام متغير البيئة
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get(
    "DATABASE_URL", "mysql+pymysql://root:@localhost/student_portal"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.secret_key = "your_secret_key"  # مفتاح الجلسة

pymysql.install_as_MySQLdb()

# تهيئة SQLAlchemy
db = SQLAlchemy(app)


# نموذج الطالب
class Student(db.Model):
    __tablename__ = "students"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)


# نموذج الدورة
class Course(db.Model):
    __tablename__ = "courses"
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)

    # إضافة وظيفة لتحويل البيانات إلى JSON
    def to_dict(self):
        return {"id": self.id, "title": self.title, "description": self.description}


# نموذج التسجيل
class Enrollment(db.Model):
    __tablename__ = "enrollments"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey("students.id"))
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"))
    timestamp = db.Column(db.DateTime, default=db.func.current_timestamp())


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        name = request.form["name"]
        email = request.form["email"]
        password = request.form["password"]

        # تشفير كلمة المرور قبل التخزين
        hashed_password = generate_password_hash(password)

        # إضافة الطالب إلى قاعدة البيانات
        new_student = Student(name=name, email=email, password_hash=hashed_password)
        db.session.add(new_student)
        db.session.commit()

        # عرض رسالة تأكيد
        flash("تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.", "success")

        return redirect("/login")

    return render_template("register.html")


@app.route("/delete_account", methods=["POST"])
def delete_account():
    if "user_id" not in session:
        flash("يجب تسجيل الدخول لحذف الحساب.", "danger")
        return redirect("/login")

    student = Student.query.get(session["user_id"])
    if student:
        db.session.delete(student)
        db.session.commit()
        session.clear()
        flash("تم حذف حسابك نهائيًا!", "success")
        return redirect("/register")

    flash("حدث خطأ أثناء الحذف.", "danger")
    return redirect("/dashboard")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]

        # البحث عن الطالب باستخدام البريد الإلكتروني
        student = Student.query.filter_by(email=email).first()
        if student and check_password_hash(student.password_hash, password):
            session["user_id"] = student.id
            session["user_name"] = student.name
            return redirect("/dashboard")
        else:
            return "Invalid email or password. Try again."

    return render_template("login.html")


@app.route("/dashboard")
def dashboard():
    if "user_id" not in session:
        return redirect("/login")

    student_id = session["user_id"]
    student_name = session["user_name"]

    query = text(
        "SELECT courses.title FROM enrollments JOIN courses ON enrollments.course_id = courses.id WHERE enrollments.student_id = :student_id"
    )
    enrolled_courses = db.session.execute(query, {"student_id": student_id}).fetchall()

    return render_template(
        "dashboard.html", user_name=student_name, courses=enrolled_courses
    )


@app.route("/ajax/enroll", methods=["POST"])
def ajax_enroll():
    if "user_id" not in session:
        return jsonify({"message": "You must be logged in to enroll."}), 401

    student_id = session["user_id"]
    data = request.get_json()
    course_id = data.get("course_id")
    if not course_id:
        return jsonify({"message": "Missing course_id in request."}), 400

    existing_enrollment = Enrollment.query.filter_by(
        student_id=student_id, course_id=course_id
    ).first()
    if existing_enrollment:
        return jsonify({"message": "You are already enrolled in this course."}), 409

    new_enrollment = Enrollment(student_id=student_id, course_id=course_id)
    db.session.add(new_enrollment)
    db.session.commit()

    return jsonify({"message": "Successfully enrolled!"})


@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")


@app.route("/profile", methods=["GET", "POST"])
def profile():
    if "user_id" not in session:
        return redirect("/login")

    student = Student.query.get(session["user_id"])

    if request.method == "POST":
        student.name = request.form["name"]
        student.email = request.form["email"]
        if request.form["password"]:  # تحديث كلمة المرور إذا أدخل المستخدم قيمة جديدة
            student.password_hash = generate_password_hash(request.form["password"])

        db.session.commit()
        return redirect("/dashboard")

    return render_template("profile.html", student=student)


@app.route("/courses")
def courses():
    all_courses = Course.query.all()
    return render_template("courses.html", courses=all_courses)


@app.route("/api/courses")
def api_courses():
    courses = Course.query.all()
    return jsonify([c.to_dict() for c in courses])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
