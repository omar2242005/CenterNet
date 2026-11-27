import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/payments/models/payment.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  Payment make({
    String centerId = 'c1',
    String studentId = 's7',
    String groupId = 'g1',
    int year = 2026,
    int month = 11,
    double amount = 450,
    String note = '',
    String recordedBy = 'adminA',
  }) => Payment.create(
    centerId: centerId,
    studentId: studentId,
    groupId: groupId,
    year: year,
    month: month,
    amount: amount,
    note: note,
    recordedBy: recordedBy,
  );

  group('monthKey', () {
    test('بتعمل yyyyMM بصفر بادئ', () {
      expect(Payment.monthKey(2026, 1), '202601');
      expect(Payment.monthKey(2026, 11), '202611');
    });

    test('بترفض شهر خارج 1-12', () {
      expect(() => Payment.monthKey(2026, 0), throwsArgumentError);
      expect(() => Payment.monthKey(2026, 13), throwsArgumentError);
    });
  });

  group('create', () {
    test('الـ id حتمي sid_gid_yyyyMM والحالة paid وبيانات الإلغاء فاضية', () {
      final p = make();
      expect(p.id, 's7_g1_202611');
      expect(p.month, '202611');
      expect(p.status, PaymentStatus.paid);
      expect(p.isPaid, isTrue);
      expect(p.cancelledBy, isNull);
      expect(p.cancelledAt, isNull);
      expect(p.cancelReason, isNull);
    });

    test('بيقص الملاحظة', () {
      expect(make(note: '  كاش  ').note, 'كاش');
    });

    test('بيرفض ids فيها _ أو فاضية', () {
      expect(() => make(centerId: 'c_1'), throwsArgumentError);
      expect(() => make(studentId: ''), throwsArgumentError);
      expect(() => make(groupId: 'g_1'), throwsArgumentError);
    });

    test('بيرفض شهر خارج 1-12', () {
      expect(() => make(month: 0), throwsArgumentError);
      expect(() => make(month: 13), throwsArgumentError);
    });

    test('المبلغ لازم أكبر من صفر', () {
      expect(() => make(amount: 0), throwsArgumentError);
      expect(() => make(amount: -5), throwsArgumentError);
      expect(() => make(amount: double.nan), throwsArgumentError);
      expect(() => make(amount: double.infinity), throwsArgumentError);
      expect(make(amount: 0.5).amount, 0.5);
    });

    test('بيرفض ملاحظة أطول من 300 حرف وrecordedBy فاضي', () {
      expect(() => make(note: 'ا' * 301), throwsArgumentError);
      expect(make(note: 'ا' * 300).note.length, 300);
      expect(() => make(recordedBy: ''), throwsArgumentError);
    });
  });

  group('toCreateMap', () {
    test('فيه كل الحقول والحالة paid وبيانات إلغاء null', () {
      final m = make().toCreateMap(recordedAt: fakeServerTime);
      expect(m['centerId'], 'c1');
      expect(m['studentId'], 's7');
      expect(m['groupId'], 'g1');
      expect(m['month'], '202611');
      expect(m['amount'], 450);
      expect(m['status'], 'paid');
      expect(m['note'], '');
      expect(m['recordedBy'], 'adminA');
      expect(m['recordedAt'], fakeServerTime);
      expect(m['cancelledBy'], isNull);
      expect(m['cancelledAt'], isNull);
      expect(m['cancelReason'], isNull);
    });
  });

  group('toCancelMap', () {
    test('بيقص السبب ويكتب بيانات الإلغاء', () {
      final m = Payment.toCancelMap(
        reason: '  اتسجلت بالغلط  ',
        cancelledBy: 'adminA',
        cancelledAt: fakeServerTime,
      );
      expect(m['status'], 'cancelled');
      expect(m['cancelledBy'], 'adminA');
      expect(m['cancelledAt'], fakeServerTime);
      expect(m['cancelReason'], 'اتسجلت بالغلط');
    });

    test('السبب إلزامي وبحد أقصى 300 حرف', () {
      expect(
        () => Payment.toCancelMap(reason: '   ', cancelledBy: 'adminA'),
        throwsArgumentError,
      );
      expect(
        () => Payment.toCancelMap(reason: 'ا' * 301, cancelledBy: 'adminA'),
        throwsArgumentError,
      );
      expect(
        () => Payment.toCancelMap(reason: 'سبب', cancelledBy: ''),
        throwsArgumentError,
      );
    });
  });

  group('toRerecordMap', () {
    test('بيرجّع paid بالقيم الجديدة وبيفضّي بيانات الإلغاء', () {
      final m = Payment.toRerecordMap(
        amount: 500,
        note: '  تصحيح  ',
        recordedBy: 'adminA',
        recordedAt: fakeServerTime,
      );
      expect(m['status'], 'paid');
      expect(m['amount'], 500);
      expect(m['note'], 'تصحيح');
      expect(m['recordedBy'], 'adminA');
      expect(m['recordedAt'], fakeServerTime);
      expect(m['cancelledBy'], isNull);
      expect(m['cancelledAt'], isNull);
      expect(m['cancelReason'], isNull);
    });

    test('بيرفض مبلغ مش موجب', () {
      expect(
        () => Payment.toRerecordMap(amount: 0, note: '', recordedBy: 'a'),
        throwsArgumentError,
      );
    });
  });

  group('fromMap', () {
    Map<String, dynamic> createMap() =>
        make().toCreateMap(recordedAt: fakeServerTime);

    test('رحلة كاملة create -> map -> fromMap', () {
      final p = Payment.fromMap('s7_g1_202611', createMap());
      expect(p.id, 's7_g1_202611');
      expect(p.centerId, 'c1');
      expect(p.month, '202611');
      expect(p.amount, 450);
      expect(p.isPaid, isTrue);
      expect(p.recordedAt, fakeServerTime.toDate());
    });

    test('دفعة ملغاة بتتقري ببيانات الإلغاء', () {
      final m = createMap()
        ..addAll(
          Payment.toCancelMap(
            reason: 'غلط',
            cancelledBy: 'adminA',
            cancelledAt: fakeServerTime,
          ),
        );
      final p = Payment.fromMap('s7_g1_202611', m);
      expect(p.status, PaymentStatus.cancelled);
      expect(p.isPaid, isFalse);
      expect(p.cancelledBy, 'adminA');
      expect(p.cancelReason, 'غلط');
      expect(p.cancelledAt, fakeServerTime.toDate());
    });

    test('بيرفض مستند ناقص أو تالف', () {
      expect(
        () => Payment.fromMap('x', <String, dynamic>{}),
        throwsFormatException,
      );
      expect(
        () => Payment.fromMap('x', createMap()..['month'] = '20261'),
        throwsFormatException,
      );
      expect(
        () => Payment.fromMap('x', createMap()..['month'] = '202613'),
        throwsFormatException,
      );
      expect(
        () => Payment.fromMap('x', createMap()..['amount'] = 0),
        throwsFormatException,
      );
      expect(
        () => Payment.fromMap('x', createMap()..['status'] = 'pending'),
        throwsFormatException,
      );
      expect(
        () => Payment.fromMap('x', createMap()..['status'] = 'cancelled'),
        throwsFormatException, // ملغاة من غير بيانات إلغاء
      );
    });

    test('recordedAt مش timestamp بتبقى null (كاش محلي)', () {
      final p = Payment.fromMap('x', createMap()..['recordedAt'] = null);
      expect(p.recordedAt, isNull);
    });
  });
}
