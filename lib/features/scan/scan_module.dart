import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/connectivity_monitor.dart';
import '../../core/services/local_store.dart';
import '../../core/services/pending_ops_guard.dart';
import '../attendance/repository/attendance_repository.dart';
import 'cubit/sync_cubit.dart';
import 'repository/firestore_scan_repository.dart';
import 'repository/scan_repository.dart';
import 'services/pending_scan_store.dart';

/// سطر الـ DI بتاع الـ scan module: طابور المسحات المحلي، وكتابتها بعد
/// تأكيد السيرفر، وشاشة المزامنة.
///
/// زي الحضور: مفيش مسارات هنا، كل دور بيركّب شاشة المسح تحت مساره.
void registerScan(GetIt g) {
  g.registerLazySingleton<PendingScanStore>(
    () => PendingScanStore(g<LocalStore>(), g<PendingOpsGuard>()),
  );
  g.registerLazySingleton<ConnectivityMonitor>(ConnectivityPlusMonitor.new);
  g.registerLazySingleton<ScanRepository>(
    () => FirestoreScanRepository(
      g<AttendanceRepository>(),
      g<FirebaseAuth>(),
      g<FirebaseFirestore>(),
    ),
  );
  g.registerFactory<SyncCubit>(
    () => SyncCubit(
      g<ScanRepository>(),
      g<PendingScanStore>(),
      g<ConnectivityMonitor>(),
    ),
  );
}
