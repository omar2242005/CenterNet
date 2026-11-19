import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_store.dart';
import '../../core/services/pending_ops_guard.dart';
import 'attendance_route_names.dart';
import 'models/scan_setup.dart';
import 'screens/scan_screen.dart';
import 'services/pending_scan_store.dart';

/// سطر الـ DI بتاع الـ feature.
void registerAttendance(GetIt g) {
  g.registerLazySingleton<PendingScanStore>(
    () => PendingScanStore(g<LocalStore>(), g<PendingOpsGuard>()),
  );
}

/// سطر الـ router بتاع الـ feature.
final List<RouteBase> attendanceRoutes = <RouteBase>[
  GoRoute(
    path: AttendanceRoutes.scan,
    builder: (context, state) {
      final extra = state.extra;
      return ScanScreen(setup: extra is ScanSetup ? extra : null);
    },
  ),
];
