import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../cubit/group_enrollment_cubit.dart';
import '../models/group.dart';
import '../repository/groups_repository.dart';

/// تسجيل طلاب السنتر في مجموعة (وإلغاء تسجيلهم) بعلامة اختيار لكل طالب.
/// الطالب المؤرشف بيظهر بس لو لسه مسجّل، عشان يتشال من المجموعة.
class GroupEnrollmentScreen extends StatelessWidget {
  const GroupEnrollmentScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GroupEnrollmentCubit(sl<StudentsRepository>(), sl<GroupsRepository>(), group)
            ..load(),
      child: const _GroupEnrollmentView(),
    );
  }
}

class _GroupEnrollmentView extends StatelessWidget {
  const _GroupEnrollmentView();

  Future<void> _toggle(BuildContext context, Student student) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure =
        await context.read<GroupEnrollmentCubit>().toggle(student);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GroupEnrollmentCubit>();
    final group = cubit.state.group;

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<GroupEnrollmentCubit, GroupEnrollmentState>(
                    buildWhen: (a, b) =>
                        a.enrolled.length != b.enrolled.length ||
                        a.isFull != b.isFull,
                    builder: (context, state) => Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.groupEnrolledCount(state.enrolled.length),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        if (state.isFull)
                          StatusBadge(
                            label: l10n.groupFullBadge,
                            tone: StatusTone.warning,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SearchField(
                    hint: l10n.groupStudentsSearchHint,
                    onChanged: cubit.setQuery,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<GroupEnrollmentCubit, GroupEnrollmentState>(
                builder: (context, state) {
                  return AsyncView<List<Student>>(
                    state: state.view,
                    onRetry: cubit.load,
                    emptyMessage: l10n.groupStudentsEmpty,
                    emptyIcon: Icons.school_outlined,
                    builder: (context, students) => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: students.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _EnrollmentTile(
                        student: students[index],
                        enrolled: students[index].isInGroup(group.id),
                        busy: state.busyStudentId == students[index].id,
                        onTap: () => _toggle(context, students[index]),
                      ),
                    ),
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

class _EnrollmentTile extends StatelessWidget {
  const _EnrollmentTile({
    required this.student,
    required this.enrolled,
    required this.busy,
    required this.onTap,
  });

  final Student student;
  final bool enrolled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      onTap: busy ? null : onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  student.grade.isEmpty
                      ? l10n.studentNumber(student.studentNo)
                      : '${l10n.studentNumber(student.studentNo)} · '
                          '${student.grade}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (student.isArchived) ...[
            StatusBadge(label: l10n.studentArchivedBadge),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (busy)
            const SizedBox(
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Checkbox(
              value: enrolled,
              onChanged: (_) => onTap(),
            ),
        ],
      ),
    );
  }
}
