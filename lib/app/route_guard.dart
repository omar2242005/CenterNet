import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/assistant_route_names.dart';
import '../features/auth/auth_route_names.dart';
import '../features/auth/repository/auth_repository.dart';
import '../features/centers/center_route_names.dart';
import '../features/home/home_route_names.dart';
import '../features/home/models/home_destination.dart';
import '../features/linking/link_route_names.dart';
import '../features/staff/staff_route_names.dart';
import '../features/student_area/child_route_names.dart';
import '../features/students/student_route_names.dart';
import '../features/groups/group_route_names.dart';
import 'di.dart';
import 'router.dart';
import 'session_role.dart';

/// مين يقدر يفتح أنهي شاشة. UX فقط (الـ Rules هي الحكم الحقيقي).
///
/// كل حد بيضيف مساراته هنا (سطر لكل مسار). المسار اللي مش مكتوب بيعدّي
/// لأي مستخدم مسجّل دخول ومأكّد إيميله.
const Set<HomeDestination> _admin = {HomeDestination.admin};

final Map<String, Set<HomeDestination>> _exactAccess = {
  HomeRoutes.admin: _admin,
  HomeRoutes.teacher: {HomeDestination.teacher},
  HomeRoutes.assistant: {HomeDestination.assistant},
  HomeRoutes.student: {HomeDestination.student},
  HomeRoutes.guardian: {HomeDestination.guardian},
  HomeRoutes.inactive: {HomeDestination.inactive},
  HomeRoutes.noAccess: {HomeDestination.noAccess},
  CenterRoutes.create: {HomeDestination.createCenter},
  CenterRoutes.settings: _admin,
  StaffRoutes.list: _admin,
  StaffRoutes.inviteTeacher: _admin,
  StaffRoutes.inviteAssistant: _admin,
  StaffRoutes.join: {HomeDestination.joinCenter},
  // matchedLocation دايمًا بشرطة مائلة في الأول.
  '/${AssistantRouteNames.scan}': {
    HomeDestination.assistant,
    HomeDestination.teacher,
  },
  // الطالب وولي الأمر (Person 3)
  LinkRoutes.enter: {HomeDestination.student, HomeDestination.guardian},
  ChildRoutes.schedule: {HomeDestination.student, HomeDestination.guardian},
  ChildRoutes.attendance: {HomeDestination.student, HomeDestination.guardian},
  ChildRoutes.results: {HomeDestination.student, HomeDestination.guardian},
};

/// المسار نفسه وكل اللي تحته (`/students` و`/students/new` ...).
final Map<String, Set<HomeDestination>> _prefixAccess = {
  StudentRoutes.list: _admin,
  GroupRoutes.list: _admin,
};

Set<HomeDestination>? _rolesFor(String location) {
  final exact = _exactAccess[location];
  if (exact != null) return exact;
  for (final e in _prefixAccess.entries) {
    if (location == e.key || location.startsWith('${e.key}/')) return e.value;
  }
  return null;
}

const Set<String> _publicPaths = {
  AuthRoutes.login,
  AuthRoutes.register,
  AuthRoutes.accountType,
  AuthRoutes.forgotPassword,
};

/// بترجّع null (عدّي) أو المسار اللي لازم يتحوّل له.
/// [location] هو `state.matchedLocation`.
String? guardRoute({
  required String location,
  required bool signedIn,
  required bool emailVerified,
  required HomeDestination? role,
}) {
  // شاشة البداية بتوجّه لوحدها.
  if (location == AppRoutes.splash) return null;

  if (!signedIn) {
    return _publicPaths.contains(location) ? null : AuthRoutes.login;
  }

  if (!emailVerified) {
    final ok = location == AuthRoutes.verifyEmail ||
        _publicPaths.contains(location);
    return ok ? null : AuthRoutes.verifyEmail;
  }

  // مسجّل ومأكّد: شاشات الدخول ملهاش لازمة، يروح للـ gate.
  if (location == AuthRoutes.verifyEmail || _publicPaths.contains(location)) {
    return AuthRoutes.signedIn;
  }
  if (location == AuthRoutes.signedIn) return null;

  // معطّل أو من غير عضوية: شاشته بس.
  if (role == HomeDestination.inactive || role == HomeDestination.noAccess) {
    final home = HomeRoutes.forDestination(role!);
    return location == home ? null : home;
  }

  final allowed = _rolesFor(location);
  if (allowed == null) return null;
  // الدور لسه ما اتحددش: نعدّي على الـ gate الأول.
  if (role == null) return AuthRoutes.signedIn;
  return allowed.contains(role) ? null : HomeRoutes.forDestination(role);
}

/// الـ redirect الحقيقي للتطبيق (main.dart بيبعته لـ buildRouter).
String? appRedirect(BuildContext context, GoRouterState state) {
  final auth = sl<AuthRepository>();
  return guardRoute(
    location: state.matchedLocation,
    signedIn: auth.currentUser != null,
    emailVerified: auth.isEmailVerified,
    role: sl<SessionRole>().value,
  );
}
