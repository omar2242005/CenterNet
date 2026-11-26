import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/features/home/home_route_names.dart';
import 'package:center_net/features/teacher/cubit/teacher_home_cubit.dart';
import 'package:center_net/features/teacher/rules/teacher_home_builder.dart';
import 'package:center_net/features/teacher/screens/teacher_home_screen.dart';
import 'package:center_net/features/teacher/teacher_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/fake_teacher_home_repository.dart';
import '../helpers/teacher_fixtures.dart';

void main() {
  tzdata.initializeTimeZones();

  final cairo = tz.getLocation('Africa/Cairo');
  final now = tz.TZDateTime(cairo, 2026, 11, 9, 15);

  late FakeTeacherHomeRepository repo;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    sl.registerFactory<TeacherHomeCubit>(
      () => TeacherHomeCubit(repo, clock: () => now),
    );
    final router = GoRouter(
      initialLocation: HomeRoutes.teacher,
      routes: [
        GoRoute(
          path: HomeRoutes.teacher,
          builder: (_, _) => const TeacherHomeScreen(),
        ),
        GoRoute(
          path: TeacherRoutes.groups,
          builder: (_, _) => const Scaffold(body: Text('MY_GROUPS')),
        ),
        GoRoute(
          path: AuthRoutes.myAccount,
          builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
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
  }

  tearDown(() async {
    await sl.reset();
  });

  void withData({bool withSession = true}) {
    repo = FakeTeacherHomeRepository(
      data: buildTeacherHomeData(
        name: 'سارة أحمد',
        groups: [
          fakeGroup('g1', room: '3001'),
          fakeGroup('g2'),
        ],
        students: [
          fakeStudent('s1', 1, ['g1']),
          fakeStudent('s2', 2, ['g1', 'g2']),
        ],
        sessions: [
          if (withSession)
            fakeSession('g1', tz.TZDateTime(cairo, 2026, 11, 9, 16)),
        ],
        now: now,
      ),
    );
  }

  testWidgets('بيعرض التحية والإحصائيات والحصة القادمة', (tester) async {
    withData();
    await open(tester);
    expect(find.text('أهلاً، سارة أحمد'), findsOneWidget);
    expect(find.text('مجموعاتك النشطة'), findsOneWidget);
    expect(find.text('العام الدراسي 2026 – 2027'), findsOneWidget);
    expect(find.text('2 طالبًا · المواد: رياضيات'), findsOneWidget);
    expect(find.text('الحصة القادمة'), findsOneWidget);
    expect(find.text('القاعة: 3001 · 2 طالبًا'), findsOneWidget);
    expect(find.text('قادمة'), findsOneWidget);
    expect(find.textContaining('اليوم'), findsOneWidget);
  });

  testWidgets('من غير حصص قادمة بيظهر رسالة', (tester) async {
    withData(withSession: false);
    await open(tester);
    expect(find.text('مفيش حصص قادمة في جدولك دلوقتي.'), findsOneWidget);
  });

  testWidgets('زر عرض مجموعاتي وتبويب مجموعاتي بيفتحوا مجموعاتي', (
    tester,
  ) async {
    withData();
    await open(tester);
    await tester.tap(find.text('عرض مجموعاتي'));
    await tester.pumpAndSettle();
    expect(find.text('MY_GROUPS'), findsOneWidget);
  });

  testWidgets('تبويب حسابي بيفتح حسابي، وفيه تبويب الامتحانات', (tester) async {
    withData();
    await open(tester);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('الامتحانات'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('حسابي'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
  });

  testWidgets('خطأ: رسالة وإعادة محاولة', (tester) async {
    repo = FakeTeacherHomeRepository(failure: const Failure.network());
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
