import '../../assistant/services/cairo_time.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/teacher_home_data.dart';

/// بداية العام الدراسي: من سبتمبر، فقبله لسه في عام السنة اللي فاتت.
int academicYearStartOf(DateTime now) {
  final wall = toCairoWallTime(now);
  return wall.month >= 9 ? wall.year : wall.year - 1;
}

/// دالة نقية بتجمّع رئيسية المعلم من اللي اتقرا (سهلة الاختبار).
///
/// * بتتجاهل المجموعات المؤرشفة والطلاب المؤرشفين.
/// * الحصة القادمة: أقرب حصة مش ملغاة ومخلصتش لسه، في مجموعة نشطة.
TeacherHomeData buildTeacherHomeData({
  required String name,
  required List<Group> groups,
  required List<Student> students,
  required List<Session> sessions,
  required DateTime now,
}) {
  final active = <Group>[
    for (final g in groups)
      if (!g.isArchived) g,
  ];
  final byId = {for (final g in active) g.id: g};
  final activeStudents = [
    for (final s in students)
      if (!s.isArchived) s,
  ];

  final studentsInMine = activeStudents
      .where((s) => active.any((g) => s.isInGroup(g.id)))
      .length;

  final subjects = <String>[];
  for (final g in active) {
    final subject = g.subject.trim();
    if (subject.isNotEmpty && !subjects.contains(subject)) {
      subjects.add(subject);
    }
  }

  Session? next;
  for (final s in sessions) {
    if (s.isCancelled || !byId.containsKey(s.groupId)) continue;
    if (!s.endAt.isAfter(now)) continue;
    if (next == null || s.startAt.isBefore(next.startAt)) next = s;
  }

  TeacherNextSession? nextSession;
  if (next != null) {
    final group = byId[next.groupId]!;
    nextSession = TeacherNextSession(
      session: next,
      group: group,
      studentCount: activeStudents.where((s) => s.isInGroup(group.id)).length,
    );
  }

  return TeacherHomeData(
    name: name,
    groupsCount: active.length,
    studentsCount: studentsInMine,
    subjects: subjects,
    academicYearStart: academicYearStartOf(now),
    now: now,
    nextSession: nextSession,
  );
}
