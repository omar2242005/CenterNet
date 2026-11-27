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
import '../../students/models/student.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';

/// متابعة الابن (ولي الأمر): حضور الشهر الحالي ونتايجه + الحصة الجاية.
class ChildOverviewScreen extends StatelessWidget {
  const ChildOverviewScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<ChildSummary>(
        () => sl<StudentDataRepository>().loadSummary(student),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.childOverviewTitle)),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final cubit = context.read<ChildDataCubit<ChildSummary>>();
              return BlocBuilder<ChildDataCubit<ChildSummary>,
                  ViewState<ChildSummary>>(
                builder: (context, state) => AsyncView<ChildSummary>(
                  state: state,
                  onRetry: cubit.load,
                  builder: (context, summary) => _Overview(
                    student: student,
                    summary: summary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.student, required this.summary});

  final Student student;
  final ChildSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    final att = monthAttendance(summary.attendance, now);
    final average = monthAverage(summary.results, now);
    final next = nextSession(summary.sessions, now);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(student.fullName, style: theme.textTheme.titleLarge),
        Text(l10n.monthName('m${now.month}'), style: secondary),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.childMonthAttendance,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                att.total == 0
                    ? l10n.areaAttendanceEmpty
                    : l10n.attendanceSummary(att.attended, att.total),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.childMonthResults,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                average == null
                    ? l10n.areaResultsEmpty
                    : l10n.resultsAverage(average.toStringAsFixed(1)),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.childNextSession, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (next == null)
                Text(l10n.childNoNextSession, style: secondary)
              else ...[
                Text(next.group.name, style: theme.textTheme.bodyLarge),
                Text(
                  l10n.attendanceDateTime(
                    formatDate(l10n, next.when),
                    formatTime(l10n, next.when),
                  ),
                  style: secondary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
