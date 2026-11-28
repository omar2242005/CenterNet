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
import '../../../core/utils/cairo_time.dart';
import '../../grades/grade_format.dart';
import '../cubit/teacher_exams_cubit.dart';
import '../models/exam_summary.dart';
import '../rules/teacher_exams_builder.dart';
import '../teacher_route_names.dart';
import '../widgets/teacher_shell.dart';

/// تبويب "الامتحانات": امتحانات كل مجموعات المعلم، مقسومة حسب المادة.
class TeacherExamsScreen extends StatelessWidget {
  const TeacherExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => sl<TeacherExamsCubit>()..load(),
      child: TeacherShell(
        current: TeacherTab.exams,
        title: l10n.teacherExamsTitle,
        body: const _ExamsBody(),
      ),
    );
  }
}

class _ExamsBody extends StatelessWidget {
  const _ExamsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TeacherExamsCubit, TeacherExamsState>(
      builder: (context, state) => AsyncView<List<ExamSummary>>(
        state: state.status,
        onRetry: () => context.read<TeacherExamsCubit>().load(),
        emptyMessage: l10n.teacherExamsEmpty,
        emptyIcon: Icons.school_outlined,
        emptyAction: AppButton(
          label: l10n.teacherExamCreateButton,
          expand: false,
          onPressed: () => _create(context),
        ),
        builder: (context, items) => _ExamsList(items: items),
      ),
    );
  }
}

Future<void> _create(BuildContext context) async {
  final cubit = context.read<TeacherExamsCubit>();
  await context.push(TeacherRoutes.examCreate);
  if (!cubit.isClosed) await cubit.load();
}

class _ExamsList extends StatelessWidget {
  const _ExamsList({required this.items});

  final List<ExamSummary> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sections = groupExamsBySubject(items);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppButton(
          label: l10n.teacherExamCreateButton,
          icon: Icons.add,
          onPressed: () => _create(context),
        ),
        for (final entry in sections.entries) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            entry.key.isEmpty
                ? l10n.teacherExamsOther
                : l10n.teacherExamsOfSubject(entry.key),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in entry.value) ...[
            _ExamCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.item});

  final ExamSummary item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = item.statusAt(DateTime.now());
    final (label, tone) = switch (status) {
      TeacherExamStatus.graded => (
        l10n.teacherExamStatusGraded,
        StatusTone.success,
      ),
      TeacherExamStatus.inProgress => (
        l10n.teacherExamStatusInProgress,
        StatusTone.warning,
      ),
      TeacherExamStatus.upcoming => (
        l10n.teacherExamStatusUpcoming,
        StatusTone.info,
      ),
    };
    return AppCard(
      onTap: () async {
        final cubit = context.read<TeacherExamsCubit>();
        await context.push(
          TeacherRoutes.examDetails,
          extra: TeacherExamArgs(item.group, item.exam),
        );
        if (!cubit.isClosed) await cubit.load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.exam.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${item.group.name} · ${fmtDate(l10n, toCairoWallTime(item.exam.date))}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.teacherExamSummaryLine(
              item.recordedCount,
              item.studentCount,
              fmtScore(item.exam.maxScore),
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
