import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../../attendance/models/attendance_entry.dart';
import '../../scan/models/scan_setup.dart';
import '../../attendance/rules/attendance_merger.dart';

/// بيانات شاشة تفاصيل الحصة.
class SessionDetailsData {
  const SessionDetailsData({
    required this.session,
    required this.group,
    this.summary,
    this.lastScans = const <AttendanceEntry>[],
  });

  final Session session;
  final Group group;

  /// ملخص الحضور المدموج. null لو قراءته فشلت (انظر
  /// [SessionDetailsState.summaryFailure]).
  final AttendanceSummary? summary;

  /// آخر عمليات المسح (الأحدث أولًا).
  final List<AttendanceEntry> lastScans;
}

class SessionDetailsState {
  final ViewState<SessionDetailsData> status;

  /// زر "مسح كود الطالب" بيجهّز البيانات للأوفلاين.
  final bool preparing;

  /// حقول لحظية: الشاشة بتتصرف عليها (تنقّل/عرض خطأ) وبعدين بتتمسح.
  final ScanSetup? preparedSetup;
  final Failure? prepareFailure;

  /// فشل قراءة ملخص الحضور (الشاشة بتعرضه في كارت الملخص مع زر إعادة).
  final Failure? summaryFailure;

  const SessionDetailsState({
    this.status = const ViewLoading(),
    this.preparing = false,
    this.preparedSetup,
    this.prepareFailure,
    this.summaryFailure,
  });

  SessionDetailsState copyWith({
    ViewState<SessionDetailsData>? status,
    bool? preparing,
    ScanSetup? preparedSetup,
    Failure? prepareFailure,
    Failure? summaryFailure,
  }) => SessionDetailsState(
    status: status ?? this.status,
    preparing: preparing ?? this.preparing,
    preparedSetup: preparedSetup,
    prepareFailure: prepareFailure,
    summaryFailure: summaryFailure,
  );
}
