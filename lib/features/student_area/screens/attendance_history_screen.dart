import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../assistant/models/attendance.dart';
import '../../students/models/student.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';

/// سجل حضور الطالب (الأحدث أولًا) مع ملخص "حضر X من Y".
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<AttendanceHistory>(
        () => sl<StudentDataRepository>().loadAttendance(student),
        isEmpty: (d) => d.rows.isEmpty,
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.areaAttendanceTitle)),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final cubit = context.read<ChildDataCubit<AttendanceHistory>>();
              return BlocBuilder<ChildDataCubit<AttendanceHistory>,
                  ViewState<AttendanceHistory>>(
                builder: (context, state) => AsyncView<AttendanceHistory>(
                  state: state,
                  onRetry: cubit.load,
                  emptyMessage: l10n.areaAttendanceEmpty,
                  emptyIcon: Icons.fact_check_outlined,
                  builder: (context, history) =>
                      _AttendanceList(history: history),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.history});

  final AttendanceHistory history;

  (String, StatusTone) _status(AppLocalizations l10n, AttendanceStatus s) =>
      switch (s) {
        AttendanceStatus.present => (
            l10n.attendanceStatusPresent,
            StatusTone.success,
          ),
        AttendanceStatus.lateArrival => (
            l10n.attendanceStatusLate,
            StatusTone.warning,
          ),
        AttendanceStatus.excused => (
            l10n.attendanceStatusExcused,
            StatusTone.info,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppCard(
          child: Text(
            l10n.attendanceSummary(history.attended, history.total),
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final row in history.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (row.groupName.isNotEmpty)
                          Text(
                            row.groupName,
                            style: theme.textTheme.titleMedium,
                          ),
                        if (row.when != null)
                          Text(
                            l10n.attendanceDateTime(
                              formatDate(l10n, row.when!),
                              formatTime(l10n, row.when!),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final (label, tone) = _status(l10n, row.attendance.status);
                      return StatusBadge(label: label, tone: tone);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
