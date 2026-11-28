import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/scan/rules/scan_validator.dart';

void main() {
  final start = DateTime(2026, 11, 19, 17);
  final onTime = DateTime(2026, 11, 19, 17, 5);

  ScanValidator make({
    Set<String> students = const {'s1', 's2', 's7'},
    int lateAfter = 15,
  }) =>
      ScanValidator(
        centerId: 'c1',
        sessionStart: start,
        groupStudentIds: students,
        lateAfterMinutes: lateAfter,
      );

  ExistingAttendance none(String sid) => ExistingAttendance.none;

  group('1) رمز غير صالح', () {
    for (final raw in [
      '',
      'c1',
      'c1:',
      ':s7',
      'c1:s7:x',
      ' c1:s7',
      'c1:s7 ',
      'c1:s_7',
      'مركز:s7',
      'hello world',
    ]) {
      test('"$raw" مرفوض', () {
        final r = make().validate(raw, now: onTime, existingOf: none);
        expect(r.outcome, ScanOutcome.invalidCode);
        expect(r.studentId, isNull);
        expect(r.shouldWrite, isFalse);
      });
    }
  });

  group('2) مركز آخر', () {
    test('centerId مختلف', () {
      final r = make().validate('c2:s7', now: onTime, existingOf: none);
      expect(r, const ScanResult.otherCenter('s7'));
      expect(r.shouldWrite, isFalse);
    });

    test('أولوية على "غير مسجل" (طالب مش في المجموعة أصلًا)', () {
      final r = make().validate('c2:s99', now: onTime, existingOf: none);
      expect(r.outcome, ScanOutcome.otherCenter);
    });

    test('مبيسألش عن الحضور الموجود', () {
      make().validate(
        'c2:s7',
        now: onTime,
        existingOf: (_) => fail('مفروض مانسألش'),
      );
    });
  });

  group('3) غير مسجل', () {
    test('طالب مش في مجموعة الجلسة', () {
      final r = make().validate('c1:s99', now: onTime, existingOf: none);
      expect(r, const ScanResult.notRegistered('s99'));
      expect(r.shouldWrite, isFalse);
    });

    test('مجموعة فاضية = كله غير مسجل', () {
      final r = make(students: const {}).validate(
        'c1:s7',
        now: onTime,
        existingOf: none,
      );
      expect(r.outcome, ScanOutcome.notRegistered);
    });

    test('مبيسألش عن الحضور الموجود', () {
      make().validate(
        'c1:s99',
        now: onTime,
        existingOf: (_) => fail('مفروض مانسألش'),
      );
    });
  });

  group('4) مسجل بالفعل', () {
    test('سجل شغّال', () {
      final r = make().validate(
        'c1:s7',
        now: onTime,
        existingOf: (_) => ExistingAttendance.active,
      );
      expect(r, const ScanResult.alreadyRegistered('s7'));
      expect(r.wasVoided, isFalse);
      expect(r.shouldWrite, isFalse);
    });

    test('سجل ملغي = ملغى سابقًا (من غير تسجيل تلقائي)', () {
      final r = make().validate(
        'c1:s7',
        now: onTime,
        existingOf: (_) => ExistingAttendance.voided,
      );
      expect(r, const ScanResult.alreadyRegistered('s7', wasVoided: true));
      expect(r.shouldWrite, isFalse);
    });

    test('بيسأل عن الطالب الصح', () {
      String? asked;
      make().validate(
        'c1:s2',
        now: onTime,
        existingOf: (sid) {
          asked = sid;
          return ExistingAttendance.none;
        },
      );
      expect(asked, 's2');
    });
  });

  group('5) تم التسجيل (حاضر/متأخر)', () {
    ScanResult at(DateTime now, {int lateAfter = 15}) => make(
          lateAfter: lateAfter,
        ).validate('c1:s7', now: now, existingOf: none);

    test('قبل بداية الحصة = حاضر', () {
      final r = at(DateTime(2026, 11, 19, 16, 30));
      expect(r, const ScanResult.recorded('s7', ScanTiming.present));
      expect(r.shouldWrite, isTrue);
    });

    test('لحظة البداية = حاضر', () {
      expect(at(start).timing, ScanTiming.present);
    });

    test('بعد 14 دقيقة = حاضر', () {
      expect(at(DateTime(2026, 11, 19, 17, 14)).timing, ScanTiming.present);
    });

    test('بالظبط 15 دقيقة = حاضر (الحد شامل)', () {
      expect(at(DateTime(2026, 11, 19, 17, 15)).timing, ScanTiming.present);
    });

    test('15 دقيقة وثانية = متأخر', () {
      expect(
        at(DateTime(2026, 11, 19, 17, 15, 1)).timing,
        ScanTiming.late,
      );
    });

    test('بعد ساعة = متأخر', () {
      expect(at(DateTime(2026, 11, 19, 18)).timing, ScanTiming.late);
    });

    test('lateAfterMinutes مخصص (5 دقايق)', () {
      expect(
        at(DateTime(2026, 11, 19, 17, 6), lateAfter: 5).timing,
        ScanTiming.late,
      );
      expect(
        at(DateTime(2026, 11, 19, 17, 5), lateAfter: 5).timing,
        ScanTiming.present,
      );
    });

    test('lateAfterMinutes = 0: بعد البداية بثانية متأخر', () {
      expect(
        at(DateTime(2026, 11, 19, 17, 0, 1), lateAfter: 0).timing,
        ScanTiming.late,
      );
      expect(at(start, lateAfter: 0).timing, ScanTiming.present);
    });

    test('المقارنة باللحظة الزمنية مش بنوع الـ DateTime (UTC مقابل محلي)', () {
      final startUtc = DateTime.utc(2026, 11, 19, 15);
      final v = ScanValidator(
        centerId: 'c1',
        sessionStart: startUtc,
        groupStudentIds: const {'s7'},
      );
      final inTime = startUtc.add(const Duration(minutes: 15)).toLocal();
      final tooLate = startUtc.add(const Duration(minutes: 16)).toLocal();
      expect(
        v.validate('c1:s7', now: inTime, existingOf: none).timing,
        ScanTiming.present,
      );
      expect(
        v.validate('c1:s7', now: tooLate, existingOf: none).timing,
        ScanTiming.late,
      );
    });
  });

  group('الإعدادات', () {
    test('الافتراضي 15 دقيقة', () {
      expect(make().lateAfterMinutes, 15);
      expect(ScanValidator.defaultLateAfterMinutes, 15);
    });

    test('presentDeadline = startAt + lateAfterMinutes', () {
      expect(make().presentDeadline, DateTime(2026, 11, 19, 17, 15));
    });

    test('centerId فاضي مرفوض', () {
      expect(
        () => ScanValidator(
          centerId: '',
          sessionStart: start,
          groupStudentIds: const {},
        ),
        throwsArgumentError,
      );
    });

    test('lateAfterMinutes سالب مرفوض', () {
      expect(() => make(lateAfter: -1), throwsArgumentError);
    });

    test('تعديل الـ Set الأصلي بعد البناء مبيأثرش', () {
      final students = <String>{'s7'};
      final v = ScanValidator(
        centerId: 'c1',
        sessionStart: start,
        groupStudentIds: students,
      );
      students.add('s99');
      expect(
        v.validate('c1:s99', now: onTime, existingOf: none).outcome,
        ScanOutcome.notRegistered,
      );
    });

    test('الـ Set الداخلي مش قابل للتعديل', () {
      expect(() => make().groupStudentIds.add('x'), throwsUnsupportedError);
    });
  });
}
