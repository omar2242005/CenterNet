import 'package:center_net/features/assistant/cubit/scan_cubit.dart';
import 'package:center_net/features/assistant/models/pending_scan.dart';
import 'package:center_net/features/assistant/models/scan_setup.dart';
import 'package:center_net/features/assistant/services/scan_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

/// recorder بيرمي استثناء عند الكتابة (لاختبار فشل التخزين).
class _FailingRecorder implements ScanRecorder {
  @override
  Set<String> loadStudentIds(String sessionId) => <String>{};

  @override
  Future<bool> record(PendingScan scan) async =>
      throw StateError('تخزين فاشل');

  @override
  int get pendingCount => 0;
}

/// recorder بيرمي FormatException عند التحميل (تخزين تالف).
class _CorruptRecorder implements ScanRecorder {
  @override
  Set<String> loadStudentIds(String sessionId) =>
      throw const FormatException('تالف');

  @override
  Future<bool> record(PendingScan scan) async => true;

  @override
  int get pendingCount => 0;
}

void main() {
  const sessionId = 'g1_20261120_1700';
  final start = DateTime.utc(2026, 11, 20, 15, 0);

  late DateTime now;
  late MemoryScanRecorder recorder;

  ScanSetup setup() => ScanSetup(
        centerId: 'c1',
        sessionId: sessionId,
        sessionStart: start,
        groupStudentIds: {'s1', 's2'},
        lateAfterMinutes: 15,
      );

  ScanCubit build([ScanRecorder? r]) => ScanCubit(
        setup: setup(),
        recorder: r ?? recorder,
        clock: () => now,
      )..load();

  setUp(() {
    now = start.add(const Duration(minutes: 5));
    recorder = MemoryScanRecorder();
  });

  test('مسح صالح في الميعاد = حاضر وبيتسجل', () async {
    final cubit = build();
    await cubit.onCode('c1:s1');

    expect(cubit.state.feedback!.kind, ScanFeedbackKind.recordedPresent);
    expect(cubit.state.feedback!.studentId, 's1');
    expect(cubit.state.presentCount, 1);
    expect(cubit.state.pendingCount, 1);
    expect(recorder.scans.single.id, '${sessionId}_s1');
    await cubit.close();
  });

  test('بعد مهلة التأخير = متأخر', () async {
    now = start.add(const Duration(minutes: 20));
    final cubit = build();
    await cubit.onCode('c1:s1');

    expect(cubit.state.feedback!.kind, ScanFeedbackKind.recordedLate);
    expect(cubit.state.lateCount, 1);
    expect(cubit.state.presentCount, 0);
    await cubit.close();
  });

  test('نفس الرمز جوه فترة التكرار بيتتجاهل من غير رد جديد', () async {
    final cubit = build();
    await cubit.onCode('c1:s1');
    final seq = cubit.state.feedback!.seq;

    now = now.add(const Duration(seconds: 1));
    await cubit.onCode('c1:s1');

    expect(cubit.state.feedback!.seq, seq);
    expect(recorder.scans, hasLength(1));
    await cubit.close();
  });

  test('نفس الرمز بعد فترة التكرار = مسجّل بالفعل ومن غير تسجيل تاني', () async {
    final cubit = build();
    await cubit.onCode('c1:s1');

    now = now.add(const Duration(seconds: 10));
    await cubit.onCode('c1:s1');

    expect(cubit.state.feedback!.kind, ScanFeedbackKind.alreadyRegistered);
    expect(cubit.state.presentCount, 1);
    expect(recorder.scans, hasLength(1));
    await cubit.close();
  });

  test('طالب اتسجل قبل فتح الشاشة = مسجّل بالفعل', () async {
    final before = MemoryScanRecorder([
      PendingScan(
        id: '${sessionId}_s2',
        sessionId: sessionId,
        studentId: 's2',
        scannedAt: start,
      ),
    ]);
    final cubit = build(before);
    await cubit.onCode('c1:s2');

    expect(cubit.state.feedback!.kind, ScanFeedbackKind.alreadyRegistered);
    expect(before.scans, hasLength(1));
    await cubit.close();
  });

  test('سنتر تاني / رمز غلط / طالب برا المجموعة = مرفوض ومن غير تسجيل', () async {
    final cubit = build();

    await cubit.onCode('c2:s1');
    expect(cubit.state.feedback!.kind, ScanFeedbackKind.otherCenter);

    await cubit.onCode('hello');
    expect(cubit.state.feedback!.kind, ScanFeedbackKind.invalidCode);
    expect(cubit.state.feedback!.studentId, isNull);

    await cubit.onCode('c1:s9');
    expect(cubit.state.feedback!.kind, ScanFeedbackKind.notRegistered);
    expect(cubit.state.feedback!.studentId, 's9');

    expect(cubit.state.rejectedCount, 3);
    expect(recorder.scans, isEmpty);
    await cubit.close();
  });

  test('فشل التخزين بيظهر كخطأ ومش بيتحسب حضور', () async {
    final cubit = build(_FailingRecorder());
    await cubit.onCode('c1:s1');

    expect(cubit.state.feedback!.kind, ScanFeedbackKind.storageError);
    expect(cubit.state.presentCount, 0);
    await cubit.close();
  });

  test('تخزين تالف بيوقف المسح بدل ما يتجاهل المشكلة', () async {
    final cubit = build(_CorruptRecorder());
    expect(cubit.state.loadFailed, isTrue);

    await cubit.onCode('c1:s1');
    expect(cubit.state.feedback, isNull);
    await cubit.close();
  });

  test('كل رد له seq أكبر من اللي قبله', () async {
    final cubit = build();
    await cubit.onCode('bad1');
    final first = cubit.state.feedback!.seq;
    await cubit.onCode('bad2');
    expect(cubit.state.feedback!.seq, greaterThan(first));
    await cubit.close();
  });
}
