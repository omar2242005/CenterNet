import 'pending_scan_store.dart';

/// المكان اللي المسحات الناجحة بتتسجل فيه.
///
/// عملنا الواجهة دي عشان الشاشة التجريبية متكتبش في القائمة المحلية الحقيقية
/// (القائمة دي بتمنع تسجيل الخروج لحد ما تتزامن، ومفيش مزامنة لسه).
abstract interface class ScanRecorder {
  /// ids الطلاب اللي اتسجلوا قبل كده في الجلسة دي (لمنع التكرار).
  /// ممكن يرمي [FormatException] لو التخزين المحلي تالف.
  Set<String> loadStudentIds(String sessionId);

  /// بيسجّل المسحة. بيرجّع false لو كانت متسجلة قبل كده.
  Future<bool> record(PendingScan scan);

  /// عدد المسحات اللي لسه بانتظار المزامنة.
  int get pendingCount;
}

/// في الذاكرة بس (للنموذج التجريبي): مفيش حاجة بتتحفظ بعد قفل الشاشة.
class MemoryScanRecorder implements ScanRecorder {
  MemoryScanRecorder([Iterable<PendingScan> initial = const <PendingScan>[]])
      : _scans = List<PendingScan>.of(initial);

  final List<PendingScan> _scans;

  List<PendingScan> get scans => List<PendingScan>.unmodifiable(_scans);

  @override
  Set<String> loadStudentIds(String sessionId) => _scans
      .where((s) => s.sessionId == sessionId)
      .map((s) => s.studentId)
      .toSet();

  @override
  Future<bool> record(PendingScan scan) async {
    if (_scans.any((s) => s.id == scan.id)) return false;
    _scans.add(scan);
    return true;
  }

  @override
  int get pendingCount =>
      _scans.where((s) => s.status == PendingScanStatus.pending).length;
}

/// الحقيقي: بيكتب في [PendingScanStore] (القائمة المحلية + حارس الخروج).
class StoreScanRecorder implements ScanRecorder {
  StoreScanRecorder(this._store);

  final PendingScanStore _store;

  @override
  Set<String> loadStudentIds(String sessionId) {
    _store.syncGuard();
    return _store
        .all()
        .where((s) => s.sessionId == sessionId)
        .map((s) => s.studentId)
        .toSet();
  }

  @override
  Future<bool> record(PendingScan scan) => _store.add(scan);

  @override
  int get pendingCount => _store.pendingCount;
}
