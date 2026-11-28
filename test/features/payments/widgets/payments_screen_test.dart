import 'package:center_net/app/di.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/payments/repositories/payments_repository.dart';
import 'package:center_net/features/admin/screens/payments_screen.dart';
import 'package:center_net/features/students/repository/students_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../groups/helpers/fake_groups_repository.dart';
import '../../students/helpers/fake_students_repository.dart';
import '../cubit/payments_cubit_test.dart'
    show archivedStudent, groupWithFee, studentWithGroups;
import '../helpers/fake_payments_repository.dart';

void main() {
  late FakePaymentsRepository payments;
  late FakeGroupsRepository groups;
  late FakeStudentsRepository students;

  setUp(() {
    payments = FakePaymentsRepository();
    groups = FakeGroupsRepository(
      groups: [
        groupWithFee('g1', 'رياضيات أ', 45000),
        groupWithFee('g2', 'فيزياء', 30000),
      ],
    );
    students = FakeStudentsRepository(
      students: [
        studentWithGroups('s1', 'كريم حسن', ['g1']),
        studentWithGroups('s2', 'سارة علي', ['g2']),
        archivedStudent('s3', ['g1']),
      ],
    );
    sl
      ..registerSingleton<PaymentsRepository>(payments)
      ..registerSingleton<GroupsRepository>(groups)
      ..registerSingleton<StudentsRepository>(students);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpApp(const PaymentsScreen());
    await tester.pumpAndSettle();
  }

  testWidgets('قائمة الشهر الحالي: صف لكل تسجيل، الكل غير مدفوع', (tester) async {
    await openScreen(tester);

    expect(find.text(arL10n.paymentsScreenTitle), findsOneWidget);
    expect(find.text('كريم حسن'), findsOneWidget);
    expect(find.text('سارة علي'), findsOneWidget);
    expect(find.text(arL10n.paymentsFilterUnpaid), findsWidgets);
    expect(find.text('450 ج.م'), findsOneWidget);
    expect(find.text('300 ج.م'), findsOneWidget);
    // الطالب المؤرشف مش بيظهر.
    expect(find.text('طالب مؤرشف'), findsNothing);
  });

  testWidgets('اللمس على غير مدفوع بيفتح شيت التسجيل جاهز وبيسجّل', (
    tester,
  ) async {
    await openScreen(tester);

    await tester.tap(find.text('كريم حسن'));
    await tester.pumpAndSettle();

    // الشيت: المجموعة مختارة والمبلغ متملّي من سعرها.
    expect(find.text(arL10n.paymentsRecord), findsOneWidget);
    expect(find.text('رياضيات أ'), findsWidgets);
    expect(find.text('450'), findsOneWidget);

    await tester.tap(find.text(arL10n.paymentsSave));
    await tester.pumpAndSettle();

    expect(payments.calls, contains(startsWith('record:s1:g1:')));
    expect(find.text(arL10n.paymentsFilterPaid), findsWidgets);
  });

  testWidgets('اللمس على مدفوع بيفتح الإلغاء، والسبب إلزامي', (tester) async {
    final now = DateTime.now();
    payments.payments.add(
      makePayment(studentId: 's1', groupId: 'g1', year: now.year, month: now.month),
    );
    await openScreen(tester);

    await tester.tap(find.text('كريم حسن'));
    await tester.pumpAndSettle();

    expect(find.text(arL10n.paymentsCancelTitle), findsOneWidget);

    // من غير سبب: رسالة الخطأ بتظهر ومفيش إلغاء.
    await tester.tap(find.text(arL10n.paymentsCancelConfirm));
    await tester.pumpAndSettle();
    expect(find.text(arL10n.paymentsCancelReasonRequired), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'اتسجلت بالغلط',
    );
    await tester.tap(find.text(arL10n.paymentsCancelConfirm));
    await tester.pumpAndSettle();

    expect(payments.calls, contains(startsWith('cancel:')));
    // رجع غير مدفوع: المدفوع الوحيد اختفى.
    expect(find.text(arL10n.paymentsFilterPaid), findsOneWidget); // الزرار بس
  });

  testWidgets('البحث بيفلتر بالاسم', (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'سارة');
    await tester.pumpAndSettle();

    expect(find.text('سارة علي'), findsOneWidget);
    expect(find.text('كريم حسن'), findsNothing);
  });

  testWidgets('فلتر المجموعة بيحصر الصفوف', (tester) async {
    await openScreen(tester);

    await tester.tap(find.text(arL10n.paymentsAllGroups));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فيزياء').last);
    await tester.pumpAndSettle();

    expect(find.text('سارة علي'), findsOneWidget);
    expect(find.text('كريم حسن'), findsNothing);
  });
}
