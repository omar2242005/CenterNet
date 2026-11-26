import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/sign_out_action.dart';
import '../../centers/center_route_names.dart';
import '../../groups/group_route_names.dart';
import '../../staff/staff_route_names.dart';
import '../../students/student_route_names.dart';
import '../home_route_names.dart';

/// تبويبات الأدمن في شريط التنقل السفلي.
enum AdminTab { home, students, groups, staff }

/// هيكل الأدمن: نفس هيكل المساعد (AppShell) بتبويبات الأدمن: رئيسية / طلاب /
/// مجموعات / فريق، وقائمة جانبية فيها إضافة موظف وإعدادات السنتر وحسابي والخروج.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.current,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final AdminTab current;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const Map<AdminTab, String> _paths = <AdminTab, String>{
    AdminTab.home: HomeRoutes.admin,
    AdminTab.students: StudentRoutes.list,
    AdminTab.groups: GroupRoutes.list,
    AdminTab.staff: StaffRoutes.list,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShell(
      title: title,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      currentIndex: current.index,
      onDestinationSelected: (index) => _goTab(context, AdminTab.values[index]),
      destinations: [
        AppShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.adminNavHome,
        ),
        AppShellDestination(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          label: l10n.studentsListTitle,
        ),
        AppShellDestination(
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: l10n.groupsListTitle,
        ),
        AppShellDestination(
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          label: l10n.staffListTitle,
        ),
      ],
      drawerItems: [
        AppShellDrawerItem(
          icon: Icons.home_outlined,
          label: l10n.adminNavHome,
          onTap: () => _goTab(context, AdminTab.home),
        ),
        AppShellDrawerItem(
          icon: Icons.school_outlined,
          label: l10n.staffInviteTeacherTitle,
          onTap: () => context.push(StaffRoutes.inviteTeacher),
        ),
        AppShellDrawerItem(
          icon: Icons.person_add_alt_1_outlined,
          label: l10n.staffInviteAssistantTitle,
          onTap: () => context.push(StaffRoutes.inviteAssistant),
        ),
        AppShellDrawerItem(
          icon: Icons.settings_outlined,
          label: l10n.centerSettingsTitle,
          onTap: () => context.push(CenterRoutes.settings),
        ),
        AppShellDrawerItem(
          icon: Icons.person_outline,
          label: l10n.myAccountTitle,
          dividerBefore: true,
          onTap: () => context.push(AuthRoutes.myAccount),
        ),
        AppShellDrawerItem(
          icon: Icons.logout,
          label: l10n.authSignOut,
          destructive: true,
          onTap: () => confirmAndSignOut(context),
        ),
      ],
    );
  }

  void _goTab(BuildContext context, AdminTab tab) {
    if (tab == current) return;
    context.go(_paths[tab]!);
  }
}
