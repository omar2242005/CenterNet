import 'package:center_net/app/di.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/models/group_input.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/groups/screens/group_form_screen.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';
import 'package:center_net/features/teacher/screens/my_groups_screen.dart';
import 'package:center_net/features/teacher/teacher_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../groups/helpers/fake_groups_repository.dart';
import '../../staff/helpers/fake_staff_repository.dart';

class _RecordingGroupsRepository extends FakeGroupsRepository {
  _RecordingGroupsRepository();

  final List<GroupInput> inputs = <GroupInput>[];

  @override
  Future<Group> createGroup(GroupInput input) {
    inputs.add(input);
    return super.createGroup(input);
  }
}

const _me = StaffMember(
  uid: 'me',
  name: 'المعلم أنا',
  role: StaffMemberRole.teacher,
  active: true,
);
const _otherTeacher = StaffMember(
  uid: 't2',
  name: 'معلم تاني',
  role: StaffMemberRole.teacher,
  active: true,
);
const _karim = StaffMember(
  uid: 's1',
  name: 'كريم',
  role: StaffMemberRole.assistant,
  active: true,
);
const _offAssistant = StaffMember(
  uid: 's2',
  name: 'مساعد معطل',
  role: StaffMemberRole.assistant,
  active: false,
);

void main() {
  late _RecordingGroupsRepository groupsRepo;
  final l10n = lookupAppLocalizations(const Locale('ar'));

  setUp(() {
    groupsRepo = _RecordingGroupsRepository();
    sl.registerSingleton<GroupsRepository>(groupsRepo);
    sl.registerSingleton<StaffRepository>(
      FakeStaffRepository(members: [_me, _otherTeacher, _karim, _offAssistant]),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required Widget start,
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (_, _) => start),
        GoRoute(
          path: TeacherRoutes.groupCreate,
          builder: (_, _) => const GroupFormScreen(fixedTeacherId: 'me'),
        ),
        GoRoute(
          path: TeacherRoutes.groupDetails,
          builder: (_, _) => const Scaffold(body: Text('DETAILS')),
        ),
        GoRoute(
          path: TeacherRoutes.groups,
          builder: (_, _) => const Scaffold(body: Text('MY_GROUPS')),
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
    return router;
  }

  testWidgets('فورم المعلم: مفيش منتقي معلم، والمساعدين النشطين بس', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      start: const GroupFormScreen(fixedTeacherId: 'me'),
    );
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text(l10n.groupFieldTeacher), findsNothing);
    expect(find.text('كريم'), findsOneWidget);
    expect(find.text('مساعد معطل'), findsNothing);
    expect(find.text('معلم تاني'), findsNothing);
    expect(find.text('المعلم أنا'), findsNothing);
  });

  testWidgets('فورم الأدمن لسه فيه منتقي المعلم', (tester) async {
    await pumpRouter(tester, start: const GroupFormScreen());
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('الحفظ بيبعت teacherId = المعلم الحالي مع المساعدين المختارين', (
    tester,
  ) async {
    final router = await pumpRouter(tester, start: const SizedBox());
    router.push(TeacherRoutes.groupCreate);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'مجموعة المعلم');
    await tester.tap(find.text('كريم'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, l10n.studentSave);
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(groupsRepo.inputs, hasLength(1));
    expect(groupsRepo.inputs.single.teacherId, 'me');
    expect(groupsRepo.inputs.single.assistantIds, ['s1']);
    expect(groupsRepo.inputs.single.name, 'مجموعة المعلم');
  });

  testWidgets('الاسم فاضي: مفيش حفظ', (tester) async {
    final router = await pumpRouter(tester, start: const SizedBox());
    router.push(TeacherRoutes.groupCreate);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, l10n.studentSave);
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(groupsRepo.inputs, isEmpty);
  });

  testWidgets(
    'مجموعاتي: زر إنشاء مجموعة بيفتح الفورم وبعد الحفظ القائمة بتتحدث',
    (tester) async {
      await pumpRouter(tester, start: const MyGroupsScreen());
      expect(find.text(l10n.teacherGroupsAdd), findsOneWidget);
      expect(groupsRepo.calls.where((c) => c == 'loadMy'), hasLength(1));

      await tester.tap(find.text(l10n.teacherGroupsAdd));
      await tester.pumpAndSettle();
      expect(find.text(l10n.groupsAddTitle), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'مجموعة جديدة');
      final button = find.widgetWithText(FilledButton, l10n.studentSave);
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text(l10n.teacherGroupsAdd), findsOneWidget);
      expect(groupsRepo.calls.where((c) => c == 'loadMy'), hasLength(2));
    },
  );
}
