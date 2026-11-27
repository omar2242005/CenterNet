import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../cubit/child_data_cubit.dart';
import '../repository/student_data_repository.dart';
import '../widgets/child_shell.dart';

/// ملف الابن (ولي الأمر): بياناته + المجموعات اللي هو فيها.
/// اسم المعلم مش معروض لأنه مش متخزن في مستند المجموعة.
class ChildProfileScreen extends StatelessWidget {
  const ChildProfileScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<List<Group>>(
        () => sl<StudentDataRepository>().loadGroups(student),
      )..load(),
      child: ChildShell(
        current: ChildTab.fourth,
        title: l10n.guardianNavProfile,
        student: student,
        body: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            _InfoCard(student: student),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.childProfileGroups,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                final cubit = context.read<ChildDataCubit<List<Group>>>();
                return BlocBuilder<ChildDataCubit<List<Group>>,
                    ViewState<List<Group>>>(
                  builder: (context, state) => AsyncView<List<Group>>(
                    state: state,
                    onRetry: cubit.load,
                    emptyMessage: l10n.childProfileNoGroups,
                    emptyIcon: Icons.groups_outlined,
                    builder: (context, groups) => Column(
                      children: [
                        for (final g in groups)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _GroupCard(group: g),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.studentNumber(student.studentNo), style: secondary),
          if (student.grade.isNotEmpty)
            Text(l10n.studentGradeLabel(student.grade), style: secondary),
          if (student.phone.isNotEmpty)
            Text('${l10n.myAccountPhone}: ${student.phone}', style: secondary),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final Group group;

  /// "الأحد: 5:00 م - 6:30 م".
  String _slotText(AppLocalizations l10n, GroupSlot s) {
    final start = formatMinutesOfDay(l10n, s.startMinutes);
    final end = formatMinutesOfDay(l10n, s.startMinutes + s.durationMinutes);
    return '${l10n.weekdayName('d${s.weekday}')}: '
        '${l10n.scheduleTimeRange(start, end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: theme.textTheme.titleMedium),
          if (group.subject.isNotEmpty) Text(group.subject, style: secondary),
          if (group.room.isNotEmpty)
            Text(l10n.scheduleRoom(group.room), style: secondary),
          for (final s in group.slots)
            Text(_slotText(l10n, s), style: secondary),
        ],
      ),
    );
  }
}
