import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/repository/auth_repository.dart';
import '../../centers/center_route_names.dart';
import '../../centers/repository/centers_repository.dart';
import '../../grades/grade_route_names.dart';
import '../../groups/group_route_names.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';
import '../../linking/link_route_names.dart';
import '../../payments/payment_route_names.dart';
import '../../staff/staff_route_names.dart';
import '../../students/student_route_names.dart';
import '../widgets/admin_shell.dart';

/// رئيسية الأدمن: ترحيب + اسم السنتر + كروت اختصار للأقسام (جوه AdminShell).
/// لو تحميل الاسم أو السنتر فشل بنعرض الكروت من غيرهم (مش بنعطّل الرئيسية).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final Future<({String? name, String? center, String? code})> _future = _load();

  Future<({String? name, String? center, String? code})> _load() async {
    String? name;
    String? center;
    String? code;
    try {
      name = (await sl<AuthRepository>().loadProfile())?.name;
    } catch (_) {}
    try {
      final info = await sl<CentersRepository>().loadMyCenter();
      center = info?.name;
      code = info?.id;
    } catch (_) {}
    return (name: name, center: center, code: code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final shortcuts = <_Shortcut>[
      _Shortcut(Icons.school_outlined, l10n.studentsListTitle, StudentRoutes.list),
      _Shortcut(Icons.groups_outlined, l10n.groupsListTitle, GroupRoutes.list),
      _Shortcut(Icons.badge_outlined, l10n.staffListTitle, StaffRoutes.list),
      _Shortcut(
        Icons.school_outlined,
        l10n.staffInviteTeacherTitle,
        StaffRoutes.inviteTeacher,
        push: true,
      ),
      _Shortcut(
        Icons.person_add_alt_1_outlined,
        l10n.staffInviteAssistantTitle,
        StaffRoutes.inviteAssistant,
        push: true,
      ),
      _Shortcut(
        Icons.settings_outlined,
        l10n.centerSettingsTitle,
        CenterRoutes.settings,
        push: true,
      ),
      _Shortcut(
        Icons.link,
        l10n.linkRequestsTitle,
        LinkRoutes.requests,
        push: true,
      ),
      _Shortcut(
        Icons.payments_outlined,
        l10n.paymentsScreenTitle,
        PaymentRoutes.list,
        push: true,
      ),
      // الامتحانات بتحتاج مجموعة الأول، فالكارت بيسأل عن المجموعة وبعدها
      // بيفتح شاشة امتحاناتها.
      _Shortcut(
        Icons.quiz_outlined,
        l10n.examsTitle,
        GradeRoutes.exams,
        push: true,
        needsGroup: true,
      ),
    ];

    return AdminShell(
      current: AdminTab.home,
      title: l10n.adminHomeTitle,
      body: FutureBuilder<({String? name, String? center, String? code})>(
        future: _future,
        builder: (context, snap) {
          final name = snap.data?.name;
          final center = snap.data?.center;
          final code = snap.data?.code;
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              if (name != null)
                Text(
                  l10n.adminGreeting(name),
                  style: theme.textTheme.titleLarge,
                ),
              if (center != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              if (code != null) ...[
                const SizedBox(height: AppSpacing.xs),
                // الطالب/ولي الأمر محتاجينه في طلب الربط.
                SelectableText(
                  l10n.adminCenterCode(code),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.adminShortcuts, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final s in shortcuts) ...[
                _ShortcutCard(
                  shortcut: s,
                  onTap: () => _openShortcut(context, s),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  /// بيفتح وجهة الكارت. الامتحانات بتحتاج مجموعة، فبنسأل عنها في شيت الأول.
  Future<void> _openShortcut(BuildContext context, _Shortcut shortcut) async {
    if (shortcut.needsGroup) {
      final group = await showModalBottomSheet<Group>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _GroupPickerSheet(),
      );
      if (group == null || !context.mounted) return;
      await context.push<Object?>(shortcut.route, extra: group);
      return;
    }
    if (shortcut.push) {
      await context.push<Object?>(shortcut.route);
    } else {
      context.go(shortcut.route);
    }
  }
}

class _Shortcut {
  const _Shortcut(
    this.icon,
    this.label,
    this.route, {
    this.push = false,
    this.needsGroup = false,
  });

  final IconData icon;
  final String label;
  final String route;

  /// صفحات الفورم بتتفتح فوق (push)، والأقسام الرئيسية بتتبدّل (go).
  final bool push;

  /// الشاشة محتاجة مجموعة (extra)، فبنسأل عنها الأول.
  final bool needsGroup;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut, required this.onTap});

  final _Shortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            Icon(shortcut.icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                shortcut.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// شيت اختيار المجموعة قبل فتح الامتحانات: بيعرض المجموعات النشطة بس.
/// التحميل هنا مباشر من الـ repository لأن الشيت مش شاشة كاملة، ولو فشل
/// بيعرض رسالة الخطأ بدل القايمة.
class _GroupPickerSheet extends StatefulWidget {
  const _GroupPickerSheet();

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  late final Future<List<Group>> _future = _load();

  Future<List<Group>> _load() async {
    final roster = await sl<GroupsRepository>().loadGroups();
    return roster.groups.where((g) => g.status == GroupStatus.active).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: FutureBuilder<List<Group>>(
          future: _future,
          builder: (context, snap) {
            final groups = snap.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.teacherExamGroupRequired,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(ErrorMapper.map(snap.error!).message),
                  )
                else if (groups == null || groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      l10n.groupsEmpty,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final details = [group.subject, group.grade]
                            .where((s) => s.trim().isNotEmpty)
                            .join(' · ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(group.name),
                          subtitle: details.isEmpty ? null : Text(details),
                          onTap: () => Navigator.of(context).pop(group),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
