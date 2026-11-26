import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';

/// الحصة القادمة (أو الجارية) في رئيسية المعلم.
class TeacherNextSession {
  const TeacherNextSession({
    required this.session,
    required this.group,
    required this.studentCount,
  });

  final Session session;
  final Group group;

  /// طلاب المجموعة النشطين.
  final int studentCount;
}

/// بيانات رئيسية المعلم.
class TeacherHomeData {
  const TeacherHomeData({
    required this.name,
    required this.groupsCount,
    required this.studentsCount,
    required this.subjects,
    required this.academicYearStart,
    required this.now,
    this.nextSession,
  });

  final String name;

  /// عدد المجموعات النشطة.
  final int groupsCount;

  /// طلاب نشطين في مجموعات المعلم النشطة (من غير تكرار).
  final int studentsCount;

  /// مواد مجموعاته من غير تكرار.
  final List<String> subjects;

  /// سنة بداية العام الدراسي (سبتمبر لسبتمبر).
  final int academicYearStart;

  /// وقت الحساب (لتحديد اليوم والحالة).
  final DateTime now;

  final TeacherNextSession? nextSession;
}
