import '../models/pending_scan.dart';
import '../models/scan_setup.dart';
import 'scan_repository.dart';

/// نسخة اختبارية من [ScanRepository]: بتسجّل كل مسحة بتتكتب، وبترجّع
/// [ScanSetup] جاهز للاختبارات اللي مش عايزة Firestore.
class MockScanRepository implements ScanRepository {
  MockScanRepository({
    this.onWriteAttendance,
    this.onLateAfterMinutes,
    this.onPrepareScanSetup,
    this.onGroupMonthPaymentStatus,
    this.setup,
  });

  final Future<void> Function(PendingScan scan)? onWriteAttendance;
  final Future<int> Function(String centerId)? onLateAfterMinutes;
  final Future<ScanSetup> Function(String sessionId)? onPrepareScanSetup;
  final Future<Map<String, bool>> Function(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  })?
  onGroupMonthPaymentStatus;

  /// لو اتحط، [prepareScanSetup] بيرجّعه من غير أي callback.
  final ScanSetup? setup;

  final List<PendingScan> writes = <PendingScan>[];

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    writes.add(scan);
    await onWriteAttendance?.call(scan);
  }

  @override
  Future<int> lateAfterMinutes(String centerId) =>
      onLateAfterMinutes?.call(centerId) ?? Future.value(15);

  @override
  Future<ScanSetup> prepareScanSetup(String sessionId) {
    final prepared = setup;
    if (prepared != null) return Future.value(prepared);
    return onPrepareScanSetup?.call(sessionId) ??
        (throw UnimplementedError('MockScanRepository.prepareScanSetup'));
  }

  @override
  Future<Map<String, bool>> groupMonthPaymentStatus(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  }) =>
      onGroupMonthPaymentStatus?.call(
        centerId,
        groupId,
        year: year,
        month: month,
      ) ??
      Future.value(const <String, bool>{});
}
