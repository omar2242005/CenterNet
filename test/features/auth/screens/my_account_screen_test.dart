import 'package:center_net/app/di.dart';
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
}
