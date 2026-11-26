import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../assistant/services/cairo_time.dart';
import '../../groups/models/group.dart';
import '../cubit/group_sessions_cubit.dart';
import '../models/session.dart';
import '../repository/sessions_repository.dart';

/// حصص مجموعة من النهارده: عرض بالترتيب، توليد الأسابيع الجاية، وإلغاء.
class GroupSessionsScreen extends StatelessWidget {
  const GroupSessionsScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupSessionsCubit(sl<SessionsRepository>(), group)..load(),
      child: _GroupSessionsView(group: group),
    );
  }
}

class _GroupSessionsView extends StatelessWidget {
  const _GroupSessionsView({required this.group});

  final Group group;

  Future<void> _generate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<GroupSessionsCubit>().generate();
    final failure = outcome.failure;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else if (outcome.result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.sessionsGenerateResult(
              outcome.result!.created,
              outcome.result!.skipped,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _cancel(BuildContext context, Session session) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<GroupSessionsCubit>();
    final start = toCairoWallTime(session.startAt);
    final ok = await showConfirmDialog(
      context,
      title: l10n.sessionCancelTitle,
      message: l10n.sessionCancelMessage(formatDate(l10n, start)),
      confirmLabel: l10n.sessionCancelConfirm,
      destructive: true,
    );
    if (!ok) return;
    final failure = await cubit.cancel(session);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GroupSessionsCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BlocBuilder<GroupSessionsCubit, GroupSessionsState>(
                buildWhen: (a, b) => a.generating != b.generating,
                builder: (context, state) => SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: state.generating ? null : () => _generate(context),
                    icon: state.generating
                        ? const SizedBox(
                            width: AppSpacing.md,
                            height: AppSpacing.md,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(l10n.sessionsGenerateButton),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<GroupSessionsCubit, GroupSessionsState>(
                builder: (context, state) {
                  return AsyncView<List<Session>>(
                    state: state.view,
                    onRetry: cubit.load,
                    emptyMessage: l10n.sessionsEmpty,
                    emptyIcon: Icons.event_busy_outlined,
                    builder: (context, sessions) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _SessionTile(
                        session: sessions[index],
                        busy: state.cancellingId != null,
                        cancelling: state.cancellingId == sessions[index].id,
                        onCancel: () => _cancel(context, sessions[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.busy,
    required this.cancelling,
    required this.onCancel,
  });

  final Session session;

  /// إلغاء تاني شغال: كل الأزرار متعطلة.
  final bool busy;

  /// الإلغاء شغال على الحصة دي بالذات.
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final start = toCairoWallTime(session.startAt);
    final end = toCairoWallTime(session.endAt);

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.weekdayName('d${start.weekday}')} '
                  '${formatDate(l10n, start)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatTime(l10n, start)} - ${formatTime(l10n, end)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: session.isCancelled
                ? l10n.sessionCancelledBadge
                : l10n.sessionScheduledBadge,
            tone: session.isCancelled ? StatusTone.error : StatusTone.info,
          ),
          if (!session.isCancelled)
            cancelling
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.sessionCancelAction,
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: busy ? null : onCancel,
                  ),
        ],
      ),
    );
  }
}
