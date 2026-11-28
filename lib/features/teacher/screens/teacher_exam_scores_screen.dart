import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/search_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../grades/grade_format.dart';
import '../../grades/models/score.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../grades/repositories/scores_repository.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../cubit/exam_scores_cubit.dart';
import '../models/exam_summary.dart';
import '../../../core/widgets/app_page.dart';

/// رصد الدرجات: بحث + خانة درجة لكل طالب + زر "حفظ الدرجات" واحد.
/// الخانة الفاضية بتتخطى (مش صفر).
class TeacherExamScoresScreen extends StatelessWidget {
  const TeacherExamScoresScreen({super.key, required this.args});

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
      child: const _ScoresView(),
    );
  }
}

class _ScoresView extends StatefulWidget {
  const _ScoresView();

  @override
  State<_ScoresView> createState() => _ScoresViewState();
}

class _ScoresViewState extends State<_ScoresView> {
  final Map<String, TextEditingController> _controllers = {};
  Map<String, String> _errors = {};
  String _query = '';

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(Student s, Score? existing) {
    return _controllers.putIfAbsent(
      s.id,
      () => TextEditingController(
        text: existing != null && existing.isCounted
            ? fmtScore(existing.score!)
            : '',
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ExamScoresCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.saveAll({
      for (final e in _controllers.entries) e.key: e.value.text,
    });
    if (!mounted) return;
    setState(() => _errors = result.errors);
    final text = result.hasErrors
        ? l10n.teacherScoresSomeFailed(result.errors.length)
        : result.saved == 0
        ? l10n.teacherScoresNothing
        : l10n.teacherScoresSaved(result.saved);
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.teacherScoresTitle,
      body: BlocBuilder<ExamScoresCubit, ExamScoresState>(
        builder: (context, state) => AsyncView<List<Student>>(
          state: state.view,
          onRetry: () => context.read<ExamScoresCubit>().load(),
          emptyMessage: l10n.scoresEmpty,
          emptyIcon: Icons.school_outlined,
          builder: (context, students) {
            final shown = [
              for (final s in students)
                if (matchesSearch('${s.fullName} ${s.studentNo}', _query)) s,
            ];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.exam.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.teacherScoresFinal(fmtScore(state.exam.maxScore)),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SearchField(
                        hint: l10n.teacherScoresSearchHint,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? Center(child: Text(l10n.teacherScoresNoMatch))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final s = shown[i];
                            final existing = state.scores[s.id];
                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.fullName} · ${s.studentNo}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  if (existing != null && !existing.isCounted)
                                    Text(
                                      existing.state == ScoreState.absent
                                          ? l10n.scoreStateAbsent
                                          : l10n.scoreStateExcused,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppTextField(
                                    controller: _controllerFor(s, existing),
                                    label: l10n.scoreFieldScore,
                                    isLtr: true,
                                    latinDigits: true,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    errorText: _errors[s.id],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Text(
                        l10n.teacherScoresNote,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.teacherScoresSaveAll,
                        isLoading: state.saving,
                        onPressed: () => _save(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
