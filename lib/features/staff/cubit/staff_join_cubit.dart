import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/staff_invite_preview.dart';
import '../models/staff_join_result.dart';
import '../repository/staff_join_repository.dart';

/// idle ← إدخال الكود، checking ← فحص الكود، confirm ← معاينة الدور وانتظار
/// التأكيد، submitting ← الانضمام، success / failure.
enum StaffJoinStatus { idle, checking, confirm, submitting, success, failure }

class StaffJoinState {
  const StaffJoinState({
    this.status = StaffJoinStatus.idle,
    this.preview,
    this.result,
    this.failure,
  });

  final StaffJoinStatus status;
  final StaffInvitePreview? preview;
  final StaffJoinResult? result;
  final Failure? failure;

  bool get isSubmitting =>
      status == StaffJoinStatus.checking ||
      status == StaffJoinStatus.submitting;
}

class StaffJoinCubit extends Cubit<StaffJoinState> {
  StaffJoinCubit(this._repo) : super(const StaffJoinState());

  final StaffJoinRepository _repo;

  /// الخطوة 1: فحص الكود وعرض الدور اللي هيتمنح. مفيش كتابة.
  Future<void> check(String code) async {
    if (state.isSubmitting) return;
    emit(const StaffJoinState(status: StaffJoinStatus.checking));
    try {
      final preview = await _repo.previewInvite(code);
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.confirm, preview: preview));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.failure, failure: f));
    }
  }

  /// الخطوة 2: تأكيد الانضمام بعد المعاينة.
  Future<void> confirm() async {
    final preview = state.preview;
    if (state.isSubmitting || preview == null) return;
    emit(StaffJoinState(status: StaffJoinStatus.submitting, preview: preview));
    try {
      final result = await _repo.acceptStaffInvite(preview.code);
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.success, result: result));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.failure, failure: f));
    }
  }

  /// رجوع من المعاينة لتعديل الكود.
  void back() {
    if (state.isSubmitting) return;
    emit(const StaffJoinState());
  }
}
