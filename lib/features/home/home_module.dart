import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../app/session_role.dart';
import '../../l10n/app_localizations.dart';

import '../assistant/screens/assistant_home_screen.dart';
import '../auth/auth_route_names.dart';
import '../guardian/screens/guardian_home_screen.dart';
import '../student_area/screens/student_home_screen.dart';
import '../teacher/teacher_route_names.dart';
import 'home_route_names.dart';
import 'repository/role_repository.dart';
import 'screens/blocked_account_screen.dart';
import 'screens/home_gate_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/role_home_screen.dart';

/// سطر الـ DI بتاع الـ feature.
void registerHome(GetIt g) {
  g.registerLazySingleton<RoleRepository>(
    () => RoleRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
  g.registerLazySingleton<SessionRole>(SessionRole.new);
}

/// سطر الـ router بتاع الـ feature.
/// الرئيسيات دي مؤقتة، والشاشات الحقيقية بتيجي في الموجة 2 (كل واحد لدوره).
final List<RouteBase> homeRoutes = <RouteBase>[
  // نقطة الدخول بعد أي تسجيل دخول.
  GoRoute(
    path: AuthRoutes.signedIn,
    builder: (context, state) => const HomeGateScreen(),
  ),
  GoRoute(
    path: HomeRoutes.admin,
    builder: (context, state) => const AdminHomeScreen(),
  ),
  GoRoute(
    path: HomeRoutes.teacher,
    builder: (context, state) =>
        RoleHomeScreen(
          title: AppLocalizations.of(context).homeTeacherTitle,
          actions: [
            (
              label: AppLocalizations.of(context).myGroupsTitle,
              route: TeacherRoutes.groups,
            ),
          ],
        ),
  ),
  GoRoute(
    path: HomeRoutes.assistant,
    builder: (context, state) => const AssistantHomeScreen(),
  ),
  GoRoute(
    path: HomeRoutes.student,
    builder: (context, state) => const StudentHomeScreen(),
  ),
  GoRoute(
    path: HomeRoutes.guardian,
    builder: (context, state) => const GuardianHomeScreen(),
  ),
  GoRoute(
    path: HomeRoutes.inactive,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return BlockedAccountScreen(
        title: l10n.homeInactiveTitle,
        body: l10n.homeInactiveBody,
      );
    },
  ),
  GoRoute(
    path: HomeRoutes.noAccess,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return BlockedAccountScreen(
        title: l10n.homeNoAccessTitle,
        body: l10n.homeNoAccessBody,
      );
    },
  ),
];

