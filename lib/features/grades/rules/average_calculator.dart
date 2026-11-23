import '../models/exam.dart';
import '../models/score.dart';

/// حساب متوسط درجات الطالب. كلاس نقي: مفيش Flutter ولا Firebase.
///
/// * بيدخل في المتوسط الدرجات المرصودة بس ([Score.isCounted])؛ الغائب
///   والمعفى برّه، والصفر درجة حقيقية بتدخل.
/// * المتوسط نسبة مئوية: مجموع الدرجات ÷ مجموع الدرجات النهائية × 100،
///   عشان امتحان من 10 وامتحان من 100 يتحسبوا صح.
/// * لو مفيش ولا درجة محتسبة بيرجّع null (الشاشة تعرض "لسه").
class AverageCalculator {
  const AverageCalculator._();

  /// متوسط طالب واحد كنسبة مئوية (0..100)، أو null.
  /// [exams] الامتحانات المعروفة (للدرجة النهائية). أي درجة امتحانها مش
  /// في [exams] بتتجاهل. [onlyPublished] = true للطالب وولي الأمر
  /// (الامتحانات المنشورة بس).
  static double? percentage({
    required Iterable<Score> scores,
    required Iterable<Exam> exams,
    bool onlyPublished = false,
  }) {
    final examById = {for (final e in exams) e.id: e};
    var earned = 0.0;
    var possible = 0.0;
    for (final s in scores) {
      if (!s.isCounted) continue;
      final exam = examById[s.examId];
      if (exam == null) continue;
      if (onlyPublished && !exam.published) continue;
      earned += s.score!;
      possible += exam.maxScore;
    }
    if (possible == 0) return null;
    return earned / possible * 100;
  }
}