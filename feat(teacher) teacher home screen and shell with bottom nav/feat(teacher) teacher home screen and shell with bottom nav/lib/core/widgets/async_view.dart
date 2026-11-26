import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../state/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// صندوق الحالات الأربع لأي شاشة بيانات: تحميل · فارغ · خطأ مع إعادة محاولة · نجاح.
///
/// ```dart
/// AsyncView<List<Student>>(
///   state: state,
///   onRetry: cubit.load,
///   emptyMessage: l10n.noStudents,
///   builder: (context, students) => StudentsList(students),
/// )
/// ```
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
  });

  final ViewState<T> state;

  /// بيتبني في حالة النجاح بس.
  final Widget Function(BuildContext context, T data) builder;

  /// لو موجود بيظهر زر "إعادة المحاولة" في حالة الخطأ.
  final VoidCallback? onRetry;

  /// رسالة الحالة الفاضية (من arb). الافتراضي رسالة عامة.
  final String? emptyMessage;
  final IconData emptyIcon;

  /// زر اختياري تحت الرسالة الفاضية (مثلًا "إضافة طالب").
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (state) {
      ViewLoading() => Center(
          child: Semantics(
            label: l10n.loading,
            child: const CircularProgressIndicator(),
          ),
        ),
      ViewEmpty() => _MessageView(
          icon: emptyIcon,
          message: emptyMessage ?? l10n.emptyDefault,
          action: emptyAction,
        ),
      ViewFailed(:final failure) => _MessageView(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          message: failure.message,
          action: onRetry == null
              ? null
              : AppButton(
                  label: l10n.retry,
                  icon: Icons.refresh,
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: onRetry,
                ),
        ),
      ViewSuccess(:final data) => builder(context, data),
    };
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    this.iconColor = AppColors.textSecondary,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
