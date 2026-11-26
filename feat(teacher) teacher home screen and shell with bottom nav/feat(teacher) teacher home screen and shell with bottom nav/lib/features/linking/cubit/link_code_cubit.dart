import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/student_link.dart';
import '../repository/linking_repository.dart';

class LinkCodeState {
  const LinkCodeState({this.busy = false, this.done = false, this.failure});

  /// الربط شغال دلوقتي.
  final bool busy;

  /// الربط نجح.
  final bool done;

  /// آخر فشل (بيتصفّر مع أي محاولة جديدة).
  final Failure? failure;
}

/// إدخال كود الربط (طالب أو ولي أمر).
class LinkCodeCubit extends Cubit<LinkCodeState> {
  LinkCodeCubit(this._repo, this.kind) : super(const LinkCodeState());

  final LinkingRepository _repo;
  final LinkKind kind;

  Future<void> submit(String code) async {
    if (state.busy || state.done) return;
    emit(const LinkCodeState(busy: true));
    try {
      await _repo.redeem(code, expected: kind);
      if (isClosed) return;
      emit(const LinkCodeState(done: true));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(LinkCodeState(failure: f));
    }
  }
}
