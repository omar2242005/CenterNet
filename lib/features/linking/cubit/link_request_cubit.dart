import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/link_request.dart';
import '../models/student_link.dart';
import '../repository/linking_repository.dart';

class LinkRequestState {
  const LinkRequestState({
    this.request,
    this.busy = false,
    this.done = false,
    this.failure,
  });

  /// الطلب بعد إرساله (null = لسه بيملا الفورم).
  final LinkRequest? request;
  final bool busy;

  /// الربط تم بعد موافقة الأدمن.
  final bool done;
  final Failure? failure;
}

/// طلب الربط من الطالب/ولي الأمر: إرسال، تحديث الحالة، إكمال الربط بعد الموافقة.
class LinkRequestCubit extends Cubit<LinkRequestState> {
  LinkRequestCubit(this._repo, this.kind) : super(const LinkRequestState());

  final LinkingRepository _repo;
  final LinkKind kind;

  Future<void> _run(
    Future<LinkRequest?> Function() action, {
    bool completes = false,
  }) async {
    if (state.busy) return;
    emit(LinkRequestState(request: state.request, busy: true));
    try {
      final r = await action();
      if (isClosed) return;
      emit(LinkRequestState(request: r, done: completes));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(LinkRequestState(request: state.request, failure: f));
    }
  }

  Future<void> send({
    required String centerId,
    required int studentNo,
    String? relation,
  }) {
    return _run(
      () => _repo.sendRequest(
        centerId: centerId.trim(),
        studentNo: studentNo,
        kind: kind,
        relation: relation,
      ),
    );
  }

  Future<void> refresh() {
    final r = state.request;
    if (r == null) return Future.value();
    return _run(() => _repo.loadRequest(r));
  }

  /// بعد الرفض: يمسح الطلب ويرجع للفورم.
  Future<void> retry() {
    final r = state.request;
    if (r == null) return Future.value();
    return _run(() async {
      await _repo.cancelRequest(r);
      return null;
    });
  }

  Future<void> complete() {
    final r = state.request;
    if (r == null) return Future.value();
    return _run(() async {
      await _repo.completeRequest(r);
      return r;
    }, completes: true);
  }
}
