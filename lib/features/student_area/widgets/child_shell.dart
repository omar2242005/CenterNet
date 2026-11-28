import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/session_role.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/sign_out_action.dart';
import '../../home/home_route_names.dart';
import '../../home/models/home_destination.dart';
import '../../students/models/student.dart';
import '../child_route_names.dart';

/// تبويبات الطالب وولي الأمر. الرابع: "حسابي" للطالب، و"ملف الابن" لولي الأمر.
enum ChildTab { home, schedule, grades, fourth }

/// الهيكل المشترك لشاشات الطالب وولي الأمر (شبه TeacherShell): AppBar + Drawer
/// + شريط تنقل سفلي بـ 4 أزرار. [student] هو الطالب المفتوح حاليًا
/// (null لحد ما الرئيسية تحمّله).
class ChildShell extends StatelessWidget {
  const ChildShell({
    super.key,
    required this.current,
    required this.title,
    required this.body,
    this.student,
    this.actions,
    this.isDetail = false,
  });

  final ChildTab current;
  final String title;
  final Widget body;
  final Student? student;
  final List<Widget>? actions;

  /// شاشة تفاصيل مفتوحة فوق (مش تبويب): التبويب المضلَّل بيفضل شغال،
  /// وضغطه بيرجّع لشاشته بدل ما يتجاهل الضغطة.
  final bool isDetail;

  bool get _isGuardian => sl<SessionRole>().value == HomeDestination.guardian;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guardian = _isGuardian;
    final gradesLabel = guardian
        ? l10n.guardianNavGrades
        : l10n.studentNavGrades;
    final fourthLabel = guardian
        ? l10n.guardianNavProfile
        : l10n.myAccountTitle;
    final fourthIcon = guardian ? Icons.badge_outlined : Icons.person_outline;
    final fourthSelected = guardian ? Icons.badge : Icons.person;

    return AppShell(
      title: title,
      body: body,
      actions: actions,
      currentIndex: current.index,
      onDestinationSelected: (i) => _onTab(context, ChildTab.values[i]),
      destinations: [
        AppShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.childNavHome,
        ),
        AppShellDestination(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: l10n.childNavSchedule,
        ),
        AppShellDestination(
          icon: Icons.grading_outlined,
          selectedIcon: Icons.grading,
          label: gradesLabel,
        ),
        AppShellDestination(
          icon: fourthIcon,
          selectedIcon: fourthSelected,
          label: fourthLabel,
        ),
      ],
      drawerItems: [
        AppShellDrawerItem(
          icon: Icons.home_outlined,
          label: l10n.childNavHome,
          onTap: () => _go(context, ChildTab.home),
        ),
        AppShellDrawerItem(
          icon: Icons.calendar_month_outlined,
          label: l10n.childNavSchedule,
          onTap: () => _go(context, ChildTab.schedule),
        ),
        AppShellDrawerItem(
          icon: Icons.grading_outlined,
          label: gradesLabel,
          onTap: () => _go(context, ChildTab.grades),
        ),
        if (guardian)
          AppShellDrawerItem(
            icon: Icons.badge_outlined,
            label: l10n.guardianNavProfile,
            onTap: () => _go(context, ChildTab.fourth),
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

  void _onTab(BuildContext context, ChildTab tab) {
    // حسابي للطالب شاشة بتتفتح فوق، فالتبويب الحالي يفضل زي ما هو.
    if (tab == ChildTab.fourth && !_isGuardian) {
      context.push(AuthRoutes.myAccount);
      return;
    }
    _go(context, tab);
  }

  void _go(BuildContext context, ChildTab tab) {
    if (!isDetail && current == tab) return;
    final s = student;
    if (tab == ChildTab.home) {
      context.go(
        _isGuardian ? HomeRoutes.guardian : HomeRoutes.student,
        extra: s?.id,
      );
      return;
    }
    if (s == null) return; // لسه بيحمّل الطالب
    context.go(switch (tab) {
      ChildTab.schedule => ChildRoutes.schedule,
      ChildTab.grades => ChildRoutes.results,
      _ => ChildRoutes.profile,
    }, extra: s);
  }
}
