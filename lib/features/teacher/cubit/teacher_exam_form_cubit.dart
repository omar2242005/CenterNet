import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../grades/models/exam.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';

enum TeacherExamFormStatus { loading, ready, submitting, success, failure }

class TeacherExamFormState {
  const TeacherExamFormState({
    this.status = TeacherExamFormStatus.loading,
    this.groups = const <Group>[],
    this.failure,
    this.saved,
  });

  final TeacherExamFormStatus status;

  /// مجموعاته النشطة (للاختيار).
  final List<Group> groups;
  final Failure? failure;
  final Exam? saved;

  bool get isSubmitting => status == TeacherExamFormStatus.submitting;
}

/// إنشاء امتحان (مسودة) في واحدة من مجموعات المعلم.
class TeacherExamFormCubit extends Cubit<TeacherExamFormState> {
  TeacherExamFormCubit(this._groups, this._exams)
    : super(const TeacherExamFormState());

  final GroupsRepository _groups;
  final ExamsRepository _exams;

  Future<void> load() async {
    emit(const TeacherExamFormState());
    try {
      final roster = await _groups.loadMyGroups();
      if (isClosed) return;
      emit(
        TeacherExamFormState(
          status: TeacherExamFormStatus.ready,
          groups: roster.groups.where((g) => !g.isArchived).toList(),
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        TeacherExamFormState(status: TeacherExamFormStatus.failure, failure: f),
      );
    }
  }

  /// [start] لحظة بداية الامتحان (التاريخ + وقت البداية بتوقيت القاهرة).
  Future<void> submit({
    required Group group,
    required String title,
    required DateTime start,
    required double maxScore,
  }) async {
    if (state.isSubmitting) return;
    final groups = state.groups;
    emit(
      TeacherExamFormState(
        status: TeacherExamFormStatus.submitting,
        groups: groups,
      ),
    );
    try {
      final saved = await _exams.createExam(
        group,
        title: title,
        date: start,
        maxScore: maxScore,
      );
      if (isClosed) return;
      emit(
        TeacherExamFormState(
          status: TeacherExamFormStatus.success,
          groups: groups,
          saved: saved,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      // الفورم يفضل شغال (groups موجودة) والخطأ يظهر في SnackBar.
      emit(
        TeacherExamFormState(
          status: TeacherExamFormStatus.failure,
          groups: groups,
          failure: f,
        ),
      );
    }
  }
}
