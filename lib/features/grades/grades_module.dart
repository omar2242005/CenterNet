import 'package:center_net/features/grades/screens/exam_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../groups/models/group.dart';
import 'grade_route_names.dart';
import 'repositories/exams_repository.dart';
import 'repositories/scores_repository.dart';

/// سطر الـ DI بتاع الـ feature.
void registerGrades(GetIt g) {
  g.registerLazySingleton<ExamsRepository>(
    () => ExamsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerLazySingleton<ScoresRepository>(
    () => ScoresRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
/// قايمة الامتحانات وإدخال الدرجات شاشات أدمن، مساراتها في admin_module.
/// فورم الامتحان هنا لأنه مشترك مع المعلم.
final List<RouteBase> gradeRoutes = <RouteBase>[
  GoRoute(
    path: GradeRoutes.examCreate,
    builder: (context, state) {
      final group = state.extra;
      if (group is! Group) return const _MissingArgs();
      return ExamFormScreen(group: group);
    },
  ),
];

/// لو الشاشة اتفتحت من غير البيانات (مثلًا refresh على الويب).
class _MissingArgs extends StatelessWidget {
  const _MissingArgs();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SizedBox.shrink());
}
