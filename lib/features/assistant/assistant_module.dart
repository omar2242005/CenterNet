import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_store.dart';
import '../../core/services/pending_ops_guard.dart';
import 'assistant_route_names.dart';
import 'cubit/home_cubit.dart';
import 'cubit/sessions_cubit.dart';
import 'cubit/sync_cubit.dart';
import 'models/scan_setup.dart';
import 'repository/assistant_repository.dart';
import 'repository/firestore_assistant_repository.dart';
import 'screens/assistant_home_screen.dart';
import 'screens/attendance_list_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/session_details_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/sync_screen.dart';
import 'services/pending_scan_store.dart';
import 'services/connectivity_monitor.dart';

/// سطر الـ DI بتاع الـ Assistant module.
void registerAssistant(GetIt g) {
  g.registerLazySingleton<PendingScanStore>(
    () => PendingScanStore(g<LocalStore>(), g<PendingOpsGuard>()),
  );
  g.registerLazySingleton<ConnectivityMonitor>(ConnectivityPlusMonitor.new);
  g.registerLazySingleton<AssistantRepository>(
    () =>
        FirestoreAssistantRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerFactory<AssistantHomeCubit>(
    () => AssistantHomeCubit(
      g<AssistantRepository>(),
      g<ConnectivityMonitor>(),
    ),
  );
  g.registerFactory<SessionsCubit>(
    () => SessionsCubit(g<AssistantRepository>()),
  );
  g.registerFactory<SyncCubit>(
    () => SyncCubit(
      g<AssistantRepository>(),
      g<PendingScanStore>(),
      g<ConnectivityMonitor>(),
    ),
  );
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
      GoRoute(path: 'sync', builder: (context, state) => const SyncScreen()),
    ],
  ),
];
