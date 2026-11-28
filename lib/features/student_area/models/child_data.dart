import '../../attendance/models/attendance.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../grades/rules/average_calculator.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';

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

/// حصة فاتت من غير حضور مسجل (يعني غياب). مفيش سجل غياب في الداتا، فبنحسبه.
class AbsenceRow {
  const AbsenceRow({required this.groupName, required this.when});

  final String groupName;
  final DateTime when;
}

class AttendanceHistory {
  const AttendanceHistory(this.rows, [this.absences = const <AbsenceRow>[]]);

  final List<AttendanceRow> rows;
  final List<AbsenceRow> absences;

  int get total => rows.length + absences.length;
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

/// حصة بتاريخها: الحصة + مجموعتها + وقتها بتوقيت القاهرة (متقري من الـ id).
class SessionEntry {
  const SessionEntry({
    required this.session,
    required this.group,
    required this.when,
    required this.end,
  });

  final Session session;
  final Group group;
  final DateTime when;
  final DateTime end;
}

/// الحصص غير الملغية لمجموعات الطالب، مرتبة بالوقت.
List<SessionEntry> buildSessionEntries(
  Iterable<Session> sessions,
  Map<String, Group> groups,
) {
  final out = <SessionEntry>[];
  for (final s in sessions) {
    final g = groups[s.groupId];
    if (g == null || s.isCancelled) continue;
    final when = parseSessionWhen(s.id) ?? s.startAt;
    out.add(
      SessionEntry(
        session: s,
        group: g,
        when: when,
        end: when.add(s.endAt.difference(s.startAt)),
      ),
    );
  }
  out.sort((a, b) => a.when.compareTo(b.when));
  return out;
}

/// فلتر الجدول.
enum WeekFilter { thisWeek, nextWeek, all }

/// أول يوم في أسبوع [d] (السبت) الساعة 00:00.
DateTime weekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - weekdayOrder(d.weekday));

/// الحصص حسب الفلتر. "الكل" = من أول الأسبوع الحالي وطالع.
List<SessionEntry> filterByWeek(
  List<SessionEntry> all,
  WeekFilter filter,
  DateTime now,
) {
  final start = weekStart(now);
  final from = filter == WeekFilter.nextWeek
      ? DateTime(start.year, start.month, start.day + 7)
      : start;
  final to = switch (filter) {
    WeekFilter.thisWeek => DateTime(start.year, start.month, start.day + 7),
    WeekFilter.nextWeek => DateTime(start.year, start.month, start.day + 14),
    WeekFilter.all => null,
  };
  return [
    for (final e in all)
      if (!e.when.isBefore(from) && (to == null || e.when.isBefore(to))) e,
  ];
}

/// أقرب حصة لسه مخلصتش، أو null.
SessionEntry? nextSession(List<SessionEntry> all, DateTime now) {
  for (final e in all) {
    if (e.end.isAfter(now)) return e;
  }
  return null;
}

