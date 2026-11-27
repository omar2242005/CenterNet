import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'auth_route_names.dart';
import 'models/app_user.dart';
import 'models/register_draft.dart';
import 'repository/auth_repository.dart';
import 'screens/account_type_screen.dart';
import 'screens/edit_contact_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_email_screen.dart';

/// سطر الـ DI بتاع الـ feature (بيتنادى من registerFeatures في di.dart).
void registerAuth(GetIt g) {
  g.registerLazySingleton<AuthRepository>(
    () => AuthRepository(g<FirebaseAuth>(), g<FirebaseFirestore>()),
  );
}

/// سطر الـ router بتاع الـ feature (بيتنشر في featureRoutes).
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: AuthRoutes.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AuthRoutes.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: AuthRoutes.accountType,
    // لو اتفتحت من غير بيانات (مثلًا بعد استرجاع التطبيق) نرجع لشاشة البيانات.
    redirect: (context, state) =>
        state.extra is RegisterDraft ? null : AuthRoutes.register,
    builder: (context, state) =>
        AccountTypeScreen(draft: state.extra! as RegisterDraft),
  ),
  GoRoute(
    path: AuthRoutes.verifyEmail,
    builder: (context, state) => const VerifyEmailScreen(),
  ),
  GoRoute(
    path: AuthRoutes.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: AuthRoutes.myAccount,
    builder: (context, state) => const MyAccountScreen(),
  ),
  GoRoute(
    path: AuthRoutes.editContact,
    // من غير بيانات (مثلًا بعد استرجاع التطبيق) نرجع لـ "حسابي".
    redirect: (context, state) =>
        state.extra is AppUser ? null : AuthRoutes.myAccount,
    builder: (context, state) =>
        EditContactScreen(user: state.extra! as AppUser),
  ),
];
