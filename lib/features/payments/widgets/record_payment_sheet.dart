import 'package:flutter/material.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/models/group.dart';
import 'month_picker.dart';

/// نتيجة محاولة الحفظ: null = نجحت، وغير كده الفشل اللي بيظهر في الشيت.
typedef SavePayment =
    Future<Failure?> Function({
      required String groupId,
      required int year,
      required int month,
      required int amountPiasters,
      required String note,
    });

/// فورم تسجيل دفعة (bottom sheet): المجموعة والشهر والمبلغ وملاحظة.
/// المبلغ بيتملّى من `monthlyFee` بتاع المجموعة المختارة ويفضل قابل للتعديل.
///
/// الشيت مش مربوط بـ cubit معيّن: بياخد [groups] و[onSave]، فبتتستخدم من
/// قسم "حساب الرسوم" في ملف الطالب ومن شاشة المدفوعات (بلمسة واحدة على
/// طالب غير مدفوع، مع [initialGroupId] و[initialMonth] جاهزين).
class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.groups,
    required this.onSave,
    this.initialGroupId,
    this.initialMonth,
  });

  /// المجموعات المتاحة للاختيار (مثلًا مجموعات الطالب، أو كل المجموعات).
  final List<Group> groups;

  /// بيستدعى عند الحفظ. null = نجح والشيت بيقفل.
  final SavePayment onSave;

  /// مجموعة مختارة مسبقًا (لو null ومجموعة واحدة بس بتتختار لوحدها).
  final String? initialGroupId;

  /// (السنة، الشهر) المختارين مسبقًا. الافتراضي الشهر الحالي.
  final (int, int)? initialMonth;

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String? _groupId;
  late int _year;
  late int _month;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth;
    if (initial != null) {
      _year = initial.$1;
      _month = initial.$2;
    } else {
      final now = DateTime.now();
      _year = now.year;
      _month = now.month;
    }
    final initialGroup = widget.initialGroupId;
    if (initialGroup != null &&
        widget.groups.any((g) => g.id == initialGroup)) {
      _groupId = initialGroup;
    } else if (widget.groups.length == 1) {
      _groupId = widget.groups.single.id;
    }
    _prefillAmount();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _prefillAmount() {
    for (final g in widget.groups) {
      if (g.id == _groupId) {
        _amount.text = g.monthlyFee > 0
            ? piastersToDecimalString(g.monthlyFee)
            : '';
        return;
      }
    }
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
    setState(() {
      _saving = true;
      _error = null;
    });
    final Failure? failure = await widget.onSave(
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
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
              for (final g in widget.groups)
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
          MonthDropdown(
            value: (_year, _month),
            label: l10n.paymentsMonthLabel,
            onChanged: (value) {
              setState(() {
                _year = value.$1;
                _month = value.$2;
              });
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
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
