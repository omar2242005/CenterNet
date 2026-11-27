import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../assistant_route_names.dart';
import '../cubit/session_details_cubit.dart';
import '../cubit/session_details_state.dart';
import '../models/attendance.dart';
import '../models/attendance_entry.dart';
import '../models/session_time_status.dart';
import '../repository/assistant_repository.dart';
import '../services/cairo_time.dart';
import '../services/pending_scan_store.dart';
import '../widgets/assistant_shell.dart';
import '../widgets/payment_status_badge.dart';

/// تفاصيل الحصة: المجموعة والوقت والقاعة + ملخص الحضور المدموج + آخر
/// عمليات المسح + زرا "مسح كود الطالب" (تحضير للأوفلاين) و"قائمة الحضور".
class SessionDetailsScreen extends StatelessWidget {
  const SessionDetailsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => SessionDetailsCubit(
        sl<AssistantRepository>(),
        sl<PendingScanStore>(),
        sl<PendingOpsGuard>(),
        sessionId: sessionId,
      )..load(),
      child: AssistantShell(
        current: AssistantTab.sessions,
        title: l10n.assistantSessionDetailsTitle,
        body: BlocListener<SessionDetailsCubit, SessionDetailsState>(
          listenWhen: (previous, current) =>
              current.preparedSetup != null &&
              current.preparedSetup != previous.preparedSetup,
          listener: (context, state) {
            final setup = state.preparedSetup;
            if (setup == null) return;
            context.read<SessionDetailsCubit>().consumePreparedSetup();
            context.push('/${AssistantRouteNames.scan}', extra: setup);
          },
          child: BlocBuilder<SessionDetailsCubit, SessionDetailsState>(
            builder: (context, state) => AsyncView<SessionDetailsData>(
              state: state.status,
              onRetry: () => context.read<SessionDetailsCubit>().load(),
              builder: (context, data) =>
                  _DetailsBody(state: state, data: data),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.state, required this.data});

  final SessionDetailsState state;
  final SessionDetailsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = data.session;
    final group = data.group;
    final status = sessionTimeStatus(session, DateTime.now());
    final start = toCairoWallTime(session.startAt);
    final end = toCairoWallTime(session.endAt);

    final (label, tone) = switch (status) {
      SessionTimeStatus.current => (
        l10n.sessionStatusCurrent,
        StatusTone.success,
      ),
      SessionTimeStatus.upcoming => (
        l10n.sessionStatusUpcoming,
        StatusTone.info,
      ),
      SessionTimeStatus.ended => (l10n.sessionStatusEnded, StatusTone.neutral),
      SessionTimeStatus.cancelled => (
        l10n.sessionStatusCancelled,
        StatusTone.error,
      ),
    };

    final canScan = status != SessionTimeStatus.cancelled;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.groups_outlined,
                label: l10n.sessionGroupLabel,
                value: group.name,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.schedule,
                label: l10n.sessionTimeLabel,
                value:
                    '${formatTime(l10n, start)} - ${formatTime(l10n, end)}',
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.meeting_room_outlined,
                label: l10n.sessionRoomLabel,
                value: group.room.isEmpty ? l10n.sessionNoRoom : group.room,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.prepareFailure != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              state.prepareFailure!.message,
              style: const TextStyle(color: AppColors.onErrorContainer),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          label: state.prepareFailure == null
              ? l10n.sessionScanStudent
              : l10n.retry,
          icon: Icons.qr_code_scanner,
          isLoading: state.preparing,
          onPressed: canScan
              ? () => context.read<SessionDetailsCubit>().prepareScan()
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SummaryCard(state: state, data: data),
        if (data.lastScans.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LastScansSection(entries: data.lastScans),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.sessionAttendanceListButton,
          variant: AppButtonVariant.secondary,
          icon: Icons.fact_check_outlined,
          onPressed: () => context.push(
            '/${AssistantRouteNames.sessions}/${session.id}/attendance',
          ),
        ),
      ],
    );
  }
}

/// كارت ملخص الحضور المدموج: "X حضر من N" + "Y بانتظار المزامنة" +
/// "Z لم يحضروا بعد". فشل القراءة بيظهر هنا مع زر إعادة، مش بيسقط الشاشة.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.data});

  final SessionDetailsState state;
  final SessionDetailsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = state.summaryFailure;
    final summary = data.summary;

    if (failure != null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                failure.message,
                style: const TextStyle(color: AppColors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => context.read<SessionDetailsCubit>().load(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (summary == null) {
      return const AppCard(
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            icon: Icons.fact_check_outlined,
            label: l10n.assistantNavAttendance,
            value: l10n.sessionAttendanceSummary(
              summary.attendedCount,
              summary.totalStudents,
            ),
          ),
          if (summary.waitingCount + summary.failedCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.cloud_upload_outlined,
              label: l10n.assistantNavSync,
              value: l10n.sessionAttendanceWaiting(
                summary.waitingCount + summary.failedCount,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.person_off_outlined,
            label: l10n.sessionAttendanceNotYetLabel,
            value: l10n.sessionAttendanceNotYet(
              summary.notYetAttendedCount,
            ),
          ),
        ],
      ),
    );
  }
}

/// "آخر عمليات المسح": أحدث 5 سطور من القايمة المدموجة.
class _LastScansSection extends StatelessWidget {
  const _LastScansSection({required this.entries});

  final List<AttendanceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sessionLastScansTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: AppSpacing.md),
                _LastScanRow(entry: entries[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LastScanRow extends StatelessWidget {
  const _LastScanRow({required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final student = entry.student;
    final scannedAt = entry.scannedAt;

    final (statusLabel, statusTone) = switch (entry.status) {
      AttendanceStatus.present => (
        l10n.attendanceStatusPresent,
        StatusTone.success,
      ),
      _ => (l10n.attendanceStatusLate, StatusTone.warning),
    };
    final (syncLabel, syncTone) = switch (entry.syncState) {
      AttendanceSyncState.synced => (
        l10n.attendanceSyncSynced,
        StatusTone.neutral,
      ),
      AttendanceSyncState.waiting => (
        l10n.attendanceSyncWaiting,
        StatusTone.info,
      ),
      AttendanceSyncState.failed => (
        l10n.attendanceSyncFailed,
        StatusTone.error,
      ),
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student?.fullName ?? l10n.attendanceUnknownStudent,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (scannedAt != null)
                Text(
                  formatTime(l10n, toCairoWallTime(scannedAt)),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        StatusBadge(label: statusLabel, tone: statusTone),
        const SizedBox(width: AppSpacing.sm),
        // [P1-خطوة4] حالة السداد لحظة التسجيل جنب علامة الحضور.
        PaymentStatusBadge(status: entry.paymentStatus),
        const SizedBox(width: AppSpacing.sm),
        StatusBadge(label: syncLabel, tone: syncTone),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
