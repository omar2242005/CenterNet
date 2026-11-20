import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'models/student.dart';
import 'repository/students_repository.dart';
import 'screens/student_detail_screen.dart';
import 'screens/student_form_screen.dart';
import 'screens/students_list_screen.dart';
import 'student_route_names.dart';

/// سطر الـ DI بتاع الـ feature.
void registerStudents(GetIt g) {
  g.registerLazySingleton<StudentsRepository>(
    () => StudentsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
final List<RouteBase> studentRoutes = <RouteBase>[
  GoRoute(
    path: StudentRoutes.list,
    builder: (context, state) => const StudentsListScreen(),
  ),
  GoRoute(
    path: StudentRoutes.create,
    builder: (context, state) => const StudentFormScreen(),
  ),
  GoRoute(
    path: StudentRoutes.detail,
    redirect: (context, state) =>
        state.extra is Student ? null : StudentRoutes.list,
    builder: (context, state) =>
        StudentDetailScreen(student: state.extra! as Student),
  ),
  GoRoute(
    path: StudentRoutes.edit,
    redirect: (context, state) =>
        state.extra is Student ? null : StudentRoutes.list,
    builder: (context, state) =>
        StudentFormScreen(editing: state.extra! as Student),
  ),
];
