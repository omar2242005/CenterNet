import 'package:center_net/app/di.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/assistant/widgets/assistant_shell.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/features/guardian/screens/guardian_home_screen.dart';
import 'package:center_net/features/linking/repository/linking_repository.dart';
import 'package:center_net/features/student_area/screens/student_home_screen.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../../linking/helpers/fake_linking_repository.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => home),
      GoRoute(
        path: AuthRoutes.myAccount,
        builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    sl.registerSingleton<LinkingRepository>(FakeLinkingRepository());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('درج المساعد فيه حسابي وبيفتح شاشة الحساب', (tester) async {
    await _pump(
      tester,
      const AssistantShell(
        current: AssistantTab.home,
        title: 'x',
        body: SizedBox(),
      ),
    );
    await tester.tap(find.byTooltip(MaterialLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    ).openAppDrawerTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.myAccountTitle));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
  });

  testWidgets('شاشة الطالب فيها حسابي', (tester) async {
    await _pump(tester, const StudentHomeScreen());
    await tester.tap(find.byTooltip(arL10n.myAccountTitle));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
  });

  testWidgets('شاشة ولي الأمر فيها حسابي', (tester) async {
    await _pump(tester, const GuardianHomeScreen());
    await tester.tap(find.byTooltip(arL10n.myAccountTitle));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
  });
}
