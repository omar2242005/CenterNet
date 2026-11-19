import 'dart:math';

/// مولّد أكواد الدعوة والربط: 8 رموز من غير الحروف الملتبسة (0 / O / 1 / I).
abstract final class LinkCodeGenerator {
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int length = 8;

  static final RegExp _format = RegExp('^[$alphabet]{$length}\$');

  /// كود جديد. الافتراضي `Random.secure()`؛ الاختبار بيبعت Random ثابت.
  static String generate([Random? random]) {
    final r = random ?? Random.secure();
    final b = StringBuffer();
    for (var i = 0; i < length; i++) {
      b.write(alphabet[r.nextInt(alphabet.length)]);
    }
    return b.toString();
  }

  /// يظبّط اللي المستخدم كتبه: حروف كبيرة، من غير مسافات أو شرطات.
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// هل الصيغة سليمة (بعد [normalize])؟ ده فحص شكلي فقط، مش وجود الكود.
  static bool isWellFormed(String input) =>
      _format.hasMatch(normalize(input));
}
