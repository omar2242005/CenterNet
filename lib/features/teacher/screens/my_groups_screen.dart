import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/cubit/groups_list_cubit.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';
import '../teacher_route_names.dart';

/// "مجموعاتي": المجموعات اللي المعلم أو المساعد فيها.
class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GroupsListCubit(sl<GroupsRepository>(), mineOnly: true)..load(),
      child: const _MyGroupsView(),
    );
  }
}

class _MyGroupsView extends StatelessWidget {
  const _MyGroupsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myGroupsTitle)),
      body: SafeArea(
        child: BlocBuilder<GroupsListCubit, GroupsListState>(
          builder: (context, state) {
            return AsyncView<List<Group>>(
              state: state.view,
              onRetry: context.read<GroupsListCubit>().load,
              emptyMessage: l10n.myGroupsEmpty,
              emptyIcon: Icons.groups_outlined,
              builder: (context, groups) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: groups.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _GroupTile(
                  group: groups[index],
                  onTap: () => context.push(
                    TeacherRoutes.groupDetails,
                    extra: groups[index],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = [
      if (group.subject.isNotEmpty) group.subject,
      if (group.grade.isNotEmpty) group.grade,
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: theme.textTheme.titleMedium),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              sub,
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