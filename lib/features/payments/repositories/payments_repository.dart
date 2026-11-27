import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../models/payment.dart';

/// المدفوعات النقدية (P1): تسجيل، إلغاء بسبب، إعادة تسجيل، وقراءة.
///
/// * الأدمن بس هو اللي يكتب (الـ Rules هي الحكم). المساعد يقرا لعلامة
///   الدفع في المسح.
/// * الـ id حتمي (`studentId_groupId_yyyyMM`)، فالتسجيل مرتين لنفس الشهر
///   بيرجّع [FailureType.alreadyExists]، وإعادة التسجيل بعد الإلغاء بتحدّث
///   نفس المستند.
/// * مفيش حذف نهائي: الإلغاء منطقي بسبب.
class PaymentsRepository {
  PaymentsRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  /// تسجيل دفعة لطالب في مجموعة عن شهر (بتوقيت الحائط المحلي).
  ///
  /// لو الشهر مسجّل مدفوع بالفعل بترمي [FailureType.alreadyExists]. لو ملغي
  /// بتحدّث نفس المستند بالقيم الجديدة (إعادة تسجيل). المبلغ المقترح في
  /// الواجهة = `monthlyFee` بتاع المجموعة، بس التسجيل يقبل أي مبلغ موجب.
  Future<Payment> recordPayment({
    required String centerId,
    required String studentId,
    required String groupId,
    required int year,
    required int month,
    required double amount,
    String note = '',
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final Payment draft;
      try {
        draft = Payment.create(
          centerId: centerId,
          studentId: studentId,
          groupId: groupId,
          year: year,
          month: month,
          amount: amount,
          note: note,
          recordedBy: uid,
        );
      } on ArgumentError catch (e) {
        throw Failure.validation(e.message.toString());
      }
      final ref = _ref(centerId, draft.id);
      await _db
          .runTransaction((tx) async {
            final snap = await tx.get(ref);
            if (!snap.exists) {
              tx.set(ref, draft.toCreateMap());
              return;
            }
            final data = snap.data();
            if (data == null) throw const Failure.notFound();
            final Payment existing;
            try {
              existing = Payment.fromMap(snap.id, data);
            } on FormatException {
              throw const Failure.unknown();
            }
            if (existing.isPaid) {
              throw const Failure.alreadyExists(
                message:
                    'الشهر ده مسجّل مدفوع بالفعل. لو عايز تغيّره، الغيه الأول.',
              );
            }
            // إعادة تسجيل بعد إلغاء = تحديث نفس المستند.
            tx.update(
              ref,
              Payment.toRerecordMap(
                amount: draft.amount,
                note: draft.note,
                recordedBy: uid,
              ),
            );
          })
          .timeout(timeout);
      return _read(ref);
    });
  }

  /// إلغاء منطقي لدفعة مدفوعة، بسبب إلزامي.
  Future<Payment> cancelPayment(Payment payment, {required String reason}) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      if (!payment.isPaid) {
        throw const Failure.validation('الدفعة ملغاة بالفعل.');
      }
      final Map<String, dynamic> map;
      try {
        map = Payment.toCancelMap(reason: reason, cancelledBy: uid);
      } on ArgumentError catch (e) {
        throw Failure.validation(e.message.toString());
      }
      final ref = _ref(payment.centerId, payment.id);
      await ref.update(map).timeout(timeout);
      return _read(ref);
    });
  }

  /// دفعة (طالب، مجموعة، شهر) بالـ id الحتمي، أو null لو مش موجودة.
  /// ده اللي علامة الدفع في المسح هتقراه.
  Future<Payment?> loadPayment(
    String centerId, {
    required String studentId,
    required String groupId,
    required int year,
    required int month,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final id = FirestoreIds.payment(studentId, groupId, year, month);
      final snap = await _ref(centerId, id).get().timeout(timeout);
      final data = snap.data();
      if (data == null) return null;
      try {
        return Payment.fromMap(snap.id, data);
      } on FormatException {
        return null; // مستند تالف: بنعتبره غير موجود
      }
    });
  }

  /// كل دفعات طالب، الأحدث أولًا (الترتيب في Dart، فمفيش index).
  Future<List<Payment>> loadStudentPayments(String centerId, String studentId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.payments(centerId))
          .where('studentId', isEqualTo: studentId)
          .get()
          .timeout(timeout);
      return _parseAll(snap);
    });
  }

  /// دفعات مجموعة في شهر معيّن، الأحدث أولًا. بيجيب دفعات المجموعة كلها
  /// (فلتر واحد = مفيش composite index) ويفلتر الشهر في Dart.
  Future<List<Payment>> loadGroupMonthPayments(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final key = Payment.monthKey(year, month);
      final snap = await _db
          .collection(FirestorePaths.payments(centerId))
          .where('groupId', isEqualTo: groupId)
          .get()
          .timeout(timeout);
      return _parseAll(snap, month: key);
    });
  }

  List<Payment> _parseAll(
    QuerySnapshot<Map<String, dynamic>> snap, {
    String? month,
  }) {
    final out = <Payment>[];
    for (final doc in snap.docs) {
      try {
        final p = Payment.fromMap(doc.id, doc.data());
        if (month != null && p.month != month) continue;
        out.add(p);
      } on FormatException {
        continue; // مستند تالف: بنتخطاه
      }
    }
    out.sort((a, b) => b.month.compareTo(a.month));
    return out;
  }

  Future<Payment> _read(DocumentReference<Map<String, dynamic>> ref) async {
    final snap = await ref.get().timeout(timeout);
    final data = snap.data();
    if (data == null) throw const Failure.notFound();
    try {
      return Payment.fromMap(snap.id, data);
    } on FormatException {
      throw const Failure.unknown();
    }
  }

  DocumentReference<Map<String, dynamic>> _ref(String centerId, String id) =>
      _db.doc(FirestorePaths.payment(centerId, id));

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}
