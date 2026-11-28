import 'package:center_net/features/attendance/models/attendance.dart';
import 'package:center_net/features/scan/models/pending_scan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PendingScan scan({
    String? centerId,
    PendingAttendanceStatus? attendanceStatus,
    PendingScanStatus status = PendingScanStatus.pending,
    ScanPaymentStatus paymentStatus = ScanPaymentStatus.unknown,
  }) => PendingScan(
    id: 'g1_20261119_1700_s1',
    sessionId: 'g1_20261119_1700',
    studentId: 's1',
    scannedAt: DateTime.utc(2026, 11, 19, 15, 5),
    centerId: centerId,
    attendanceStatus: attendanceStatus,
    status: status,
    paymentStatus: paymentStatus,
  );

  test('سجل قديم من غير الحقول الجديدة بيتقرا كما هو', () {
    final legacy = <String, dynamic>{
      'id': 'g1_20261119_1700_s1',
      'sessionId': 'g1_20261119_1700',
      'studentId': 's1',
      'scannedAt': '2026-11-19T15:05:00.000Z',
      'status': 'pending',
      'failReason': null,
    };

    final result = PendingScan.fromMap(legacy);
    expect(result.centerId, isNull);
    expect(result.attendanceStatus, isNull);
    expect(result.paymentStatus, ScanPaymentStatus.unknown);
    // إعادة الحفظ بتضيف حقل السداد (الـ Rules بتطلبه عند المزامنة).
    expect(result.toMap(), {...legacy, 'paymentStatus': 'unknown'});
  });

  test('round-trip يحتفظ بحالة السداد وقت المسح', () {
    final original = scan(paymentStatus: ScanPaymentStatus.unpaid);

    final result = PendingScan.fromMap(original.toMap());
    expect(result.paymentStatus, ScanPaymentStatus.unpaid);
    expect(result.toMap(), original.toMap());
  });

  test('round-trip يحتفظ بحقول المزامنة الجديدة', () {
    final original = scan(
      centerId: 'c1',
      attendanceStatus: PendingAttendanceStatus.late,
      status: PendingScanStatus.failed,
    );

    final result = PendingScan.fromMap(original.toMap());
    expect(result.centerId, 'c1');
    expect(result.attendanceStatus, PendingAttendanceStatus.late);
    expect(result.status, PendingScanStatus.failed);
    expect(result.scannedAt, original.scannedAt);
  });

  test('قيم الحقول الجديدة غير الصالحة مرفوضة', () {
    final valid = scan().toMap();
    expect(
      () => PendingScan.fromMap({...valid, 'centerId': ''}),
      throwsFormatException,
    );
    expect(
      () => PendingScan.fromMap({...valid, 'centerId': 1}),
      throwsFormatException,
    );
    expect(
      () => PendingScan.fromMap({...valid, 'attendanceStatus': 'excused'}),
      throwsFormatException,
    );
    expect(
      () => PendingScan.fromMap({...valid, 'attendanceStatus': 1}),
      throwsFormatException,
    );
  });

  test('copyWith يحافظ على الحقول الجديدة ويقبل تعديلها', () {
    final original = scan(
      centerId: 'c1',
      attendanceStatus: PendingAttendanceStatus.present,
    );
    expect(original.copyWith(status: PendingScanStatus.synced).centerId, 'c1');
    expect(
      original
          .copyWith(attendanceStatus: PendingAttendanceStatus.late)
          .attendanceStatus,
      PendingAttendanceStatus.late,
    );
  });
}
