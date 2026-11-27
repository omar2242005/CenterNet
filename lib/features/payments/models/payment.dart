import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة الدفعة: مدفوعة أو ملغاة (إلغاء منطقي بسبب، مفيش حذف).
enum PaymentStatus {
  paid('paid'),
  cancelled('cancelled');

  const PaymentStatus(this.wire);

  /// القيمة المخزّنة في Firestore.
  final String wire;

  static PaymentStatus? tryParse(Object? raw) {
    for (final s in PaymentStatus.values) {
      if (s.wire == raw) return s;
    }
    return null;
  }
}

/// مستند `centers/{c}/payments/{id}` — تسجيل دفع نقدي يدوي (P1).
///
/// * الـ id حتمي: `studentId_groupId_yyyyMM` (من [FirestoreIds.payment])،
///   فمستحيل تتسجّل دفعتان لنفس (طالب، مجموعة، شهر).
/// * الأدمن بس هو اللي يسجّل ويلغي. المساعد يقرا بس (علامة الدفع في المسح).
/// * الإلغاء منطقي بسبب ([cancelReason]). إعادة التسجيل بعد الإلغاء =
///   تحديث لنفس المستند (status ترجع paid والقيم الجديدة تتكتب).
/// * الشهر "مدفوع" لو فيه دفعة غير ملغاة، وإلا "غير مدفوع".
class Payment {
  /// أقصى طول للملاحظة.
  static const int maxNoteLength = 300;

  /// أقصى طول لسبب الإلغاء.
  static const int maxCancelReasonLength = 300;

  final String id;
  final String centerId;
  final String studentId;
  final String groupId;

  /// الشهر بصيغة `yyyyMM` (مثال: `202611`). نفس الجزء الأخير من الـ id.
  final String month;

  final double amount;
  final PaymentStatus status;
  final String note;
  final String recordedBy;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? recordedAt;

  /// كلها null طالما الحالة paid. لما تتلغي: مين وإمتى وليه.
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const Payment._({
    required this.id,
    required this.centerId,
    required this.studentId,
    required this.groupId,
    required this.month,
    required this.amount,
    required this.status,
    required this.note,
    required this.recordedBy,
    this.recordedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.cancelReason,
  });

