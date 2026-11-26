import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

/// الزر الوحيد في التطبيق. الارتفاع 48dp على الأقل، وفيه حالة تحميل.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;

  /// `null` = الزر معطّل.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// بيظهر مؤشر تحميل، والضغط بيتتجاهل (من غير ما شكل الزر يتغير).
  final bool isLoading;

  /// ياخد العرض كله (الافتراضي). false = على قد المحتوى.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // أثناء التحميل بنبقي الزر شكله مفعّل بس مش بيعمل حاجة.
    final VoidCallback? handler =
        onPressed == null ? null : (isLoading ? () {} : onPressed);

    final filled =
        variant == AppButtonVariant.primary ||
        variant == AppButtonVariant.destructive;
    final spinnerColor = filled ? Colors.white : AppColors.primary;

    final Widget leading = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: spinnerColor,
            ),
          )
        : (icon == null ? const SizedBox.shrink() : Icon(icon, size: 20));

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading || icon != null) ...[
          leading,
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: handler,
          child: content,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: handler,
          child: content,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: handler,
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
