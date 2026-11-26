import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/groups_list_cubit.dart';
import '../group_route_names.dart';
import '../models/group.dart';
import '../repository/groups_repository.dart';

/// شاشة "المجموعات" (للأدمن): قائمة كل مجموعات السنتر + بحث + أرشيف.
/// الإضافة والتعديل وتسجيل الطلاب وحصص المجموعة شاشات منفصلة بتتبني فوقها.
class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupsListCubit(sl<GroupsRepository>())..load(),
      child: const _GroupsListView(),
    );
  }
}

class _GroupsListView extends StatefulWidget {
  const _GroupsListView();

  @override
  State<_GroupsListView> createState() => _GroupsListViewState();
}

class _GroupsListViewState extends State<_GroupsListView> {
  String _query = '';

  /// بنفتح الإضافة/التعديل وبعد الرجوع بنحمّل القائمة من جديد.
  Future<void> _open(String route, {Group? extra}) async {
    final cubit = context.read<GroupsListCubit>();
    await context.push(route, extra: extra);
    if (!cubit.isClosed) await cubit.load();
  }

  Future<void> _archive(Group group) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<GroupsListCubit>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.groupArchiveTitle,
      message: l10n.groupArchiveMessage(group.name),
      confirmLabel: l10n.groupArchiveConfirm,
      destructive: true,
    );
    if (!ok) return;
    final failure = await cubit.archive(group);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupsListTitle),
        actions: [
          BlocBuilder<GroupsListCubit, GroupsListState>(
            buildWhen: (a, b) => a.showArchived != b.showArchived,
            builder: (context, state) => IconButton(
              tooltip: state.showArchived
                  ? l10n.groupsHideArchived
                  : l10n.groupsShowArchived,
              icon: Icon(
                state.showArchived
                    ? Icons.inventory_2
                    : Icons.inventory_2_outlined,
              ),
              onPressed: () => context
                  .read<GroupsListCubit>()
                  .setShowArchived(!state.showArchived),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(GroupRoutes.create),
        icon: const Icon(Icons.group_add_outlined),
        label: Text(l10n.groupsAddTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: SearchField(
                hint: l10n.groupsSearchHint,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: BlocBuilder<GroupsListCubit, GroupsListState>(
                builder: (context, state) {
                  return AsyncView<List<Group>>(
                    state: state.view,
                    onRetry: context.read<GroupsListCubit>().load,
                    emptyMessage: l10n.groupsEmpty,
                    emptyIcon: Icons.groups_2_outlined,
                    builder: (context, groups) {
                      final filtered = <Group>[
                        for (final g in groups)
                          if (matchesSearch(
                            '${g.name} ${g.subject} ${g.grade}',
                            _query,
                          ))
                            g,
                      ];
                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(l10n.groupsNoResults),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          // مسافة تحت عشان الزر العايم مايغطيش آخر مجموعة.
                          AppSpacing.xl * 3,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final group = filtered[index];
                          return _GroupTile(
                            group: group,
                            onTap: () => _open(
                              GroupRoutes.edit,
                              extra: group,
                            ),
                            onArchive: group.isArchived
                                ? null
                                : () => _archive(group),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap, this.onArchive});

  final Group group;
  final VoidCallback onTap;

  /// null للمؤرشفة (مفيش إجراءات عليها من القائمة).
  final VoidCallback? onArchive;

  String _slotsSummary(AppLocalizations l10n) {
    const base = 1700; // يوم مرجعي ثابت، formatTime بيقرأ الساعة والدقيقة بس.
    final origin = DateTime.fromMillisecondsSinceEpoch(base);
    return [
      for (final slot in group.slots)
        '${l10n.weekdayName('d${slot.weekday}')} '
            '${formatTime(l10n, origin.add(Duration(minutes: slot.startMinutes)))}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final headline = <String>[
      if (group.subject.trim().isNotEmpty) group.subject,
      if (group.grade.trim().isNotEmpty) group.grade,
    ].join(' · ');
    final meta = <String>[
      if (group.room.trim().isNotEmpty) group.room,
      if (group.monthlyFee > 0) formatMoney(l10n, group.monthlyFee),
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: group.isArchived
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        headline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (group.isArchived) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(label: l10n.groupArchivedBadge),
              ],
              if (onArchive != null)
                PopupMenuButton<String>(
                  onSelected: (_) => onArchive!(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(l10n.groupArchiveAction),
                    ),
                  ],
                ),
            ],
          ),
          if (group.slots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _slotsSummary(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              meta,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
