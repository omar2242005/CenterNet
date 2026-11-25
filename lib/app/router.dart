import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/assistant_module.dart';
import '../features/auth/auth_module.dart';
import '../features/centers/centers_module.dart';
import '../features/grades/grades_module.dart';
import '../features/groups/groups_module.dart';
import '../features/home/home_module.dart';
import '../features/staff/staff_module.dart';
import '../features/students/students_module.dart';
import '../features/teacher/teacher_module.dart';

/// أسماء المسارات في مكان واحد.
abstract final class AppRoutes {
  static const String splash = '/';
}

/// كل feature بتضيف سطرها هنا (سطر واحد لكل feature).
final List<RouteBase> featureRoutes = <RouteBase>[
  ...authRoutes,
  ...homeRoutes,
  ...centerRoutes,
  ...staffRoutes,
  ...studentRoutes,
  ...groupRoutes,
  ...gradeRoutes,
  ...assistantRoutes,
  ...teacherRoutes,
];

/// [routes] للاختبار بس. الافتراضي هو [featureRoutes].
/// [splashBuilder]: شاشة البداية. الافتراضي نص ثابت (عشان الاختبارات من غير Firebase)،
/// و main.dart بيبعت AuthGateScreen.
GoRouter buildRouter({
  List<RouteBase>? routes,
  String initialLocation = AppRoutes.splash,
  WidgetBuilder? splashBuilder,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: redirect,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            splashBuilder?.call(context) ??
            const Scaffold(body: Center(child: Text('أهلاً بك في CenterNet'))),
      ),
      ...(routes ?? featureRoutes),
    ],
  );
}