import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';

/// ديالوج إلغاء دفعة: سبب إلزامي. بيرجّع السبب (مقصوص) أو null لو اترفض.
Future<String?> showCancelPaymentDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _CancelPaymentDialog(),
  );
}

class _CancelPaymentDialog extends StatefulWidget {
  const _CancelPaymentDialog();

  @override
  State<_CancelPaymentDialog> createState() => _CancelPaymentDialogState();
}

class _CancelPaymentDialogState extends State<_CancelPaymentDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context);
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = l10n.paymentsCancelReasonRequired);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.paymentsCancelTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _reason,
            label: l10n.paymentsCancelReasonLabel,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.paymentsBack),
        ),
        AppButton(
          label: l10n.paymentsCancelConfirm,
          variant: AppButtonVariant.destructive,
          expand: false,
          onPressed: _confirm,
        ),
      ],
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }
}
