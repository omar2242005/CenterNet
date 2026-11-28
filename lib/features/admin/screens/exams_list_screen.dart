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
import '../../groups/models/group.dart';
import '../../grades/cubit/exams_list_cubit.dart';
import '../../grades/grade_format.dart';
import '../../grades/grade_route_names.dart';
import '../../grades/models/exam.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../../core/widgets/app_page.dart';

/// امتحانات مجموعة: قايمة + إنشاء + نشر وإلغاء نشر.
class ExamsListScreen extends StatelessWidget {
  const ExamsListScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExamsListCubit(sl<ExamsRepository>(), group)..load(),
      child: _ExamsListView(group: group),
    );
  }
}

class _ExamsListView extends StatelessWidget {
  const _ExamsListView({required this.group});

  final Group group;

  /// بنفتح الشاشة وبعد الرجوع بنحمّل القايمة من جديد.
  Future<void> _open(BuildContext context, String route, Object extra) async {
    final cubit = context.read<ExamsListCubit>();
    await context.push<Object?>(route, extra: extra);
    if (!cubit.isClosed) await cubit.load();
  }

  Future<void> _togglePublish(BuildContext context, Exam exam) async {
    final failure = await context.read<ExamsListCubit>().setPublished(
      exam,
      published: !exam.published,
    );
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppPage(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.examsTitle),
          Text(
            group.name,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, GradeRoutes.examCreate, group),
        icon: const Icon(Icons.add),
        label: Text(l10n.examAddTitle),
      ),
      body: BlocBuilder<ExamsListCubit, ExamsListState>(
        builder: (context, state) {
          return AsyncView<List<Exam>>(
            state: state.view,
            onRetry: context.read<ExamsListCubit>().load,
            emptyMessage: l10n.examsEmpty,
            emptyIcon: Icons.quiz_outlined,
            builder: (context, exams) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                // مسافة تحت عشان الزر العايم مايغطيش آخر امتحان.
                AppSpacing.xl * 3,
              ),
              itemCount: exams.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final exam = exams[index];
                return _ExamTile(
                  exam: exam,
                  busy: state.busyExamId == exam.id,
                  onTap: () => _open(
                    context,
                    GradeRoutes.scores,
                    ExamScoresArgs(group, exam),
                  ),
                  onTogglePublish: () => _togglePublish(context, exam),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({
    required this.exam,
    required this.busy,
    required this.onTap,
    required this.onTogglePublish,
  });

  final Exam exam;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onTogglePublish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exam.title, style: theme.textTheme.titleMedium),
              ),
              StatusBadge(
                label: exam.published ? l10n.examPublished : l10n.examDraft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${fmtDate(l10n, exam.date)} · '
            '${l10n.examMaxLabel(fmtScore(exam.maxScore))}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: exam.published ? l10n.examUnpublish : l10n.examPublish,
            variant: exam.published
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            expand: false,
            isLoading: busy,
            onPressed: onTogglePublish,
          ),
        ],
      ),
    );
  }
}
