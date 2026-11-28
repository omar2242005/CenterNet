import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/attendance/models/attendance.dart';

void main() {
  final scanned = DateTime.utc(2026, 11, 19, 15, 5);
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 19, 15, 6));

  Attendance qr({
    AttendanceStatus status = AttendanceStatus.present,
    ScanPaymentStatus paymentStatus = ScanPaymentStatus.unknown,
  }) =>
      Attendance.create(
        centerId: 'c1',
        sessionId: 'g1_20261119_1700',
        studentId: 's7',
        status: status,
        method: AttendanceMethod.qr,
        recordedBy: 'asst1',
        scannedAt: scanned,
        paymentStatus: paymentStatus,
      );

  Attendance manual() => Attendance.create(
        centerId: 'c1',
        sessionId: 'g1_20261119_1700',
        studentId: 's7',
        status: AttendanceStatus.excused,
        method: AttendanceMethod.manual,
        recordedBy: 'teacher1',
      );

  group('create', () {
    test('الـ id حتمي بصيغة sessionId_sid', () {
      expect(qr().id, 'g1_20261119_1700_s7');
    });

    test('QR من غير scannedAt مرفوض', () {
      expect(
        () => Attendance.create(
          centerId: 'c1',
          sessionId: 'g1_20261119_1700',
          studentId: 's7',
          status: AttendanceStatus.present,
          method: AttendanceMethod.qr,
          recordedBy: 'asst1',
        ),
        throwsArgumentError,
      );
    });

    test('studentId فيه _ مرفوض', () {
      expect(
        () => Attendance.create(
          centerId: 'c1',
          sessionId: 'g1_20261119_1700',
          studentId: 's_7',
          status: AttendanceStatus.present,
          method: AttendanceMethod.manual,
          recordedBy: 'teacher1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('toCreateMap', () {
    test('QR: الحقول المتوقعة بالظبط', () {
      final m = qr().toCreateMap(recordedAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'sessionId', 'studentId', 'status', 'method',
        'scannedAt', 'recordedBy', 'recordedAt',
        'voided', 'voidedBy', 'voidReason', 'voidedAt',
        'paymentStatus',
      });
      expect(m['status'], 'present');
      expect(m['method'], 'qr');
    });

    test('اليدوي: من غير scannedAt', () {
      final m = manual().toCreateMap(recordedAt: fakeServerTime);
      expect(m.containsKey('scannedAt'), isFalse);
      expect(m['status'], 'excused');
      expect(m['method'], 'manual');
    });

    test('حالة السداد بتتكتب، والافتراضي unknown', () {
      expect(qr().toCreateMap()['paymentStatus'], 'unknown');
      expect(
        qr(paymentStatus: ScanPaymentStatus.paid).toCreateMap()['paymentStatus'],
        'paid',
      );
    });

    test('حقول الإلغاء بقيمها الابتدائية صراحة (الـ Rules محتاجاها)', () {
      final m = qr().toCreateMap(recordedAt: fakeServerTime);
      expect(m['voided'], false);
      for (final k in ['voidedBy', 'voidReason', 'voidedAt']) {
        expect(m.containsKey(k), isTrue);
        expect(m[k], isNull);
      }
    });
  });

  group('fromMap', () {
    test('round trip', () {
      final original = qr(status: AttendanceStatus.lateArrival);
      final back = Attendance.fromMap(
        original.id,
        original.toCreateMap(recordedAt: fakeServerTime),
      );
      expect(back.id, original.id);
      expect(back.sessionId, 'g1_20261119_1700');
      expect(back.studentId, 's7');
      expect(back.status, AttendanceStatus.lateArrival);
      expect(back.method, AttendanceMethod.qr);
      expect(back.scannedAt!.isAtSameMomentAs(scanned), isTrue);
      expect(back.recordedBy, 'asst1');
      expect(back.recordedAt, isNotNull);
      expect(back.voided, isFalse);
      expect(back.voidedBy, isNull);
    });

    test('مستند قديم من غير paymentStatus بيتقرا unknown', () {
      final m = qr(paymentStatus: ScanPaymentStatus.unpaid).toCreateMap(
        recordedAt: fakeServerTime,
      );
      expect(Attendance.fromMap('x', m).paymentStatus, ScanPaymentStatus.unpaid);
      m.remove('paymentStatus');
      expect(
        Attendance.fromMap('x', m).paymentStatus,
        ScanPaymentStatus.unknown,
      );
    });

    test('recordedAt = null لو السيرفر لسه ماكتبش الوقت', () {
      final m = qr().toCreateMap(recordedAt: fakeServerTime)
        ..['recordedAt'] = null;
      expect(Attendance.fromMap('x', m).recordedAt, isNull);
    });

    test('بترمي FormatException لو ناقص حقل أو قيمة غريبة', () {
      final good = qr().toCreateMap(recordedAt: fakeServerTime);
      expect(
        () => Attendance.fromMap('x', {...good}..remove('studentId')),
        throwsFormatException,
      );
      expect(
        () => Attendance.fromMap('x', {...good, 'status': 'weird'}),
        throwsFormatException,
      );
      expect(
        () => Attendance.fromMap('x', {...good, 'method': 'weird'}),
        throwsFormatException,
      );
    });
  });

  group('الإلغاء', () {
    test('toVoidMap: حقول الإلغاء فقط، والسبب بيتقص', () {
      final m = Attendance.toVoidMap(
        voidedBy: 'teacher1',
        reason: '  مسح بالغلط  ',
        voidedAt: fakeServerTime,
      );
      expect(m.keys.toSet(), {'voided', 'voidedBy', 'voidReason', 'voidedAt'});
      expect(m['voided'], true);
      expect(m['voidReason'], 'مسح بالغلط');
    });

    test('السبب الفاضي مرفوض', () {
      expect(
        () => Attendance.toVoidMap(voidedBy: 'teacher1', reason: '   '),
        throwsArgumentError,
      );
    });

    test('سجل ملغي بيتقرا صح ومابيتحسبش حضور', () {
      final voidedMap = {
        ...qr().toCreateMap(recordedAt: fakeServerTime),
        ...Attendance.toVoidMap(
          voidedBy: 'teacher1',
          reason: 'غلط',
          voidedAt: fakeServerTime,
        ),
      };
      final a = Attendance.fromMap('g1_20261119_1700_s7', voidedMap);
      expect(a.voided, isTrue);
      expect(a.voidedBy, 'teacher1');
      expect(a.voidReason, 'غلط');
      expect(a.voidedAt, isNotNull);
      expect(a.isActive, isFalse);
      expect(a.countsAsAttended, isFalse);
    });
  });

  group('countsAsAttended', () {
    test('حاضر ومتأخر بيتحسبوا، بعذر لا', () {
      expect(qr().countsAsAttended, isTrue);
      expect(qr(status: AttendanceStatus.lateArrival).countsAsAttended, isTrue);
      expect(manual().countsAsAttended, isFalse); // excused
    });
  });
}
