import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../grades/repositories/scores_repository.dart';
import '../../grades/rules/score_validator.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';

class ExamScoresState {
  const ExamScoresState({
    required this.exam,
    this.students = const <Student>[],
    this.scores = const <String, Score>{},
    this.loading = true,
    this.failure,
    this.saving = false,
    this.publishing = false,
  });

  final Exam exam;

  /// طلاب المجموعة النشطين بالرقم التسلسلي.
  final List<Student> students;

  /// الدرجات المرصودة (المفتاح = studentId).
  final Map<String, Score> scores;
  final bool loading;
  final Failure? failure;
  final bool saving;
  final bool publishing;

  ExamScoresState copyWith({
    Exam? exam,
    List<Student>? students,
    Map<String, Score>? scores,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    bool? saving,
    bool? publishing,
  }) {
    return ExamScoresState(
      exam: exam ?? this.exam,
      students: students ?? this.students,
      scores: scores ?? this.scores,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      saving: saving ?? this.saving,
      publishing: publishing ?? this.publishing,
    );
  }

  int get recordedCount => scores.length;

  ViewState<List<Student>> get view {
    if (loading) return const ViewLoading<List<Student>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Student>>(f);
    return listViewState<Student>(students);
  }
}

/// نتيجة "حفظ الدرجات": كام درجة اتحفظت، وأخطاء كل طالب (المفتاح = studentId).
class SaveAllResult {
  const SaveAllResult({required this.saved, required this.errors});

  final int saved;
  final Map<String, String> errors;

  bool get hasErrors => errors.isNotEmpty;
}

/// تفاصيل امتحان + رصد درجاته (نفس الـ cubit للشاشتين).
class ExamScoresCubit extends Cubit<ExamScoresState> {
  ExamScoresCubit(
    this._students,
    this._scores,
    this._exams,
    this.group,
    Exam exam,
  ) : super(ExamScoresState(exam: exam));

  final StudentsRepository _students;
  final ScoresRepository _scores;
  final ExamsRepository _exams;
  final Group group;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final roster = await _students.loadStudents();
      final saved = await _scores.loadExamScores(state.exam);
      if (isClosed) return;
      final inGroup = <Student>[
        for (final s in roster.students)
          if (!s.isArchived && s.isInGroup(group.id)) s,
      ]..sort((a, b) => a.studentNo.compareTo(b.studentNo));
      emit(
        state.copyWith(
          students: inGroup,
          scores: {for (final s in saved) s.studentId: s},
          loading: false,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  /// بيحفظ كل خانة اتغيّرت ([inputs]: studentId ← النص). الخانة الفاضية
  /// بتتخطى (مش صفر). الخانة الغلط بترجع خطأها من غير ما توقف الباقي.
  Future<SaveAllResult> saveAll(Map<String, String> inputs) async {
    if (state.saving) return const SaveAllResult(saved: 0, errors: {});
    emit(state.copyWith(saving: true));
    final errors = <String, String>{};
    var saved = 0;
    var scores = state.scores;
    for (final student in state.students) {
      final text = inputs[student.id];
      if (text == null || text.trim().isEmpty) continue;
      final parsed = ScoreValidator.parse(text, maxScore: state.exam.maxScore);
      if (!parsed.isValid) {
        errors[student.id] = parsed.error!;
        continue;
      }
      final existing = scores[student.id];
      if (existing != null &&
          existing.state == ScoreState.scored &&
          existing.score == parsed.value) {
        continue; // مفيش تغيير
      }
      try {
        final entry = await _scores.saveScore(
          exam: state.exam,
          studentId: student.id,
          state: ScoreState.scored,
          score: parsed.value,
          comment: existing?.comment ?? '',
        );
        scores = {...scores, entry.studentId: entry};
        saved++;
      } on Failure catch (f) {
        errors[student.id] = f.message;
      }
    }
    if (!isClosed) emit(state.copyWith(scores: scores, saving: false));
    return SaveAllResult(saved: saved, errors: errors);
  }

  /// نشر/إلغاء نشر. بيرجّع الخطأ أو null.
  Future<Failure?> setPublished(bool published) async {
    if (state.publishing) return null;
    emit(state.copyWith(publishing: true));
    try {
      final updated = await _exams.setPublished(
        state.exam,
        published: published,
      );
      if (isClosed) return null;
      emit(state.copyWith(exam: updated, publishing: false));
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(publishing: false));
      return f;
    }
  }
}
