import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../grades/grade_route_names.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../cubit/group_details_cubit.dart';
import '../repository/group_attendance_repository.dart';

/// تفاصيل مجموعة: الطلبة وغياب كل واحد + زرار الامتحانات.
class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupDetailsCubit(
        sl<StudentsRepository>(),
        sl<GroupAttendanceRepository>(),
        group,
      )..load(),
      child: const _GroupDetailsView(),
    );
  }
}

class _GroupDetailsView extends StatelessWidget {
  const _GroupDetailsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(state.group.name)),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: l10n.groupExamsButton,
                    icon: Icons.quiz_outlined,
                    onPressed: () => context.push(
                      GradeRoutes.exams,
                      extra: state.group,
                    ),
                  ),
                ),
                if (!state.loading && state.failure == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.groupStudentsSummary(
                          state.students.length,
                          state.sessionsCount,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                Expanded(
                  child: AsyncView<List<Student>>(
                    state: state.view,
                    onRetry: context.read<GroupDetailsCubit>().load,
                    emptyMessage: l10n.groupNoStudents,
                    emptyIcon: Icons.school_outlined,
                    builder: (context, students) => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: students.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return _StudentRow(
                          student: s,
                          absences: state.absencesOf(s.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          ),
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.absences});

  final Student student;
  final int absences;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.studentNumber(student.studentNo),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: l10n.groupAbsencesBadge(absences)),
        ],
      ),
    );
  }
}