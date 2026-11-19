/// تحويل الأرقام الهندية (٠-٩) والفارسية (۰-۹) لأرقام لاتينية (0-9).
///
/// أي رقم بيتخزن أو بيتقارن لازم يعدّي هنا الأول، عشان "٠١٠" و"010"
/// يبقوا نفس القيمة.
String toLatinDigits(String input) {
  final out = StringBuffer();
  for (final c in input.runes) {
    if (c >= 0x0660 && c <= 0x0669) {
      out.writeCharCode(0x30 + c - 0x0660);
    } else if (c >= 0x06F0 && c <= 0x06F9) {
      out.writeCharCode(0x30 + c - 0x06F0);
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}
