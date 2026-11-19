import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/staff/repository/staff_join_repository.dart';
import 'package:center_net/features/staff/screens/staff_join_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_staff_join_repository.dart';

void main() {
  late FakeStaffJoinRepository repo;

  setUp(() {
    repo = FakeStaffJoinRepository();
    sl.registerSingleton<StaffJoinRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('كود فاضي: رسالة "مطلوب" ومبينادش الـ Repository', (tester) async {
    await tester.pumpApp(const StaffJoinScreen());

    await tapText(tester, arL10n.staffJoinButton);

    expect(find.text(arL10n.validationRequired), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('كود بصيغة غلط: رسالة الصيغة ومبينادش الـ Repository', (
    tester,
  ) async {
    await tester.pumpApp(const StaffJoinScreen());

    await tester.enterText(find.byType(TextFormField), 'ABC');
    await tapText(tester, arL10n.staffJoinButton);

    expect(find.text(arL10n.staffJoinCodeInvalid), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('كود سليم: بينادي الـ Repository وبيعرض رسالة النجاح', (
    tester,
  ) async {
    await tester.pumpApp(const StaffJoinScreen());

    await tester.enterText(find.byType(TextFormField), 'ABCD2345');
    await tapText(tester, arL10n.staffJoinButton);

    expect(repo.calls, ['accept:ABCD2345']);
    expect(find.text(arL10n.staffJoinSuccessTitle), findsOneWidget);
    expect(
      find.text(arL10n.staffJoinSuccessBody('مركز النور', 'معلم')),
      findsOneWidget,
    );
    expect(find.text(arL10n.staffJoinContinue), findsOneWidget);
  });

  testWidgets('فشل: بتظهر رسالة الخطأ العربية ومفيش نجاح', (tester) async {
    repo.failure = const Failure.validation('هذا الكود مستخدم بالفعل.');
    await tester.pumpApp(const StaffJoinScreen());

    await tester.enterText(find.byType(TextFormField), 'ABCD2345');
    await tapText(tester, arL10n.staffJoinButton);

    expect(find.text('هذا الكود مستخدم بالفعل.'), findsOneWidget);
    expect(find.text(arL10n.staffJoinSuccessTitle), findsNothing);
  });
}
