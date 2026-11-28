import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../grades/grade_format.dart';
import '../child_route_names.dart';
import '../widgets/result_text.dart';
import '../widgets/child_shell.dart';

/// تفاصيل امتحان للطالب/ولي الأمر: الدرجة + بيانات الامتحان + تعليق المعلم.
/// الشاشة بتاخد النتيجة اللي اتحمّلت قبل كده، فمفيش قراءة جديدة.
class ExamDetailsScreen extends StatelessWidget {
  const ExamDetailsScreen({super.key, required this.args});

  final ExamDetailsArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = args.result;
    final exam = result.exam;
    final comment = result.score?.comment ?? '';
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return ChildShell(
      current: ChildTab.grades,
      isDetail: true,
      title: l10n.examDetailsTitle,
      student: args.student,
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.examYourScore, style: secondary),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  resultScoreText(l10n, result),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(fmtDate(l10n, exam.date), style: secondary),
                if (result.groupName.isNotEmpty)
                  Text(result.groupName, style: secondary),
                if (result.subject.isNotEmpty)
                  Text(result.subject, style: secondary),
                Text(
                  l10n.examMaxScore(fmtScore(exam.maxScore)),
                  style: secondary,
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
                  l10n.examTeacherComment,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(comment.isEmpty ? l10n.examNoComment : comment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
