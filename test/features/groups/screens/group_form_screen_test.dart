import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/groups/screens/group_form_screen.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../../staff/helpers/fake_staff_repository.dart';
import '../helpers/fake_groups_repository.dart';

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
  late FakeGroupsRepository groupsRepo;
  late FakeStaffRepository staffRepo;

  setUp(() {
    groupsRepo = FakeGroupsRepository();
    staffRepo = FakeStaffRepository(members: [_sara, _karim]);
    sl.registerSingleton<GroupsRepository>(groupsRepo);
    sl.registerSingleton<StaffRepository>(staffRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  /// بنشغّل الفورم برواتر حقيقي عشان pop بعد الحفظ الناجح.
  Future<void> openForm(WidgetTester tester, {Group? editing}) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('القائمة')),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => GroupFormScreen(editing: editing),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
    router.push('/form');
    await tester.pumpAndSettle();
  }

  Future<void> pickTeacher(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سارة').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, arL10n.studentSave);
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('الحقول الإجبارية فاضية = رسالة مطلوب، من غير حفظ', (tester) async {
    await openForm(tester);
    await tapSave(tester);

    expect(find.text(arL10n.validationRequired), findsWidgets);
    expect(groupsRepo.calls, isEmpty);
  });

  testWidgets('مفيش معلمين نشطين = تحذير عربي', (tester) async {
    staffRepo.members.clear();
    await openForm(tester);

    expect(find.text(arL10n.groupNoTeachers), findsOneWidget);
  });

  testWidgets('إنشاء مجموعة بمعلم ومساعد وسعر', (tester) async {
    await openForm(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'مجموعة السبت',
    );
    await pickTeacher(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'كريم'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(5), '450');
    await tapSave(tester);

    expect(groupsRepo.calls, contains('create:مجموعة السبت'));
    // نجاح الحفظ بيرجع للقائمة.
    expect(find.text('القائمة'), findsOneWidget);
  });

  testWidgets('ميعادان متداخلان في نفس اليوم مرفوضين برسالة عربية',
      (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'مجموعة السبت');
    await pickTeacher(tester);
    // ميعادين بنفس اليوم والوقت الافتراضي.
    for (var i = 0; i < 2; i++) {
      final add = find.text(arL10n.groupAddSlot);
      await tester.scrollUntilVisible(
        add,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
    }
    await tapSave(tester);

    expect(find.text('يوجد ميعادان متداخلان في نفس اليوم.'), findsOneWidget);
    expect(groupsRepo.calls, isEmpty);
  });

  testWidgets('وضع التعديل بيتملّى بالبيانات وبيحفظ update', (tester) async {
    final existing = Group.fromMap('g1', <String, dynamic>{
      'centerId': 'c1',
      'name': 'مجموعة الأحد',
      'subject': 'كيمياء',
      'teacherId': 't1',
      'createdBy': 'u1',
      'assistantIds': <String>['s1'],
      'monthlyFee': 45000,
      'status': 'active',
      'slots': <Map<String, dynamic>>[
        <String, dynamic>{
          'weekday': 7,
          'startMinutes': 1080,
          'durationMinutes': 60,
        },
      ],
    });
    await openForm(tester, editing: existing);

    expect(find.text(arL10n.groupEditTitle), findsOneWidget);
    expect(find.text('مجموعة الأحد'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
    expect(find.text('٦٠'), findsNothing); // الأرقام لاتينية في الحقول
    await tapSave(tester);

    expect(groupsRepo.calls, contains('update:g1:مجموعة الأحد'));
  });

  testWidgets('فشل الحفظ بيظهر رسالته', (tester) async {
    groupsRepo.writeFailure = const Failure.permission();
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'مجموعة السبت');
    await pickTeacher(tester);
    await tapSave(tester);

    expect(find.text(const Failure.permission().message), findsOneWidget);
  });
}
