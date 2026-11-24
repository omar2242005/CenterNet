import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../models/exam.dart';
import '../models/score.dart';
import '../repositories/scores_repository.dart';

class ScoresEntryState {
  const ScoresEntryState({
    required this.exam,
    this.students = const <Student>[],
    this.scores = const <String, Score>{},
    this.loading = true,
    this.failure,
    this.busyStudentId,
  });

  final Exam exam;

  /// طلاب المجموعة النشطين، مرتبين بالرقم التسلسلي.
  final List<Student> students;

  /// الدرجات المرصودة (المفتاح = studentId). الطالب اللي مالوش مدخل = "لسه".
  final Map<String, Score> scores;
  final bool loading;
  final Failure? failure;

  /// الطالب اللي عليه حفظ شغال دلوقتي.
  final String? busyStudentId;

  ScoresEntryState copyWith({
    List<Student>? students,
    Map<String, Score>? scores,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    String? busyStudentId,
    bool clearBusy = false,
  }) {
    return ScoresEntryState(
      exam: exam,
      students: students ?? this.students,
      scores: scores ?? this.scores,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      busyStudentId: clearBusy ? null : (busyStudentId ?? this.busyStudentId),
    );
  }

  Score? scoreOf(String studentId) => scores[studentId];

  /// كام طالب اترصد (أي حالة).
  int get recordedCount => scores.length;

  ViewState<List<Student>> get view {
    if (loading) return const ViewLoading<List<Student>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Student>>(f);
    return listViewState<Student>(students);
  }
}

/// إدخال درجات امتحان لطلاب المجموعة.
class ScoresEntryCubit extends Cubit<ScoresEntryState> {
  ScoresEntryCubit(this._students, this._scores, this.group, Exam exam)
      : super(ScoresEntryState(exam: exam));

  final StudentsRepository _students;
  final ScoresRepository _scores;
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

  /// بيحفظ (أو بيعدّل) رصد طالب. [score] مطلوبة مع scored وممنوعة مع غيره.
  /// بيرجّع الخطأ (للـ SnackBar) أو null.
  Future<Failure?> save(
    Student student, {
    required ScoreState scoreState,
    double? score,
    String comment = '',
  }) async {
    if (state.busyStudentId != null) return null;
    emit(state.copyWith(busyStudentId: student.id));
    try {
      final saved = await _scores.saveScore(
        exam: state.exam,
        studentId: student.id,
        state: scoreState,
        score: score,
        comment: comment,
      );
      if (isClosed) return null;
      emit(
        state.copyWith(
          scores: {...state.scores, saved.studentId: saved},
          clearBusy: true,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(clearBusy: true));
      return f;
    }
  }
}