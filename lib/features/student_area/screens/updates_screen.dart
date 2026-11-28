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
import '../models/updates_args.dart';
import '../repository/student_data_repository.dart';
import '../widgets/result_text.dart';
import '../../../core/widgets/app_page.dart';

typedef _ChildUpdates = ({Student student, List<UpdateItem> items});

/// "آخر التحديثات" (طالب) / "تحديثات الأبناء" (ولي أمر).
/// بتتحسب وقت الفتح من البيانات الموجودة: مفيش إشعارات ولا مقروء/غير مقروء.
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key, required this.args});

  final UpdatesArgs args;

  Future<List<_ChildUpdates>> _load() async {
    final repo = sl<StudentDataRepository>();
    final now = DateTime.now();
    return Future.wait(
      args.students.map((s) async {
        final summary = await repo.loadSummary(s);
        return (student: s, items: buildUpdates(summary, now));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<List<_ChildUpdates>>(
        _load,
        isEmpty: (d) => d.every((c) => c.items.isEmpty),
      )..load(),
      child: AppPage(
        title: args.guardian
            ? l10n.updatesGuardianTitle
            : l10n.updatesStudentTitle,
        body: Builder(
          builder: (context) {
            final cubit = context.read<ChildDataCubit<List<_ChildUpdates>>>();
            return BlocBuilder<
              ChildDataCubit<List<_ChildUpdates>>,
              ViewState<List<_ChildUpdates>>
            >(
              builder: (context, state) => AsyncView<List<_ChildUpdates>>(
                state: state,
                onRetry: cubit.load,
                emptyMessage: l10n.updatesEmpty,
                emptyIcon: Icons.notifications_none,
                builder: (context, children) => ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    for (final c in children)
                      _ChildSection(update: c, showName: args.guardian),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChildSection extends StatelessWidget {
  const _ChildSection({required this.update, required this.showName});

  final _ChildUpdates update;
  final bool showName;

  String _title(AppLocalizations l10n, UpdateKind k) => switch (k) {
    UpdateKind.grade => l10n.updatesGrades,
    UpdateKind.session => l10n.updatesSessions,
    UpdateKind.attendance => l10n.updatesAttendance,
    UpdateKind.absence => l10n.updatesAbsence,
  };

  /// التاريخ والوقت، أو "اليوم" لو الحصة النهارده.
  String _when(AppLocalizations l10n, DateTime? when) {
    if (when == null) return '';
    final now = DateTime.now();
    final today =
        when.year == now.year && when.month == now.month && when.day == now.day;
    return l10n.attendanceDateTime(
      today ? l10n.updatesToday : formatDate(l10n, when),
      formatTime(l10n, when),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showName)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              update.student.fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        for (final kind in UpdateKind.values) ...[
          if (update.items.any((i) => i.kind == kind)) ...[
            Text(_title(l10n, kind), style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final i in update.items.where((i) => i.kind == kind))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.title.isEmpty ? l10n.areaAttendanceTitle : i.title,
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (i.result != null)
                        Text(
                          resultScoreText(l10n, i.result!),
                          style: secondary,
                        ),
                      if (i.when != null)
                        Text(
                          kind == UpdateKind.grade
                              ? formatDate(l10n, i.when!)
                              : _when(l10n, i.when),
                          style: secondary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
