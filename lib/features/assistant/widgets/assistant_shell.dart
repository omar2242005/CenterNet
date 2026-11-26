import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(title: Text(l10n.appName)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(l10n.assistantNavHome),
                onTap: () => _go(context, _homePath),
              ),
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: Text(l10n.assistantNavSessions),
                onTap: () => _go(context, _sessionsPath),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(l10n.assistantNavSync),
                onTap: () => _go(context, _syncPath),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.myAccountTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(AuthRoutes.myAccount);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  l10n.authSignOut,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  confirmAndSignOut(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current.index,
        onDestinationSelected: (index) =>
            _onTabSelected(context, AssistantTab.values[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.assistantNavHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: l10n.assistantNavSessions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            label: l10n.assistantNavAttendance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_upload_outlined),
            selectedIcon: const Icon(Icons.cloud_upload),
            label: l10n.assistantNavSync,
          ),
        ],
      ),
    );
  }

  void _onTabSelected(BuildContext context, AssistantTab tab) {
    switch (tab) {
      case AssistantTab.home:
        if (current != tab) context.go(_homePath);
      case AssistantTab.sessions:
        if (current != tab) context.go(_sessionsPath);
      case AssistantTab.attendance:
        if (current != tab) context.go(_attendancePath);
      case AssistantTab.sync:
        if (current != tab) context.go(_syncPath);
    }
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop(); // يقفل الـ drawer
    if (current == AssistantTab.home && path == _homePath) return;
    context.go(path);
  }
}
