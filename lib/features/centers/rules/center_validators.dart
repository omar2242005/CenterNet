import '../../../core/utils/digits.dart';
import '../models/center_info.dart';

/// أخطاء حقول السنتر. النص العربي بيتجاب من arb عن طريق
/// `center_validation_text.dart` (مفيش نص عربي هنا).
enum CenterFieldError {
  required,
  nameTooShort,
  nameTooLong,
  yearInvalid,
  lateInvalid,
}

/// دوال تحقق نقية لشاشة إنشاء السنتر وإعداداته. كل دالة بترجّع `null` لو
/// القيمة سليمة. الحدود هنا لازم تفضل أضيق من حدود firestore.rules أو زيها.
abstract final class CenterValidators {
  static const int nameMinLength = 2;
  static const int minYear = 2000;
  static const int maxYear = 2100;

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _fourDigits = RegExp(r'^\d{4}$');
  static final RegExp _digits = RegExp(r'^\d{1,3}$');

  /// الاسم بعد التنضيف: مسافات متكررة ← مسافة، وبدون مسافات في الأطراف.
  /// ده اللي بيتخزن. (الأرقام مسموحة: "مركز النور 2".)
  static String cleanName(String input) =>
      input.replaceAll(_spaces, ' ').trim();

  static CenterFieldError? name(String input) {
    final n = cleanName(input);
    if (n.isEmpty) return CenterFieldError.required;
    if (n.length < nameMinLength) return CenterFieldError.nameTooShort;
    if (n.length > CenterInfo.nameMaxLength) {
      return CenterFieldError.nameTooLong;
    }
    return null;
  }

  /// السنة الدراسية: 4 أرقام (هندية أو لاتينية) بين [minYear] و [maxYear].
  static CenterFieldError? year(String input) {
    final s = toLatinDigits(input).trim();
    if (s.isEmpty) return CenterFieldError.required;
    final y = parseYear(input);
    return y == null ? CenterFieldError.yearInvalid : null;
  }

  /// بيرجّع السنة كرقم، أو null لو النص مش سنة صالحة.
  static int? parseYear(String input) {
    final s = toLatinDigits(input).trim();
    if (!_fourDigits.hasMatch(s)) return null;
    final y = int.parse(s);
    return (y < minYear || y > maxYear) ? null : y;
  }

  /// مدة التأخير: رقم صحيح من 0 لـ 180 دقيقة (حدود الـ Rules).
  static CenterFieldError? lateAfterMinutes(String input) {
    final s = toLatinDigits(input).trim();
    if (s.isEmpty) return CenterFieldError.required;
    return parseLateAfterMinutes(input) == null
        ? CenterFieldError.lateInvalid
        : null;
  }

  static int? parseLateAfterMinutes(String input) {
    final s = toLatinDigits(input).trim();
    if (!_digits.hasMatch(s)) return null;
    final m = int.parse(s);
    return m > CenterInfo.maxLateAfterMinutes ? null : m;
  }
}
