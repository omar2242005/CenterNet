import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/models/student.dart';
import '../child_route_names.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';
import 'result_text.dart';

/// كروت الرئيسية لطالب واحد: الحصة الجاية، الحضور، آخر نتيجة.
/// مشتركة بين رئيسية الطالب وولي الأمر. لازم الـ caller يديها key بـ id الطالب.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChildDataCubit<ChildSummary>(
        () => sl<StudentDataRepository>().loadSummary(student),
      )..load(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ChildDataCubit<ChildSummary>>();
          return BlocBuilder<ChildDataCubit<ChildSummary>,
              ViewState<ChildSummary>>(
            builder: (context, state) => AsyncView<ChildSummary>(
              state: state,
              onRetry: cubit.load,
              builder: (context, summary) =>
                  _Cards(student: student, summary: summary),
            ),
          );
        },
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.student, required this.summary});

  final Student student;
  final ChildSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final next = nextSession(summary.sessions, DateTime.now());
    final latest = summary.latestResult;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: () => context.push(ChildRoutes.attendance, extra: student),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.areaAttendanceTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                summary.attendance.total == 0
                    ? l10n.areaAttendanceEmpty
                    : l10n.attendanceSummary(
                        summary.attendance.attended,
                        summary.attendance.total,
                      ),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: latest == null
              ? null
              : () => context.push(ChildRoutes.exam, extra: latest),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.childLatestResult, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (latest == null)
                Text(l10n.areaResultsEmpty, style: secondary)
              else ...[
                Text(latest.exam.title, style: theme.textTheme.bodyLarge),
                Text(resultScoreText(l10n, latest), style: secondary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
