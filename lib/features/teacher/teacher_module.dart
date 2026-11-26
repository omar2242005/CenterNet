import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../groups/models/group.dart';
import '../groups/repository/groups_repository.dart';
import '../students/repository/students_repository.dart';
import '../grades/repositories/exams_repository.dart';
import '../grades/repositories/scores_repository.dart';
import 'cubit/teacher_exams_cubit.dart';
import 'cubit/teacher_home_cubit.dart';
import 'models/exam_summary.dart';
import 'repository/group_attendance_repository.dart';
import 'repository/teacher_exams_repository.dart';
import 'repository/teacher_home_repository.dart';
import 'screens/group_details_screen.dart';
import 'screens/my_groups_screen.dart';
import 'screens/teacher_exam_details_screen.dart';
import 'screens/teacher_exam_form_screen.dart';
import 'screens/teacher_exam_scores_screen.dart';
import 'screens/teacher_exams_screen.dart';
import 'teacher_route_names.dart';

/// سطر الـ DI بتاع الـ feature.
void registerTeacher(GetIt g) {
  g.registerLazySingleton<GroupAttendanceRepository>(
    () => GroupAttendanceRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerLazySingleton<TeacherHomeRepository>(
    () => FirestoreTeacherHomeRepository(
      g<FirebaseAuth>(),
      g<FirebaseFirestore>(),
      g<GroupsRepository>(),
      g<StudentsRepository>(),
    ),
  );
  g.registerLazySingleton<TeacherExamsRepository>(
    () => FirestoreTeacherExamsRepository(
      g<GroupsRepository>(),
      g<StudentsRepository>(),
      g<ExamsRepository>(),
      g<ScoresRepository>(),
    ),
  );
  g.registerFactory<TeacherExamsCubit>(
    () => TeacherExamsCubit(g<TeacherExamsRepository>()),
  );
  g.registerFactory<TeacherHomeCubit>(
    () => TeacherHomeCubit(g<TeacherHomeRepository>()),
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
  GoRoute(
    path: TeacherRoutes.exams,
    builder: (context, state) => const TeacherExamsScreen(),
  ),
  GoRoute(
    path: TeacherRoutes.examCreate,
    builder: (context, state) => const TeacherExamFormScreen(),
  ),
  GoRoute(
    path: TeacherRoutes.examDetails,
    builder: (context, state) {
      final args = state.extra;
      if (args is! TeacherExamArgs) {
        return const Scaffold(body: SizedBox.shrink());
      }
      return TeacherExamDetailsScreen(args: args);
    },
  ),
  GoRoute(
    path: TeacherRoutes.examScores,
    builder: (context, state) {
      final args = state.extra;
      if (args is! TeacherExamArgs) {
        return const Scaffold(body: SizedBox.shrink());
      }
      return TeacherExamScoresScreen(args: args);
    },
  ),
];
