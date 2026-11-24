import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_store.dart';
import '../../core/services/pending_ops_guard.dart';
import 'assistant_route_names.dart';
import 'models/scan_setup.dart';
import 'screens/assistant_home_screen.dart';
import 'screens/attendance_list_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/session_details_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/sync_screen.dart';
import 'services/pending_scan_store.dart';

/// سطر الـ DI بتاع الـ Assistant module.
void registerAssistant(GetIt g) {
  g.registerLazySingleton<PendingScanStore>(
    () => PendingScanStore(g<LocalStore>(), g<PendingOpsGuard>()),
  );
  // Add other assistant dependencies here
}

/// سطر الـ router بتاع الـ Assistant module.
final List<RouteBase> assistantRoutes = <RouteBase>[
  GoRoute(
    path: '/${AssistantRouteNames.home}',
    builder: (context, state) => const AssistantHomeScreen(),
    routes: [
      GoRoute(
        path: 'sessions',
        builder: (context, state) => const SessionsScreen(),
        routes: [
          GoRoute(
            path: ':sessionId',
            builder: (context, state) => SessionDetailsScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
            routes: [
              GoRoute(
                path: 'attendance',
                builder: (context, state) => AttendanceListScreen(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: 'scan',
        builder: (context, state) {
          final extra = state.extra;
          return ScanScreen(setup: extra is ScanSetup ? extra : null);
        },
      ),
      GoRoute(
        path: 'sync',
        builder: (context, state) => const SyncScreen(),
      ),
    ],
  ),
];
