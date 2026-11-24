import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../groups/models/group.dart';
import '../models/exam.dart';
import '../repositories/exams_repository.dart';

enum ExamFormStatus { idle, submitting, success, failure }

class ExamFormState {
  const ExamFormState({
    this.status = ExamFormStatus.idle,
    this.failure,
    this.saved,
  });

  final ExamFormStatus status;
  final Failure? failure;

  /// الامتحان بعد الحفظ (في حالة النجاح).
  final Exam? saved;

  bool get isSubmitting => status == ExamFormStatus.submitting;
}

/// إنشاء امتحان جديد (مسودة) في مجموعة.
class ExamFormCubit extends Cubit<ExamFormState> {
  ExamFormCubit(this._repo, this.group) : super(const ExamFormState());

  final ExamsRepository _repo;
  final Group group;

  Future<void> submit({
    required String title,
    required DateTime date,
    required double maxScore,
  }) async {
    if (state.isSubmitting) return;
    emit(const ExamFormState(status: ExamFormStatus.submitting));
    try {
      final saved = await _repo.createExam(
        group,
        title: title,
        date: date,
        maxScore: maxScore,
      );
      if (isClosed) return;
      emit(ExamFormState(status: ExamFormStatus.success, saved: saved));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ExamFormState(status: ExamFormStatus.failure, failure: f));
    }
  }
}