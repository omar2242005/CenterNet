import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'repository/staff_join_repository.dart';
import 'repository/staff_repository.dart';
import 'screens/staff_join_screen.dart';
import 'staff_route_names.dart';

/// سطر الـ DI بتاع الـ feature.
void registerStaff(GetIt g) {
  g.registerLazySingleton<StaffRepository>(
    () => StaffRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerLazySingleton<StaffJoinRepository>(
    () => StaffJoinRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
/// قايمة الفريق والدعوات شاشات أدمن، مساراتها في admin_module.
/// شاشة الانضمام هنا لأن أي حد جاي بكود دعوة بيعدي عليها.
final List<RouteBase> staffRoutes = <RouteBase>[
  GoRoute(
    path: StaffRoutes.join,
    builder: (context, state) => const StaffJoinScreen(),
  ),
];
