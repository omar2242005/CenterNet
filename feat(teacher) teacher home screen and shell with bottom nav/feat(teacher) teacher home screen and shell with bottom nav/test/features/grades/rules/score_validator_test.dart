import 'package:center_net/features/grades/rules/score_validator.dart';
import 'package:flutter_test/flutter_test.dart';
// عدّل المسار حسب اسم الباكدج ومكان الملف عندكم.

void main() {
  const max = 100.0;

  double? ok(String s) => ScoreValidator.parse(s, maxScore: max).value;
  String? err(String? s) => ScoreValidator.parse(s, maxScore: max).error;

  group('ScoreValidator — مقبول', () {
    test('أرقام عادية', () {
      expect(ok('85'), 85);
      expect(ok('85.5'), 85.5);
      expect(ok('0'), 0);
      expect(ok('100'), 100);
    });

    test('مسافات حواليه', () => expect(ok('  70 '), 70));

    test('أرقام عربية وفاصلة عربية', () {
      expect(ok('٨٥'), 85);
      expect(ok('٨٥٫٥'), 85.5);
      expect(ok('85,5'), 85.5);
    });
  });

  group('ScoreValidator — مرفوض', () {
    test('فاضي أو null', () {
      expect(err(''), isNotNull);
      expect(err('   '), isNotNull);
      expect(err(null), isNotNull);
    });

    test('مش رقم', () {
      expect(err('abc'), isNotNull);
      expect(err('8x'), isNotNull);
      expect(err('NaN'), isNotNull);
      expect(err('Infinity'), isNotNull);
    });

    test('سالب أو أكبر من النهائية', () {
      expect(err('-1'), isNotNull);
      expect(err('100.5'), isNotNull);
      expect(err('101'), isNotNull);
    });

    test('مش بخطوة 0.5', () {
      expect(err('85.3'), isNotNull);
      expect(err('85.25'), isNotNull);
    });

    test('الحد الأقصى بيتغيّر مع الامتحان', () {
      expect(ScoreValidator.parse('25', maxScore: 20).isValid, isFalse);
      expect(ScoreValidator.parse('20', maxScore: 20).isValid, isTrue);
    });
  });

  test('formFieldError يرجّع null لو سليم', () {
    expect(ScoreValidator.formFieldError('90', maxScore: max), isNull);
    expect(ScoreValidator.formFieldError('', maxScore: max), isNotNull);
  });
}
