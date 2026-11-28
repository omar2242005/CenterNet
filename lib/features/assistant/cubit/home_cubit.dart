import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../models/session_time_status.dart';
import '../../scan/repository/scan_repository.dart';
import '../repository/assistant_repository.dart';
import '../../../core/services/connectivity_monitor.dart';
import 'home_state.dart';

/// منطق رئيسية المساعد: تحية + حالة الاتصال + حصص النهارده + الحصة الجارية
/// وزر "ابدأ المسح" (تحضير للأوفلاين).
class AssistantHomeCubit extends Cubit<AssistantHomeState> {
  AssistantHomeCubit(
    this._repository,
    this._scan,
    this._connectivity, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const AssistantHomeState());

  final AssistantRepository _repository;
  final ScanRepository _scan;
  final ConnectivityMonitor _connectivity;
  final DateTime Function() _clock;

  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> load() async {
    _connectivitySubscription ??= _connectivity.onOnlineChanged.listen(
      (online) {
        if (!isClosed) {
          emit(
            state.copyWith(
              online: online,
              preparedSetup: state.preparedSetup,
              prepareFailure: state.prepareFailure,
            ),
          );
        }
      },
    );
    try {
      final online = await _connectivity.isOnline;
      if (!isClosed && online != state.online) {
        emit(
          state.copyWith(
            online: online,
            preparedSetup: state.preparedSetup,
            prepareFailure: state.prepareFailure,
          ),
        );
      }
    } on Object {
      // فشل فحص الاتصال مش بيوقف تحميل البيانات.
    }

    emit(
      state.copyWith(
        status: const ViewLoading(),
        preparedSetup: null,
        prepareFailure: null,
      ),
    );
    try {
      final profile = await _repository.myProfile();
      final centerId = profile.centerId;
      if (centerId == null) {
        throw const Failure.permission(
          message: 'حسابك غير مرتبط بأي سنتر بعد.',
        );
      }
      final sessions = await _repository.todaySessions();

      final now = _clock();
      Session? current;
      for (final s in sessions) {
        if (sessionTimeStatus(s, now) == SessionTimeStatus.current) {
          current = s;
          break;
        }
      }

      Group? group;
      final currentSession = current;
      if (currentSession != null) {
        try {
          group = await _repository.groupById(currentSession.groupId);
        } on Failure {
          group = null; // اسم المجموعة تجميلي: من غيره الكارت يفضل شغال.
        }
      }

      if (isClosed) return;
      emit(
        state.copyWith(
          status: ViewSuccess(
            AssistantHomeData(
              assistantName: profile.name,
              centerId: centerId,
              todaySessions: sessions,
              currentSession: currentSession,
              currentGroup: group,
            ),
          ),
          preparedSetup: null,
          prepareFailure: null,
        ),
      );
    } on Failure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ViewFailed(failure),
            preparedSetup: null,
            prepareFailure: null,
          ),
        );
      }
    }
  }

  /// "ابدأ المسح": بيحضّر [ScanSetup] من الحصة الجارية. النجاح بيحط
  /// [AssistantHomeState.preparedSetup] والشاشة بتتنقل للماسح؛ الفشل بيحط
  /// [AssistantHomeState.prepareFailure] من غير تنقّل.
  Future<void> prepareScan() async {
    if (state.preparing || isClosed) return;
    final status = state.status;
    if (status is! ViewSuccess<AssistantHomeData>) return;
    final current = status.data.currentSession;
    if (current == null) return;

    emit(
      state.copyWith(preparing: true, preparedSetup: null, prepareFailure: null),
    );
    try {
      final setup = await _scan.prepareScanSetup(current.id);
      if (isClosed) return;
      emit(
        state.copyWith(preparing: false, preparedSetup: setup),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(preparing: false, prepareFailure: failure),
      );
    }
  }

  /// الشاشة بتناديها بعد ما تتنقل للماسح عشان تمسح الحقل اللحظي.
  void consumePreparedSetup() {
    if (!isClosed) emit(state.copyWith(preparedSetup: null));
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
