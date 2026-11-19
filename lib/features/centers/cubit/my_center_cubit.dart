import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/center_info.dart';
import '../repository/centers_repository.dart';

/// سنتر المستخدم الحالي بالحالات الأربع:
/// تحميل · فارغ (مالوش سنتر) · خطأ · نجاح (السنتر + عضويته).
class MyCenterCubit extends Cubit<ViewState<CenterContext>> {
  MyCenterCubit(this._repo) : super(const ViewLoading());

  final CentersRepository _repo;

  Future<void> load() async {
    emit(const ViewLoading());
    try {
      final ctx = await _repo.loadMine();
      if (isClosed) return;
      emit(ctx == null ? const ViewEmpty() : ViewSuccess(ctx));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ViewFailed(f));
    }
  }
}
