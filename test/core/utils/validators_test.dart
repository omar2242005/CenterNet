import 'package:center_net/core/utils/validation_error.dart';
import 'package:center_net/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mobile', () {
    test('أرقام مصرية صالحة', () {
      for (final p in ['01012345678', '01112345678', '01212345678', '01512345678']) {
        expect(Validators.mobile(p), isNull, reason: p);
      }
    });

    test('أرقام هندية بتتقبل بعد التطبيع', () {
      expect(Validators.mobile('٠١٠١٢٣٤٥٦٧٨'), isNull);
    });

    test('+20 و0020 ومسافات وشرطات', () {
      expect(Validators.mobile('+201012345678'), isNull);
      expect(Validators.mobile('00201012345678'), isNull);
      expect(Validators.mobile('0101 234-5678'), isNull);
    });

    test('أرقام غلط', () {
      expect(Validators.mobile('01312345678'), ValidationError.mobileInvalid);
      expect(Validators.mobile('0101234567'), ValidationError.mobileInvalid);
      expect(Validators.mobile('010123456789'), ValidationError.mobileInvalid);
      expect(Validators.mobile('abc'), ValidationError.mobileInvalid);
    });

    test('فاضي = مطلوب', () {
      expect(Validators.mobile(''), ValidationError.required);
      expect(Validators.mobile('   '), ValidationError.required);
    });

    test('normalizeMobile بيرجّع الصيغة المحلية', () {
      expect(Validators.normalizeMobile('+٢٠١٠١٢٣٤٥٦٧٨'), '01012345678');
      expect(Validators.normalizeMobile('0020 101 234 5678'), '01012345678');
    });
  });

  group('email', () {
    test('صالح', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('  omar.x@mail.co.uk '), isNull);
    });

    test('غلط', () {
      for (final e in ['abc', 'a@b', 'a b@c.com', '@c.com', 'a@.com']) {
        expect(Validators.email(e), ValidationError.emailInvalid, reason: e);
      }
      expect(Validators.email(''), ValidationError.required);
    });
  });

  group('password', () {
    test('8 حروف أو أكتر', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('1234567'), ValidationError.passwordTooShort);
      expect(Validators.password(''), ValidationError.required);
    });
  });

  group('name', () {
    test('أسماء عربية صالحة', () {
      expect(Validators.name('أحمد علي'), isNull);
      expect(Validators.name('عبد الرحمن'), isNull);
      expect(Validators.name('مُحَمَّد'), isNull);
    });

    test('اسم لاتيني', () {
      expect(Validators.name("Ahmed O'Neil"), isNull);
    });

    test('قصير أو طويل أو فيه أرقام ورموز', () {
      expect(Validators.name(''), ValidationError.required);
      expect(Validators.name('أ'), ValidationError.nameTooShort);
      expect(Validators.name('ا' * 61), ValidationError.nameTooLong);
      expect(Validators.name('أحمد 2'), ValidationError.nameInvalid);
      expect(Validators.name('أحمد ٢'), ValidationError.nameInvalid);
      expect(Validators.name('أحمد@'), ValidationError.nameInvalid);
    });
  });

  group('score', () {
    test('من 0 لحد النهائية بخطوة 0.5', () {
      expect(Validators.score('0', maxScore: 30), isNull);
      expect(Validators.score('30', maxScore: 30), isNull);
      expect(Validators.score('7.5', maxScore: 30), isNull);
      expect(Validators.score('٢٥', maxScore: 30), isNull);
      expect(Validators.score('7٫5', maxScore: 30), isNull);
      expect(Validators.score('7,5', maxScore: 30), isNull);
    });

    test('31 على امتحان 30 مرفوض، و-1 مرفوض', () {
      expect(Validators.score('31', maxScore: 30), ValidationError.scoreOutOfRange);
      expect(Validators.score('-1', maxScore: 30), ValidationError.scoreOutOfRange);
    });

    test('خطوة غلط ونص مش رقم', () {
      expect(Validators.score('7.25', maxScore: 30), ValidationError.scoreStep);
      expect(Validators.score('abc', maxScore: 30), ValidationError.scoreInvalid);
      expect(Validators.score('1.2.3', maxScore: 30), ValidationError.scoreInvalid);
    });

    test('الخانة الفاضية مش خطأ ومش صفر', () {
      expect(Validators.score('', maxScore: 30), isNull);
      expect(Validators.score('  ', maxScore: 30), isNull);
      expect(Validators.parseScore(''), isNull);
      expect(Validators.parseScore('0'), 0);
    });

    test('parseScore', () {
      expect(Validators.parseScore('٧٫٥'), 7.5);
      expect(Validators.parseScore('12'), 12);
      expect(Validators.parseScore('x'), isNull);
    });
  });
}
