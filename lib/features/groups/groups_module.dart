import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'repository/groups_repository.dart';

/// سطر الـ DI بتاع الـ feature.
void registerGroups(GetIt g) {
  g.registerLazySingleton<GroupsRepository>(
    () => GroupsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature. الشاشات بتتضاف في الموجة 2.
final List<RouteBase> groupRoutes = <RouteBase>[];