  /// مفتاح الشهر `yyyyMM`. بيرمي ArgumentError لو month مش من 1 لـ 12.
  static String monthKey(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'الشهر من 1 لـ 12');
    }
    return '${year.toString().padLeft(4, '0')}'
        '${month.toString().padLeft(2, '0')}';
  }

  bool get isPaid => status == PaymentStatus.paid;

  /// دفعة جديدة بحالة paid. بيرمي ArgumentError لو أي مدخل غلط.
  factory Payment.create({
    required String centerId,
    required String studentId,
    required String groupId,
    required int year,
    required int month,
    required double amount,
    String note = '',
    required String recordedBy,
  }) {
    // بيرمي ArgumentError لو أي id فيه غير حروف وأرقام، أو month خارج 1-12.
    final id = FirestoreIds.payment(studentId, groupId, year, month);
    FirestorePaths.payment(centerId, id);
    _requireValidAmount(amount);
    final trimmed = note.trim();
    if (trimmed.length > maxNoteLength) {
      throw ArgumentError.value(note, 'note', 'أطول من $maxNoteLength حرف');
    }
    if (recordedBy.isEmpty) {
      throw ArgumentError.value(recordedBy, 'recordedBy', 'مينفعش يكون فاضي');
    }
    return Payment._(
      id: id,
      centerId: centerId,
      studentId: studentId,
      groupId: groupId,
      month: monthKey(year, month),
      amount: amount,
      status: PaymentStatus.paid,
      note: trimmed,
      recordedBy: recordedBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند. بيرمي FormatException لو تالف.
  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final studentId = map['studentId'];
    final groupId = map['groupId'];
    final month = map['month'];
    final recordedBy = map['recordedBy'];
    if (centerId is! String ||
        studentId is! String ||
        groupId is! String ||
        month is! String ||
        recordedBy is! String) {
      throw const FormatException('دفعة ناقصة الحقول الأساسية');
    }
    if (!_monthRegExp.hasMatch(month)) {
      throw const FormatException('شهر الدفعة مش بصيغة yyyyMM');
    }
    final rawAmount = map['amount'];
    if (rawAmount is! num || !rawAmount.isFinite || rawAmount <= 0) {
      throw const FormatException('دفعة من غير مبلغ صالح');
    }
    final status = PaymentStatus.tryParse(map['status']);
    if (status == null) {
      throw const FormatException('حالة دفعة غير معروفة');
    }
    final note = map['note'];
    if (note is! String) {
      throw const FormatException('ملاحظة الدفعة مش نص');
    }
    String? cancelledBy;
    DateTime? cancelledAt;
    String? cancelReason;
    if (status == PaymentStatus.cancelled) {
      final by = map['cancelledBy'];
      final reason = map['cancelReason'];
      if (by is! String || reason is! String) {
        throw const FormatException('دفعة ملغاة من غير بيانات الإلغاء');
      }
      cancelledBy = by;
      cancelledAt = _toDate(map['cancelledAt']);
      cancelReason = reason;
    }
    return Payment._(
      id: id,
      centerId: centerId,
      studentId: studentId,
      groupId: groupId,
      month: month,
      amount: rawAmount.toDouble(),
      status: status,
      note: note,
      recordedBy: recordedBy,
      recordedAt: _toDate(map['recordedAt']),
      cancelledBy: cancelledBy,
      cancelledAt: cancelledAt,
      cancelReason: cancelReason,
    );
  }

  /// الـ map بتاع الإنشاء. [recordedAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? recordedAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'studentId': studentId,
      'groupId': groupId,
      'month': month,
      'amount': amount,
      'status': status.wire,
      'note': note,
      'recordedBy': recordedBy,
      'recordedAt': recordedAt ?? FieldValue.serverTimestamp(),
      'cancelledBy': null,
      'cancelledAt': null,
      'cancelReason': null,
    };
  }

  /// الـ map بتاع الإلغاء المنطقي. [reason] إلزامي (من 1 لـ
  /// [maxCancelReasonLength] حرف بعد القص). بيرمي ArgumentError لو غلط.
  static Map<String, dynamic> toCancelMap({
    required String reason,
    required String cancelledBy,
    Object? cancelledAt,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty || trimmed.length > maxCancelReasonLength) {
      throw ArgumentError.value(
        reason,
        'reason',
        'سبب الإلغاء من 1 لـ $maxCancelReasonLength حرف',
      );
    }
    if (cancelledBy.isEmpty) {
      throw ArgumentError.value(cancelledBy, 'cancelledBy', 'مينفعش يكون فاضي');
    }
    return <String, dynamic>{
      'status': PaymentStatus.cancelled.wire,
      'cancelledBy': cancelledBy,
      'cancelledAt': cancelledAt ?? FieldValue.serverTimestamp(),
      'cancelReason': trimmed,
    };
  }

  /// الـ map بتاع إعادة التسجيل بعد الإلغاء: يرجّع الحالة paid بالقيم
  /// الجديدة ويفضّي بيانات الإلغاء. بيرمي ArgumentError لو غلط.
  static Map<String, dynamic> toRerecordMap({
    required double amount,
    required String note,
    required String recordedBy,
    Object? recordedAt,
  }) {
    _requireValidAmount(amount);
    final trimmed = note.trim();
    if (trimmed.length > maxNoteLength) {
      throw ArgumentError.value(note, 'note', 'أطول من $maxNoteLength حرف');
    }
    if (recordedBy.isEmpty) {
      throw ArgumentError.value(recordedBy, 'recordedBy', 'مينفعش يكون فاضي');
    }
    return <String, dynamic>{
      'status': PaymentStatus.paid.wire,
      'amount': amount,
      'note': trimmed,
      'recordedBy': recordedBy,
      'recordedAt': recordedAt ?? FieldValue.serverTimestamp(),
      'cancelledBy': null,
      'cancelledAt': null,
      'cancelReason': null,
    };
  }

  static final RegExp _monthRegExp = RegExp(r'^\d{4}(0[1-9]|1[0-2])$');

  static void _requireValidAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'لازم يكون أكبر من صفر');
    }
  }

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
