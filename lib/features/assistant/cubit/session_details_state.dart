import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../models/scan_setup.dart';

/// بيانات شاشة تفاصيل الحصة.
class SessionDetailsData {
  const SessionDetailsData({required this.session, required this.group});

  final Session session;
  final Group group;
}

class SessionDetailsState {
  final ViewState<SessionDetailsData> status;

  /// زر "مسح كود الطالب" بيجهّز البيانات للأوفلاين.
  final bool preparing;

  /// حقول لحظية: الشاشة بتتصرف عليها (تنقّل/عرض خطأ) وبعدين بتتمسح.
  final ScanSetup? preparedSetup;
  final Failure? prepareFailure;

  const SessionDetailsState({
    this.status = const ViewLoading(),
    this.preparing = false,
    this.preparedSetup,
    this.prepareFailure,
  });

  SessionDetailsState copyWith({
    ViewState<SessionDetailsData>? status,
    bool? preparing,
    ScanSetup? preparedSetup,
    Failure? prepareFailure,
  }) => SessionDetailsState(
    status: status ?? this.status,
    preparing: preparing ?? this.preparing,
    preparedSetup: preparedSetup,
    prepareFailure: prepareFailure,
  );
}
