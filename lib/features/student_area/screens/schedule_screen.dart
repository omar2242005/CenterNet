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
import '../repository/student_data_repository.dart';

/// الجدول الأسبوعي للطالب (من مواعيد مجموعاته).
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => ChildDataCubit<List<ScheduleEntry>>(
        () => sl<StudentDataRepository>().loadSchedule(student),
        isEmpty: (d) => d.isEmpty,
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.areaScheduleTitle)),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final cubit = context.read<ChildDataCubit<List<ScheduleEntry>>>();
              return BlocBuilder<ChildDataCubit<List<ScheduleEntry>>,
                  ViewState<List<ScheduleEntry>>>(
                builder: (context, state) => AsyncView<List<ScheduleEntry>>(
                  state: state,
                  onRetry: cubit.load,
                  emptyMessage: l10n.areaScheduleEmpty,
                  emptyIcon: Icons.calendar_month_outlined,
                  builder: (context, entries) => _ScheduleList(entries: entries),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.entries});

  final List<ScheduleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final children = <Widget>[];
    int? currentDay;
    for (final e in entries) {
      if (e.slot.weekday != currentDay) {
        currentDay = e.slot.weekday;
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              l10n.weekdayName('d${e.slot.weekday}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      final start = DateTime(2000, 1, 1, e.slot.startHour, e.slot.startMinute);
      final end = start.add(Duration(minutes: e.slot.durationMinutes));
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.group.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.scheduleTimeRange(
                    formatTime(l10n, start),
                    formatTime(l10n, end),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                if (e.group.subject.isNotEmpty)
                  Text(
                    e.group.subject,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (e.group.room.isNotEmpty)
                  Text(
                    l10n.scheduleRoom(e.group.room),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView(padding: AppSpacing.screenPadding, children: children);
  }
}
