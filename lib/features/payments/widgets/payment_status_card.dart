import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/payments_cubit.dart';

/// كارت (طالب × مجموعة) في شاشة المدفوعات: الاسم والمجموعة والمبلغ وحالة
/// السداد (وتاريخ الدفع لو مدفوع). اللمسة بتسجّل (غير مدفوع) أو تلغي (مدفوع).
class PaymentStatusCard extends StatelessWidget {
  const PaymentStatusCard({super.key, required this.row, this.onTap});

  final PaymentRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final paid = row.isPaid;
    final recordedAt = row.payment?.recordedAt;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.student.fullName, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  row.group.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(l10n, row.amountPiasters),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (paid && recordedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.paymentsPaidOn(formatDate(l10n, recordedAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: paid ? l10n.paymentsFilterPaid : l10n.paymentsFilterUnpaid,
            tone: paid ? StatusTone.success : StatusTone.error,
          ),
        ],
      ),
    );
  }
}
