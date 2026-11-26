import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/home/screens/role_home_screen.dart';
import 'package:center_net/features/teacher/teacher_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('رئيسية المعلم فيها زر مجموعاتي وبيفتح شاشة المجموعات',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => RoleHomeScreen(
            title: 'معلم',
            actions: [
              (
                label: AppLocalizations.of(context).myGroupsTitle,
                route: TeacherRoutes.groups,
              ),
            ],
          ),
        ),
        GoRoute(
          path: TeacherRoutes.groups,
          builder: (_, _) => const Scaffold(body: Text('TEACHER_GROUPS')),
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
    expect(find.text('مجموعاتي'), findsOneWidget);
    await tester.tap(find.text('مجموعاتي'));
    await tester.pumpAndSettle();
    expect(find.text('TEACHER_GROUPS'), findsOneWidget);
  });
}
