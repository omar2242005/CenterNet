import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../core/services/local_store.dart';
import '../core/services/pending_ops_guard.dart';
import '../core/services/whatsapp_launcher.dart';
import '../features/assistant/assistant_module.dart';
import '../features/auth/auth_module.dart';
import '../features/centers/centers_module.dart';
import '../features/groups/groups_module.dart';
import '../features/home/home_module.dart';
import '../features/sessions/sessions_module.dart';
import '../features/staff/staff_module.dart';
import '../features/students/students_module.dart';

/// الـ service locator الوحيد في التطبيق.
final GetIt sl = GetIt.instance;

/// بتتنادى مرة واحدة من main بعد تهيئة Firebase.
void configureDependencies(LocalStore localStore, [GetIt? locator]) {
  final g = locator ?? sl;
  registerInfrastructure(g, localStore);
  registerFeatures(g);
}

/// الأساسيات المشتركة (Firebase + الخدمات الصغيرة).
/// الـ Repositories هي اللي بتاخدها من هنا.
void registerInfrastructure(GetIt g, LocalStore localStore) {
  g.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  g.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  g.registerSingleton<LocalStore>(localStore);
  g.registerLazySingleton<WhatsAppLauncher>(WhatsAppLauncher.new);
  g.registerLazySingleton<PendingOpsGuard>(PendingOpsGuard.new);
}

/// كل feature بتضيف سطرها هنا (سطر واحد لكل feature).
void registerFeatures(GetIt g) {
  registerAuth(g);
  registerHome(g);
  registerCenters(g);
  registerStaff(g);
  registerStudents(g);
  registerGroups(g);
  registerSessions(g);
  registerAssistant(g);
}