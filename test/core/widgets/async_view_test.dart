import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/core/widgets/async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  Widget view(ViewState<List<String>> state, {VoidCallback? onRetry, String? empty}) {
    return AsyncView<List<String>>(
      state: state,
      onRetry: onRetry,
      emptyMessage: empty,
      builder: (_, items) => Text(items.join(',')),
    );
  }

  testWidgets('تحميل: مؤشر تحميل', (tester) async {
    await tester.pumpApp(view(const ViewLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('فارغ: رسالة افتراضية من arb', (tester) async {
    await tester.pumpApp(view(const ViewEmpty()));
    expect(find.text(arL10n.emptyDefault), findsOneWidget);
  });

  testWidgets('فارغ: رسالة مخصصة', (tester) async {
    await tester.pumpApp(view(const ViewEmpty(), empty: 'مفيش طلاب'));
    expect(find.text('مفيش طلاب'), findsOneWidget);
  });

  testWidgets('خطأ: رسالة الـ Failure وزر إعادة المحاولة', (tester) async {
    var retried = 0;
    await tester.pumpApp(
      view(
        const ViewFailed(Failure.network()),
        onRetry: () => retried++,
      ),
    );
    expect(find.text(const Failure.network().message), findsOneWidget);
    await tester.tap(find.text(arL10n.retry));
    expect(retried, 1);
  });

  testWidgets('خطأ من غير onRetry: مفيش زر', (tester) async {
    await tester.pumpApp(view(const ViewFailed(Failure.network())));
    expect(find.text(arL10n.retry), findsNothing);
  });

  testWidgets('نجاح: بيبني المحتوى', (tester) async {
    await tester.pumpApp(view(const ViewSuccess(['أ', 'ب'])));
    expect(find.text('أ,ب'), findsOneWidget);
  });
}
