import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/connectivity_monitor.dart';
import '../../l10n/app_localizations.dart';
import '../attendance/screens/attendance_list_screen.dart';
import '../scan/models/scan_setup.dart';
import '../scan/repository/scan_repository.dart';
import '../scan/screens/scan_screen.dart';
import '../scan/screens/sync_screen.dart';
import 'assistant_route_names.dart';
import 'cubit/home_cubit.dart';
import 'cubit/sessions_cubit.dart';
import 'repository/assistant_repository.dart';
import 'repository/firestore_assistant_repository.dart';
import 'screens/assistant_home_screen.dart';
import 'screens/attendance_tab_screen.dart';
import 'screens/session_details_screen.dart';
import 'screens/sessions_screen.dart';
import 'widgets/assistant_shell.dart';

/// سطر الـ DI بتاع الـ Assistant module.
void registerAssistant(GetIt g) {
  g.registerLazySingleton<AssistantRepository>(
    () =>
        FirestoreAssistantRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerFactory<AssistantHomeCubit>(
    () => AssistantHomeCubit(
      g<AssistantRepository>(),
      g<ScanRepository>(),
      g<ConnectivityMonitor>(),
    ),
  );
  g.registerFactory<SessionsCubit>(
    () => SessionsCubit(g<AssistantRepository>()),
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
                  frame: (context, body) => AssistantShell(
                    current: AssistantTab.attendance,
                    title: AppLocalizations.of(context).assistantAttendanceTitle,
                    body: body,
                  ),
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
        path: 'attendance',
        builder: (context, state) => const AttendanceTabScreen(),
      ),
      GoRoute(path: 'sync', builder: (context, state) => const SyncScreen()),
    ],
  ),
];
