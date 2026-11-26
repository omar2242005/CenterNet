import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/grades/models/exam.dart';
import 'package:center_net/features/grades/models/score.dart';
import 'package:center_net/features/grades/repositories/exams_repository.dart';
import 'package:center_net/features/grades/repositories/scores_repository.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/teacher/models/exam_summary.dart';
import 'package:center_net/features/teacher/repository/teacher_exams_repository.dart';

Exam fakeExam(
  String id,
  String groupId,
  DateTime date, {
  double max = 20,
  bool published = false,
  String title = 'اختبار',
}) => Exam.fromMap(id, <String, dynamic>{
  'centerId': 'c1',
  'groupId': groupId,
  'title': title,
  'date': date,
  'maxScore': max,
  'published': published,
  'createdBy': 'u1',
});

Score fakeScore(
  String examId,
  String studentId,
  double? value, {
  String state = 'scored',
}) => Score.fromMap('${examId}_$studentId', <String, dynamic>{
  'centerId': 'c1',
  'examId': examId,
  'studentId': studentId,
  'state': state,
  'score': value,
  'comment': '',
  'createdBy': 'u1',
});

class FakeTeacherExamsRepository implements TeacherExamsRepository {
  FakeTeacherExamsRepository({this.items = const [], this.failure});

  List<ExamSummary> items;
  Failure? failure;
  int loads = 0;

  @override
  Future<List<ExamSummary>> loadAll() async {
    loads++;
    final f = failure;
    if (f != null) throw f;
    return items;
  }
}

class FakeScoresRepository implements ScoresRepository {
  FakeScoresRepository({List<Score>? scores}) : scores = scores ?? [];

  final List<Score> scores;

  /// studentId ← خطأ بيرميه الحفظ.
  final Map<String, Failure> saveFailureFor = {};
  final List<String> saved = [];

  @override
  Future<List<Score>> loadExamScores(Exam exam) async => [
    for (final s in scores)
      if (s.examId == exam.id) s,
  ];

  @override
  Future<Score> saveScore({
    required Exam exam,
    required String studentId,
    required ScoreState state,
    double? score,
    String comment = '',
  }) async {
    final f = saveFailureFor[studentId];
    if (f != null) throw f;
    saved.add('$studentId:$score');
    final entry = fakeScore(exam.id, studentId, score);
    scores.removeWhere((s) => s.examId == exam.id && s.studentId == studentId);
    scores.add(entry);
    return entry;
  }
}

class FakeExamsRepository implements ExamsRepository {
  final List<String> created = [];
  final List<DateTime> createdDates = [];
  Failure? createFailure;

  @override
  Future<Exam> createExam(
    Group group, {
    required String title,
    required DateTime date,
    required double maxScore,
  }) async {
    final f = createFailure;
    if (f != null) throw f;
    created.add('${group.id}:$title:$maxScore');
    createdDates.add(date);
    return fakeExam('new1', group.id, date, max: maxScore, title: title);
  }

  @override
  Future<Exam> setPublished(Exam exam, {required bool published}) async {
    return fakeExam(
      exam.id,
      exam.groupId,
      exam.date,
      max: exam.maxScore,
      published: published,
      title: exam.title,
    );
  }

  @override
  Future<List<Exam>> loadGroupExams(Group group) async => const [];
}
