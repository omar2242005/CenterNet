import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/sync_cubit.dart';
import '../cubit/sync_state.dart';
import '../models/pending_scan.dart';
import '../../../core/widgets/app_page.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with WidgetsBindingObserver {
  late final SyncCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<SyncCubit>()..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _cubit, child: const _SyncView());
  }
}

class _SyncView extends StatelessWidget {
  const _SyncView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.syncTitle,
      safeArea: false,
      body: BlocBuilder<SyncCubit, SyncState>(
        builder: (context, state) => Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignOutWarning(text: l10n.syncSignOutWarning),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _SyncBody(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncBody extends StatelessWidget {
  const _SyncBody({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SyncCubit>();
    return switch (state.phase) {
      SyncPhase.offline => _StatePanel(
        icon: Icons.cloud_off_outlined,
        title: l10n.syncNoConnection,
        message: state.message ?? l10n.syncNoConnectionHint,
        action: FilledButton(
          onPressed: () => cubit.sync(),
          child: Text(l10n.retry),
        ),
      ),
      SyncPhase.syncing => _StatePanel(
        icon: Icons.sync,
        title: l10n.syncInProgress,
        message: l10n.syncProgress(state.completed, state.total),
        progress: state.total == 0 ? null : state.completed / state.total,
      ),
      SyncPhase.failed => _FailedPanel(state: state),
      SyncPhase.done => _StatePanel(
        icon: Icons.check_circle_outline,
        title: l10n.syncDone,
        message: l10n.syncDoneCount(state.syncedCount),
        action: OutlinedButton(
          onPressed: () => cubit.sync(),
          child: Text(l10n.retry),
        ),
      ),
      SyncPhase.ready =>
        state.records.isEmpty
            ? _StatePanel(
                icon: Icons.cloud_done_outlined,
                title: l10n.syncEmpty,
                message: '',
              )
            : _StatePanel(
                icon: Icons.cloud_upload_outlined,
                title: l10n.syncPending(state.records.length),
                message: '',
                action: FilledButton(
                  onPressed: () => cubit.sync(),
                  child: Text(l10n.syncStart),
                ),
              ),
    };
  }
}

class _FailedPanel extends StatelessWidget {
  const _FailedPanel({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            state.message ?? l10n.syncNeedsAction(state.failedCount),
            style: const TextStyle(color: AppColors.onErrorContainer),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.read<SyncCubit>().sync(retryFailed: true),
          child: Text(l10n.syncRetryFailed),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: state.failed.length,
            itemBuilder: (context, index) =>
                _FailedScanTile(scan: state.failed[index]),
          ),
        ),
      ],
    );
  }
}

class _FailedScanTile extends StatelessWidget {
  const _FailedScanTile({required this.scan});

  final PendingScan scan;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.error_outline, color: AppColors.error),
    title: Text(scan.studentId),
    subtitle: Text(scan.failReason ?? ''),
  );
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.progress,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final double? progress;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (message.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
        ],
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: progress),
        ],
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      ],
    ),
  );
}

class _SignOutWarning extends StatelessWidget {
  const _SignOutWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.warningContainer,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.onWarningContainer),
    ),
  );
}
