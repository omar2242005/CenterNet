import 'package:flutter/services.dart';

import 'digits.dart';

/// يحوّل الأرقام الهندية لأرقام لاتينية وقت الكتابة (للموبايل والكود والدرجة).
class LatinDigitsFormatter extends TextInputFormatter {
  const LatinDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = toLatinDigits(newValue.text);
    if (converted == newValue.text) return newValue;
    // التحويل حرف بحرف بنفس الطول، فمكان المؤشر بيفضل زي ما هو.
    return newValue.copyWith(text: converted);
  }
}
