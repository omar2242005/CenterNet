import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'group_route_names.dart';
import 'models/group.dart';
import 'repository/groups_repository.dart';
import 'screens/group_enrollment_screen.dart';
import 'screens/group_form_screen.dart';
import 'screens/groups_list_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerGroups(GetIt g) {
  g.registerLazySingleton<GroupsRepository>(
    () => GroupsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature. تسجيل الطلاب والحصص بتتضاف مع شاشاتها.
final List<RouteBase> groupRoutes = <RouteBase>[
  GoRoute(
    path: GroupRoutes.list,
    builder: (context, state) => const GroupsListScreen(),
  ),
  GoRoute(
    path: GroupRoutes.create,
    builder: (context, state) => const GroupFormScreen(),
  ),
  GoRoute(
    path: GroupRoutes.edit,
    redirect: (context, state) =>
        state.extra is Group ? null : GroupRoutes.list,
    builder: (context, state) =>
        GroupFormScreen(editing: state.extra! as Group),
  ),
  GoRoute(
    path: GroupRoutes.students,
    redirect: (context, state) =>
        state.extra is Group ? null : GroupRoutes.list,
    builder: (context, state) =>
        GroupEnrollmentScreen(group: state.extra! as Group),
  ),
];
