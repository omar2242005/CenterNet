import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة الحضور. القيمة المكتوبة في Firestore = [wire].
enum AttendanceStatus {
  present('present'),
  lateArrival('late'),
  excused('excused');

  const AttendanceStatus(this.wire);
  final String wire;

  static AttendanceStatus parse(Object? raw) {
    for (final s in AttendanceStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة حضور غير معروفة: $raw');
  }
}

/// حالة السداد وقت المسح (P1-خطوة4). بتتخزن في سجل الحضور لحظة التسجيل
/// ومش بتتغير لو الطالب دفع بعدها؛ حالة \"لسه عليه فلوس دلوقتي\" مصدرها
/// مجموعة payments/paymentStatus مش سجل الحضور.
///
/// unknown = المسح حصل أوفلاين أو علامة الشهر ما كانتش متاحة (مش معناها
/// غير مدفوع).
enum ScanPaymentStatus {
  paid('paid'),
  unpaid('unpaid'),
  unknown('unknown');

  const ScanPaymentStatus(this.wire);
  final String wire;

  /// المستندات القديمة (قبل خطوة 4) من غير الحقل بتقرا unknown.
  static ScanPaymentStatus parse(Object? raw) {
    for (final s in ScanPaymentStatus.values) {
      if (s.wire == raw) return s;
    }
    return ScanPaymentStatus.unknown;
  }
}

/// طريقة التسجيل.
enum AttendanceMethod {
  qr('qr'),
  manual('manual');

  const AttendanceMethod(this.wire);
  final String wire;

  static AttendanceMethod parse(Object? raw) {
    for (final m in AttendanceMethod.values) {
      if (m.wire == raw) return m;
    }
    throw FormatException('طريقة تسجيل غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/attendance/{sessionId_sid}`.
///
/// * الـ id حتمي من [FirestoreIds.attendance]، فالتكرار مستحيل (create فقط).
/// * `sessionId` و`studentId` متخزنين كحقول كمان (مش بس جوه الـ id) عشان
///   الاستعلامات: حضور جلسة، وحضور طالب (ولي الأمر لازم يحمل studentId).
/// * مفيش حذف نهائي أبدًا. الإلغاء = [toVoidMap] مع السبب ومن ومتى.
/// * `recordedAt` = serverTimestamp. `scannedAt` = وقت الجهاز لحظة المسح،
///   وهو اللي بيتحسب منه حاضر/متأخر.
class Attendance {
  final String id;
  final String centerId;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final AttendanceMethod method;

  /// وقت المسح بساعة الجهاز (للمسح بالـ QR فقط).
  final DateTime? scannedAt;
  final String recordedBy;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? recordedAt;

  final bool voided;
  final String? voidedBy;
  final String? voidReason;
  final DateTime? voidedAt;

  /// حالة السداد لحظة التسجيل. مستندات ما قبل خطوة 4 بتقرا unknown.
  final ScanPaymentStatus paymentStatus;

  const Attendance._({
    required this.id,
    required this.centerId,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.method,
    required this.recordedBy,
    this.scannedAt,
    this.recordedAt,
    this.voided = false,
    this.voidedBy,
    this.voidReason,
    this.voidedAt,
    this.paymentStatus = ScanPaymentStatus.unknown,
  });

  /// تسجيل حضور جديد. الـ id بيتحسب من [sessionId] و[studentId].
  factory Attendance.create({
    required String centerId,
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    required AttendanceMethod method,
    required String recordedBy,
    DateTime? scannedAt,
    ScanPaymentStatus paymentStatus = ScanPaymentStatus.unknown,
  }) {
    if (centerId.isEmpty) {
      throw ArgumentError.value(centerId, 'centerId', 'مينفعش يكون فاضي');
    }
    if (recordedBy.isEmpty) {
      throw ArgumentError.value(recordedBy, 'recordedBy', 'مينفعش يكون فاضي');
    }
    if (method == AttendanceMethod.qr && scannedAt == null) {
      throw ArgumentError.notNull('scannedAt');
    }
    return Attendance._(
      id: FirestoreIds.attendance(sessionId, studentId),
      centerId: centerId,
      sessionId: sessionId,
      studentId: studentId,
      status: status,
      method: method,
      scannedAt: scannedAt,
      recordedBy: recordedBy,
      paymentStatus: paymentStatus,
    );
  }

  /// قراءة مستند. [id] هو id المستند.
  factory Attendance.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final sessionId = map['sessionId'];
    final studentId = map['studentId'];
    final recordedBy = map['recordedBy'];
    if (centerId is! String ||
        sessionId is! String ||
        studentId is! String ||
        recordedBy is! String) {
      throw const FormatException(
        'حضور ناقص centerId أو sessionId أو studentId أو recordedBy',
      );
    }
    final voidedBy = map['voidedBy'];
    final voidReason = map['voidReason'];
    return Attendance._(
      id: id,
      centerId: centerId,
      sessionId: sessionId,
      studentId: studentId,
      status: AttendanceStatus.parse(map['status']),
      method: AttendanceMethod.parse(map['method']),
      scannedAt: _toDate(map['scannedAt']),
      recordedBy: recordedBy,
      recordedAt: _toDate(map['recordedAt']),
      voided: map['voided'] == true,
      voidedBy: voidedBy is String ? voidedBy : null,
      voidReason: voidReason is String ? voidReason : null,
      voidedAt: _toDate(map['voidedAt']),
      paymentStatus: ScanPaymentStatus.parse(map['paymentStatus']),
    );
  }

  /// الـ map بتاع الإنشاء (create فقط).
  ///
  /// حقول الإلغاء بتتكتب بقيمها الابتدائية صراحة (voided=false والباقي null)
  /// عشان الـ Rules تتحقق منها. [recordedAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? recordedAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status.wire,
      'method': method.wire,
      if (scannedAt != null) 'scannedAt': Timestamp.fromDate(scannedAt!),
      'recordedBy': recordedBy,
      'recordedAt': recordedAt ?? FieldValue.serverTimestamp(),
      'voided': false,
      'voidedBy': null,
      'voidReason': null,
      'voidedAt': null,
      'paymentStatus': paymentStatus.wire,
    };
  }

  /// الـ map بتاع الإلغاء: update لحقول الإلغاء فقط، ومن غير حذف.
  /// السبب إلزامي. [voidedAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  static Map<String, dynamic> toVoidMap({
    required String voidedBy,
    required String reason,
    Object? voidedAt,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'سبب الإلغاء إلزامي');
    }
    if (voidedBy.isEmpty) {
      throw ArgumentError.value(voidedBy, 'voidedBy', 'مينفعش يكون فاضي');
    }
    return <String, dynamic>{
      'voided': true,
      'voidedBy': voidedBy,
      'voidReason': trimmed,
      'voidedAt': voidedAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// سجل شغّال (مش ملغي).
  bool get isActive => !voided;

  /// بيتحسب في "حضر" (حاضر أو متأخر وغير ملغي).
  bool get countsAsAttended =>
      !voided &&
      (status == AttendanceStatus.present || status == AttendanceStatus.lateArrival);

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
