import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/search_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/repository/groups_repository.dart';
import '../widgets/admin_shell.dart';
import '../../students/repository/students_repository.dart';
import '../../payments/cubit/payments_cubit.dart';
import '../../payments/repositories/payments_repository.dart';
import '../../payments/widgets/cancel_payment_dialog.dart';
import '../../payments/widgets/month_picker.dart';
import '../../payments/widgets/payment_status_card.dart';
import '../../payments/widgets/record_payment_sheet.dart';

/// شاشة "المدفوعات" (أدمن): لكل (طالب × مجموعة) في الشهر المختار مدفوع
/// ولا غير مدفوع، مع بحث وفلاتر، وتسجيل/إلغاء بلمسة من نفس الكارت.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentsCubit(
        sl<PaymentsRepository>(),
        sl<GroupsRepository>(),
        sl<StudentsRepository>(),
      )..load(),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  /// كارت غير مدفوع: شيت التسجيل ببيانات الطالب والمجموعة والشهر جاهزة.
  Future<void> _record(BuildContext context, PaymentRow row) async {
    final cubit = context.read<PaymentsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordPaymentSheet(
        groups: [row.group],
        initialGroupId: row.group.id,
        initialMonth: (cubit.state.year, cubit.state.month),
        onSave: ({
          required String groupId,
          required int year,
          required int month,
          required int amountPiasters,
          required String note,
        }) => cubit.record(
          studentId: row.student.id,
          groupId: groupId,
          year: year,
          month: month,
          amountPiasters: amountPiasters,
          note: note,
        ),
      ),
    );
  }

  /// كارت مدفوع: إلغاء بسبب إلزامي.
  Future<void> _cancel(BuildContext context, PaymentRow row) async {
    final payment = row.payment;
    if (payment == null) return;
    final cubit = context.read<PaymentsCubit>();
    final reason = await showCancelPaymentDialog(context);
    if (reason == null || !context.mounted) return;
    final failure = await cubit.cancel(payment, reason: reason);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminShell(
      current: AdminTab.home,
      title: l10n.paymentsScreenTitle,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchField(
                          hint: l10n.paymentsSearchHint,
                          onChanged: context.read<PaymentsCubit>().setQuery,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      BlocBuilder<PaymentsCubit, PaymentsState>(
                        buildWhen: (a, b) =>
                            a.year != b.year || a.month != b.month,
                        builder: (context, state) => MonthDropdown(
                          value: (state.year, state.month),
                          onChanged: (v) =>
                              context.read<PaymentsCubit>().setMonth(v.$1, v.$2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<PaymentsCubit, PaymentsState>(
                    buildWhen: (a, b) =>
                        a.groups != b.groups ||
                        a.groupId != b.groupId ||
                        a.filter != b.filter,
                    builder: (context, state) => Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: state.groupId,
                            decoration: InputDecoration(
                              labelText: l10n.paymentsGroupLabel,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.paymentsAllGroups),
                              ),
                              for (final g in state.groups)
                                DropdownMenuItem(
                                  value: g.id,
                                  child: Text(g.name),
                                ),
                            ],
                            onChanged: context
                                .read<PaymentsCubit>()
                                .setGroupFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<PaymentsCubit, PaymentsState>(
                    buildWhen: (a, b) => a.filter != b.filter,
                    builder: (context, state) => Row(
                      children: [
                        for (final (f, label) in [
                          (PaymentsFilter.all, l10n.paymentsFilterAll),
                          (PaymentsFilter.paid, l10n.paymentsFilterPaid),
                          (PaymentsFilter.unpaid, l10n.paymentsFilterUnpaid),
                        ]) ...[
                          ChoiceChip(
                            label: Text(label),
                            selected: state.filter == f,
                            onSelected: (_) =>
                                context.read<PaymentsCubit>().setFilter(f),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<PaymentsCubit, PaymentsState>(
                builder: (context, state) {
                  return AsyncView<List<PaymentRow>>(
                    state: state.view,
                    onRetry: context.read<PaymentsCubit>().load,
                    emptyMessage: state.rows.isEmpty
                        ? l10n.paymentsEmptyMonth
                        : l10n.paymentsNoResults,
                    emptyIcon: Icons.payments_outlined,
                    builder: (context, rows) => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return PaymentStatusCard(
                          row: row,
                          onTap: state.busy
                              ? null
                              : () => row.isPaid
                                    ? _cancel(context, row)
                                    : _record(context, row),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
