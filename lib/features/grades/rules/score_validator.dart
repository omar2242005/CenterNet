/// طبقة رفيعة بين خانة الدرجة في الشاشة وبين Score.create.
/// بتاخد النص اللي المدرس كتبه وترجّع رقم أو رسالة خطأ بالعربي.
/// القواعد هنا لازم تطابق قواعد Firestore: من 0 للدرجة النهائية، بخطوة 0.5.
class ScoreInputResult {
  const ScoreInputResult.ok(double this.value) : error = null;
  const ScoreInputResult.error(String this.error) : value = null;

  final double? value;
  final String? error;

  bool get isValid => error == null;
}

class ScoreValidator {
  const ScoreValidator._();

  static const double step = 0.5;

  static ScoreInputResult parse(String? input, {required double maxScore}) {
    final text = _normalize(input ?? '');

    if (text.isEmpty) {
      return const ScoreInputResult.error('اكتب الدرجة');
    }

    final value = double.tryParse(text);
    if (value == null || value.isNaN || value.isInfinite) {
      return const ScoreInputResult.error('الدرجة لازم تكون رقم');
    }
    if (value < 0) {
      return const ScoreInputResult.error('الدرجة مينفعش تكون سالبة');
    }
    if (value > maxScore) {
      return ScoreInputResult.error(
        'الدرجة أكبر من الدرجة النهائية (${_fmt(maxScore)})',
      );
    }
    // نفس شرط القواعد: floor(score * 2) == score * 2
    if ((value * 2) != (value * 2).floorToDouble()) {
      return const ScoreInputResult.error(
        'الدرجة لازم تكون بخطوة نص (مثلًا 85 أو 85.5)',
      );
    }
    return ScoreInputResult.ok(value);
  }

  /// للاستخدام في validator بتاع TextFormField: يرجّع null لو سليم.
  static String? formFieldError(String? input, {required double maxScore}) =>
      parse(input, maxScore: maxScore).error;

  /// يحوّل الأرقام العربية والفاصلة العربية لصيغة double.tryParse تفهمها.
  static String _normalize(String s) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.trim().runes) {
      final c = String.fromCharCode(ch);
      final a = arabicDigits.indexOf(c);
      final p = persianDigits.indexOf(c);
      if (a >= 0) {
        b.write(a);
      } else if (p >= 0) {
        b.write(p);
      } else if (c == '٫' || c == ',' || c == '،') {
        b.write('.');
      } else if (c.trim().isNotEmpty) {
        b.write(c);
      }
    }
    return b.toString();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
