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
import '../../attendance/models/attendance.dart';
import '../../students/models/student.dart';
import '../cubit/child_data_cubit.dart';
import '../models/child_data.dart';
import '../repository/student_data_repository.dart';
import '../widgets/filter_chips.dart';

/// سجل حضور الطالب (الأحدث أولًا) مع ملخص "حضر X من Y" وفلتر (الكل / حضر / غاب).
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<AttendanceHistory>(
        () => sl<StudentDataRepository>().loadAttendance(student),
        isEmpty: (d) => d.total == 0,
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

enum _AttendanceFilter { all, present, absent }

/// سطر معروض: حضور مسجل، أو غياب لو [attendance] = null.
class _Line {
  const _Line(this.groupName, this.when, this.attendance);

  final String groupName;
  final DateTime? when;
  final Attendance? attendance;
}

class _AttendanceList extends StatefulWidget {
  const _AttendanceList({required this.history});

  final AttendanceHistory history;

  @override
  State<_AttendanceList> createState() => _AttendanceListState();
}

class _AttendanceListState extends State<_AttendanceList> {
  _AttendanceFilter _filter = _AttendanceFilter.all;

  List<_Line> _lines() {
    final h = widget.history;
    final present = [
      for (final r in h.rows)
        if (_filter == _AttendanceFilter.all || r.attendance.countsAsAttended)
          _Line(r.groupName, r.when, r.attendance),
    ];
    final absent = [
      for (final a in h.absences) _Line(a.groupName, a.when, null),
    ];
    final lines = switch (_filter) {
      _AttendanceFilter.present => present,
      _AttendanceFilter.absent => absent,
      _AttendanceFilter.all => [...present, ...absent],
    };
    lines.sort((a, b) {
      final x = a.when;
      final y = b.when;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return lines;
  }

  (String, StatusTone) _status(AppLocalizations l10n, Attendance? a) {
    if (a == null) return (l10n.attendanceStatusAbsent, StatusTone.error);
    return switch (a.status) {
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final history = widget.history;
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
        FilterChips<_AttendanceFilter>(
          options: {
            _AttendanceFilter.all: l10n.filterAll,
            _AttendanceFilter.present: l10n.filterPresent,
            _AttendanceFilter.absent: l10n.filterAbsent,
          },
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final line in _lines())
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (line.groupName.isNotEmpty)
                          Text(
                            line.groupName,
                            style: theme.textTheme.titleMedium,
                          ),
                        if (line.when != null)
                          Text(
                            l10n.attendanceDateTime(
                              formatDate(l10n, line.when!),
                              formatTime(l10n, line.when!),
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
                      final (label, tone) = _status(l10n, line.attendance);
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
