import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/sign_out_action.dart';
import '../../home/home_route_names.dart';
import '../teacher_route_names.dart';

/// تبويبات المعلم في شريط التنقل السفلي.
enum TeacherTab { home, groups, exams, account }

/// الهيكل المشترك لشاشات المعلم: AppBar + Drawer (فيه تسجيل الخروج) +
/// شريط تنقل سفلي (رئيسية / مجموعاتي / الامتحانات / حسابي).
class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.current,
    required this.title,
    required this.body,
  });

  final TeacherTab current;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShell(
      title: title,
      body: body,
      currentIndex: current.index,
      onDestinationSelected: (index) =>
          _onTabSelected(context, TeacherTab.values[index]),
      destinations: [
        AppShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.teacherNavHome,
        ),
        AppShellDestination(
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: l10n.myGroupsTitle,
        ),
        AppShellDestination(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          label: l10n.teacherNavExams,
        ),
        AppShellDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.myAccountTitle,
        ),
      ],
      drawerItems: [
        AppShellDrawerItem(
          icon: Icons.home_outlined,
          label: l10n.teacherNavHome,
          onTap: () => _go(context, TeacherTab.home),
        ),
        AppShellDrawerItem(
          icon: Icons.groups_outlined,
          label: l10n.myGroupsTitle,
          onTap: () => _go(context, TeacherTab.groups),
        ),
        AppShellDrawerItem(
          icon: Icons.school_outlined,
          label: l10n.teacherNavExams,
          onTap: () => _go(context, TeacherTab.exams),
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

  void _onTabSelected(BuildContext context, TeacherTab tab) {
    if (tab == TeacherTab.account) {
      // حسابي شاشة بتتفتح فوق، فالتبويب الحالي يفضل زي ما هو.
      context.push(AuthRoutes.myAccount);
      return;
    }
    _go(context, tab);
  }

  void _go(BuildContext context, TeacherTab tab) {
    if (current == tab) return;
    context.go(switch (tab) {
      TeacherTab.home => HomeRoutes.teacher,
      TeacherTab.groups => TeacherRoutes.groups,
      TeacherTab.exams => TeacherRoutes.exams,
      TeacherTab.account => AuthRoutes.myAccount,
    });
  }
}
