import 'package:center_net/app/di.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/groups/screens/groups_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_groups_repository.dart';

void main() {
  late FakeGroupsRepository repo;

  setUp(() {
    repo = FakeGroupsRepository(
      groups: [
        Group.fromMap('g1', <String, dynamic>{
          'centerId': 'c1',
          'name': 'مجموعة السبت',
          'subject': 'فيزياء',
          'grade': '٣ ثانوي',
          'teacherId': 't1',
          'createdBy': 'u1',
          'assistantIds': <String>[],
          'room': 'قاعة ٢',
          'monthlyFee': 45000,
          'status': 'active',
          'slots': <Map<String, dynamic>>[
            <String, dynamic>{
              'weekday': 6,
              'startMinutes': 1020,
              'durationMinutes': 90,
            },
          ],
        }),
        makeGroup('g2', 'مجموعة الأحد'),
        makeGroup('g3', 'مجموعة قديمة', archived: true),
      ],
    );
    sl.registerSingleton<GroupsRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> openList(WidgetTester tester) async {
    await tester.pumpApp(const GroupsListScreen());
    await tester.pumpAndSettle();
  }

  testWidgets('بتعرض النشطة وتخفي المؤرشفة', (tester) async {
    await openList(tester);

    expect(find.text('مجموعة السبت'), findsOneWidget);
    expect(find.text('مجموعة الأحد'), findsOneWidget);
    expect(find.text('مجموعة قديمة'), findsNothing);
  });

  testWidgets('الكارت بيعرض المادة والصف والميعاد والقاعة والسعر', (tester) async {
    await openList(tester);

    expect(find.text('فيزياء · ٣ ثانوي'), findsOneWidget);
    expect(find.textContaining('السبت'), findsWidgets);
    expect(find.textContaining('قاعة ٢'), findsOneWidget);
    expect(find.textContaining('450'), findsOneWidget);
  });

  testWidgets('زر الأرشيف بيظهر المؤرشفة بشارتها', (tester) async {
    await openList(tester);

    await tester.tap(find.byTooltip(arL10n.groupsShowArchived));
    await tester.pumpAndSettle();

    expect(find.text('مجموعة قديمة'), findsOneWidget);
    expect(find.text(arL10n.groupArchivedBadge), findsOneWidget);
  });

  testWidgets('البحث بالتطبيع العربي', (tester) async {
    await openList(tester);

    await tester.enterText(find.byType(TextField), 'مجموعه السبت');
    await tester.pumpAndSettle();

    expect(find.text('مجموعة السبت'), findsOneWidget);
    expect(find.text('مجموعة الأحد'), findsNothing);
  });

  testWidgets('بحث من غير نتايج بيعرض رسالة', (tester) async {
    await openList(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text(arL10n.groupsNoResults), findsOneWidget);
  });

  testWidgets('سنتر فاضي بيعرض رسالة فارغ', (tester) async {
    repo.groups.clear();
    await openList(tester);

    expect(find.text(arL10n.groupsEmpty), findsOneWidget);
  });

  testWidgets('الأرشفة من القائمة بعد التأكيد', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.groupArchiveAction));
    await tester.pumpAndSettle();

    // نافذة التأكيد ظهرت باسم المجموعة.
    expect(find.text(arL10n.groupArchiveTitle), findsOneWidget);
    await tester.tap(find.text(arL10n.groupArchiveConfirm));
    await tester.pumpAndSettle();

    expect(find.text('مجموعة السبت'), findsNothing);
    expect(repo.calls, contains('archive:g1'));
  });

  testWidgets('إلغاء نافذة الأرشفة مبيغيرش حاجة', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.groupArchiveAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.cancel));
    await tester.pumpAndSettle();

    expect(find.text('مجموعة السبت'), findsOneWidget);
    expect(repo.calls, isNot(contains('archive:g1')));
  });
}
