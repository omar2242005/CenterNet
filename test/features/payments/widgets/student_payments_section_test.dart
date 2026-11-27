import 'package:center_net/app/di.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/payments/repositories/payments_repository.dart';
import 'package:center_net/features/payments/widgets/student_payments_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../groups/helpers/fake_groups_repository.dart';
import '../cubit/student_payments_cubit_test.dart'
    show groupWithFee, studentWithGroups;
import '../helpers/fake_payments_repository.dart';

void main() {
  late FakePaymentsRepository payments;
  late FakeGroupsRepository groups;

  final student = studentWithGroups(<String>['g1']);

  setUp(() {
    payments = FakePaymentsRepository();
    groups = FakeGroupsRepository(
      groups: [groupWithFee('g1', 'رياضيات أ', 45000)],
    );
    sl.registerSingleton<PaymentsRepository>(payments);
    sl.registerSingleton<GroupsRepository>(groups);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> openSection(WidgetTester tester) async {
    await tester.pumpApp(StudentPaymentsSection(student: student));
    await tester.pumpAndSettle();
  }

  testWidgets('حالة فاضية: عنوان ورسالة وزر تسجيل', (tester) async {
    await openSection(tester);

    expect(find.text(arL10n.paymentsSectionTitle), findsOneWidget);
    expect(find.text(arL10n.paymentsEmpty), findsOneWidget);
    expect(find.text(arL10n.paymentsRecord), findsOneWidget);
  });

  testWidgets('تسجيل دفعة: المبلغ بيتملّى من سعر المجموعة والدفعة بتظهر', (
    tester,
  ) async {
    await openSection(tester);

    await tester.tap(find.text(arL10n.paymentsRecord));
    await tester.pumpAndSettle();

    // مجموعة واحدة: مختارة والمبلغ متملّي من سعرها (450 ج.م).
    expect(find.text('رياضيات أ'), findsWidgets);
    expect(find.text('450'), findsOneWidget);

    await tester.tap(find.text(arL10n.paymentsSave));
    await tester.pumpAndSettle();

    expect(find.text(arL10n.paymentsStatusPaid), findsOneWidget);
    expect(find.text('450 ج.م'), findsOneWidget);
  });

  testWidgets('شهر مدفوع قبل كده بيظهر رسالة الخطأ في الشيت', (tester) async {
    payments.payments.add(makePayment());
    await openSection(tester);

    await tester.tap(find.text(arL10n.paymentsRecord));
    await tester.pumpAndSettle();

    // الشهر الافتراضي هو الحالي، فنختار شهر الدفعة الموجودة (نوفمبر 2026).
    // لو الشهر الحالي هو نوفمبر 2026 هتفشل لوحدها؛ غير كده نسجّل مرتين:
    // الأولى تنجح والتانية تفشل.
    await tester.tap(find.text(arL10n.paymentsSave));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    if (now.year != 2026 || now.month != 11) {
      await tester.tap(find.text(arL10n.paymentsRecord));
      await tester.pumpAndSettle();
      await tester.tap(find.text(arL10n.paymentsSave));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('مدفوع بالفعل'), findsWidgets);
  });

  testWidgets('إلغاء دفعة: السبب إجباري والدفعة بتتحول لملغاة', (tester) async {
    payments.payments.add(makePayment());
    await openSection(tester);

    expect(find.text(arL10n.paymentsStatusPaid), findsOneWidget);

    await tester.tap(find.text(arL10n.paymentsCancelAction));
    await tester.pumpAndSettle();

    // تأكيد من غير سبب: رسالة خطأ والديالوج مكانه.
    await tester.tap(find.text(arL10n.paymentsCancelConfirm));
    await tester.pumpAndSettle();
    expect(find.text(arL10n.paymentsCancelReasonRequired), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'اتسجلت بالغلط');
    await tester.tap(find.text(arL10n.paymentsCancelConfirm));
    await tester.pumpAndSettle();

    expect(find.text(arL10n.paymentsStatusCancelled), findsOneWidget);
    expect(
      find.text(arL10n.paymentsCancelledReason('اتسجلت بالغلط')),
      findsOneWidget,
    );
  });
}
