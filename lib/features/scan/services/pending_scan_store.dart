import 'dart:convert';

import '../../../core/services/local_store.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../models/pending_scan.dart';

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
    if (raw is! List) {
      throw const FormatException('قائمة المسحات المحلية تالفة');
    }
    return raw
        .map((e) => PendingScan.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  int get pendingCount =>
      all().where((s) => s.status == PendingScanStatus.pending).length;

  /// كل المسحات التي لم تُرفع بنجاح بعد، بما فيها التي فشلت وتحتاج إجراء.
  int get unsyncedCount =>
      all().where((s) => s.status != PendingScanStatus.synced).length;

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
    final list = all()
      ..removeWhere((s) => s.status == PendingScanStatus.synced);
    await _save(list);
  }

  /// بيزامن عدّاد الحارس مع المحفوظ (يتنادى مرة عند فتح التطبيق).
  void syncGuard() => _guard.setPending(unsyncedCount);

  Future<void> _update(
    String id,
    PendingScanStatus status, {
    String? reason,
  }) async {
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
      list.where((s) => s.status != PendingScanStatus.synced).length,
    );
  }
}
