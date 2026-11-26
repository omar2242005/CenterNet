import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/widgets/admin_shell.dart';
import '../../linking/models/invite_code.dart';
import '../cubit/staff_list_cubit.dart';
import '../models/staff_member.dart';
import '../models/staff_role_text.dart';
import '../repository/staff_repository.dart';
import '../staff_route_names.dart';

/// شاشة "الموظفون" (للأدمن): قائمة الأعضاء، وتغيير الدور، وتعطيل/تفعيل العضو.
class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffListCubit(sl<StaffRepository>())..load(),
      child: const _StaffListView(),
    );
  }
}

class _StaffListView extends StatelessWidget {
  const _StaffListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminShell(
      current: AdminTab.staff,
      title: l10n.staffListTitle,
      actions: [
        IconButton(
          tooltip: l10n.staffInviteTitle,
          icon: const Icon(Icons.person_add_alt_1),
          onPressed: () => context.push(StaffRoutes.invite),
        ),
      ],
      body: SafeArea(
        child: BlocConsumer<StaffListCubit, StaffListState>(
          listenWhen: (previous, current) =>
              current.actionFailure != null &&
              current.actionFailure != previous.actionFailure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionFailure!.message)),
            );
          },
          builder: (context, state) {
            return AsyncView<List<StaffMember>>(
              state: state.view,
              onRetry: context.read<StaffListCubit>().load,
              emptyMessage: l10n.staffListEmpty,
              emptyIcon: Icons.group_outlined,
              builder: (context, members) => ListView.separated(
                padding: AppSpacing.screenPadding,
                itemCount: members.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return _StaffTile(
                    member: member,
                    busy: state.busyUid == member.uid,
                    locked: state.busyUid != null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _StaffAction { changeRole, toggleActive }

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.member,
    required this.busy,
    required this.locked,
  });

  final StaffMember member;

  /// التعديل شغال على الموظف ده دلوقتي.
  final bool busy;

  /// فيه تعديل شغال على أي موظف (بنمنع تعديلين مع بعض).
  final bool locked;

  Future<void> _changeRole(BuildContext context, StaffInviteRole target) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StaffListCubit>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.staffChangeRoleTitle,
      message: l10n.staffChangeRoleMessage(member.name, target.label(l10n)),
      confirmLabel: l10n.staffChangeRoleConfirm,
    );
    if (ok) await cubit.changeRole(member, target);
  }

  Future<void> _toggleActive(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StaffListCubit>();
    final disabling = member.active;
    final ok = await showConfirmDialog(
      context,
      title: disabling ? l10n.staffDisableTitle : l10n.staffEnableTitle,
      message: disabling
          ? l10n.staffDisableMessage(member.name)
          : l10n.staffEnableMessage(member.name),
      confirmLabel:
          disabling ? l10n.staffActionDisable : l10n.staffActionEnable,
      destructive: disabling,
    );
    if (ok) await cubit.setActive(member, !disabling);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final other = member.otherRole;

    Widget? trailing;
    if (busy) {
      trailing = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (member.editable && other != null) {
      trailing = PopupMenuButton<_StaffAction>(
        tooltip: l10n.staffMenuTooltip,
        enabled: !locked,
        onSelected: (action) {
          switch (action) {
            case _StaffAction.changeRole:
              _changeRole(context, other);
            case _StaffAction.toggleActive:
              _toggleActive(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<_StaffAction>(
            value: _StaffAction.changeRole,
            child: Text(l10n.staffActionChangeRoleTo(other.label(l10n))),
          ),
          PopupMenuItem<_StaffAction>(
            value: _StaffAction.toggleActive,
            child: Text(
              member.active
                  ? l10n.staffActionDisable
                  : l10n.staffActionEnable,
            ),
          ),
        ],
      );
    }

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: member.active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(
                      label: member.role.label(l10n),
                      tone: member.isAdmin
                          ? StatusTone.info
                          : StatusTone.neutral,
                    ),
                    StatusBadge(
                      label: member.active
                          ? l10n.staffStatusActive
                          : l10n.staffStatusDisabled,
                      tone: member.active
                          ? StatusTone.success
                          : StatusTone.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing,
          ],
        ],
      ),
    );
  }
}
