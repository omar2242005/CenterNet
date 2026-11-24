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
