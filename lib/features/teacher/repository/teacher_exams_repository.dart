import '../../../core/errors/error_mapper.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../grades/repositories/scores_repository.dart';
import '../../groups/repository/groups_repository.dart';
import '../../students/repository/students_repository.dart';
import '../models/exam_summary.dart';
import '../rules/teacher_exams_builder.dart';

/// مصدر قايمة امتحانات المعلم (للاختبار بنبدله بـ fake).
abstract class TeacherExamsRepository {
  Future<List<ExamSummary>> loadAll();
}

/// قراءة بس: امتحانات كل مجموعات المعلم النشطة.
///
/// الـ Rules بتقبل قراءة الامتحانات والدرجات بس لو الاستعلام مقيّد (groupId /
/// examId)، فبنعمل استعلام لكل مجموعة ثم لكل امتحان (مش استعلام واحد للسنتر).
class FirestoreTeacherExamsRepository implements TeacherExamsRepository {
  FirestoreTeacherExamsRepository(
    this._groups,
    this._students,
    this._exams,
    this._scores,
  );

  final GroupsRepository _groups;
  final StudentsRepository _students;
  final ExamsRepository _exams;
  final ScoresRepository _scores;

  @override
  Future<List<ExamSummary>> loadAll() {
    return ErrorMapper.guard(() async {
      final roster = await _groups.loadMyGroups();
      final active = roster.groups.where((g) => !g.isArchived).toList();
      if (active.isEmpty) return const <ExamSummary>[];

      final students = await _students.loadStudents();
      final perGroup = await Future.wait([
        for (final g in active) _exams.loadGroupExams(g),
      ]);
      final exams = <Exam>[for (final list in perGroup) ...list];
      final perExam = await Future.wait([
        for (final e in exams) _scores.loadExamScores(e),
      ]);
      final scoresByExam = <String, List<Score>>{
        for (var i = 0; i < exams.length; i++) exams[i].id: perExam[i],
      };

      return buildExamSummaries(
        groups: active,
        students: students.students,
        exams: exams,
        scoresByExam: scoresByExam,
      );
    });
  }
}
