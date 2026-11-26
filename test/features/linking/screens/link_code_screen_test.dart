import 'package:center_net/app/di.dart';
import 'package:center_net/app/session_role.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/linking/models/student_link.dart';
import 'package:center_net/features/linking/repository/linking_repository.dart';
import 'package:center_net/features/linking/screens/link_code_screen.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../../auth/helpers/fake_auth_repository.dart';
import '../helpers/fake_linking_repository.dart';

Future<void> _pumpLinkCode(WidgetTester tester) {
  final router = GoRouter(
    initialLocation: '/link',
    routes: [
      GoRoute(
        path: '/link',
        builder: (_, _) => const LinkCodeScreen(kind: LinkKind.student),
      ),
      GoRoute(
        path: AuthRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  late FakeAuthRepository auth;
  late PendingOpsGuard guard;

  setUp(() {
    auth = FakeAuthRepository();
    guard = PendingOpsGuard();
    sl.registerSingleton<LinkingRepository>(FakeLinkingRepository());
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<PendingOpsGuard>(guard);
    sl.registerSingleton<SessionRole>(SessionRole());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('فيها زرار تسجيل خروج ظاهر في الـ app bar', (tester) async {
    await _pumpLinkCode(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip(arL10n.authSignOut), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('التأكيد بيسجّل الخروج ويروح لشاشة الدخول', (tester) async {
    await _pumpLinkCode(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(arL10n.authSignOut));
    await tester.pumpAndSettle();
    expect(find.text(arL10n.authSignOutMessage), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, arL10n.authSignOut));
    await tester.pumpAndSettle();

    expect(auth.calls, contains('signOut'));
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('الإلغاء بيقفل النافذة من غير خروج', (tester) async {
    await _pumpLinkCode(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(arL10n.authSignOut));
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.cancel));
    await tester.pumpAndSettle();

    expect(auth.calls, isNot(contains('signOut')));
    expect(find.text(arL10n.authSignOutMessage), findsNothing);
    expect(find.text(arL10n.linkEnterTitle), findsOneWidget);
  });

  testWidgets('وجود عمليات معلّقة بيمنع الخروج برسالة', (tester) async {
    guard.setPending(2);
    await _pumpLinkCode(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(arL10n.authSignOut));
    await tester.pumpAndSettle();

    expect(find.text(guard.blockReason!), findsOneWidget);
    expect(find.text(arL10n.authSignOutMessage), findsNothing);
    expect(auth.calls, isNot(contains('signOut')));
  });
}
