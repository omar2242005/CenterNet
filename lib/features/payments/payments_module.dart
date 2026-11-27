import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'repositories/payments_repository.dart';

/// سطر الـ DI بتاع الـ feature.
void registerPayments(GetIt g) {
  g.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}
