import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/features/attendance/services/pending_scan_store.dart';

void main() {
  late LocalStore local;
  late PendingOpsGuard guard;
  late PendingScanStore store;

  PendingScan scan(String sid) => PendingScan(
        id: 'g1_20261119_1700_$sid',
        sessionId: 'g1_20261119_1700',
        studentId: sid,
        scannedAt: DateTime.utc(2026, 11, 19, 15, 5),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = await LocalStore.open();
    guard = PendingOpsGuard();
    store = PendingScanStore(local, guard);
  });

  test('الإضافة بتزوّد العدّاد والحارس بيمنع الخروج', () async {
    await store.add(scan('s1'));
    await store.add(scan('s2'));
    expect(store.pendingCount, 2);
    expect(guard.canLeave, isFalse);
  });

  test('نفس المسحة مرتين مش بتتكرر', () async {
    expect(await store.add(scan('s1')), isTrue);
    expect(await store.add(scan('s1')), isFalse);
    expect(store.all(), hasLength(1));
  });

  test('تمت: العدّاد بينزل والخروج يتسمح لما يخلصوا', () async {
    await store.add(scan('s1'));
    await store.markSynced(scan('s1').id);
    expect(store.pendingCount, 0);
    expect(guard.canLeave, isTrue);
  });

  test('فشلت: بتتسجل بالسبب وبتظهر في القائمة وما بتمنعش الخروج', () async {
    await store.add(scan('s1'));
    await store.markFailed(scan('s1').id, 'سجّله مساعد آخر');
    expect(store.failed.single.failReason, 'سجّله مساعد آخر');
    expect(guard.canLeave, isTrue);
  });

  test('clearSynced بتشيل التمام بس', () async {
    await store.add(scan('s1'));
    await store.add(scan('s2'));
    await store.add(scan('s3'));
    await store.markSynced(scan('s1').id);
    await store.markFailed(scan('s2').id, 'x');
    await store.clearSynced();
    expect(store.all().map((s) => s.studentId), ['s2', 's3']);
  });

  test('بتفضل محفوظة بعد إعادة فتح التطبيق وsyncGuard بترجّع العدّاد', () async {
    await store.add(scan('s1'));
    final reopened = PendingScanStore(local, PendingOpsGuard());
    expect(reopened.pendingCount, 1);
    final g2 = PendingOpsGuard();
    PendingScanStore(local, g2).syncGuard();
    expect(g2.pending.value, 1);
  });

  test('قائمة تالفة بترمي FormatException (مفيش فشل صامت)', () async {
    await local.setString(PendingScanStore.storageKey, '{"x":1}');
    expect(() => store.all(), throwsFormatException);
  });

  test('تحديث مسحة مش موجودة بيرمي StateError', () async {
    expect(() => store.markSynced('nope'), throwsStateError);
  });
}
