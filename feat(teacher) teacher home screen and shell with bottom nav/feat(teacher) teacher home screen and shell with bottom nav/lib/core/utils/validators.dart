import 'arabic_normalizer.dart';
import 'digits.dart';
import 'validation_error.dart';

/// دوال تحقق نقية: كل دالة بترجّع `null` لو القيمة سليمة، أو [ValidationError].
abstract final class Validators {
  static final RegExp _mobile = RegExp(r'^01[0125]\d{8}$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  // حروف عربية (من غير الأرقام الهندية) + لاتينية + مسافة ونقطة وشرطة وفاصلة علوية.
  static final RegExp _nameChars =
      RegExp('^[\u0621-\u065F\u0670\u0671a-zA-Z .\'\\-]+\$');

  static const int nameMinLength = 2;
  static const int nameMaxLength = 60;
  static const int passwordMinLength = 8;

  // ---------------------------------------------------------------- الموبايل

  /// يحوّل أي صيغة لموبايل مصري محلي 01XXXXXXXXX:
  /// أرقام هندية ← لاتينية، حذف المسافات والشرطات والأقواس، و+20 / 0020 ← 0.
  /// بيرجّع النص بعد التنظيف حتى لو لسه مش صالح (التحقق في [mobile]).
  static String normalizeMobile(String input) {
    var p = toLatinDigits(input).replaceAll(RegExp(r'[\s\-().]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0020')) p = '0${p.substring(4)}';
    if (p.startsWith('20') && p.length == 12) p = '0${p.substring(2)}';
    return p;
  }

  /// موبايل مصري: 01[0125] + 8 أرقام.
  static ValidationError? mobile(String input) {
    final p = normalizeMobile(input);
    if (p.isEmpty) return ValidationError.required;
    return _mobile.hasMatch(p) ? null : ValidationError.mobileInvalid;
  }

  // ---------------------------------------------------------------- الإيميل

  static ValidationError? email(String input) {
    final e = input.trim();
    if (e.isEmpty) return ValidationError.required;
    return _email.hasMatch(e) ? null : ValidationError.emailInvalid;
  }

  // ---------------------------------------------------------------- كلمة السر

  /// كلمة السر 8 حروف على الأقل. مفيش trim: المسافة جزء من كلمة السر.
  static ValidationError? password(String input) {
    if (input.isEmpty) return ValidationError.required;
    return input.length >= passwordMinLength
        ? null
        : ValidationError.passwordTooShort;
  }

  // ---------------------------------------------------------------- الاسم

  static ValidationError? name(String input) {
    final n = normalizeArabic(input);
    if (n.isEmpty) return ValidationError.required;
    if (n.length < nameMinLength) return ValidationError.nameTooShort;
    if (n.length > nameMaxLength) return ValidationError.nameTooLong;
    if (!_nameChars.hasMatch(n)) return ValidationError.nameInvalid;
    return null;
  }

  // ---------------------------------------------------------------- الدرجة

  /// يحوّل نص الدرجة لرقم. بيقبل الأرقام الهندية والفاصلة العربية "٫"
  /// والفاصلة العادية. بيرجّع `null` لو النص فاضي أو مش رقم.
  static double? parseScore(String input) {
    final s = toLatinDigits(input)
        .trim()
        .replaceAll('\u066B', '.')
        .replaceAll(',', '.');
    if (s.isEmpty) return null;
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) return null;
    return double.tryParse(s);
  }

  /// الدرجة من 0 لحد [maxScore] بخطوة 0.5.
  ///
  /// **الخانة الفاضية مش خطأ**: معناها "لسه" (مش صفر)، فبترجّع `null`.
  /// استخدم [parseScore] عشان تفرّق بين "لسه" والدرجة الفعلية.
  static ValidationError? score(String input, {required double maxScore}) {
    if (input.trim().isEmpty) return null;
    final v = parseScore(input);
    if (v == null) return ValidationError.scoreInvalid;
    if (v < 0 || v > maxScore) return ValidationError.scoreOutOfRange;
    if (v * 2 != (v * 2).roundToDouble()) return ValidationError.scoreStep;
    return null;
  }
}
