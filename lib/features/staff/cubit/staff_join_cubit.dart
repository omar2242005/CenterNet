import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/staff_join_result.dart';
import '../repository/staff_join_repository.dart';

enum StaffJoinStatus { idle, submitting, success, failure }

class StaffJoinState {
  const StaffJoinState({
    this.status = StaffJoinStatus.idle,
    this.result,
    this.failure,
  });

  final StaffJoinStatus status;
  final StaffJoinResult? result;
  final Failure? failure;

  bool get isSubmitting => status == StaffJoinStatus.submitting;
}

class StaffJoinCubit extends Cubit<StaffJoinState> {
  StaffJoinCubit(this._repo) : super(const StaffJoinState());

  final StaffJoinRepository _repo;

  Future<void> submit(String code) async {
    if (state.isSubmitting) return;
    emit(const StaffJoinState(status: StaffJoinStatus.submitting));
    try {
      final result = await _repo.acceptStaffInvite(code);
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.success, result: result));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StaffJoinState(status: StaffJoinStatus.failure, failure: f));
    }
  }
}
