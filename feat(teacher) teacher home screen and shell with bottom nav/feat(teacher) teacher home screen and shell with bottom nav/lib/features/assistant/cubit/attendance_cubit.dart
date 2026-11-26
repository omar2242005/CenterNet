import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../models/attendance.dart';
import '../models/attendance_entry.dart';
import '../repository/assistant_repository.dart';
import '../rules/attendance_merger.dart';
import '../services/pending_scan_store.dart';
import 'attendance_state.dart';

/// قائمة حضور جلسة: دمج Firestore + المسحات المحلية، بحث بالاسم/الكود،
/// وفلترة بالحالة.
///
/// بيسمع [PendingOpsGuard]: أي تغيير في قائمة المسحات المحلية (مسحة جديدة
/// من الماسح مثلًا) بيعمل تحديث هادي من غير ما يقلب الشاشة تحميل، فالسطر
/// الجديد يظهر لوحده لما المستخدم يرجع للشاشة.
class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(
    this._repository,
    this._store,
    this._guard, {
    required this.sessionId,
  }) : super(const AttendanceState()) {
    _guard.pending.addListener(_onPendingChanged);
  }

  final AssistantRepository _repository;
  final PendingScanStore _store;
  final PendingOpsGuard _guard;
  final String sessionId;

  List<AttendanceEntry> _entries = const <AttendanceEntry>[];
  bool _loading = false;

  Future<void> load() => _load(quiet: false);

  void search(String query) {
    if (isClosed) return;
    emit(
      state.copyWith(query: query, status: _viewFor(_entries, query: query)),
    );
  }

  void setFilter(AttendanceFilter filter) {
    if (isClosed) return;
    emit(
      state.copyWith(filter: filter, status: _viewFor(_entries, filter: filter)),
    );
  }

  Future<void> _load({required bool quiet}) async {
    if (_loading || isClosed) return;
    _loading = true;
    if (!quiet) {
      emit(state.copyWith(status: const ViewLoading()));
    }
    try {
      final centerId = await _myCenterId();
      final session = await _repository.sessionById(sessionId);
      final students = await _repository.groupStudents(
        centerId,
        session.groupId,
      );
      final records = await _repository.sessionAttendance(centerId, sessionId);
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
      _entries = entries;
      emit(state.copyWith(status: _viewFor(entries), summary: summary));
    } on FormatException {
      // التخزين المحلي تالف: مفيش فشل صامت.
      if (!isClosed && !quiet) {
        emit(state.copyWith(status: const ViewFailed(Failure.unknown())));
      }
    } on Failure catch (failure) {
      // التحديث الهادي لو فشل بيسيب البيانات المعروضة زي ما هي.
      if (!isClosed && !quiet) {
        emit(state.copyWith(status: ViewFailed(failure)));
      }
    } finally {
      _loading = false;
    }
  }

  void _onPendingChanged() {
    if (!isClosed) _load(quiet: true);
  }

  ViewState<List<AttendanceEntry>> _viewFor(
    List<AttendanceEntry> entries, {
    String? query,
    AttendanceFilter? filter,
  }) {
    final q = query ?? state.query;
    final f = filter ?? state.filter;
    if (entries.isEmpty && q.trim().isEmpty && f == AttendanceFilter.all) {
      return const ViewEmpty();
    }
    return ViewSuccess(_visible(entries, q, f));
  }

  List<AttendanceEntry> _visible(
    List<AttendanceEntry> entries,
    String query,
    AttendanceFilter filter,
  ) {
    return [
      for (final entry in entries)
        if (_matchesQuery(entry, query) && _matchesFilter(entry, filter))
          entry,
    ];
  }

  bool _matchesQuery(AttendanceEntry entry, String query) {
    final q = normalizeArabic(query);
    if (q.isEmpty) return true;
    final student = entry.student;
    if (student == null) return false;
    return matchesSearch(student.searchKey, q) ||
        student.studentNo.toString().contains(q);
  }

  bool _matchesFilter(AttendanceEntry entry, AttendanceFilter filter) {
    return switch (filter) {
      AttendanceFilter.all => true,
      AttendanceFilter.present => entry.status == AttendanceStatus.present,
      AttendanceFilter.late => entry.status == AttendanceStatus.lateArrival,
      AttendanceFilter.waiting =>
        entry.syncState == AttendanceSyncState.waiting,
      AttendanceFilter.failed => entry.syncState == AttendanceSyncState.failed,
    };
  }

  Future<String> _myCenterId() async {
    final profile = await _repository.myProfile();
    final centerId = profile.centerId;
    if (centerId == null) {
      throw const Failure.permission(message: 'حسابك غير مرتبط بأي سنتر بعد.');
    }
    return centerId;
  }

  @override
  Future<void> close() {
    _guard.pending.removeListener(_onPendingChanged);
    return super.close();
  }
}
