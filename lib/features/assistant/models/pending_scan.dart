import 'attendance.dart';

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

/// حالة الحضور التي ستُكتب لاحقًا عند مزامنة المسحة.
///
/// مستقلة عن [PendingScanStatus]، لأن الأخيرة تصف حالة الرفع المحلي وليس
/// حضور الطالب نفسه. لا نستخدم `AttendanceStatus` هنا كي يظل نموذج المسحات
/// المحلية خفيفًا وغير مرتبط بـ Firestore.
enum PendingAttendanceStatus {
  present('present'),
  late('late');

  const PendingAttendanceStatus(this.wire);
  final String wire;

  static PendingAttendanceStatus parse(Object? raw) {
    for (final status in values) {
      if (status.wire == raw) return status;
    }
    throw FormatException('حالة حضور المسحة غير معروفة: $raw');
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
  final String? centerId;
  final PendingAttendanceStatus? attendanceStatus;

  /// حالة السداد لحظة المسح (بتتخزن في سجل الحضور عند المزامنة). المسحات
  /// المحفوظة قبل خطوة 4 بتقرا unknown.
  final ScanPaymentStatus paymentStatus;

  const PendingScan({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.scannedAt,
    this.status = PendingScanStatus.pending,
    this.failReason,
    this.centerId,
    this.attendanceStatus,
    this.paymentStatus = ScanPaymentStatus.unknown,
  });

  PendingScan copyWith({
    PendingScanStatus? status,
    String? failReason,
    String? centerId,
    PendingAttendanceStatus? attendanceStatus,
    ScanPaymentStatus? paymentStatus,
  }) => PendingScan(
    id: id,
    sessionId: sessionId,
    studentId: studentId,
    scannedAt: scannedAt,
    status: status ?? this.status,
    failReason: failReason,
    centerId: centerId ?? this.centerId,
    attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    paymentStatus: paymentStatus ?? this.paymentStatus,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'sessionId': sessionId,
    'studentId': studentId,
    'scannedAt': scannedAt.toUtc().toIso8601String(),
    'status': status.wire,
    'failReason': failReason,
    if (centerId != null) 'centerId': centerId,
    if (attendanceStatus != null) 'attendanceStatus': attendanceStatus!.wire,
    'paymentStatus': paymentStatus.wire,
  };

  factory PendingScan.fromMap(Map<String, dynamic> m) {
    final id = m['id'];
    final sessionId = m['sessionId'];
    final studentId = m['studentId'];
    final at = m['scannedAt'];
    final centerId = m['centerId'];
    final attendanceStatus = m['attendanceStatus'];
    if (id is! String ||
        sessionId is! String ||
        studentId is! String ||
        at is! String) {
      throw const FormatException('مسحة محلية ناقصة حقول');
    }
    if (centerId != null && (centerId is! String || centerId.isEmpty)) {
      throw const FormatException('centerId للمسحة غير صالح');
    }
    if (attendanceStatus != null && attendanceStatus is! String) {
      throw const FormatException('attendanceStatus للمسحة غير صالح');
    }
    return PendingScan(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      scannedAt: DateTime.parse(at),
      status: PendingScanStatus.parse(m['status']),
      failReason: m['failReason'] as String?,
      centerId: centerId as String?,
      attendanceStatus: attendanceStatus == null
          ? null
          : PendingAttendanceStatus.parse(attendanceStatus),
      paymentStatus: ScanPaymentStatus.parse(m['paymentStatus']),
    );
  }
}
