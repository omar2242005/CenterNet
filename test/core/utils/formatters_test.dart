import 'package:center_net/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  final l10n = arL10n;

  group('formatDate', () {
    test('"9 نوفمبر 2026"', () {
      expect(formatDate(l10n, DateTime(2026, 11, 9)), '9 نوفمبر 2026');
    });

    test('كل الشهور', () {
      const names = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      for (var m = 1; m <= 12; m++) {
        expect(formatDate(l10n, DateTime(2026, m, 1)), '1 ${names[m - 1]} 2026');
      }
    });
  });

  group('formatTime', () {
    test('نظام 12 ساعة ص / م', () {
      expect(formatTime(l10n, DateTime(2026, 1, 1, 17, 0)), '5:00 م');
      expect(formatTime(l10n, DateTime(2026, 1, 1, 9, 5)), '9:05 ص');
      expect(formatTime(l10n, DateTime(2026, 1, 1, 0, 30)), '12:30 ص');
      expect(formatTime(l10n, DateTime(2026, 1, 1, 12, 0)), '12:00 م');
    });
  });

  group('formatMoney', () {
    test('450 ج.م = 45000 قرش', () {
      expect(formatMoney(l10n, 45000), '450 ج.م');
    });

    test('كسور وآلاف', () {
      expect(formatMoney(l10n, 45050), '450.50 ج.م');
      expect(formatMoney(l10n, 125000), '1,250 ج.م');
      expect(formatMoney(l10n, 0), '0 ج.م');
    });
  });

  group('piastersToDecimalString', () {
    test('بدون l10n', () {
      expect(piastersToDecimalString(45000), '450');
      expect(piastersToDecimalString(5), '0.05');
      expect(piastersToDecimalString(123456789), '1,234,567.89');
      expect(piastersToDecimalString(-500), '-5');
    });
  });
}
