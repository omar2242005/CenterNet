import '../groups/models/group.dart';
import 'models/exam.dart';

/// مسارات شاشات الدرجات.
abstract final class GradeRoutes {
  static const String exams = '/grades/exams'; // extra: Group
  static const String examCreate = '/grades/exams/new'; // extra: Group
  static const String scores = '/grades/scores'; // extra: ExamScoresArgs
}

/// بارامترات شاشة إدخال الدرجات.
class ExamScoresArgs {
  const ExamScoresArgs(this.group, this.exam);

  final Group group;
  final Exam exam;
}