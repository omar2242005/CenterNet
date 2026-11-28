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
import '../../grades/models/score.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../grades/repositories/scores_repository.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../cubit/exam_scores_cubit.dart';
import '../models/exam_summary.dart';
import '../rules/teacher_exams_builder.dart';
import '../teacher_route_names.dart';
import '../../../core/widgets/app_page.dart';

/// تفاصيل اختبار: كارت ملخص + درجات الطلاب، وزر رصد الدرجات.
class TeacherExamDetailsScreen extends StatelessWidget {
  const TeacherExamDetailsScreen({super.key, required this.args});

  final TeacherExamArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExamScoresCubit(
        sl<StudentsRepository>(),
        sl<ScoresRepository>(),
        sl<ExamsRepository>(),
        args.group,
        args.exam,
      )..load(),
      child: _DetailsView(args: args),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.args});

  final TeacherExamArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.teacherExamDetailsTitle,
      body: BlocBuilder<ExamScoresCubit, ExamScoresState>(
        builder: (context, state) => AsyncView<List<Student>>(
          state: state.view,
          onRetry: () => context.read<ExamScoresCubit>().load(),
          emptyMessage: l10n.scoresEmpty,
          emptyIcon: Icons.school_outlined,
          builder: (context, students) =>
              _Body(args: args, state: state, students: students),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.args,
    required this.state,
    required this.students,
  });

  final TeacherExamArgs args;
  final ExamScoresState state;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exam = state.exam;
    final avg = averageScore(state.scores.values);
    final max = fmtScore(exam.maxScore);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(exam.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      args.group.subject.isEmpty
                          ? args.group.name
                          : '${args.group.subject} · ${args.group.name}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: exam.published ? l10n.examPublished : l10n.examDraft,
                    tone: exam.published
                        ? StatusTone.success
                        : StatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                fmtDate(l10n, toCairoWallTime(exam.date)),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                avg == null
                    ? l10n.scoreNotYet
                    : l10n.resultsScoreOf(fmtAverage(avg), max),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.teacherExamAverage} · ${l10n.teacherExamRecordedCount(state.recordedCount, students.length)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.teacherExamRecordButton,
          icon: Icons.edit_note,
          onPressed: () async {
            final cubit = context.read<ExamScoresCubit>();
            await context.push(
              TeacherRoutes.examScores,
              extra: TeacherExamArgs(args.group, exam),
            );
            if (!cubit.isClosed) await cubit.load();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: exam.published ? l10n.examUnpublish : l10n.examPublish,
          variant: AppButtonVariant.secondary,
          isLoading: state.publishing,
          onPressed: () async {
            final failure = await context.read<ExamScoresCubit>().setPublished(
              !exam.published,
            );
            if (failure != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(failureText(failure))));
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.teacherExamStudentScores, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final s in students) ...[
          _StudentCard(student: s, score: state.scores[s.id], max: max),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.score,
    required this.max,
  });

  final Student student;
  final Score? score;
  final String max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = score;
    final String headline;
    final String caption;
    if (s == null) {
      headline = l10n.scoreNotYet;
      caption = l10n.teacherExamNotRecorded;
    } else if (s.isCounted) {
      headline = l10n.resultsScoreOf(fmtScore(s.score!), max);
      caption = l10n.teacherExamScoreRecorded;
    } else {
      headline = s.state == ScoreState.absent
          ? l10n.scoreStateAbsent
          : l10n.scoreStateExcused;
      caption = l10n.teacherExamScoreRecorded;
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.fullName, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            headline,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: s == null ? AppColors.textSecondary : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.teacherStudentNo(student.studentNo.toString())} · $caption',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
