import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/features/home/home_module.dart';
import 'package:center_net/features/home/home_route_names.dart';
import 'package:center_net/features/home/models/home_destination.dart';
import 'package:center_net/features/home/repository/role_repository.dart';
import 'package:center_net/features/home/screens/home_gate_screen.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';

class _FakeRoleRepository implements RoleRepository {
  _FakeRoleRepository(this.result);

  /// [HomeDestination] أو [Failure].
  Object result;
  int calls = 0;

  @override
  Future<HomeDestination> resolve() async {
    calls++;
    final r = result;
    if (r is Failure) throw r;
    return r as HomeDestination;
  }
}

Future<void> _pumpGate(WidgetTester tester) {
  final router = GoRouter(
    initialLocation: AuthRoutes.signedIn,
    routes: [
      GoRoute(
        path: AuthRoutes.signedIn,
        builder: (_, _) => const HomeGateScreen(),
      ),
      GoRoute(
        path: HomeRoutes.admin,
        builder: (_, _) => const Scaffold(body: Text('ADMIN')),
      ),
      GoRoute(
        path: HomeRoutes.teacher,
        builder: (_, _) => const Scaffold(body: Text('TEACHER')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets('بيوجّه الأدمن لرئيسية الأدمن', (tester) async {
    sl.registerSingleton<RoleRepository>(
      _FakeRoleRepository(HomeDestination.admin),
    );
    await _pumpGate(tester);
    await tester.pumpAndSettle();
    expect(find.text('ADMIN'), findsOneWidget);
  });

  testWidgets('بيوجّه المعلم لرئيسية المعلم', (tester) async {
    sl.registerSingleton<RoleRepository>(
      _FakeRoleRepository(HomeDestination.teacher),
    );
    await _pumpGate(tester);
    await tester.pumpAndSettle();
    expect(find.text('TEACHER'), findsOneWidget);
  });

  testWidgets('الفشل بيظهر برسالة وإعادة محاولة وتسجيل خروج، والمحاولة تنجح',
      (tester) async {
    final repo = _FakeRoleRepository(const Failure.network());
    sl.registerSingleton<RoleRepository>(repo);
    await _pumpGate(tester);
    await tester.pumpAndSettle();

    expect(find.text(const Failure.network().message), findsOneWidget);
    expect(find.text(arL10n.retry), findsOneWidget);
    expect(find.text(arL10n.authSignOut), findsOneWidget);
    expect(find.text('ADMIN'), findsNothing);

    repo.result = HomeDestination.admin;
    await tester.tap(find.text(arL10n.retry));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('ADMIN'), findsOneWidget);
  });

  test('كل وجهة ليها route (ماعدا اللي بتروح لشاشات feature تانية)', () {
    final paths = homeRoutes.whereType<GoRoute>().map((r) => r.path).toSet();
    for (final d in HomeDestination.values) {
      if (d == HomeDestination.createCenter ||
          d == HomeDestination.joinCenter) {
        continue;
      }
      expect(paths, contains(HomeRoutes.forDestination(d)), reason: '$d');
    }
  });
}
