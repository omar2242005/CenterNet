import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/scan_cubit.dart';
import '../models/scan_setup.dart';
import '../services/pending_scan_store.dart';
import '../services/scan_recorder.dart';
import '../../attendance/widgets/payment_status_badge.dart';
import '../widgets/scan_camera.dart';
import '../../../core/widgets/app_page.dart';

/// شاشة المسح بالكاميرا (نموذج أولي).
///
/// [setup] = null → بيانات تجريبية والمسحات في الذاكرة بس. مع [setup] حقيقي
/// المسحات بتتكتب في القائمة المحلية ([PendingScanStore]).
class ScanScreen extends StatelessWidget {
  const ScanScreen({
    super.key,
    this.setup,
    this.recorder,
    this.cameraBuilder,
    this.showManualEntry = kDebugMode,
  });

  final ScanSetup? setup;

  /// للاختبار بس. الافتراضي بيتحدد من [setup].
  final ScanRecorder? recorder;

  /// للاختبار بس. الافتراضي هو الكاميرا الحقيقية.
  final ScanCameraBuilder? cameraBuilder;

  /// إدخال نص الـ QR بإيديك (للتجربة على المحاكي من غير كاميرا).
  final bool showManualEntry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final s = setup ?? ScanSetup.demo();
        final r = recorder ??
            (s.isDemo
                ? MemoryScanRecorder()
                : StoreScanRecorder(sl<PendingScanStore>()));
        return ScanCubit(setup: s, recorder: r)..load();
      },
      child: _ScanView(
        cameraBuilder:
            cameraBuilder ?? (context, onCode) => ScanCamera(onCode: onCode),
        showManualEntry: showManualEntry,
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView({required this.cameraBuilder, required this.showManualEntry});

  final ScanCameraBuilder cameraBuilder;
  final bool showManualEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ScanCubit>();

    return AppPage(title: l10n.scanTitle, body: BlocListener<ScanCubit, ScanState>(
          listenWhen: (previous, current) =>
              current.feedback != null &&
              current.feedback?.seq != previous.feedback?.seq,
          listener: (context, state) {
            // اهتزاز خفيف للنجاح، وأقوى للتنبيه أو الرفض.
            final ok = state.feedback!.kind == ScanFeedbackKind.recordedPresent;
            if (ok) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.heavyImpact();
            }
          },
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipRect(child: cameraBuilder(context, cubit.onCode)),
              ),
              Expanded(
                flex: 2,
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    if (cubit.setup.isDemo) ...[
                      Text(
                        l10n.scanDemoBanner,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const _ResultPanel(),
                    const SizedBox(height: AppSpacing.md),
                    const _Counters(),
                    if (showManualEntry) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ManualEntry(setup: cubit.setup, onSubmit: cubit.onCode),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

/// لون وأيقونة ونص الرد. النص بيوصل المعنى والشكل بيأكده (مش اللون لوحده).
({String message, Color background, Color foreground, IconData icon})
    _present(AppLocalizations l10n, ScanFeedback f) {
  final sid = f.studentId ?? '';
  return switch (f.kind) {
    ScanFeedbackKind.recordedPresent => (
        message: l10n.scanRecordedPresent(sid),
        background: AppColors.successContainer,
        foreground: AppColors.onSuccessContainer,
        icon: Icons.check_circle_outline,
      ),
    ScanFeedbackKind.recordedLate => (
        message: l10n.scanRecordedLate(sid),
        background: AppColors.warningContainer,
        foreground: AppColors.onWarningContainer,
        icon: Icons.schedule,
      ),
    ScanFeedbackKind.alreadyRegistered => (
        message: l10n.scanAlreadyRegistered(sid),
        background: AppColors.primaryContainer,
        foreground: AppColors.onPrimaryContainer,
        icon: Icons.info_outline,
      ),
    ScanFeedbackKind.voidedBefore => (
        message: l10n.scanVoidedBefore(sid),
        background: AppColors.warningContainer,
        foreground: AppColors.onWarningContainer,
        icon: Icons.report_gmailerrorred_outlined,
      ),
    ScanFeedbackKind.notRegistered => (
        message: l10n.scanNotRegistered(sid),
        background: AppColors.warningContainer,
        foreground: AppColors.onWarningContainer,
        icon: Icons.person_off_outlined,
      ),
    ScanFeedbackKind.otherCenter => (
        message: l10n.scanOtherCenter,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        icon: Icons.block,
      ),
    ScanFeedbackKind.invalidCode => (
        message: l10n.scanInvalidCode,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        icon: Icons.qr_code_2,
      ),
    ScanFeedbackKind.storageError => (
        message: l10n.scanStorageError,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        icon: Icons.error_outline,
      ),
  };
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ScanCubit>().state;

    final ({String message, Color background, Color foreground, IconData icon})
        view;
    if (state.loadFailed) {
      view = (
        message: l10n.scanLocalListCorrupt,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        icon: Icons.error_outline,
      );
    } else if (state.feedback == null) {
      view = (
        message: l10n.scanWaiting,
        background: AppColors.neutralContainer,
        foreground: AppColors.onNeutralContainer,
        icon: Icons.qr_code_scanner,
      );
    } else {
      view = _present(l10n, state.feedback!);
    }

    // علامة السداد بتظهر مع المسحات المتسجلة (مش مع الرفض أو الأخطاء).
    final kind = state.feedback?.kind;
    final showPaymentBadge =
        kind == ScanFeedbackKind.recordedPresent ||
        kind == ScanFeedbackKind.recordedLate ||
        kind == ScanFeedbackKind.alreadyRegistered;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: view.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            children: [
              Icon(view.icon, color: view.foreground, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      view.message,
                      style: TextStyle(
                        color: view.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // [P1-خطوة4] علامة السداد جنب نتيجة المسحة الناجحة.
                    if (showPaymentBadge) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PaymentStatusBadge(status: state.feedback!.paymentStatus),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counters extends StatelessWidget {
  const _Counters();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ScanCubit>().state;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        StatusBadge(
          label: l10n.scanCountPresent(state.presentCount),
          tone: StatusTone.success,
        ),
        StatusBadge(
          label: l10n.scanCountLate(state.lateCount),
          tone: StatusTone.warning,
        ),
        StatusBadge(
          label: l10n.scanCountRejected(state.rejectedCount),
          tone: StatusTone.error,
        ),
        StatusBadge(
          label: l10n.scanPendingCount(state.pendingCount),
          tone: StatusTone.info,
        ),
      ],
    );
  }
}

class _ManualEntry extends StatefulWidget {
  const _ManualEntry({required this.setup, required this.onSubmit});

  final ScanSetup setup;
  final ValueChanged<String> onSubmit;

  @override
  State<_ManualEntry> createState() => _ManualEntryState();
}

class _ManualEntryState extends State<_ManualEntry> {
  final TextEditingController _text = TextEditingController();

  void _submit() {
    final raw = _text.text;
    if (raw.isEmpty) return;
    widget.onSubmit(raw);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.scanManualTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _text,
          // نص الـ QR ASCII دايمًا (centerId:studentId).
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(hintText: l10n.scanManualHint),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.scanManualSubmit,
          variant: AppButtonVariant.secondary,
          onPressed: _submit,
        ),
        if (widget.setup.isDemo) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final sid in ScanSetup.demoStudentIds)
                ActionChip(
                  label: Text('${ScanSetup.demoCenterId}:$sid'),
                  onPressed: () => widget.onSubmit('${ScanSetup.demoCenterId}:$sid'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
