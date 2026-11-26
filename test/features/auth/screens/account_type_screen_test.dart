import 'package:center_net/app/di.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/register_draft.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/auth/screens/account_type_screen.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_auth_repository.dart';

Future<void> pumpWithRouter(WidgetTester tester) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: AccountTypeScreen(
            draft: RegisterDraft(
              name: 'سارة',
              email: 'a@b.com',
              phone: '01012345678',
              password: 'secret123',
            ),
          ),
        ),
      ),
      GoRoute(path: '/:any', builder: (_, _) => const Scaffold()),
    ],
  );
  return tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

void main() {
  late FakeAuthRepository repo;
  const draft = RegisterDraft(
    name: 'سارة',
    email: 'a@b.com',
    phone: '01012345678',
    password: 'secret123',
  );

  setUp(() {
    repo = FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('المعلم والمساعد خيارين منفصلين ومفيش خيار مدمج', (tester) async {
    await tester.pumpApp(const AccountTypeScreen(draft: draft));

    expect(find.text(arL10n.accountTypeTeacher), findsOneWidget);
    expect(find.text(arL10n.accountTypeAssistant), findsOneWidget);
    expect(find.text(arL10n.accountTypeStaff), findsNothing);
    expect(find.text(arL10n.accountTypeAdmin), findsOneWidget);
    expect(find.text(arL10n.accountTypeGuardian), findsOneWidget);
    expect(find.text(arL10n.accountTypeStudent), findsOneWidget);
  });

  testWidgets('اختيار مساعد بيسجّل accountType=assistant', (tester) async {
    await pumpWithRouter(tester);
    await tester.tap(find.text(arL10n.accountTypeAssistant));
    await tester.pump();
    await tester.tap(find.text(arL10n.authCreateAccountButton));
    await tester.pumpAndSettle();

    expect(repo.calls, ['register:a@b.com:assistant']);
  });

  testWidgets('اختيار معلم بيسجّل accountType=teacher', (tester) async {
    await pumpWithRouter(tester);
    await tester.tap(find.text(arL10n.accountTypeTeacher));
    await tester.pump();
    await tester.tap(find.text(arL10n.authCreateAccountButton));
    await tester.pumpAndSettle();

    expect(repo.calls, ['register:a@b.com:teacher']);
  });

  test('staff القديم بيتقرأ لكن مش في الاختيار، وكله جهة موظفين', () {
    expect(AccountType.selectable.contains(AccountType.staff), isFalse);
    expect(AccountType.parse('staff'), AccountType.staff);
    for (final t in [
      AccountType.admin,
      AccountType.teacher,
      AccountType.assistant,
      AccountType.staff,
    ]) {
      expect(t.isStaffSide, isTrue);
    }
    expect(AccountType.student.isStaffSide, isFalse);
    expect(AccountType.guardian.isStaffSide, isFalse);
  });
}
