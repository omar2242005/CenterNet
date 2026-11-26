import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/student.dart';
import '../repository/students_repository.dart';

enum StudentFormStatus { idle, submitting, success, failure }

class StudentFormState {
  const StudentFormState({
    this.status = StudentFormStatus.idle,
    this.failure,
    this.saved,
  });

  final StudentFormStatus status;
  final Failure? failure;

  /// الطالب بعد الحفظ (في حالة النجاح).
  final Student? saved;

  bool get isSubmitting => status == StudentFormStatus.submitting;
}

/// إضافة طالب جديد، أو تعديل طالب لو [editing] متحدد.
class StudentFormCubit extends Cubit<StudentFormState> {
  StudentFormCubit(this._repo, {this.editing}) : super(const StudentFormState());

  final StudentsRepository _repo;
  final Student? editing;

  Future<void> submit({
    required String fullName,
    required String phone,
    required String grade,
  }) async {
    if (state.isSubmitting) return;
    emit(const StudentFormState(status: StudentFormStatus.submitting));
    try {
      final current = editing;
      final saved = current == null
          ? await _repo.addStudent(
              fullName: fullName,
              phone: phone,
              grade: grade,
            )
          : await _repo.updateStudent(
              current,
              fullName: fullName,
              phone: phone,
              grade: grade,
            );
      if (isClosed) return;
      emit(StudentFormState(status: StudentFormStatus.success, saved: saved));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StudentFormState(status: StudentFormStatus.failure, failure: f));
    }
  }
}
