# app/services/dashboard_service.py
#
# Pure read-only analytics service.
# Does NOT import or modify any other service.
# Does NOT write to the database.

from sqlalchemy.orm import Session
from app.models.user       import User
from app.models.student    import Student
from app.models.advisor    import Advisor
from app.models.course     import Course
from app.models.enrollment import Enrollment


def get_dashboard_stats(db: Session) -> dict:
    """
    Returns a single dictionary containing all dashboard metrics.
    Every query here is SELECT-only — nothing is written or modified.
    """

    # ── 1. Overview counts ────────────────────────────────────────────────────

    total_students = db.query(Student).count()
    total_advisors = db.query(Advisor).count()

    total_admins = db.query(User).filter(
        User.role == "admin"
    ).count()

    total_courses = db.query(Course).count()

    pending_users = db.query(User).filter(
        User.is_active == False
    ).count()

    pending_enrollments = db.query(Enrollment).filter(
        Enrollment.approval_status == "pending"
    ).count()

    total_enrollments = db.query(Enrollment).count()

    approved_enrollments = db.query(Enrollment).filter(
        Enrollment.approval_status == "approved"
    ).count()

    passed_enrollments = db.query(Enrollment).filter(
        Enrollment.status == "passed"
    ).count()

    failed_enrollments = db.query(Enrollment).filter(
        Enrollment.status == "failed"
    ).count()

    registered_enrollments = db.query(Enrollment).filter(
        Enrollment.status == "registered"
    ).count()

    # ── 2. Students by year level ─────────────────────────────────────────────

    students_by_year = []
    for year in [1, 2, 3, 4]:
        count = db.query(Student).filter(
            Student.level == year
        ).count()
        students_by_year.append({"year": year, "count": count})

    # ── 3. Students by department ─────────────────────────────────────────────

    # Collect distinct non-null departments from the students table
    all_students = db.query(Student).all()
    dept_map: dict[str, int] = {}
    for s in all_students:
        dept = (s.department or "").strip()
        if dept:
            dept_map[dept] = dept_map.get(dept, 0) + 1

    students_by_department = [
        {"department": dept, "count": count}
        for dept, count in sorted(dept_map.items(), key=lambda x: -x[1])
    ]

    # ── 4. Per-course statistics ───────────────────────────────────────────────

    courses = db.query(Course).all()
    course_stats = []

    for course in courses:
        cid = course.course_id

        enrolled = db.query(Enrollment).filter(
            Enrollment.course_id       == cid,
            Enrollment.approval_status == "approved",
        ).count()

        passed = db.query(Enrollment).filter(
            Enrollment.course_id == cid,
            Enrollment.status    == "passed",
        ).count()

        failed = db.query(Enrollment).filter(
            Enrollment.course_id == cid,
            Enrollment.status    == "failed",
        ).count()

        registered = db.query(Enrollment).filter(
            Enrollment.course_id       == cid,
            Enrollment.status          == "registered",
            Enrollment.approval_status == "approved",
        ).count()

        # pass_rate  = passed / (passed + failed) × 100
        # Only calculated when at least one graded student exists
        graded_total = passed + failed
        pass_rate = round((passed / graded_total) * 100, 1) if graded_total > 0 else 0.0

        # occupancy_rate = approved_enrolled / capacity × 100
        capacity = course.capacity if course.capacity and course.capacity > 0 else 1
        occupancy_rate = round((enrolled / capacity) * 100, 1)

        course_stats.append({
            "course_id":       cid,
            "course_name":     course.course_name,
            "course_code":     course.course_code or "",
            "department":      course.department  or "",
            "level":           course.level,
            "capacity":        course.capacity,
            "enrolled_count":  enrolled,
            "passed_count":    passed,
            "failed_count":    failed,
            "registered_count": registered,
            "pass_rate":       pass_rate,
            "occupancy_rate":  occupancy_rate,
        })

    # Sort by enrolled_count descending so busiest courses appear first
    course_stats.sort(key=lambda x: -x["enrolled_count"])

    # ── 5. Assemble final result ───────────────────────────────────────────────

    return {
        "overview": {
            "total_students":        total_students,
            "total_advisors":        total_advisors,
            "total_admins":          total_admins,
            "total_courses":         total_courses,
            "pending_users":         pending_users,
            "pending_enrollments":   pending_enrollments,
            "total_enrollments":     total_enrollments,
            "approved_enrollments":  approved_enrollments,
            "passed_enrollments":    passed_enrollments,
            "failed_enrollments":    failed_enrollments,
            "registered_enrollments": registered_enrollments,
        },
        "students_by_year":       students_by_year,
        "students_by_department": students_by_department,
        "course_stats":           course_stats,
    }