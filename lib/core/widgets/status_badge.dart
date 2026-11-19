import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StatusTone { success, warning, error, info, neutral }

/// شارة حالة صغيرة (حاضر / متأخر / ملغى / بانتظار...). النص من الـ caller (arb).
/// اللون لوحده مش كفاية للمعنى، فالنص (واختياريًا الأيقونة) دايمًا ظاهر.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  (Color background, Color foreground) get _colors => switch (tone) {
        StatusTone.success => (
            AppColors.successContainer,
            AppColors.onSuccessContainer,
          ),
        StatusTone.warning => (
            AppColors.warningContainer,
            AppColors.onWarningContainer,
          ),
        StatusTone.error => (
            AppColors.errorContainer,
            AppColors.onErrorContainer,
          ),
        StatusTone.info => (
            AppColors.primaryContainer,
            AppColors.onPrimaryContainer,
          ),
        StatusTone.neutral => (
            AppColors.neutralContainer,
            AppColors.onNeutralContainer,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
