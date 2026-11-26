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
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../assistant_route_names.dart';
import '../cubit/sessions_cubit.dart';
import '../cubit/sessions_state.dart';
import '../models/session_time_status.dart';
import '../services/cairo_time.dart';
import '../widgets/assistant_shell.dart';

/// حصص النهارده، متعلّم عليها: جارية / قادمة / انتهت / ملغاة.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => sl<SessionsCubit>()..load(),
      child: AssistantShell(
        current: AssistantTab.sessions,
        title: l10n.assistantSessionsTitle,
        body: BlocBuilder<SessionsCubit, SessionsState>(
          builder: (context, state) => AsyncView<SessionsData>(
            state: state.status,
            onRetry: () => context.read<SessionsCubit>().load(),
            emptyMessage: l10n.assistantNoSessionsToday,
            emptyAction: AppButton(
              label: l10n.retry,
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () => context.read<SessionsCubit>().load(),
            ),
            builder: (context, data) => ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: data.sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _SessionTile(
                session: data.sessions[index],
                group: data.groups[data.sessions[index].groupId],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.group});

  final Session session;
  final Group? group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    return AppCard(
      onTap: () => context.push(
        '/${AssistantRouteNames.home}/sessions/${session.id}',
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ?? session.groupId,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatTime(l10n, start)} - ${formatTime(l10n, end)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (group != null && group!.room.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${l10n.sessionRoomLabel}: ${group!.room}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}
