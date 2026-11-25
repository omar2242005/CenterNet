import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../groups/models/group.dart';
import 'repository/group_attendance_repository.dart';
import 'screens/group_details_screen.dart';
import 'screens/my_groups_screen.dart';
import 'teacher_route_names.dart';

/// سطر الـ DI بتاع الـ feature.
void registerTeacher(GetIt g) {
  g.registerLazySingleton<GroupAttendanceRepository>(
    () => GroupAttendanceRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
final List<RouteBase> teacherRoutes = <RouteBase>[
  GoRoute(
    path: TeacherRoutes.groups,
    builder: (context, state) => const MyGroupsScreen(),
  ),
  GoRoute(
    path: TeacherRoutes.groupDetails,
    builder: (context, state) {
      final group = state.extra;
      if (group is! Group) return const Scaffold(body: SizedBox.shrink());
      return GroupDetailsScreen(group: group);
    },
  ),
];