import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/centers/center_route_names.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:center_net/features/centers/repository/centers_repository.dart';
import 'package:center_net/features/groups/group_route_names.dart';
import 'package:center_net/features/home/home_route_names.dart';
import 'package:center_net/features/home/screens/admin_home_screen.dart';
import 'package:center_net/features/staff/staff_route_names.dart';
import 'package:center_net/features/students/student_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../../auth/helpers/fake_auth_repository.dart';
import '../../centers/helpers/fake_centers_repository.dart';

Future<void> _pump(WidgetTester tester) async {
  Widget stub(String t) => Scaffold(body: Text(t));
  final router = GoRouter(
    initialLocation: HomeRoutes.admin,
    routes: [
      GoRoute(
        path: HomeRoutes.admin,
        builder: (_, _) => const AdminHomeScreen(),
      ),
      GoRoute(path: StudentRoutes.list, builder: (_, _) => stub('STUDENTS')),
      GoRoute(path: GroupRoutes.list, builder: (_, _) => stub('GROUPS')),
      GoRoute(path: StaffRoutes.list, builder: (_, _) => stub('STAFF')),
      GoRoute(
        path: StaffRoutes.inviteTeacher,
        builder: (_, _) => stub('INVITE_T'),
      ),
      GoRoute(
        path: StaffRoutes.inviteAssistant,
        builder: (_, _) => stub('INVITE_A'),
      ),
      GoRoute(path: CenterRoutes.settings, builder: (_, _) => stub('SETTINGS')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeAuthRepository auth;
  late FakeCentersRepository centers;

  setUp(() {
    auth = FakeAuthRepository()
      ..profile = const AppUser(
        uid: 'u1',
        name: 'أحمد مدير',
        email: 'a@b.com',
        phone: '',
        accountType: AccountType.admin,
        centerId: 'c1',
      );
    centers = FakeCentersRepository(
      center: const CenterInfo(
        id: 'c1',
        name: 'مركز النور',
        year: 2026,
        createdBy: 'u1',
        lateAfterMinutes: 15,
      ),
    );
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<CentersRepository>(centers);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('بيعرض الترحيب واسم السنتر وكروت الأقسام', (tester) async {
    await _pump(tester);
    expect(find.text(arL10n.adminGreeting('أحمد مدير')), findsOneWidget);
    expect(find.text('مركز النور'), findsOneWidget);
    expect(find.text(arL10n.studentsListTitle), findsWidgets);
    expect(find.text(arL10n.centerSettingsTitle), findsOneWidget);
  });

  testWidgets('شريط التنقل فيه 4 تبويبات والرئيسية متحددة', (tester) async {
    await _pump(tester);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 4);
    expect(bar.selectedIndex, 0);
    // عنوان الشريط العلوي معبّر، وتبويب التنقل فضل "الرئيسية".
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('إدارة السنتر'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('الرئيسية'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('تبويب الطلاب بيودّي لقائمة الطلاب', (tester) async {
    await _pump(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(arL10n.studentsListTitle),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('STUDENTS'), findsOneWidget);
  });

  testWidgets('كارت إضافة معلم بيفتح دعوة المعلم', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(
      find.text(arL10n.staffInviteTeacherTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(arL10n.staffInviteTeacherTitle));
    await tester.pumpAndSettle();
    expect(find.text('INVITE_T'), findsOneWidget);
  });

  testWidgets('كارت إضافة مساعد بيفتح دعوة المساعد', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(
      find.text(arL10n.staffInviteAssistantTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(arL10n.staffInviteAssistantTitle));
    await tester.pumpAndSettle();
    expect(find.text('INVITE_A'), findsOneWidget);
  });

  testWidgets('كارت إعدادات السنتر بيفتح الإعدادات', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(
      find.text(arL10n.centerSettingsTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.centerSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('القائمة الجانبية فيها الإعدادات وحسابي وتسجيل الخروج',
      (tester) async {
    await _pump(tester);
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    final drawer = find.byType(Drawer);
    for (final label in [
      arL10n.staffInviteTeacherTitle,
      arL10n.staffInviteAssistantTitle,
      arL10n.centerSettingsTitle,
      arL10n.myAccountTitle,
      arL10n.authSignOut,
    ]) {
      expect(
        find.descendant(of: drawer, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('فشل تحميل الاسم والسنتر مبيعطّلش الرئيسية', (tester) async {
    auth.failure = const Failure.network();
    centers.failure = const Failure.network();
    await _pump(tester);
    expect(find.text(arL10n.adminShortcuts), findsOneWidget);
    expect(find.text(arL10n.groupsListTitle), findsWidgets);
    expect(find.text('مركز النور'), findsNothing);
  });
}
