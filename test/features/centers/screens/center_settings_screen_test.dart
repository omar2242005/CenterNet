import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/centers/models/center_member.dart';
import 'package:center_net/features/centers/repository/centers_repository.dart';
import 'package:center_net/features/centers/screens/center_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_centers_repository.dart';

void main() {
  late FakeCentersRepository repo;

  setUp(() {
    repo = FakeCentersRepository(mine: sampleContext());
    sl.registerSingleton<CentersRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('الأدمن يشوف القيم الحالية في الفورم', (tester) async {
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text('مركز النور'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('تعديل وحفظ: بيبعت القيم الجديدة ويظهر "تم الحفظ"', (
    tester,
  ) async {
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'مركز الأمل');
    await tester.enterText(find.byType(TextFormField).at(2), '30');
    await tester.tap(find.text(arL10n.centersSaveButton));
    await tester.pumpAndSettle();

    expect(repo.calls.last, 'update:c1:مركز الأمل:2026:30');
    expect(find.text(arL10n.centersSaved), findsOneWidget);
  });

  testWidgets('مدة تأخير 200: رسالة تحقق ومفيش حفظ', (tester) async {
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), '200');
    await tester.tap(find.text(arL10n.centersSaveButton));
    await tester.pump();

    expect(find.text(arL10n.centersLateInvalid), findsOneWidget);
    expect(repo.calls.where((c) => c.startsWith('update')), isEmpty);
  });

  testWidgets('فشل الحفظ بيظهر برسالة عربية', (tester) async {
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    repo.failure = const Failure.permission(message: 'غير مسموح');
    await tester.tap(find.text(arL10n.centersSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('غير مسموح'), findsOneWidget);
  });

  testWidgets('المعلم مايشوفش الفورم، بيشوف رسالة "للمدير فقط"', (
    tester,
  ) async {
    repo.mine = sampleContext(role: MemberRole.teacher);
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.centersAdminOnly), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('الأدمن المعطّل مايشوفش الفورم', (tester) async {
    repo.mine = sampleContext(active: false);
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.centersAdminOnly), findsOneWidget);
  });

  testWidgets('مفيش سنتر: رسالة فارغة', (tester) async {
    repo.mine = null;
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.centersNoCenter), findsOneWidget);
  });

  testWidgets('خطأ تحميل: رسالة وزر إعادة المحاولة', (tester) async {
    repo.failure = const Failure.network();
    await tester.pumpApp(const CenterSettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.retry), findsOneWidget);

    repo.failure = null;
    await tester.tap(find.text(arL10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('مركز النور'), findsOneWidget);
  });
}
