import '../../l10n/app_localizations.dart';

// تنسيق التاريخ والوقت والفلوس للعرض. النصوص كلها من `app_ar.arb`.
//
// التاريخ والوقت بيتعرضوا بالقيم اللي في الـ DateTime زي ما هي، فالـ caller
// يبعت وقت القاهرة (TZDateTime بتاع الـ timezone). الأرقام لاتينية دايمًا.

/// "9 نوفمبر 2026".
String formatDate(AppLocalizations l10n, DateTime date) {
  return l10n.dateFull(date.day, l10n.monthName('m${date.month}'), date.year);
}

/// "5:00 م". نظام 12 ساعة بحرف ص / م.
String formatTime(AppLocalizations l10n, DateTime time) {
  final isPm = time.hour >= 12;
  var h = time.hour % 12;
  if (h == 0) h = 12;
  return l10n.timeFormat(
    h.toString(),
    time.minute.toString().padLeft(2, '0'),
    isPm ? l10n.pm : l10n.am,
  );
}

/// "12:00 م" من دقائق اليوم (0..1439، أو أكتر فتلف حوالين 24 ساعة).
/// من غير أي DateTime، فمش بيتأثر بتوقيت الجهاز.
String formatMinutesOfDay(AppLocalizations l10n, int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  final isPm = m >= 720;
  var h = (m ~/ 60) % 12;
  if (h == 0) h = 12;
  return l10n.timeFormat(
    h.toString(),
    (m % 60).toString().padLeft(2, '0'),
    isPm ? l10n.pm : l10n.am,
  );
}

/// الفلوس بتتخزن بالقروش (450 ج.م = 45000): "450 ج.م" أو "1,250.50 ج.م".
String formatMoney(AppLocalizations l10n, int piasters) {
  return l10n.currencyEgp(piastersToDecimalString(piasters));
}

/// 45000 ← "450" · 45050 ← "450.50" · 125000 ← "1,250" · -500 ← "-5".
/// (دالة نقية بتتختبر من غير l10n.)
String piastersToDecimalString(int piasters) {
  final negative = piasters < 0;
  final abs = piasters.abs();
  final whole = _groupThousands((abs ~/ 100).toString());
  final fraction = abs % 100;
  final body =
      fraction == 0 ? whole : '$whole.${fraction.toString().padLeft(2, '0')}';
  return negative ? '-$body' : body;
}

String _groupThousands(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
