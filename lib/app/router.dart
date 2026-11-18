import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// أسماء المسارات في مكان واحد.
abstract final class AppRoutes {
  static const String splash = '/';
}

/// كل feature بتضيف سطرها هنا (سطر واحد لكل feature).
/// مثال: ...authRoutes,
final List<RouteBase> featureRoutes = <RouteBase>[
  // auth / centers / staff (A)
  // sessions / attendance (B)
  // students / linking / groups (C)
  // grades (D)
];

/// [routes] للاختبار بس. الافتراضي هو [featureRoutes].
/// التوجيه حسب الدور (redirect) هيتضاف هنا في خطوة 3.5.
GoRouter buildRouter({
  List<RouteBase>? routes,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('أهلاً بك في CenterNet'))),
      ),
      ...(routes ?? featureRoutes),
    ],
  );
}
