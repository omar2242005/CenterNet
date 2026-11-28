import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'group_route_names.dart';
import 'models/group.dart';
import 'repository/groups_repository.dart';
import 'screens/group_form_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerGroups(GetIt g) {
  g.registerLazySingleton<GroupsRepository>(
    () => GroupsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
/// القايمة وتسجيل الطلاب والحصص شاشات أدمن، مساراتها في admin_module.
/// فورم المجموعة هنا لأنه مشترك مع المعلم (إنشاء مجموعة بمعلم ثابت).
final List<RouteBase> groupRoutes = <RouteBase>[
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
];
