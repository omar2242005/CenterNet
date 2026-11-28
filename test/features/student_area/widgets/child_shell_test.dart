import 'package:center_net/app/di.dart';
import 'package:center_net/app/session_role.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/home/home_route_names.dart';
import 'package:center_net/features/home/models/home_destination.dart';
import 'package:center_net/features/student_area/child_route_names.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:center_net/features/student_area/widgets/child_shell.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../students/helpers/fake_students_repository.dart';

/// شاشة تفاصيل بتستخدم [ChildShell] بـ isDetail، عشان نتأكد إن التبويبات
/// بتفضل ظاهرة وإن التبويب المضلَّل بيرجّع لشاشته بدل ما يتجاهل الضغطة.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required bool isDetail,
  HomeDestination role = HomeDestination.student,
  Student? student,
}) async {
  sl.registerSingleton<SessionRole>(SessionRole()..set(role));
  Widget stub(String t) => Scaffold(body: Text(t));
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) => ChildShell(
          current: ChildTab.home,
          isDetail: isDetail,
          title: 'تفاصيل',
          student: student,
          body: const SizedBox.shrink(),
        ),
      ),
      GoRoute(path: HomeRoutes.student, builder: (_, _) => stub('HOME')),
      GoRoute(path: HomeRoutes.guardian, builder: (_, _) => stub('GUARDIAN')),
      GoRoute(path: ChildRoutes.schedule, builder: (_, _) => stub('SCHEDULE')),
      GoRoute(path: ChildRoutes.results, builder: (_, _) => stub('RESULTS')),
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

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets('شاشة التفاصيل بتعرض التبويبات الأربعة', (tester) async {
    await _pump(tester, isDetail: true);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 4);
    expect(bar.selectedIndex, ChildTab.home.index);
  });

  testWidgets('في شاشة تفاصيل، ضغط التبويب المضلَّل بيرجّع لرئيسته', (
    tester,
  ) async {
    await _pump(tester, isDetail: true);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(arL10nForTest().childNavHome),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('في تبويب عادي، ضغط نفس التبويب مبيعملش حاجة', (tester) async {
    await _pump(tester, isDetail: false);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(arL10nForTest().childNavHome),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('ولي الأمر: تبويب الحصص بيفتح الجدول', (tester) async {
    await _pump(
      tester,
      isDetail: true,
      role: HomeDestination.guardian,
      student: makeStudent(1, 'أحمد'),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(arL10nForTest().childNavSchedule),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SCHEDULE'), findsOneWidget);
  });
}

/// نصوص arb من غير widget.
AppLocalizations arL10nForTest() => lookupAppLocalizations(const Locale('ar'));
