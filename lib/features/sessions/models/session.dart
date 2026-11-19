import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة الجلسة. القيمة المكتوبة في Firestore = [wire].
enum SessionStatus {
  scheduled('scheduled'),
  cancelled('cancelled');

  const SessionStatus(this.wire);
  final String wire;

  static SessionStatus parse(Object? raw) {
    for (final s in SessionStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة جلسة غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/sessions/{gid_yyyyMMdd_HHmm}`.
///
/// * الـ id حتمي من [FirestoreIds.session] بتوقيت القاهرة، فإعادة توليد
///   الجلسات مش بتكرر (set على نفس الـ id).
/// * `startAt` و`endAt` بيتخزنوا Timestamp (لحظة زمنية). عرض الوقت بتوقيت
///   القاهرة مسؤولية الشاشة (حزمة timezone)، مش الموديل.
/// * مفيش غياب مخزّن: الغياب بيتحسب بعد انتهاء الحصة ([isCountedAt]).
class Session {
  final String id;
  final String centerId;
  final String groupId;
  final DateTime startAt;
  final DateTime endAt;
  final SessionStatus status;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;
  final String createdBy;

  const Session._({
    required this.id,
    required this.centerId,
    required this.groupId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.createdBy,
    this.createdAt,
  });

  /// جلسة جديدة. [cairoStart] لازم وقت حائط بتوقيت القاهرة (TZDateTime)،
  /// ومش UTC، وإلا [FirestoreIds.session] بترمي ArgumentError.
  factory Session.create({
    required String centerId,
    required String groupId,
    required DateTime cairoStart,
    required DateTime cairoEnd,
    required String createdBy,
  }) {
    if (centerId.isEmpty) {
      throw ArgumentError.value(centerId, 'centerId', 'مينفعش يكون فاضي');
    }
    if (createdBy.isEmpty) {
      throw ArgumentError.value(createdBy, 'createdBy', 'مينفعش يكون فاضي');
    }
    if (!cairoEnd.isAfter(cairoStart)) {
      throw ArgumentError.value(
        cairoEnd,
        'cairoEnd',
        'نهاية الحصة لازم تبقى بعد بدايتها',
      );
    }
    return Session._(
      id: FirestoreIds.session(groupId, cairoStart),
      centerId: centerId,
      groupId: groupId,
      startAt: cairoStart,
      endAt: cairoEnd,
      status: SessionStatus.scheduled,
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند.
  factory Session.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final groupId = map['groupId'];
    final createdBy = map['createdBy'];
    if (centerId is! String || groupId is! String || createdBy is! String) {
      throw const FormatException('جلسة ناقصة centerId أو groupId أو createdBy');
    }
    final start = _toDate(map['startAt']);
    final end = _toDate(map['endAt']);
    if (start == null || end == null) {
      throw const FormatException('جلسة من غير startAt أو endAt');
    }
    return Session._(
      id: id,
      centerId: centerId,
      groupId: groupId,
      startAt: start,
      endAt: end,
      status: SessionStatus.parse(map['status']),
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء. [createdAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'groupId': groupId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status.wire,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// الـ map بتاع إلغاء الجلسة (update لحقل الحالة بس).
  static Map<String, dynamic> toCancelMap() =>
      <String, dynamic>{'status': SessionStatus.cancelled.wire};

  bool get isCancelled => status == SessionStatus.cancelled;

  /// "جلسة محتسبة" = مش ملغاة وانتهت (أساس حساب الغياب).
  bool isCountedAt(DateTime now) => !isCancelled && !endAt.isAfter(now);

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
