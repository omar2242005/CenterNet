import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'app/di.dart';
import 'app/route_guard.dart';
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
  // للتجربة على الـ Emulator بدل Firebase الحقيقي:
  //   flutter run --dart-define=USE_EMULATOR=true
  // (10.0.2.2 = جهاز الكمبيوتر من جوه محاكي أندرويد. لجهاز حقيقي ابعت
  //  --dart-define=EMULATOR_HOST=<IP الكمبيوتر>)
  if (const bool.fromEnvironment('USE_EMULATOR')) {
    const host = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    );
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }
  tz.initializeTimeZones();
  configureDependencies(await LocalStore.open());
  runApp(
    CenterNetApp(
      router: buildRouter(
        splashBuilder: (_) => const AuthGateScreen(),
        redirect: appRedirect,
      ),
    ),
  );
}