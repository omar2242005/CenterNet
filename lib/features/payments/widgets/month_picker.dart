import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// الشهر الحالي و11 شهر قبله، الأحدث أولًا، كـ (سنة، شهر).
List<(int, int)> recentMonthChoices() {
  final out = <(int, int)>[];
  final now = DateTime.now();
  var y = now.year;
  var m = now.month;
  for (var i = 0; i < 12; i++) {
    out.add((y, m));
    m--;
    if (m == 0) {
      m = 12;
      y--;
    }
  }
  return out;
}

/// عنوان شهر زي "نوفمبر 2026".
String monthLabel(AppLocalizations l10n, int year, int month) =>
    '${l10n.monthName('m$month')} $year';

/// قائمة منسدلة لاختيار شهر من [recentMonthChoices]. بتتشارك بين
/// شيت تسجيل الدفعة وشاشة المدفوعات.
class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  /// (السنة، الشهر) المختارين.
  final (int, int) value;
  final ValueChanged<(int, int)> onChanged;

  /// label الفورم (في الشيت). null = من غير decoration (في شاشة المدفوعات).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      for (final (y, m) in recentMonthChoices())
        DropdownMenuItem(value: (y, m), child: Text(monthLabel(l10n, y, m))),
    ];
    if (label != null) {
      return DropdownButtonFormField<(int, int)>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );
    }
    return DropdownButton<(int, int)>(
      value: value,
      underline: const SizedBox.shrink(),
      items: items,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
