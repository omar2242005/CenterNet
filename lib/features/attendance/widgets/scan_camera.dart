import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// بيبني الكاميرا ويبعت لـ [onCode] نص كل QR بيتقري.
/// الشاشة بتاخده كـ parameter عشان الاختبارات تستبدل الكاميرا بحاجة وهمية.
typedef ScanCameraBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onCode,
);

/// الكاميرا الحقيقية (mobile_scanner): QR بس، مع فلاش وتبديل كاميرا.
/// إيقاف/تشغيل الكاميرا مع خروج التطبيق ورجوعه بتتولاه المكتبة نفسها.
class ScanCamera extends StatefulWidget {
  const ScanCamera({super.key, required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<ScanCamera> createState() => _ScanCameraState();
}

class _ScanCameraState extends State<ScanCamera> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        widget.onCode(raw);
        return;
      }
    }
  }

  /// فلاش/تبديل الكاميرا مش لازم يوقعوا الشاشة لو الجهاز مش بيدعمهم.
  void _safe(Future<void> Function() action) {
    unawaited(action().catchError((Object _) {}));
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _CameraError(error: error),
        ),
        const IgnorePointer(child: _ScanFrame()),
        PositionedDirectional(
          top: AppSpacing.sm,
          end: AppSpacing.sm,
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.torchState != TorchState.unavailable)
                    IconButton.filledTonal(
                      tooltip: l10n.scanTorch,
                      onPressed: () => _safe(_controller.toggleTorch),
                      icon: Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                      ),
                    ),
                  IconButton.filledTonal(
                    tooltip: l10n.scanSwitchCamera,
                    onPressed: () => _safe(_controller.switchCamera),
                    icon: const Icon(Icons.cameraswitch_outlined),
                  ),
                ],
              );
            },
          ),
        ),
        PositionedDirectional(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.scanHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.surface),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// إطار التوجيه في نص الكاميرا (للشكل بس، مش بيحدد منطقة المسح).
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surface, width: 3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

/// رسالة عربية واضحة بدل شاشة سودا لو الكاميرا مش شغالة.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => l10n.scanPermissionDenied,
      MobileScannerErrorCode.unsupported => l10n.scanCameraUnsupported,
      _ => l10n.scanCameraError,
    };
    return ColoredBox(
      color: AppColors.neutralContainer,
      child: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: AppColors.onNeutralContainer,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onNeutralContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
