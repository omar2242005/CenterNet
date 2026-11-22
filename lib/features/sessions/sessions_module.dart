import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'repository/sessions_repository.dart';

/// سطر الـ DI بتاع الـ feature.
void registerSessions(GetIt g) {
  g.registerLazySingleton<SessionsRepository>(
    () => SessionsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}
