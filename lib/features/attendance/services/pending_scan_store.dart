import 'dart:convert';

import '../../../core/services/local_store.dart';
import '../../../core/services/pending_ops_guard.dart';

/// حالة مسحة في القائمة المحلية.
enum PendingScanStatus {
  pending('pending'),
  synced('synced'),
  failed('failed');

  const PendingScanStatus(this.wire);
  final String wire;

  static PendingScanStatus parse(Object? raw) {
    for (final s in values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة مسحة غير معروفة: $raw');
  }
}

/// مسحة واحدة في القائمة المحلية. [id] = id الحضور الحتمي (sessionId_sid)،
/// فتسجيل نفس المسحة مرتين مش بيكرر.
class PendingScan {
  final String id;
  final String sessionId;
  final String studentId;
  final DateTime scannedAt;
  final PendingScanStatus status;
  final String? failReason;

  const PendingScan({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.scannedAt,
    this.status = PendingScanStatus.pending,
    this.failReason,
  });

  PendingScan copyWith({PendingScanStatus? status, String? failReason}) =>
      PendingScan(
        id: id,
        sessionId: sessionId,
        studentId: studentId,
        scannedAt: scannedAt,
        status: status ?? this.status,
        failReason: failReason,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'studentId': studentId,
        'scannedAt': scannedAt.toUtc().toIso8601String(),
        'status': status.wire,
        'failReason': failReason,
      };

  factory PendingScan.fromMap(Map<String, dynamic> m) {
    final id = m['id'];
    final sessionId = m['sessionId'];
    final studentId = m['studentId'];
    final at = m['scannedAt'];
    if (id is! String ||
        sessionId is! String ||
        studentId is! String ||
        at is! String) {
      throw const FormatException('مسحة محلية ناقصة حقول');
    }
    return PendingScan(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      scannedAt: DateTime.parse(at),
      status: PendingScanStatus.parse(m['status']),
      failReason: m['failReason'] as String?,
    );
  }
}

/// القائمة المحلية الصغيرة للمسحات (متابعة المزامنة بس؛ الحضور نفسه في
/// Firestore persistence). بتحدّث [PendingOpsGuard] مع كل تغيير عشان تمنع
/// الخروج وفي مسحات معلّقة. مفيش فشل صامت: القائمة التالفة بترمي
/// FormatException بدل ما تتعامل كأنها فاضية.
class PendingScanStore {
  PendingScanStore(this._store, this._guard);

  static const String storageKey = 'pending_scans_v1';

  final LocalStore _store;
  final PendingOpsGuard _guard;

  List<PendingScan> all() {
    final raw = _store.getJson(storageKey);
    if (raw == null) return <PendingScan>[];
    if (raw is! List) throw const FormatException('قائمة المسحات المحلية تالفة');
    return raw
        .map((e) => PendingScan.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  int get pendingCount =>
      all().where((s) => s.status == PendingScanStatus.pending).length;

  List<PendingScan> get failed =>
      all().where((s) => s.status == PendingScanStatus.failed).toList();

  /// بيضيف مسحة. لو نفس الـ id موجود (أي حالة) مش بيتكرر وبيرجّع false.
  Future<bool> add(PendingScan scan) async {
    final list = all();
    if (list.any((s) => s.id == scan.id)) return false;
    list.add(scan);
    await _save(list);
    return true;
  }

  Future<void> markSynced(String id) => _update(id, PendingScanStatus.synced);

  Future<void> markFailed(String id, String reason) =>
      _update(id, PendingScanStatus.failed, reason: reason);

  /// بيشيل المسحات المتزامنة (تمت) بس. الفاشلة والمعلّقة بتفضل.
  Future<void> clearSynced() async {
    final list = all()..removeWhere((s) => s.status == PendingScanStatus.synced);
    await _save(list);
  }

  /// بيزامن عدّاد الحارس مع المحفوظ (يتنادى مرة عند فتح التطبيق).
  void syncGuard() => _guard.setPending(pendingCount);

  Future<void> _update(String id, PendingScanStatus status,
      {String? reason}) async {
    final list = all();
    final i = list.indexWhere((s) => s.id == id);
    if (i < 0) throw StateError('مسحة غير موجودة: $id');
    list[i] = list[i].copyWith(status: status, failReason: reason);
    await _save(list);
  }

  Future<void> _save(List<PendingScan> list) async {
    await _store.setJson(
      storageKey,
      jsonDecode(jsonEncode(list.map((s) => s.toMap()).toList())) as Object,
    );
    _guard.setPending(
      list.where((s) => s.status == PendingScanStatus.pending).length,
    );
  }
}
