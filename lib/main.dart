import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'app/di.dart';
import 'app/router.dart';
import 'features/auth/screens/auth_gate_screen.dart';
import 'core/services/local_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // لازم قبل أي استخدام تاني لـ Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  tz.initializeTimeZones();
  configureDependencies(await LocalStore.open());
  runApp(
    CenterNetApp(
      router: buildRouter(splashBuilder: (_) => const AuthGateScreen()),
    ),
  );
}