import '../../core/errors/failure.dart';
import '../../l10n/app_localizations.dart';

/// الدرجة من غير ".0" لو رقم صحيح (85 بدل 85.0).
String fmtScore(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// التاريخ بالعربي: 30 نوفمبر 2026.
String fmtDate(AppLocalizations l10n, DateTime d) =>
    l10n.dateFull(d.day, l10n.monthName('m${d.month}'), d.year);

/// نص رسالة الخطأ. لو `Failure` اسم الحقل فيها غير `message`، عدّله هنا بس.
String failureText(Failure? f) => f?.message ?? '';