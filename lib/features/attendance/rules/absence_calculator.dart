import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';

///
/// الغياب مش مخزّن، بيتحسب من: الحصة + الطلبة + سجلات الحضور.
/// الطالب "مغطّى" في الحصة لو عنده سجل غير ملغي حاضر أو متأخر أو بعذر.
/// الحضور الملغي (voided) مابيغطيش، فالطالب بيرجع غايب.
class AbsenceCalculator {
  const AbsenceCalculator._();

  /// الطلبة الغايبين عن حصة معينة.
  /// [records] أي سجلات حضور (بيتفلتر منها اللي يخص الحصة دي بس).
  /// مفيش غياب لو الحصة ملغاة أو لسه ماخلصتش.
  static List<String> absentStudentIds({
    required Session session,
    required DateTime now,
    required Iterable<Student> students,
    required Iterable<Attendance> records,
  }) {
    if (!session.isCountedAt(now)) return const [];
    final covered = <String>{
      for (final r in records)
        if (r.sessionId == session.id && _covers(r)) r.studentId,
    };
    return [
      for (final s in students)
        if (!s.isArchived &&
            s.isInGroup(session.groupId) &&
            !covered.contains(s.id))
          s.id,
    ];
  }

  /// عدد غيابات طالب واحد (لشاشة ولي الأمر والطالب).
  static int absenceCount({
    required Student student,
    required Iterable<Session> sessions,
    required DateTime now,
    required Iterable<Attendance> records,
  }) {
    if (student.isArchived) return 0;
    final covered = <String>{
      for (final r in records)
        if (r.studentId == student.id && _covers(r)) r.sessionId,
    };
    var count = 0;
    for (final session in sessions) {
      if (!student.isInGroup(session.groupId)) continue;
      if (!session.isCountedAt(now)) continue;
      if (covered.contains(session.id)) continue;
      count++;
    }
    return count;
  }

  /// السجل ده بيمنع الغياب؟ (القرار: الغياب بعذر مش بيتحسب غياب.)
  static bool _covers(Attendance r) =>
      r.countsAsAttended ||
      (!r.voided && r.status == AttendanceStatus.excused);
}