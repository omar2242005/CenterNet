import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../../scan/models/scan_setup.dart';

/// بيانات الرئيسية بعد التحميل: اسم المساعد وحصص النهارده والحصة الجارية.
class AssistantHomeData {
  const AssistantHomeData({
    required this.assistantName,
    required this.centerId,
    required this.todaySessions,
    this.currentSession,
    this.currentGroup,
  });

  final String assistantName;
  final String centerId;
  final List<Session> todaySessions;

  /// الحصة اللي شغّالة دلوقتي (لو فيه) ومجموعتها.
  final Session? currentSession;
  final Group? currentGroup;
}

class AssistantHomeState {
  final ViewState<AssistantHomeData> status;
  final bool online;

  /// زر "ابدأ المسح" بيجهّز البيانات للأوفلاين.
  final bool preparing;

  /// حقول لحظية: الشاشة بتتصرف عليها (تنقّل/عرض خطأ) وبعدين بتتمسح.
  final ScanSetup? preparedSetup;
  final Failure? prepareFailure;

  const AssistantHomeState({
    this.status = const ViewLoading(),
    this.online = true,
    this.preparing = false,
    this.preparedSetup,
    this.prepareFailure,
  });

  AssistantHomeState copyWith({
    ViewState<AssistantHomeData>? status,
    bool? online,
    bool? preparing,
    ScanSetup? preparedSetup,
    Failure? prepareFailure,
  }) => AssistantHomeState(
    status: status ?? this.status,
    online: online ?? this.online,
    preparing: preparing ?? this.preparing,
    // الحقول اللحظية بتتكتب دايمًا (نفس أسلوب SyncState.message).
    preparedSetup: preparedSetup,
    prepareFailure: prepareFailure,
  );
}
