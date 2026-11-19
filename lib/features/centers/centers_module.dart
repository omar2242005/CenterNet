import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'centers_route_names.dart';
import 'repository/centers_repository.dart';
import 'screens/center_settings_screen.dart';
import 'screens/create_center_screen.dart';

/// سطر الـ DI بتاع الـ feature (بيتنادى من registerFeatures في di.dart).
void registerCenters(GetIt g) {
  g.registerLazySingleton<CentersRepository>(
    () => CentersRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature (بيتنشر في featureRoutes).
final List<RouteBase> centersRoutes = <RouteBase>[
  GoRoute(
    path: CentersRoutes.create,
    builder: (context, state) => const CreateCenterScreen(),
  ),
  GoRoute(
    path: CentersRoutes.settings,
    builder: (context, state) => const CenterSettingsScreen(),
  ),
];
