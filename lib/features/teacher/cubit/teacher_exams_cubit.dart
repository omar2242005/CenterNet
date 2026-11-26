import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/exam_summary.dart';
import '../repository/teacher_exams_repository.dart';

class TeacherExamsState {
  const TeacherExamsState({
    this.status = const ViewLoading<List<ExamSummary>>(),
  });

  final ViewState<List<ExamSummary>> status;
}

/// قايمة امتحانات المعلم عبر مجموعاته.
class TeacherExamsCubit extends Cubit<TeacherExamsState> {
  TeacherExamsCubit(this._repo) : super(const TeacherExamsState());

  final TeacherExamsRepository _repo;

  Future<void> load() async {
    emit(const TeacherExamsState());
    try {
      final items = await _repo.loadAll();
      if (isClosed) return;
      emit(TeacherExamsState(status: listViewState<ExamSummary>(items)));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(TeacherExamsState(status: ViewFailed<List<ExamSummary>>(f)));
    }
  }
}
