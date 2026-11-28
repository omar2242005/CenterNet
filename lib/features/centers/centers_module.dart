import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'center_route_names.dart';
import 'repository/centers_repository.dart';
import 'screens/create_center_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerCenters(GetIt g) {
  g.registerLazySingleton<CentersRepository>(
    () => CentersRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
/// إعدادات السنتر شاشة أدمن، مسارها في admin_module.
/// إنشاء السنتر هنا لأنه جزء من أول تسجيل دخول.
final List<RouteBase> centerRoutes = <RouteBase>[
  GoRoute(
    path: CenterRoutes.create,
    builder: (context, state) => const CreateCenterScreen(),
  ),
];
