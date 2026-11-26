import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/sign_out_action.dart';
import '../assistant_route_names.dart';

/// تبويبات المساعد في شريط التنقل السفلي.
enum AssistantTab { home, sessions, attendance, sync }

/// الهيكل المشترك لشاشات المساعد: AppBar + Drawer (فيه تسجيل الخروج) +
/// شريط تنقل سفلي (رئيسية / حصص / حضور / مزامنة).
class AssistantShell extends StatelessWidget {
  const AssistantShell({
    super.key,
    required this.current,
    required this.title,
    required this.body,
  });

  final AssistantTab current;
  final String title;
  final Widget body;

  static const String _homePath = '/${AssistantRouteNames.home}';
  static const String _sessionsPath = '/${AssistantRouteNames.sessions}';
  static const String _attendancePath = '/${AssistantRouteNames.attendance}';
  static const String _syncPath = '/${AssistantRouteNames.sync}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShell(
      title: title,
      body: body,
      currentIndex: current.index,
      onDestinationSelected: (index) =>
          _onTabSelected(context, AssistantTab.values[index]),
      destinations: [
        AppShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.assistantNavHome,
        ),
        AppShellDestination(
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          label: l10n.assistantNavSessions,
        ),
        AppShellDestination(
          icon: Icons.fact_check_outlined,
          label: l10n.assistantNavAttendance,
        ),
        AppShellDestination(
          icon: Icons.cloud_upload_outlined,
          selectedIcon: Icons.cloud_upload,
          label: l10n.assistantNavSync,
        ),
      ],
      drawerItems: [
        AppShellDrawerItem(
          icon: Icons.home_outlined,
          label: l10n.assistantNavHome,
          onTap: () => _go(context, _homePath),
        ),
        AppShellDrawerItem(
          icon: Icons.event_note_outlined,
          label: l10n.assistantNavSessions,
          onTap: () => _go(context, _sessionsPath),
        ),
        AppShellDrawerItem(
          icon: Icons.cloud_upload_outlined,
          label: l10n.assistantNavSync,
          onTap: () => _go(context, _syncPath),
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

  void _onTabSelected(BuildContext context, AssistantTab tab) {
    if (current == tab) return;
    switch (tab) {
      case AssistantTab.home:
        context.go(_homePath);
      case AssistantTab.sessions:
        context.go(_sessionsPath);
      case AssistantTab.attendance:
        context.go(_attendancePath);
      case AssistantTab.sync:
        context.go(_syncPath);
    }
  }

  void _go(BuildContext context, String path) {
    if (current == AssistantTab.home && path == _homePath) return;
    context.go(path);
  }
}
