import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'link_route_names.dart';
import 'repository/linking_repository.dart';
import 'screens/link_code_screen.dart';
import 'screens/link_request_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerLinking(GetIt g) {
  g.registerLazySingleton<LinkingRepository>(
    () => LinkingRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
/// طلبات الربط (شاشة الأدمن) مسارها في admin_module.
final List<RouteBase> linkingRoutes = <RouteBase>[
  GoRoute(
    path: LinkRoutes.enter,
    builder: (context, state) =>
        LinkCodeScreen(kind: linkKindFromExtra(state.extra)),
  ),
  GoRoute(
    path: LinkRoutes.request,
    builder: (context, state) =>
        LinkRequestScreen(kind: linkKindFromExtra(state.extra)),
  ),
];
