import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../../../core/state/view_state.dart';
import '../../attendance/repository/attendance_repository.dart';
import '../../scan/repository/scan_repository.dart';
import '../repository/assistant_repository.dart';
import '../../attendance/rules/attendance_merger.dart';
import '../../scan/services/pending_scan_store.dart';
import 'session_details_state.dart';

/// تفاصيل حصة واحدة + ملخص الحضور المدموج + زر "مسح كود الطالب"
/// (تحضير للأوفلاين).
///
/// بيسمع [PendingOpsGuard]: أي تغيير في المسحات المحلية بيعمل تحديث هادي
/// للملخص (من غير قلب الشاشة تحميل)، فالملخص يتحدث لوحده لما المستخدم
/// يرجع من الماسح.
class SessionDetailsCubit extends Cubit<SessionDetailsState> {
  SessionDetailsCubit(
    this._assistant,
    this._attendance,
    this._scan,
    this._store,
    this._guard, {
    required this.sessionId,
  }) : super(const SessionDetailsState()) {
    _guard.pending.addListener(_onPendingChanged);
  }

  final AssistantRepository _assistant;
  final AttendanceRepository _attendance;
  final ScanRepository _scan;
  final PendingScanStore _store;
  final PendingOpsGuard _guard;
  final String sessionId;

  bool _loadingSummary = false;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: const ViewLoading(),
        preparedSetup: null,
        prepareFailure: null,
        summaryFailure: null,
      ),
    );
    try {
      final session = await _attendance.sessionById(sessionId);
      final group = await _assistant.groupById(session.groupId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ViewSuccess(
            SessionDetailsData(session: session, group: group),
          ),
          preparedSetup: null,
          prepareFailure: null,
          summaryFailure: null,
        ),
      );
      await _loadSummary();
    } on Failure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ViewFailed(failure),
            preparedSetup: null,
            prepareFailure: null,
            summaryFailure: null,
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
      final setup = await _scan.prepareScanSetup(sessionId);
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

  void _onPendingChanged() {
    if (!isClosed) _loadSummary();
  }

  /// بيقرا سجلات الحضور + طلاب المجموعة + المسحات المحلية ويحدّث الملخص
  /// و"آخر عمليات المسح". فشلها مش بيسقط الشاشة: بيتحط في
  /// [SessionDetailsState.summaryFailure] والكارت بيعرض إعادة المحاولة.
  Future<void> _loadSummary() async {
    if (_loadingSummary || isClosed) return;
    final current = state.status;
    if (current is! ViewSuccess<SessionDetailsData>) return;
    _loadingSummary = true;
    try {
      final profile = await _assistant.myProfile();
      final centerId = profile.centerId;
      if (centerId == null) {
        throw const Failure.permission(message: 'حسابك غير مرتبط بأي سنتر بعد.');
      }
      final session = current.data.session;
      final students = await _attendance.groupStudents(
        centerId,
        session.groupId,
      );
      final records = await _attendance.sessionAttendance(centerId, sessionId);
      final scans = _store.all();

      final studentsById = {for (final s in students) s.id: s};
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: records,
        pendingScans: scans,
        studentsById: studentsById,
      );
      final summary = AttendanceMerger.summary(
        entries: entries,
        students: students,
        coveredStudentIds: AttendanceMerger.coveredStudentIds(
          sessionId: sessionId,
          records: records,
          entries: entries,
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ViewSuccess(
            SessionDetailsData(
              session: session,
              group: current.data.group,
              summary: summary,
              lastScans: entries.reversed.take(5).toList(),
            ),
          ),
          preparedSetup: state.preparedSetup,
          prepareFailure: state.prepareFailure,
          summaryFailure: null,
        ),
      );
    } on FormatException {
      // التخزين المحلي تالف: مفيش فشل صامت.
      if (!isClosed) {
        emit(
          state.copyWith(
            preparedSetup: state.preparedSetup,
            prepareFailure: state.prepareFailure,
            summaryFailure: const Failure.unknown(),
          ),
        );
      }
    } on Failure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            preparedSetup: state.preparedSetup,
            prepareFailure: state.prepareFailure,
            summaryFailure: failure,
          ),
        );
      }
    } on Object {
      if (!isClosed) {
        emit(
          state.copyWith(
            preparedSetup: state.preparedSetup,
            prepareFailure: state.prepareFailure,
            summaryFailure: const Failure.unknown(),
          ),
        );
      }
    } finally {
      _loadingSummary = false;
    }
  }

  @override
  Future<void> close() {
    _guard.pending.removeListener(_onPendingChanged);
    return super.close();
  }
}
