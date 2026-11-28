import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/cairo_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../scan/services/pending_scan_store.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../models/attendance.dart';
import '../models/attendance_entry.dart';
import '../repository/attendance_repository.dart';
import '../widgets/payment_status_badge.dart';

/// قائمة حضور جلسة: سجلات Firestore + المسحات المحلية غير المتزامنة،
/// مع بحث بالاسم/الكود وفلترة بالحالة.
class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({
    super.key,
    required this.sessionId,
    required this.frame,
  });

  final String sessionId;

  /// هيكل الشاشة (AppBar والتابات) بيجي من الدور اللي بيعرضها: المساعد
  /// بيدي `AssistantShell`، وأي دور تاني بيدي هيكله. كده الفيتشر المشترك
  /// ما بيعرفش حاجة عن أدوار التطبيق.
  final Widget Function(BuildContext context, Widget body) frame;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceCubit(
        sl<AttendanceRepository>(),
        sl<PendingScanStore>(),
        sl<PendingOpsGuard>(),
        sessionId: sessionId,
      )..load(),
      child: frame(context, const _AttendanceBody()),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) => AsyncView<List<AttendanceEntry>>(
        state: state.status,
        onRetry: () => context.read<AttendanceCubit>().load(),
        emptyMessage: l10n.attendanceEmpty,
        builder: (context, entries) =>
            _DataBody(state: state, entries: entries),
      ),
    );
  }
}

class _DataBody extends StatelessWidget {
  const _DataBody({required this.state, required this.entries});

  final AttendanceState state;
  final List<AttendanceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AttendanceCubit>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SearchField(
            onChanged: cubit.search,
            hint: l10n.attendanceSearchHint,
          ),
        ),
        _FilterChips(
          selected: state.filter,
          onSelected: cubit.setFilter,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    l10n.attendanceNoResults,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _AttendanceRow(entry: entries[index]),
                ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final AttendanceFilter selected;
  final ValueChanged<AttendanceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(AttendanceFilter, String)>[
      (AttendanceFilter.all, l10n.attendanceFilterAll),
      (AttendanceFilter.present, l10n.attendanceStatusPresent),
      (AttendanceFilter.late, l10n.attendanceStatusLate),
      (AttendanceFilter.waiting, l10n.attendanceFilterWaiting),
      (AttendanceFilter.failed, l10n.attendanceFilterFailed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final (filter, label) in items) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
            if (filter != items.last.$1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final student = entry.student;
    final scannedAt = entry.scannedAt;
    final paymentStatus = entry.paymentStatus;
    final timeText = scannedAt == null
        ? ''
        : ' · ${formatTime(l10n, toCairoWallTime(scannedAt))}';
    final codeText = student == null
        ? ''
        : l10n.attendanceStudentCode(student.studentNo);

    final (statusLabel, statusTone) = switch (entry.status) {
      AttendanceStatus.present => (
        l10n.attendanceStatusPresent,
        StatusTone.success,
      ),
      _ => (l10n.attendanceStatusLate, StatusTone.warning),
    };
    final (syncLabel, syncTone, syncIcon) = switch (entry.syncState) {
      AttendanceSyncState.synced => (
        l10n.attendanceSyncSynced,
        StatusTone.neutral,
        Icons.cloud_done_outlined,
      ),
      AttendanceSyncState.waiting => (
        l10n.attendanceSyncWaiting,
        StatusTone.info,
        Icons.schedule,
      ),
      AttendanceSyncState.failed => (
        l10n.attendanceSyncFailed,
        StatusTone.error,
        Icons.error_outline,
      ),
    };

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student?.fullName ?? l10n.attendanceUnknownStudent,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (codeText.isNotEmpty || timeText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$codeText$timeText',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: statusLabel, tone: statusTone),
              const SizedBox(height: AppSpacing.xs),
              // [P1-خطوة4] حالة السداد لحظة التسجيل جنب علامة الحضور.
              PaymentStatusBadge(status: paymentStatus),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(label: syncLabel, tone: syncTone, icon: syncIcon),
            ],
          ),
        ],
      ),
    );
  }
}
