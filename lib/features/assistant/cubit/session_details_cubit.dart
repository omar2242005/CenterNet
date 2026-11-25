import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../repository/assistant_repository.dart';
import 'session_details_state.dart';

/// تفاصيل حصة واحدة + زر "مسح كود الطالب" (تحضير للأوفلاين).
class SessionDetailsCubit extends Cubit<SessionDetailsState> {
  SessionDetailsCubit(this._repository, {required this.sessionId})
    : super(const SessionDetailsState());

  final AssistantRepository _repository;
  final String sessionId;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: const ViewLoading(),
        preparedSetup: null,
        prepareFailure: null,
      ),
    );
    try {
      final session = await _repository.sessionById(sessionId);
      final group = await _repository.groupById(session.groupId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ViewSuccess(
            SessionDetailsData(session: session, group: group),
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

  /// "مسح كود الطالب": بيحضّر [ScanSetup] من الجلسة الحقيقية. النجاح بيحط
  /// [SessionDetailsState.preparedSetup] والشاشة بتتنقل للماسح؛ الفشل
  /// (أوفلاين من غير كاش، مجموعة فاضية...) بيحط
  /// [SessionDetailsState.prepareFailure] من غير تنقّل.
  Future<void> prepareScan() async {
    if (state.preparing || isClosed) return;
    if (state.status is! ViewSuccess<SessionDetailsData>) return;

    emit(
      state.copyWith(preparing: true, preparedSetup: null, prepareFailure: null),
    );
    try {
      final setup = await _repository.prepareScanSetup(sessionId);
      if (isClosed) return;
      emit(state.copyWith(preparing: false, preparedSetup: setup));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(preparing: false, prepareFailure: failure));
    }
  }

  /// الشاشة بتناديها بعد ما تتنقل للماسح عشان تمسح الحقل اللحظي.
  void consumePreparedSetup() {
    if (!isClosed) emit(state.copyWith(preparedSetup: null));
  }
}
