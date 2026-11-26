import 'package:center_net/app/di.dart';
import 'package:center_net/app/session_role.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/auth/screens/my_account_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() {
    repo = FakeAuthRepository()
      ..profile = const AppUser(
        uid: 'u1',
        name: 'أحمد مدير',
        email: 'ahmed@center.com',
        phone: '01012345678',
        accountType: AccountType.admin,
        centerId: 'c1',
      );
    sl.registerSingleton<AuthRepository>(repo);
    sl.registerSingleton<PendingOpsGuard>(PendingOpsGuard());
    sl.registerSingleton<SessionRole>(SessionRole());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('بتعرض بيانات الحساب ونوعه بالعربي', (tester) async {
    await tester.pumpApp(const MyAccountScreen());
    await tester.pumpAndSettle();

    expect(find.text('أحمد مدير'), findsOneWidget);
    expect(find.text('ahmed@center.com'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text(arL10n.accountTypeAdmin), findsOneWidget);
    expect(find.text(arL10n.authSignOut), findsOneWidget);
  });

  testWidgets('حقل فاضي مبيظهرش سطره', (tester) async {
    repo.profile = const AppUser(
      uid: 'u1',
      name: 'سارة طالبة',
      email: '',
      phone: '',
      accountType: AccountType.student,
      centerId: 'c1',
    );
    await tester.pumpApp(const MyAccountScreen());
    await tester.pumpAndSettle();

    expect(find.text('سارة طالبة'), findsOneWidget);
    expect(find.text(arL10n.myAccountEmail), findsNothing);
    expect(find.text(arL10n.myAccountPhone), findsNothing);
    expect(find.text(arL10n.accountTypeStudent), findsOneWidget);
  });

  testWidgets('فشل التحميل برسالة عربية', (tester) async {
    repo.failure = const Failure.network();
    await tester.pumpApp(const MyAccountScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.myAccountLoadError), findsOneWidget);
  });

  testWidgets('بروفايل غير موجود برسالة عربية', (tester) async {
    repo.profile = null;
    await tester.pumpApp(const MyAccountScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.myAccountLoadError), findsOneWidget);
  });

  Future<void> pumpRouted(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/acc',
      routes: [
        GoRoute(path: '/acc', builder: (_, _) => const MyAccountScreen()),
        GoRoute(
          path: AuthRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
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

  testWidgets('زرار حذف الحساب ظاهر', (tester) async {
    await pumpRouted(tester);
    expect(find.text(arL10n.accountDeleteAction), findsOneWidget);
  });

  testWidgets('الحذف بكلمة السر بيمسح ويروح للدخول', (tester) async {
    await pumpRouted(tester);
    await tester.tap(find.text(arL10n.accountDeleteAction));
    await tester.pumpAndSettle();
    expect(find.text(arL10n.accountDeleteMessage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.pump();
    await tester.tap(find.text(arL10n.accountDeleteConfirm));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('delete:secret123'));
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('الإلغاء مبيمسحش حاجة', (tester) async {
    await pumpRouted(tester);
    await tester.tap(find.text(arL10n.accountDeleteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.cancel));
    await tester.pumpAndSettle();

    expect(repo.calls.where((c) => c.startsWith('delete')), isEmpty);
    expect(find.text(arL10n.myAccountTitle), findsOneWidget);
  });

  testWidgets('زرار التأكيد متعطل من غير كلمة سر', (tester) async {
    await pumpRouted(tester);
    await tester.tap(find.text(arL10n.accountDeleteAction));
    await tester.pumpAndSettle();
    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, arL10n.accountDeleteConfirm),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('فشل الحذف برسالة وبيفضل في الشاشة', (tester) async {
    await pumpRouted(tester);
    await tester.tap(find.text(arL10n.accountDeleteAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    repo.failure = const Failure.validation('كلمة السر غير صحيحة.');
    await tester.tap(find.text(arL10n.accountDeleteConfirm));
    await tester.pumpAndSettle();

    expect(find.text('كلمة السر غير صحيحة.'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });

  testWidgets('عمليات معلّقة بتمنع الحذف', (tester) async {
    sl<PendingOpsGuard>().setPending(3);
    await pumpRouted(tester);
    await tester.tap(find.text(arL10n.accountDeleteAction));
    await tester.pumpAndSettle();

    expect(find.text(sl<PendingOpsGuard>().blockReason!), findsOneWidget);
    expect(find.text(arL10n.accountDeleteMessage), findsNothing);
  });
}
