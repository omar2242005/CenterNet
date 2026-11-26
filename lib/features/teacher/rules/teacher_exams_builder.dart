import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../models/exam_summary.dart';

/// بيجمّع قايمة امتحانات المعلم (دالة نقية).
///
/// * بيتجاهل المجموعات المؤرشفة.
/// * [scoresByExam]: درجات كل امتحان (المفتاح = examId).
/// * الأحدث الأول.
List<ExamSummary> buildExamSummaries({
  required List<Group> groups,
  required List<Student> students,
  required List<Exam> exams,
  required Map<String, List<Score>> scoresByExam,
}) {
  final byId = {
    for (final g in groups)
      if (!g.isArchived) g.id: g,
  };
  final active = [
    for (final s in students)
      if (!s.isArchived) s,
  ];
  final out = <ExamSummary>[];
  for (final e in exams) {
    final group = byId[e.groupId];
    if (group == null) continue;
    out.add(
      ExamSummary(
        exam: e,
        group: group,
        studentCount: active.where((s) => s.isInGroup(group.id)).length,
        recordedCount: (scoresByExam[e.id] ?? const <Score>[]).length,
      ),
    );
  }
  out.sort((a, b) => b.exam.date.compareTo(a.exam.date));
  return out;
}

/// يقسّم القايمة حسب مادة المجموعة (بنفس ترتيب أول ظهور). المادة الفاضية
/// بتتجمّع تحت مفتاح فاضي.
Map<String, List<ExamSummary>> groupExamsBySubject(List<ExamSummary> items) {
  final out = <String, List<ExamSummary>>{};
  for (final i in items) {
    out.putIfAbsent(i.group.subject.trim(), () => []).add(i);
  }
  return out;
}

/// متوسط الدرجات المرصودة (scored فقط) أو null.
double? averageScore(Iterable<Score> scores) {
  final counted = [
    for (final s in scores)
      if (s.isCounted) s.score!,
  ];
  if (counted.isEmpty) return null;
  return counted.reduce((a, b) => a + b) / counted.length;
}

/// درجة بخانة عشرية واحدة بالكتير (18 أو 18.5 أو 17.3).
String fmtAverage(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
}
