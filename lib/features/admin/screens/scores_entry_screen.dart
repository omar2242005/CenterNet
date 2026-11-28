import 'package:center_net/features/grades/rules/score_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../../grades/cubit/scores_entry_cubit.dart';
import '../../grades/grade_format.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../grades/repositories/scores_repository.dart';
import '../../../core/widgets/app_page.dart';

/// إدخال درجات امتحان لطلاب المجموعة.
class ScoresEntryScreen extends StatelessWidget {
  const ScoresEntryScreen({super.key, required this.group, required this.exam});

  final Group group;
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScoresEntryCubit(
        sl<StudentsRepository>(),
        sl<ScoresRepository>(),
        group,
        exam,
      )..load(),
      child: const _ScoresEntryView(),
    );
  }
}

class _ScoresEntryView extends StatelessWidget {
  const _ScoresEntryView();

  Future<void> _edit(
    BuildContext context,
    Student student,
    ScoresEntryState state,
  ) {
    final cubit = context.read<ScoresEntryCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScoreSheet(
        student: student,
        existing: state.scoreOf(student.id),
        maxScore: state.exam.maxScore,
        onSave: (scoreState, score, comment) => cubit.save(
          student,
          scoreState: scoreState,
          score: score,
          comment: comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppPage(
      title: l10n.scoresTitle,
      body: BlocBuilder<ScoresEntryCubit, ScoresEntryState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${state.exam.title} · '
                        '${l10n.examMaxLabel(fmtScore(state.exam.maxScore))}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!state.loading)
                      Text(
                        l10n.scoresRecorded(
                          state.recordedCount,
                          state.students.length,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncView<List<Student>>(
                  state: state.view,
                  onRetry: context.read<ScoresEntryCubit>().load,
                  emptyMessage: l10n.scoresEmpty,
                  emptyIcon: Icons.groups_outlined,
                  builder: (context, students) => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: students.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _StudentScoreTile(
                        student: student,
                        score: state.scoreOf(student.id),
                        maxScore: state.exam.maxScore,
                        onTap: () => _edit(context, student, state),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentScoreTile extends StatelessWidget {
  const _StudentScoreTile({
    required this.student,
    required this.score,
    required this.maxScore,
    required this.onTap,
  });

  final Student student;
  final Score? score;
  final double maxScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = score;

    final Widget trailing;
    if (s == null) {
      trailing = Text(
        l10n.scoreNotYet,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    } else if (s.state == ScoreState.scored) {
      trailing = Text(
        '${fmtScore(s.score!)} / ${fmtScore(maxScore)}',
        style: theme.textTheme.titleMedium,
        textDirection: TextDirection.ltr,
      );
    } else {
      trailing = StatusBadge(
        label: s.state == ScoreState.absent
            ? l10n.scoreStateAbsent
            : l10n.scoreStateExcused,
      );
    }

    return AppCard(
      onTap: onTap,
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
          trailing,
        ],
      ),
    );
  }
}

/// ورقة رصد درجة طالب: الحالة + الدرجة + تعليق.
class _ScoreSheet extends StatefulWidget {
  const _ScoreSheet({
    required this.student,
    required this.existing,
    required this.maxScore,
    required this.onSave,
  });

  final Student student;
  final Score? existing;
  final double maxScore;
  final Future<Failure?> Function(ScoreState, double?, String) onSave;

  @override
  State<_ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<_ScoreSheet> {
  late ScoreState _state = widget.existing?.state ?? ScoreState.scored;
  late final TextEditingController _score = TextEditingController(
    text: widget.existing?.score == null
        ? ''
        : fmtScore(widget.existing!.score!),
  );
  late final TextEditingController _comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _score.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    double? value;
    if (_state == ScoreState.scored) {
      final result = ScoreValidator.parse(
        _score.text,
        maxScore: widget.maxScore,
      );
      if (!result.isValid) {
        setState(() => _error = result.error);
        return;
      }
      value = result.value;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await widget.onSave(_state, value, _comment.text);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = failureText(failure);
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.student.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilterChips<ScoreState>(
            options: {
              ScoreState.scored: l10n.scoreStateScored,
              ScoreState.absent: l10n.scoreStateAbsent,
              ScoreState.excused: l10n.scoreStateExcused,
            },
            selected: _state,
            onSelected: (s) => setState(() {
              _state = s;
              _error = null;
            }),
          ),
          if (_state == ScoreState.scored) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _score,
              label:
                  '${l10n.scoreFieldScore} (0 - ${fmtScore(widget.maxScore)})',
              isLtr: true,
              latinDigits: true,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _comment,
            label: l10n.scoreFieldComment,
            maxLength: 300,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.scoreSave,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
