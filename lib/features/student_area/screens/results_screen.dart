import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../grades/grade_format.dart';
import '../../grades/models/score.dart';
import '../../students/models/student.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';

/// نتايج الطالب في الامتحانات المنشورة + المتوسط العام (AverageCalculator).
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<ResultsData>(
        () => sl<StudentDataRepository>().loadResults(student),
        isEmpty: (d) => d.items.isEmpty,
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.areaResultsTitle)),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final cubit = context.read<ChildDataCubit<ResultsData>>();
              return BlocBuilder<ChildDataCubit<ResultsData>,
                  ViewState<ResultsData>>(
                builder: (context, state) => AsyncView<ResultsData>(
                  state: state,
                  onRetry: cubit.load,
                  emptyMessage: l10n.areaResultsEmpty,
                  emptyIcon: Icons.grading_outlined,
                  builder: (context, data) => _ResultsList(data: data),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.data});

  final ResultsData data;

  String _scoreText(AppLocalizations l10n, ExamResult r) {
    final s = r.score;
    if (s == null) return l10n.resultsPending;
    return switch (s.state) {
      ScoreState.scored => l10n.resultsScoreOf(
          fmtScore(s.score ?? 0),
          fmtScore(r.exam.maxScore),
        ),
      ScoreState.absent => l10n.resultsAbsent,
      ScoreState.excused => l10n.resultsExcused,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final average = data.average;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        if (average != null) ...[
          AppCard(
            child: Text(
              l10n.resultsAverage(average.toStringAsFixed(1)),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final r in data.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.exam.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    fmtDate(l10n, r.exam.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_scoreText(l10n, r), style: theme.textTheme.bodyLarge),
                  if ((r.score?.comment ?? '').isNotEmpty)
                    Text(
                      r.score!.comment,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
