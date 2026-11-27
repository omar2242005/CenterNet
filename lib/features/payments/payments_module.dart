import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'payment_route_names.dart';
import 'repositories/payments_repository.dart';
import 'screens/payments_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerPayments(GetIt g) {
  g.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature.
final List<RouteBase> paymentRoutes = <RouteBase>[
  GoRoute(
    path: PaymentRoutes.list,
    builder: (context, state) => const PaymentsScreen(),
  ),
];
