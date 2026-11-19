import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/attendance/attendance_module.dart';
import '../features/auth/auth_module.dart';
import '../features/centers/centers_module.dart';
import '../features/staff/staff_module.dart';

/// أسماء المسارات في مكان واحد.
abstract final class AppRoutes {
  static const String splash = '/';
}

/// كل feature بتضيف سطرها هنا (سطر واحد لكل feature).
/// مثال: ...authRoutes,
final List<RouteBase> featureRoutes = <RouteBase>[
  // auth / centers / staff (A)
  ...authRoutes,
  ...centerRoutes,
  ...staffRoutes,
  // sessions / attendance (B)
  ...attendanceRoutes,
  // students / linking / groups (C)
  // grades (D)
];

/// [routes] للاختبار بس. الافتراضي هو [featureRoutes].
/// [splashBuilder]: شاشة البداية. الافتراضي نص ثابت (عشان الاختبارات من غير Firebase)،
/// و main.dart بيبعت AuthGateScreen.
/// التوجيه حسب الدور (redirect) هيتضاف هنا في خطوة 3.5.
GoRouter buildRouter({
  List<RouteBase>? routes,
  String initialLocation = AppRoutes.splash,
  WidgetBuilder? splashBuilder,
}) {
  return GoRouter(
    initialLocation: initialLocation,
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
