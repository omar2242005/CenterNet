import 'package:center_net/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('التطبيق بيفتح بالعربي واتجاه RTL', (tester) async {
    await tester.pumpWidget(const CenterNetApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('أهلاً بك في CenterNet'), findsOneWidget);
  });
}
