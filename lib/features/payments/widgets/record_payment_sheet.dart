import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/student_payments_cubit.dart';

/// فورم تسجيل دفعة (bottom sheet): المجموعة والشهر والمبلغ وملاحظة.
/// المبلغ بيتملّى من `monthlyFee` بتاع المجموعة المختارة ويفضل قابل للتعديل.
class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({super.key});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String? _groupId;
  late int _year;
  late int _month;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    final groups = context.read<StudentPaymentsCubit>().state.groups;
    if (groups.length == 1) {
      _groupId = groups.single.id;
      _prefillAmount();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _prefillAmount() {
    final groups = context.read<StudentPaymentsCubit>().state.groups;
    for (final g in groups) {
      if (g.id == _groupId) {
        _amount.text = g.monthlyFee > 0
            ? piastersToDecimalString(g.monthlyFee)
            : '';
        return;
      }
    }
  }

  /// الشهر الحالي و11 شهر قبله.
  List<(int, int)> _monthChoices() {
    final out = <(int, int)>[];
    var y = DateTime.now().year;
    var m = DateTime.now().month;
    for (var i = 0; i < 12; i++) {
      out.add((y, m));
      m--;
      if (m == 0) {
        m = 12;
        y--;
      }
    }
    return out;
  }

  int? _parseAmount() {
    final text = toLatinDigits(_amount.text).trim();
    if (text.isEmpty) return null;
    final pounds = double.tryParse(text);
    if (pounds == null || pounds <= 0) return null;
    return (pounds * 100).round();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final groupId = _groupId;
    final amount = _parseAmount();
    if (groupId == null || amount == null) {
      setState(() => _error = l10n.paymentsInvalidAmount);
      return;
    }
    final Failure? failure = await context.read<StudentPaymentsCubit>().record(
      groupId: groupId,
      year: _year,
      month: _month,
      amountPiasters: amount,
      note: _note.text,
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = context.watch<StudentPaymentsCubit>().state;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentsRecord, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _groupId,
            decoration: InputDecoration(labelText: l10n.paymentsGroupLabel),
            items: [
              for (final g in state.groups)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
            ],
            onChanged: (value) {
              setState(() {
                _groupId = value;
                _prefillAmount();
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<(int, int)>(
            initialValue: (_year, _month),
            decoration: InputDecoration(labelText: l10n.paymentsMonthLabel),
            items: [
              for (final (y, m) in _monthChoices())
                DropdownMenuItem(
                  value: (y, m),
                  child: Text('${l10n.monthName('m$m')} $y'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _year = value.$1;
                  _month = value.$2;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _amount,
            label: l10n.paymentsAmountLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: _note, label: l10n.paymentsNoteLabel),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.paymentsSave,
            isLoading: state.busy,
            onPressed: state.busy ? null : _save,
          ),
        ],
      ),
    );
  }
}
