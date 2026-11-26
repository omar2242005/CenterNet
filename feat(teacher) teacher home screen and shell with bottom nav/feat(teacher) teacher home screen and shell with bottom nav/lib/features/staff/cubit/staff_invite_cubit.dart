import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../linking/models/invite_code.dart';
import '../models/staff_invite_issued.dart';
import '../repository/staff_repository.dart';

enum StaffInviteStatus { idle, submitting, success, failure }

class StaffInviteState {
  const StaffInviteState({
    this.status = StaffInviteStatus.idle,
    this.issued,
    this.failure,
  });

  final StaffInviteStatus status;

  /// الكود اللي اتعمل (في حالة النجاح بس).
  final StaffInviteIssued? issued;
  final Failure? failure;

  bool get isSubmitting => status == StaffInviteStatus.submitting;
}

class StaffInviteCubit extends Cubit<StaffInviteState> {
  StaffInviteCubit(this._repo) : super(const StaffInviteState());

  final StaffRepository _repo;

  Future<void> create({
    required String name,
    required StaffInviteRole role,
  }) async {
    if (state.isSubmitting) return;
    emit(const StaffInviteState(status: StaffInviteStatus.submitting));
    try {
      final issued = await _repo.createStaffInvite(name: name, role: role);
      if (isClosed) return;
      emit(StaffInviteState(status: StaffInviteStatus.success, issued: issued));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StaffInviteState(status: StaffInviteStatus.failure, failure: f));
    }
  }

  /// يرجّع الشاشة للفورم (لإضافة موظف آخر).
  void reset() {
    if (state.isSubmitting) return;
    emit(const StaffInviteState());
  }
}
