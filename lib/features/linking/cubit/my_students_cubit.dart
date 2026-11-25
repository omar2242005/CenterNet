import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/linked_student.dart';
import '../repository/linking_repository.dart';

class MyStudentsState {
  const MyStudentsState({
    this.view = const ViewLoading<List<LinkedStudent>>(),
    this.busy = false,
    this.failure,
  });

  final ViewState<List<LinkedStudent>> view;

  /// فك ربط شغال دلوقتي.
  final bool busy;

  /// آخر فشل في فك الربط (التحميل ليه [view]).
  final Failure? failure;
}

/// الطلاب المربوطين بالحساب الحالي (للطالب: واحد، ولولي الأمر: لحد كام ابن).
class MyStudentsCubit extends Cubit<MyStudentsState> {
  MyStudentsCubit(this._repo) : super(const MyStudentsState());

  final LinkingRepository _repo;

  Future<void> load() async {
    emit(const MyStudentsState());
    try {
      final items = await _repo.loadMyStudents();
      if (isClosed) return;
      emit(MyStudentsState(view: listViewState(items)));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(MyStudentsState(view: ViewFailed<List<LinkedStudent>>(f)));
    }
  }

  Future<void> unlink(LinkedStudent item) async {
    if (state.busy) return;
    final before = state.view;
    emit(MyStudentsState(view: before, busy: true));
    try {
      await _repo.unlink(item.link);
      if (isClosed) return;
      await load();
    } on Failure catch (f) {
      if (isClosed) return;
      emit(MyStudentsState(view: before, failure: f));
    }
  }
}