/// سجل الحضور من غير الملغي، الأحدث أولًا (حد أقصى [limit]).
///
/// [sessions] بتتحسب منها الغيابات: حصة خلصت قبل [now] ومفيش ليها حضور.
/// [since] بيمنع حساب حصص قبل تسجيل الطالب.
AttendanceHistory buildAttendanceHistory(
  Iterable<Attendance> records,
  Map<String, String> groupNames, {
  int limit = 100,
  Iterable<SessionEntry> sessions = const <SessionEntry>[],
  DateTime? now,
  DateTime? since,
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

  final recorded = {for (final r in rows) r.attendance.sessionId};
  final absences = <AbsenceRow>[
    if (now != null)
      for (final e in sessions)
        if (e.end.isBefore(now) &&
            !recorded.contains(e.session.id) &&
            (since == null || !e.when.isBefore(since)))
          AbsenceRow(groupName: e.group.name, when: e.when),
  ]..sort((a, b) => b.when.compareTo(a.when));

  return AttendanceHistory(
    rows.take(limit).toList(),
    absences.take(limit).toList(),
  );
}

/// امتحان منشور + درجة الطالب فيه (null = لسه متسجلتش).
class ExamResult {
  const ExamResult({
    required this.exam,
    this.score,
    this.groupName = '',
    this.subject = '',
  });

  final Exam exam;
  final Score? score;

  /// اسم المجموعة ومادتها (فاضيين لو المجموعة مش متاحة).
  final String groupName;
  final String subject;
}

class ResultsData {
  const ResultsData({required this.items, required this.average});

  final List<ExamResult> items;

  /// النسبة المئوية العامة، أو null لو مفيش درجات محسوبة.
  final double? average;

  /// المواد الموجودة في النتايج (لفلتر المادة).
  List<String> get subjects {
    final set = <String>{
      for (final i in items)
        if (i.subject.isNotEmpty) i.subject,
    };
    return set.toList()..sort();
  }
}

/// النتائج: الامتحانات المنشورة بس، الأحدث أولًا، والمتوسط من [AverageCalculator].
ResultsData buildResults(
  Iterable<Exam> exams,
  Iterable<Score> scores, {
  Map<String, Group> groups = const <String, Group>{},
}) {
  final published = exams.where((e) => e.published).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final byExam = {for (final s in scores) s.examId: s};
  return ResultsData(
    items: [
      for (final e in published)
        ExamResult(
          exam: e,
          score: byExam[e.id],
          groupName: groups[e.groupId]?.name ?? '',
          subject: groups[e.groupId]?.subject ?? '',
        ),
    ],
    average: AverageCalculator.percentage(
      scores: scores,
      exams: published,
      onlyPublished: true,
    ),
  );
}

/// كل اللي الرئيسية والتحديثات محتاجينه عن طالب واحد.
class ChildSummary {
  const ChildSummary({
    required this.attendance,
    required this.results,
    required this.sessions,
  });

  final AttendanceHistory attendance;
  final ResultsData results;

  /// حصص من 45 يوم فاتوا وطالع (غير الملغية).
  final List<SessionEntry> sessions;

  /// أحدث نتيجة ليها درجة (النتايج مرتبة من الأحدث).
  ExamResult? get latestResult {
    for (final r in results.items) {
      if (r.score != null) return r;
    }
    return null;
  }
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// حضور الشهر الحالي: حضر من إجمالي الحصص (بالغياب).
({int attended, int total}) monthAttendance(AttendanceHistory h, DateTime now) {
  final rows = h.rows.where((r) => r.when != null && _sameMonth(r.when!, now));
  final absent = h.absences.where((a) => _sameMonth(a.when, now)).length;
  return (
    attended: rows.where((r) => r.attendance.countsAsAttended).length,
    total: rows.length + absent,
  );
}

/// نسبة درجات امتحانات الشهر الحالي (من المرصودة فقط)، أو null.
double? monthAverage(ResultsData r, DateTime now) {
  var got = 0.0;
  var max = 0.0;
  for (final i in r.items) {
    final s = i.score;
    if (s == null || !s.isCounted || !_sameMonth(i.exam.date, now)) continue;
    got += s.score!;
    max += i.exam.maxScore;
  }
  return max == 0 ? null : got / max * 100;
}

/// أنواع سطور شاشة التحديثات.
enum UpdateKind { grade, session, attendance, absence }

/// سطر في شاشة التحديثات. بيتحسب من البيانات الموجودة وقت فتح الشاشة.
class UpdateItem {
  const UpdateItem({
    required this.kind,
    required this.title,
    required this.when,
    this.result,
  });

  final UpdateKind kind;
  final String title;
  final DateTime? when;

  /// للدرجات بس: النتيجة (الدرجة والامتحان).
  final ExamResult? result;
}

/// أحدث التحديثات: آخر 3 درجات، أقرب 4 حصص (النهارده والجاية)، آخر 3 حضور و3 غيابات.
/// وقت نشر الدرجة مش متسجل، فتاريخ الدرجة هو تاريخ الامتحان.
List<UpdateItem> buildUpdates(ChildSummary s, DateTime now) {
  return [
    for (final r in s.results.items.where((r) => r.score != null).take(3))
      UpdateItem(
        kind: UpdateKind.grade,
        title: r.exam.title,
        when: r.exam.date,
        result: r,
      ),
    for (final e in s.sessions.where((e) => e.end.isAfter(now)).take(4))
      UpdateItem(kind: UpdateKind.session, title: e.group.name, when: e.when),
    for (final r in s.attendance.rows.take(3))
      UpdateItem(kind: UpdateKind.attendance, title: r.groupName, when: r.when),
    for (final a in s.attendance.absences.take(3))
      UpdateItem(kind: UpdateKind.absence, title: a.groupName, when: a.when),
  ];
}
