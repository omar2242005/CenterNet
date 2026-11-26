import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// تبويب في شريط التنقل السفلي.
class AppShellDestination {
  const AppShellDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// عنصر في القائمة الجانبية. [onTap] بيتنفذ بعد قفل القائمة.
class AppShellDrawerItem {
  const AppShellDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.dividerBefore = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// بيتلوّن بلون الخطأ (تسجيل الخروج).
  final bool destructive;

  /// فاصل قبل العنصر.
  final bool dividerBefore;
}

/// الهيكل المشترك للمساعد والأدمن: AppBar + قائمة جانبية + شريط تنقل سفلي.
/// كل دور بيبني منه هيكله (تبويباته وعناصر قائمته) ومحتوى الشاشة.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.drawerItems,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final List<AppShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDrawerItem> drawerItems;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(title: Text(l10n.appName)),
              const Divider(),
              for (final item in drawerItems) ...[
                if (item.dividerBefore) const Divider(),
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: item.destructive ? AppColors.error : null,
                  ),
                  title: Text(
                    item.label,
                    style: item.destructive
                        ? const TextStyle(color: AppColors.error)
                        : null,
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // يقفل الـ drawer
                    item.onTap();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: d.selectedIcon == null ? null : Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
