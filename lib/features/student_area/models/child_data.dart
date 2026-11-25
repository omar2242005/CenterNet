import '../../assistant/models/attendance.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../grades/rules/average_calculator.dart';
import '../../groups/models/group.dart';

/// ميعاد أسبوعي: مجموعة + الميعاد بتاعها.
class ScheduleEntry {
  const ScheduleEntry({required this.group, required this.slot});

  final Group group;
  final GroupSlot slot;
}

/// ترتيب الأسبوع المصري: السبت أول يوم. weekday: 1 = الاثنين ... 7 = الأحد.
int weekdayOrder(int weekday) => (weekday + 1) % 7;

/// مواعيد المجموعات النشطة مرتبة باليوم (من السبت) ثم الوقت.
List<ScheduleEntry> buildSchedule(Iterable<Group> groups) {
  final out = <ScheduleEntry>[
    for (final g in groups)
      if (!g.isArchived)
        for (final s in g.slots) ScheduleEntry(group: g, slot: s),
  ];
  out.sort((a, b) {
    final byDay =
        weekdayOrder(a.slot.weekday).compareTo(weekdayOrder(b.slot.weekday));
    if (byDay != 0) return byDay;
    return a.slot.startMinutes.compareTo(b.slot.startMinutes);
  });
  return out;
}

/// سطر في سجل الحضور.
class AttendanceRow {
  const AttendanceRow({
    required this.attendance,
    required this.groupName,
    required this.when,
  });

  final Attendance attendance;
  final String groupName;

  /// وقت الحصة بتوقيت القاهرة (متقري من الـ sessionId)، أو null لو الصيغة غريبة.
  final DateTime? when;
}

class AttendanceHistory {
  const AttendanceHistory(this.rows);

  final List<AttendanceRow> rows;

  int get total => rows.length;
  int get attended => rows.where((r) => r.attendance.countsAsAttended).length;
}

/// وقت الحصة من الـ sessionId (`gid_yyyyMMdd_HHmm`) من غير أي تحويل توقيت.
DateTime? parseSessionWhen(String sessionId) {
  final parts = sessionId.split('_');
  if (parts.length != 3) return null;
  final d = parts[1];
  final t = parts[2];
  if (d.length != 8 || t.length != 4) return null;
  final y = int.tryParse(d.substring(0, 4));
  final mo = int.tryParse(d.substring(4, 6));
  final da = int.tryParse(d.substring(6, 8));
  final h = int.tryParse(t.substring(0, 2));
  final mi = int.tryParse(t.substring(2, 4));
  if (y == null || mo == null || da == null || h == null || mi == null) {
    return null;
  }
  return DateTime(y, mo, da, h, mi);
}

/// سجل الحضور من غير الملغي، الأحدث أولًا (حد أقصى [limit]).
AttendanceHistory buildAttendanceHistory(
  Iterable<Attendance> records,
  Map<String, String> groupNames, {
  int limit = 100,
}) {
  final rows = <AttendanceRow>[
    for (final a in records)
      if (!a.voided)
        AttendanceRow(
          attendance: a,
          groupName: groupNames[a.sessionId.split('_').first] ?? '',
          when: parseSessionWhen(a.sessionId),
        ),
  ];
  rows.sort((a, b) {
    final x = a.when;
    final y = b.when;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  });
  return AttendanceHistory(rows.take(limit).toList());
}

/// امتحان منشور + درجة الطالب فيه (null = لسه متسجلتش).
class ExamResult {
  const ExamResult({required this.exam, this.score});

  final Exam exam;
  final Score? score;
}

class ResultsData {
  const ResultsData({required this.items, required this.average});

  final List<ExamResult> items;

  /// النسبة المئوية العامة، أو null لو مفيش درجات محسوبة.
  final double? average;
}

/// النتائج: الامتحانات المنشورة بس، الأحدث أولًا، والمتوسط من [AverageCalculator].
ResultsData buildResults(Iterable<Exam> exams, Iterable<Score> scores) {
  final published = exams.where((e) => e.published).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final byExam = {for (final s in scores) s.examId: s};
  return ResultsData(
    items: [
      for (final e in published) ExamResult(exam: e, score: byExam[e.id]),
    ],
    average: AverageCalculator.percentage(
      scores: scores,
      exams: published,
      onlyPublished: true,
    ),
  );
}
