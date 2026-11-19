import 'package:center_net/features/centers/rules/center_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanName', () {
    test('بيشيل المسافات الزيادة', () {
      expect(CenterValidators.cleanName('  مركز   النور  '), 'مركز النور');
    });
  });

  group('name', () {
    test('سليم', () {
      expect(CenterValidators.name('مركز النور'), isNull);
      expect(CenterValidators.name('مركز النور 2'), isNull);
    });

    test('فاضي أو مسافات = required', () {
      expect(CenterValidators.name(''), CenterFieldError.required);
      expect(CenterValidators.name('   '), CenterFieldError.required);
    });

    test('حرف واحد = قصير', () {
      expect(CenterValidators.name('م'), CenterFieldError.nameTooShort);
    });

    test('أكتر من 80 حرف = طويل، و80 بالظبط سليم', () {
      expect(CenterValidators.name('م' * 80), isNull);
      expect(CenterValidators.name('م' * 81), CenterFieldError.nameTooLong);
    });
  });

  group('year', () {
    test('سنة سليمة (لاتيني وهندي)', () {
      expect(CenterValidators.year('2026'), isNull);
      expect(CenterValidators.year('٢٠٢٦'), isNull);
      expect(CenterValidators.parseYear('٢٠٢٦'), 2026);
      expect(CenterValidators.parseYear(' 2026 '), 2026);
    });

    test('فاضي = required', () {
      expect(CenterValidators.year(''), CenterFieldError.required);
    });

    test('مش 4 أرقام أو برا المدى أو مش رقم', () {
      for (final bad in ['26', '20266', 'abcd', '1999', '2101', '20.5']) {
        expect(
          CenterValidators.year(bad),
          CenterFieldError.yearInvalid,
          reason: bad,
        );
        expect(CenterValidators.parseYear(bad), isNull, reason: bad);
      }
    });

    test('حدود المدى 2000 و2100 مقبولة', () {
      expect(CenterValidators.parseYear('2000'), 2000);
      expect(CenterValidators.parseYear('2100'), 2100);
    });
  });

  group('lateAfterMinutes', () {
    test('من 0 لـ 180 سليم', () {
      for (final ok in ['0', '15', '180', '١٥']) {
        expect(CenterValidators.lateAfterMinutes(ok), isNull, reason: ok);
      }
      expect(CenterValidators.parseLateAfterMinutes('١٥'), 15);
    });

    test('فاضي = required', () {
      expect(CenterValidators.lateAfterMinutes(''), CenterFieldError.required);
    });

    test('أكبر من 180 أو سالب أو عشري أو مش رقم = غلط', () {
      for (final bad in ['181', '1000', '-5', '1.5', 'x', '0015']) {
        expect(
          CenterValidators.lateAfterMinutes(bad),
          CenterFieldError.lateInvalid,
          reason: bad,
        );
        expect(
          CenterValidators.parseLateAfterMinutes(bad),
          isNull,
          reason: bad,
        );
      }
    });
  });
}
