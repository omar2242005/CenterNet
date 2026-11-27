import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/firestore_paths.dart';
import 'package:center_net/features/payments/models/payment.dart';
import 'package:center_net/features/payments/repositories/payments_repository.dart';

final _recordedAt = Timestamp.fromDate(DateTime.utc(2026, 11, 1));
final _cancelledAt = Timestamp.fromDate(DateTime.utc(2026, 11, 2));

Payment makePayment({
  String studentId = 's1',
  String groupId = 'g1',
  int year = 2026,
  int month = 11,
  double amount = 45000,
  bool cancelled = false,
}) {
  final p = Payment.create(
    centerId: 'c1',
    studentId: studentId,
    groupId: groupId,
    year: year,
    month: month,
    amount: amount,
    recordedBy: 'adminA',
  );
  final map = p.toCreateMap(recordedAt: _recordedAt);
  if (cancelled) {
    map.addAll(
      Payment.toCancelMap(
        reason: 'اتسجلت بالغلط',
        cancelledBy: 'adminA',
        cancelledAt: _cancelledAt,
      ),
    );
  }
  return Payment.fromMap(p.id, map);
}

class FakePaymentsRepository implements PaymentsRepository {
  FakePaymentsRepository({
    List<Payment>? payments,
    this.loadFailure,
    this.writeFailure,
  }) : payments = payments ?? <Payment>[];

  /// بيفشّل القراءة.
  Failure? loadFailure;

  /// بيفشّل التسجيل والإلغاء.
  Failure? writeFailure;

  final List<Payment> payments;
  final List<String> calls = <String>[];

  @override
  Future<Payment> recordPayment({
    required String centerId,
    required String studentId,
    required String groupId,
    required int year,
    required int month,
    required double amount,
    String note = '',
  }) async {
    calls.add('record:$studentId:$groupId:${Payment.monthKey(year, month)}');
    final f = writeFailure;
    if (f != null) throw f;
    final id = FirestoreIds.payment(studentId, groupId, year, month);
    final i = payments.indexWhere((p) => p.id == id);
    if (i >= 0 && payments[i].isPaid) {
      throw const Failure.alreadyExists(
        message: 'الشهر ده مسجّل مدفوع بالفعل. لو عايز تغيّره، الغيه الأول.',
      );
    }
    final created = Payment.create(
      centerId: centerId,
      studentId: studentId,
      groupId: groupId,
      year: year,
      month: month,
      amount: amount,
      note: note,
      recordedBy: 'adminA',
    );
    final stored = Payment.fromMap(
      id,
      created.toCreateMap(recordedAt: _recordedAt),
    );
    if (i >= 0) {
      payments[i] = stored;
    } else {
      payments.add(stored);
    }
    return stored;
  }

  @override
  Future<Payment> cancelPayment(
    Payment payment, {
    required String reason,
  }) async {
    calls.add('cancel:${payment.id}');
    final f = writeFailure;
    if (f != null) throw f;
    if (!payment.isPaid) {
      throw const Failure.validation('الدفعة ملغاة بالفعل.');
    }
    final map = payment.toCreateMap(recordedAt: _recordedAt)
      ..addAll(
        Payment.toCancelMap(
          reason: reason,
          cancelledBy: 'adminA',
          cancelledAt: _cancelledAt,
        ),
      );
    final updated = Payment.fromMap(payment.id, map);
    final i = payments.indexWhere((p) => p.id == payment.id);
    if (i >= 0) payments[i] = updated;
    return updated;
  }

  @override
  Future<Payment?> loadPayment(
    String centerId, {
    required String studentId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    final id = FirestoreIds.payment(studentId, groupId, year, month);
    for (final p in payments) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<Payment>> loadStudentPayments(
    String centerId,
    String studentId,
  ) async {
    calls.add('history:$studentId');
    final f = loadFailure;
    if (f != null) throw f;
    final out = payments
        .where((p) => p.studentId == studentId)
        .toList(growable: false);
    out.sort((a, b) => b.month.compareTo(a.month));
    return out;
  }

  @override
  Future<List<Payment>> loadMonthPayments(
    String centerId, {
    required int year,
    required int month,
  }) async {
    calls.add('month:${Payment.monthKey(year, month)}');
    final f = loadFailure;
    if (f != null) throw f;
    final key = Payment.monthKey(year, month);
    final out = payments.where((p) => p.month == key).toList(growable: false);
    out.sort((a, b) => b.month.compareTo(a.month));
    return out;
  }

  @override
  Future<List<Payment>> loadGroupMonthPayments(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  }) async {
    final key = Payment.monthKey(year, month);
    return payments
        .where((p) => p.groupId == groupId && p.month == key)
        .toList(growable: false);
  }
}
