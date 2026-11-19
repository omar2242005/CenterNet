import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';
import 'package:center_net/features/staff/screens/staff_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_staff_repository.dart';

const _admin = StaffMember(
  uid: 'a1',
  name: 'مدير السنتر',
  role: StaffMemberRole.admin,
  active: true,
);
const _sara = StaffMember(
  uid: 't1',
  name: 'سارة',
  role: StaffMemberRole.teacher,
  active: true,
);
const _karim = StaffMember(
  uid: 's1',
  name: 'كريم',
  role: StaffMemberRole.assistant,
  active: true,
);

void main() {
  late FakeStaffRepository repo;

  setUp(() {
    repo = FakeStaffRepository(members: [_admin, _sara, _karim]);
    sl.registerSingleton<StaffRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpApp(const StaffListScreen());
    await tester.pumpAndSettle();
  }

  /// بيفتح قائمة أول موظف قابل للتعديل (سارة).
  Future<void> openSaraMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip(arL10n.staffMenuTooltip).first);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> tapDialogConfirm(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('بيعرض الأعضاء بأدوارهم وحالتهم', (tester) async {
    await openScreen(tester);

    expect(find.text('مدير السنتر'), findsOneWidget);
    expect(find.text('سارة'), findsOneWidget);
    expect(find.text('كريم'), findsOneWidget);
    expect(find.text(arL10n.staffRoleAdmin), findsOneWidget);
    expect(find.text(arL10n.staffRoleTeacher), findsOneWidget);
    expect(find.text(arL10n.staffRoleAssistant), findsOneWidget);
    expect(find.text(arL10n.staffStatusActive), findsNWidgets(3));
  });

  testWidgets('الأدمن من غير قائمة تعديل، وباقي الأعضاء ليهم', (tester) async {
    await openScreen(tester);

    expect(find.byTooltip(arL10n.staffMenuTooltip), findsNWidgets(2));
  });

  testWidgets('قائمة فاضية: رسالة فارغة', (tester) async {
    repo.members.clear();
    await openScreen(tester);

    expect(find.text(arL10n.staffListEmpty), findsOneWidget);
  });

  testWidgets('فشل التحميل: رسالة الخطأ وإعادة المحاولة', (tester) async {
    repo.loadFailure = const Failure.network();
    await openScreen(tester);

    expect(find.text(const Failure.network().message), findsOneWidget);

    repo.loadFailure = null;
    await tapText(tester, arL10n.retry);

    expect(find.text('سارة'), findsOneWidget);
  });

  testWidgets('تعطيل موظف بتأكيد: بيكتب وبتتغير الشارة', (tester) async {
    await openScreen(tester);

    await openSaraMenu(tester);
    await tapText(tester, arL10n.staffActionDisable);
    expect(find.text(arL10n.staffDisableMessage('سارة')), findsOneWidget);
    await tapDialogConfirm(tester, arL10n.staffActionDisable);

    expect(repo.calls.last, 'active:c1:t1:false');
    expect(find.text(arL10n.staffStatusDisabled), findsOneWidget);
    expect(find.text(arL10n.staffStatusActive), findsNWidgets(2));
  });

  testWidgets('إلغاء نافذة التأكيد: مفيش كتابة', (tester) async {
    await openScreen(tester);

    await openSaraMenu(tester);
    await tapText(tester, arL10n.staffActionDisable);
    await tapText(tester, arL10n.cancel);

    expect(repo.calls, ['load']);
    expect(find.text(arL10n.staffStatusDisabled), findsNothing);
  });

  testWidgets('إعادة تفعيل موظف معطّل', (tester) async {
    repo.members[1] = _sara.copyWith(active: false);
    await openScreen(tester);
    expect(find.text(arL10n.staffStatusDisabled), findsOneWidget);

    // المعطّل بيتحط بعد النشطين في الترتيب اللي الـ Repository الحقيقي بيعمله،
    // لكن الـ fake بيرجّع الترتيب زي ما هو، فسارة لسه التانية.
    await openSaraMenu(tester);
    await tapText(tester, arL10n.staffActionEnable);
    await tapDialogConfirm(tester, arL10n.staffActionEnable);

    expect(repo.calls.last, 'active:c1:t1:true');
    expect(find.text(arL10n.staffStatusDisabled), findsNothing);
  });

  testWidgets('تغيير الدور بتأكيد: معلم يبقى مساعد', (tester) async {
    await openScreen(tester);

    await openSaraMenu(tester);
    await tapText(
      tester,
      arL10n.staffActionChangeRoleTo(arL10n.staffRoleAssistant),
    );
    await tapDialogConfirm(tester, arL10n.staffChangeRoleConfirm);

    expect(repo.calls.last, 'role:c1:t1:assistant');
    expect(find.text(arL10n.staffRoleTeacher), findsNothing);
    expect(find.text(arL10n.staffRoleAssistant), findsNWidgets(2));
  });

  testWidgets('فشل الكتابة: رسالة خطأ والقائمة زي ما هي', (tester) async {
    repo.writeFailure = const Failure.permission();
    await openScreen(tester);

    await openSaraMenu(tester);
    await tapText(tester, arL10n.staffActionDisable);
    await tapDialogConfirm(tester, arL10n.staffActionDisable);

    expect(find.text(const Failure.permission().message), findsOneWidget);
    expect(find.text(arL10n.staffStatusActive), findsNWidgets(3));
    expect(find.text(arL10n.staffStatusDisabled), findsNothing);
  });
}
