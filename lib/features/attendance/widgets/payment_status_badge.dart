import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance.dart';

/// [P1-خطوة4] علامة السداد لحظة المسح: مدفوع / غير مدفوع / غير معروف
/// (أوفلاين أو علامة قديمة). بتظهر في رد المسح وفي سطر الحضور جنب
/// علامة (حاضر/متأخر). من غير مبالغ ولا تفاصيل — الحالة بس.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final ScanPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone, icon) = switch (status) {
      ScanPaymentStatus.paid => (
        l10n.paymentsFilterPaid,
        StatusTone.success,
        Icons.check_circle_outline,
      ),
      ScanPaymentStatus.unpaid => (
        l10n.paymentsFilterUnpaid,
        StatusTone.error,
        Icons.payments_outlined,
      ),
      ScanPaymentStatus.unknown => (
        l10n.paymentsStatusUnknown,
        StatusTone.neutral,
        Icons.help_outline,
      ),
    };
    return StatusBadge(label: label, tone: tone, icon: icon);
  }
}
