import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../students/models/student.dart';
import 'child_route_names.dart';
import 'models/updates_args.dart';
import 'repository/student_data_repository.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/child_overview_screen.dart';
import 'screens/child_profile_screen.dart';
import 'screens/exam_details_screen.dart';
import 'screens/results_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/updates_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerStudentArea(GetIt g) {
  g.registerLazySingleton<StudentDataRepository>(
    () => StudentDataRepository(g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature. معظم الشاشات بتاخد `extra: Student`.
final List<RouteBase> studentAreaRoutes = <RouteBase>[
  GoRoute(
    path: ChildRoutes.schedule,
    builder: (context, state) {
      final s = state.extra;
      if (s is! Student) return const _MissingArgs();
      return ScheduleScreen(student: s);
    },
  ),
  GoRoute(
    path: ChildRoutes.attendance,
    builder: (context, state) {
      final s = state.extra;
      if (s is! Student) return const _MissingArgs();
      return AttendanceHistoryScreen(student: s);
    },
  ),
  GoRoute(
    path: ChildRoutes.results,
    builder: (context, state) {
      final s = state.extra;
      if (s is! Student) return const _MissingArgs();
      return ResultsScreen(student: s);
    },
  ),
  GoRoute(
    path: ChildRoutes.profile,
    builder: (context, state) {
      final s = state.extra;
      if (s is! Student) return const _MissingArgs();
      return ChildProfileScreen(student: s);
    },
  ),
  GoRoute(
    path: ChildRoutes.overview,
    builder: (context, state) {
      final s = state.extra;
      if (s is! Student) return const _MissingArgs();
      return ChildOverviewScreen(student: s);
    },
  ),
  GoRoute(
    path: ChildRoutes.exam,
    builder: (context, state) {
      final a = state.extra;
      if (a is! ExamDetailsArgs) return const _MissingArgs();
      return ExamDetailsScreen(args: a);
    },
  ),
  GoRoute(
    path: ChildRoutes.updates,
    builder: (context, state) {
      final a = state.extra;
      if (a is! UpdatesArgs) return const _MissingArgs();
      return UpdatesScreen(args: a);
    },
  ),
];

/// لو الشاشة اتفتحت من غير البيانات (مثلًا refresh على الويب).
class _MissingArgs extends StatelessWidget {
  const _MissingArgs();

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
