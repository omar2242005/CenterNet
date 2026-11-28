import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'repository/students_repository.dart';

/// سطر الـ DI بتاع الـ feature.
/// شاشات الطلاب بقت في features/admin، ومساراتها في admin_module.
void registerStudents(GetIt g) {
  g.registerLazySingleton<StudentsRepository>(
    () => StudentsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}
