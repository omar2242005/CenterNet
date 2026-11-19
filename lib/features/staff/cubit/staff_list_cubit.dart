import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../linking/models/invite_code.dart';
import '../models/staff_member.dart';
import '../repository/staff_repository.dart';

class StaffListState {
  const StaffListState({
    this.view = const ViewLoading<List<StaffMember>>(),
    this.busyUid,
    this.actionFailure,
  });

  /// تحميل · فارغ · خطأ · نجاح.
  final ViewState<List<StaffMember>> view;

  /// uid الموظف اللي عليه تعديل شغال دلوقتي (تعديل واحد في المرة).
  final String? busyUid;

  /// آخر فشل في تعديل (بيتصفّر مع أي محاولة جديدة).
  final Failure? actionFailure;

  StaffListState copyWith({
    String? busyUid,
    bool clearBusy = false,
    Failure? actionFailure,
    bool clearFailure = false,
  }) {
    return StaffListState(
      view: view,
      busyUid: clearBusy ? null : (busyUid ?? this.busyUid),
      actionFailure:
          clearFailure ? null : (actionFailure ?? this.actionFailure),
    );
  }
}

class StaffListCubit extends Cubit<StaffListState> {
  StaffListCubit(this._repo) : super(const StaffListState());

  final StaffRepository _repo;
  String? _centerId;

  Future<void> load() async {
    emit(const StaffListState());
    try {
      final roster = await _repo.loadStaff();
      if (isClosed) return;
      _centerId = roster.centerId;
      emit(StaffListState(view: listViewState<StaffMember>(roster.members)));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(StaffListState(view: ViewFailed<List<StaffMember>>(f)));
    }
  }

  /// تبديل دور موظف (معلم ↔ مساعد).
  Future<void> changeRole(StaffMember member, StaffInviteRole role) {
    if (member.role == StaffMemberRole.fromInvite(role)) {
      return Future<void>.value();
    }
    return _apply(
      member,
      (centerId) => _repo.changeRole(
        centerId: centerId,
        uid: member.uid,
        role: role,
      ),
      member.copyWith(role: StaffMemberRole.fromInvite(role)),
    );
  }

  /// تعطيل أو إعادة تفعيل موظف.
  Future<void> setActive(StaffMember member, bool active) {
    if (member.active == active) return Future<void>.value();
    return _apply(
      member,
      (centerId) => _repo.setActive(
        centerId: centerId,
        uid: member.uid,
        active: active,
      ),
      member.copyWith(active: active),
    );
  }

  Future<void> _apply(
    StaffMember member,
    Future<void> Function(String centerId) write,
    StaffMember updated,
  ) async {
    final centerId = _centerId;
    final view = state.view;
    if (centerId == null ||
        state.busyUid != null ||
        member.isAdmin ||
        view is! ViewSuccess<List<StaffMember>>) {
      return;
    }

    emit(state.copyWith(busyUid: member.uid, clearFailure: true));
    try {
      await write(centerId);
      if (isClosed) return;
      final items = <StaffMember>[
        for (final m in view.data) m.uid == member.uid ? updated : m,
      ];
      emit(StaffListState(view: ViewSuccess<List<StaffMember>>(items)));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(clearBusy: true, actionFailure: f));
    }
  }
}
