import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/features/assistant/models/pending_scan.dart';
import 'package:center_net/features/assistant/services/pending_scan_store.dart';
import 'package:center_net/features/assistant/services/scan_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PendingScan _scan(String session, String sid) => PendingScan(
      id: '${session}_$sid',
      sessionId: session,
      studentId: sid,
      scannedAt: DateTime.utc(2026, 11, 20, 15, 5),
    );

void main() {
  group('MemoryScanRecorder', () {
    test('بيمنع التكرار وبيعدّ المعلّق', () async {
      final r = MemoryScanRecorder();
      expect(await r.record(_scan('g1_20261120_1700', 's1')), isTrue);
      expect(await r.record(_scan('g1_20261120_1700', 's1')), isFalse);
      expect(r.pendingCount, 1);
      expect(r.loadStudentIds('g1_20261120_1700'), {'s1'});
      expect(r.loadStudentIds('other'), isEmpty);
    });
  });

  group('StoreScanRecorder', () {
    late PendingOpsGuard guard;
    late PendingScanStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      guard = PendingOpsGuard();
      store = PendingScanStore(await LocalStore.open(), guard);
    });

    test('بيكتب في القائمة المحلية وبيحدّث حارس الخروج', () async {
      final r = StoreScanRecorder(store);
      expect(await r.record(_scan('g1_20261120_1700', 's1')), isTrue);
      expect(await r.record(_scan('g1_20261120_1700', 's1')), isFalse);
      expect(r.pendingCount, 1);
      expect(guard.canLeave, isFalse);
      expect(r.loadStudentIds('g1_20261120_1700'), {'s1'});
    });
  });
}
