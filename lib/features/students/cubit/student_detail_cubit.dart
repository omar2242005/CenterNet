import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/student.dart';
import '../repository/students_repository.dart';

class StudentDetailState {
  const StudentDetailState({
    required this.student,
    this.busy = false,
    this.failure,
  });

  final Student student;

  /// أرشفة/استرجاع شغال دلوقتي.
  final bool busy;

  /// آخر فشل (بيتصفّر مع أي محاولة جديدة).
  final Failure? failure;
}

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(this._repo, Student student)
      : super(StudentDetailState(student: student));

  final StudentsRepository _repo;

  /// بعد ما شاشة التعديل ترجّع الطالب المحدّث.
  void replaceStudent(Student student) =>
      emit(StudentDetailState(student: student));

  Future<void> setArchived(bool archived) async {
    if (state.busy || state.student.isArchived == archived) return;
    final current = state.student;
    emit(StudentDetailState(student: current, busy: true));
    try {
      final updated = await _repo.setArchived(current, archived: archived);
      if (isClosed) return;
      emit(StudentDetailState(student: updated));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StudentDetailState(student: current, failure: f));
    }
  }
}
