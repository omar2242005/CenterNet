import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../grades/grade_format.dart';
import '../../students/models/student.dart';
import '../child_route_names.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';
import '../widgets/child_shell.dart';
import '../widgets/filter_chips.dart';
import '../widgets/result_text.dart';

/// نتايج الطالب في الامتحانات المنشورة + المتوسط العام + فلتر المادة.
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
      child: ChildShell(
        current: ChildTab.grades,
        title: l10n.areaResultsTitle,
        student: student,
        body: Builder(
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
    );
  }
}

class _ResultsList extends StatefulWidget {
  const _ResultsList({required this.data});

  final ResultsData data;

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  /// المادة المختارة. فاضي = الكل.
  String _subject = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = widget.data;
    final average = data.average;
    final subjects = data.subjects;
    final shown = [
      for (final r in data.items)
        if (_subject.isEmpty || r.subject == _subject) r,
    ];
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
        if (subjects.isNotEmpty) ...[
          FilterChips<String>(
            options: {'': l10n.filterAll, for (final s in subjects) s: s},
            selected: _subject,
            onSelected: (s) => setState(() => _subject = s),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.push(ChildRoutes.exam, extra: r),
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
                  Text(
                    resultScoreText(l10n, r),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
