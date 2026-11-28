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
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../services/cairo_time.dart';
import '../widgets/assistant_shell.dart';

/// رئيسية المساعد: تحية + حالة الاتصال + عدد حصص النهارده + كارت الحصة
/// الجارية وزر "ابدأ المسح" (تحضير للأوفلاين).
class AssistantHomeScreen extends StatelessWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => sl<AssistantHomeCubit>()..load(),
      child: AssistantShell(
        current: AssistantTab.home,
        title: l10n.assistantHomeTitle,
        body: BlocListener<AssistantHomeCubit, AssistantHomeState>(
          listenWhen: (previous, current) =>
              current.preparedSetup != null &&
              current.preparedSetup != previous.preparedSetup,
          listener: (context, state) {
            final setup = state.preparedSetup;
            if (setup == null) return;
            context.read<AssistantHomeCubit>().consumePreparedSetup();
            context.push('/${AssistantRouteNames.scan}', extra: setup);
          },
          child: BlocBuilder<AssistantHomeCubit, AssistantHomeState>(
            builder: (context, state) => AsyncView<AssistantHomeData>(
              state: state.status,
              onRetry: () => context.read<AssistantHomeCubit>().load(),
              emptyMessage: l10n.assistantNoSessionsToday,
              emptyAction: AppButton(
                label: l10n.retry,
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => context.read<AssistantHomeCubit>().load(),
              ),
              builder: (context, data) => _HomeBody(state: state, data: data),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.data});

  final AssistantHomeState state;
  final AssistantHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.assistantGreeting(data.assistantName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            StatusBadge(
              label: state.online ? l10n.assistantOnline : l10n.assistantOffline,
              tone: state.online ? StatusTone.success : StatusTone.error,
              icon: state.online ? Icons.wifi : Icons.wifi_off,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.assistantTodayCount(data.todaySessions.length),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (data.currentSession == null)
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.event_busy_outlined,
                    color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l10n.assistantNoCurrentSession)),
              ],
            ),
          )
        else
          _CurrentSessionCard(state: state, data: data),
      ],
    );
  }
}

class _CurrentSessionCard extends StatelessWidget {
  const _CurrentSessionCard({required this.state, required this.data});

  final AssistantHomeState state;
  final AssistantHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = data.currentSession!;
    final group = data.currentGroup;
    final start = toCairoWallTime(session.startAt);
    final end = toCairoWallTime(session.endAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.assistantCurrentSession,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: l10n.sessionStatusCurrent,
                tone: StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            group?.name ?? session.groupId,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatTime(l10n, start)} - ${formatTime(l10n, end)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (group != null && group.room.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.sessionRoomLabel}: ${group.room}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
                ? l10n.assistantStartScanning
                : l10n.retry,
            icon: Icons.qr_code_scanner,
            isLoading: state.preparing,
            onPressed: () => context.read<AssistantHomeCubit>().prepareScan(),
          ),
        ],
      ),
    );
  }
}
