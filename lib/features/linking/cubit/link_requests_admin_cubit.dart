import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/link_request.dart';
import '../repository/linking_repository.dart';

class LinkRequestsState {
  const LinkRequestsState({
    this.view = const ViewLoading<List<LinkRequest>>(),
    this.busy = false,
    this.failure,
  });

  final ViewState<List<LinkRequest>> view;
  final bool busy;
  final Failure? failure;
}

/// (أدمن) طلبات الربط المعلّقة: موافقة أو رفض.
class LinkRequestsAdminCubit extends Cubit<LinkRequestsState> {
  LinkRequestsAdminCubit(this._repo) : super(const LinkRequestsState());

  final LinkingRepository _repo;

  Future<void> load() async {
    emit(const LinkRequestsState());
    try {
      final items = await _repo.loadPendingRequests();
      if (isClosed) return;
      emit(LinkRequestsState(view: listViewState(items)));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(LinkRequestsState(view: ViewFailed<List<LinkRequest>>(f)));
    }
  }

  Future<void> approve(LinkRequest r) => _answer(() => _repo.approveRequest(r));

  Future<void> reject(LinkRequest r) => _answer(() => _repo.rejectRequest(r));

  Future<void> _answer(Future<void> Function() action) async {
    if (state.busy) return;
    final before = state.view;
    emit(LinkRequestsState(view: before, busy: true));
    try {
      await action();
      if (isClosed) return;
      await load();
    } on Failure catch (f) {
      if (isClosed) return;
      emit(LinkRequestsState(view: before, failure: f));
    }
  }
}
