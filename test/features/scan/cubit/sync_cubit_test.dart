import 'dart:async';

import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/features/scan/cubit/sync_cubit.dart';
import 'package:center_net/features/scan/cubit/sync_state.dart';
import 'package:center_net/features/scan/models/pending_scan.dart';
import 'package:center_net/features/scan/repository/scan_repository.dart';
import 'package:center_net/core/services/connectivity_monitor.dart';
import 'package:center_net/features/scan/services/pending_scan_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectivity implements ConnectivityMonitor {
  _FakeConnectivity();

  bool online = true;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get onOnlineChanged => _changes.stream;

  void change(bool value) {
    online = value;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
}

class _FakeRepository implements ScanRepository {
  _FakeRepository(this.onWrite);

  final Future<void> Function(PendingScan scan) onWrite;
  final List<PendingScan> writes = <PendingScan>[];

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    writes.add(scan);
    await onWrite(scan);
  }

  // باقي الـ interface مش مستخدم في اختبارات المزامنة.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('ScanRepository.${invocation.memberName}');
}

void main() {
  late PendingOpsGuard guard;
  late PendingScanStore store;
  late _FakeConnectivity connectivity;

  PendingScan scan(
    String studentId, {
    PendingScanStatus status = PendingScanStatus.pending,
  }) => PendingScan(
    id: 'g1_20261120_1700_$studentId',
    sessionId: 'g1_20261120_1700',
    studentId: studentId,
    centerId: 'c1',
    attendanceStatus: PendingAttendanceStatus.present,
    scannedAt: DateTime.utc(2026, 11, 20, 15),
    status: status,
  );

  Future<SyncCubit> build(
    Future<void> Function(PendingScan scan) onWrite,
  ) async {
    final cubit = SyncCubit(_FakeRepository(onWrite), store, connectivity);
    await cubit.load();
    return cubit;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    guard = PendingOpsGuard();
    store = PendingScanStore(await LocalStore.open(), guard);
    connectivity = _FakeConnectivity();
  });

  tearDown(() => connectivity.dispose());

  test('فشل جزئي: الناجح يتم والفاشل يحتفظ بسبب', () async {
    await store.add(scan('s1'));
    await store.add(scan('s2'));
    final cubit = await build((scan) async {
      if (scan.studentId == 's2') throw const Failure.permission();
    });

    await cubit.sync();

    expect(cubit.state.phase, SyncPhase.failed);
    expect(cubit.state.syncedCount, 1);
    expect(store.all(), hasLength(1));
    expect(store.failed.single.studentId, 's2');
    expect(store.failed.single.failReason, isNotEmpty);
    expect(guard.pending.value, 1);
    await cubit.close();
  });

  test('فشل الشبكة في المنتصف يترك الحالي والباقي معلّقين', () async {
    await store.add(scan('s1'));
    await store.add(scan('s2'));
    final cubit = await build((scan) async {
      if (scan.studentId == 's2') throw const Failure.network();
    });

    await cubit.sync();

    expect(cubit.state.phase, SyncPhase.offline);
    expect(
      store.all().firstWhere((s) => s.studentId == 's1').status,
      PendingScanStatus.synced,
    );
    expect(
      store.all().firstWhere((s) => s.studentId == 's2').status,
      PendingScanStatus.pending,
    );
    expect(guard.pending.value, 1);
    await cubit.close();
  });

  test('المسحة القديمة الناقصة تتحول لفاشلة من غير رفع', () async {
    await store.add(
      PendingScan(
        id: 'g1_20261120_1700_s1',
        sessionId: 'g1_20261120_1700',
        studentId: 's1',
        scannedAt: DateTime.utc(2026, 11, 20, 15),
      ),
    );
    final writes = <PendingScan>[];
    final cubit = await build((scan) async => writes.add(scan));

    await cubit.sync();

    expect(writes, isEmpty);
    expect(store.failed.single.failReason, contains('قديمة'));
    await cubit.close();
  });

  test('إعادة المحاولة ترفع المسحة الفاشلة وتحذفها بعد التأكيد', () async {
    await store.add(scan('s1'));
    var attempts = 0;
    final cubit = await build((_) async {
      attempts++;
      if (attempts == 1) throw const Failure.permission();
    });

    await cubit.sync();
    expect(cubit.state.phase, SyncPhase.failed);
    await cubit.sync(retryFailed: true);

    expect(cubit.state.phase, SyncPhase.done);
    expect(cubit.state.syncedCount, 1);
    expect(store.all(), isEmpty);
    expect(guard.canLeave, isTrue);
    await cubit.close();
  });

  test('نداءا مزامنة متزامنان لا يرفعان المسحة مرتين', () async {
    await store.add(scan('s1'));
    final gate = Completer<void>();
    final repo = _FakeRepository((_) => gate.future);
    final cubit = SyncCubit(repo, store, connectivity);
    await cubit.load();

    final first = cubit.sync();
    final second = cubit.sync();
    await Future<void>.delayed(Duration.zero);
    expect(repo.writes, hasLength(1));

    gate.complete();
    await Future.wait([first, second]);
    expect(repo.writes, hasLength(1));
    await cubit.close();
  });

  test('رجوع الاتصال يبدأ مزامنة تلقائية في الواجهة الأمامية', () async {
    await store.add(scan('s1'));
    connectivity.online = false;
    final writes = <PendingScan>[];
    final cubit = await build((scan) async => writes.add(scan));
    expect(cubit.state.phase, SyncPhase.offline);

    connectivity.change(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(writes, hasLength(1));
    expect(cubit.state.phase, SyncPhase.done);
    await cubit.close();
  });

  test('قائمة 500 مسحة تتزامن بالتتابع في وقت مقبول', () async {
    for (var index = 0; index < 500; index++) {
      await store.add(scan('s$index'));
    }
    final cubit = await build((_) async {});
    final watch = Stopwatch()..start();

    await cubit.sync();
    watch.stop();

    expect(cubit.state.phase, SyncPhase.done);
    expect(store.all(), isEmpty);
    // العملية مقصودة أن تكون متسلسلة وتحفظ كل تحديث فورًا؛ الحد واسع لتفادي
    // الاعتماد على سرعة جهاز الـ CI مع كشف أي تراجع كبير في الأداء.
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
    await cubit.close();
  });
}
