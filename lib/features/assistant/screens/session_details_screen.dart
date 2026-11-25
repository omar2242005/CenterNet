import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
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
import '../models/session_time_status.dart';
import '../repository/assistant_repository.dart';
import '../services/cairo_time.dart';
import '../widgets/assistant_shell.dart';

/// تفاصيل الحصة: المجموعة والوقت والقاعة + زر "مسح كود الطالب"
/// (تحضير للأوفلاين). ملخص الحضور وقائمته placeholders للجزء الرابع.
class SessionDetailsScreen extends StatelessWidget {
  const SessionDetailsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => SessionDetailsCubit(
        sl<AssistantRepository>(),
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
        // الجزء الرابع: ملخص الحضور + قائمة الحضور.
        AppCard(
          child: Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.sessionAttendanceSummarySoon,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.sessionAttendanceListSoon,
          variant: AppButtonVariant.secondary,
          onPressed: null,
        ),
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
