import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/auth/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../helpers/pump_app.dart';
import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() {
    repo = FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('إرسال فورم فاضي بيعرض رسائل التحقق ومبينادش الـ Repository', (
    tester,
  ) async {
    await tester.pumpApp(const LoginScreen());

    await tester.tap(find.text(arL10n.authLoginButton));
    await tester.pump();

    expect(find.text(arL10n.validationRequired), findsWidgets);
    expect(repo.calls, isEmpty);
  });

  testWidgets('خطأ الدخول بيظهر برسالة عربية', (tester) async {
    repo.failure = const Failure.validation('البريد أو كلمة السر غلط');
    await tester.pumpApp(const LoginScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text(arL10n.authLoginButton));
    await tester.pumpAndSettle();

    expect(find.text('البريد أو كلمة السر غلط'), findsOneWidget);
    expect(repo.calls, ['signIn:a@b.com']);
  });
}
