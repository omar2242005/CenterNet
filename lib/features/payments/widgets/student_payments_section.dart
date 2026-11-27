import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';
import '../../students/models/student.dart';
import '../cubit/student_payments_cubit.dart';
import '../models/payment.dart';
import '../repositories/payments_repository.dart';
import 'cancel_payment_dialog.dart';
import 'record_payment_sheet.dart';

/// قسم "حساب الرسوم" في ملف الطالب (أدمن): سجل السداد + تسجيل/إلغاء دفعة.
class StudentPaymentsSection extends StatelessWidget {
  const StudentPaymentsSection({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentPaymentsCubit(
        sl<PaymentsRepository>(),
        sl<GroupsRepository>(),
        student,
      )..load(),
      child: const _SectionView(),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView();

  Future<void> _record(BuildContext context) async {
    final cubit = context.read<StudentPaymentsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const RecordPaymentSheet()),
    );
  }

  Future<void> _cancel(BuildContext context, Payment payment) async {
    final cubit = context.read<StudentPaymentsCubit>();
    final reason = await showCancelPaymentDialog(context);
    if (reason == null) return;
    await cubit.cancel(payment, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<StudentPaymentsCubit, StudentPaymentsState>(
      listenWhen: (a, b) => b.failure != null && b.failure != a.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.failure!.message)));
      },
      builder: (context, state) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.paymentsSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (state.payments.isEmpty)
                  Text(
                    l10n.paymentsEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  for (final p in state.payments)
                    _PaymentRow(
                      payment: p,
                      groupName: _groupName(state.groups, p.groupId),
                      onCancel: state.busy || !p.isPaid
                          ? null
                          : () => _cancel(context, p),
                    ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.paymentsRecord,
                  icon: Icons.payments_outlined,
                  onPressed: state.busy || state.groups.isEmpty
                      ? null
                      : () => _record(context),
                ),
                if (state.groups.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.paymentsNoGroups,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  static String _groupName(List<Group> groups, String groupId) {
    for (final g in groups) {
      if (g.id == groupId) return g.name;
    }
    return groupId;
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.groupName,
    this.onCancel,
  });

  final Payment payment;
  final String groupName;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final year = int.parse(payment.month.substring(0, 4));
    final month = int.parse(payment.month.substring(4, 6));
    final monthLabel = '${l10n.monthName('m$month')} $year';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$groupName · $monthLabel',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(l10n, payment.amount.round()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!payment.isPaid && payment.cancelReason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.paymentsCancelledReason(payment.cancelReason!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label: payment.isPaid
                    ? l10n.paymentsStatusPaid
                    : l10n.paymentsStatusCancelled,
                tone: payment.isPaid ? StatusTone.success : StatusTone.error,
              ),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  child: Text(l10n.paymentsCancelAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
