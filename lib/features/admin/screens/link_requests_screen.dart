import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../linking/cubit/link_requests_admin_cubit.dart';
import '../../linking/models/link_request.dart';
import '../../linking/models/student_link.dart';
import '../../linking/repository/linking_repository.dart';
import '../../../core/widgets/app_page.dart';

/// (أدمن) طلبات الربط المعلّقة: موافقة (بيتولّد كود ربط) أو رفض.
class LinkRequestsScreen extends StatelessWidget {
  const LinkRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => LinkRequestsAdminCubit(sl<LinkingRepository>())..load(),
      child: AppPage(
        title: l10n.linkRequestsTitle,
        body: BlocConsumer<LinkRequestsAdminCubit, LinkRequestsState>(
          listenWhen: (a, b) => b.failure != null && b.failure != a.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.failure!.message)));
          },
          builder: (context, state) {
            final cubit = context.read<LinkRequestsAdminCubit>();
            return AsyncView<List<LinkRequest>>(
              state: state.view,
              onRetry: cubit.load,
              emptyMessage: l10n.linkRequestsEmpty,
              emptyIcon: Icons.link,
              builder: (context, items) => ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  for (final r in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RequestCard(
                        request: r,
                        busy: state.busy,
                        onApprove: () => cubit.approve(r),
                        onReject: () => cubit.reject(r),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final LinkRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isGuardian = request.kind == LinkKind.guardian;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.name, style: theme.textTheme.titleMedium),
          Text(
            isGuardian ? l10n.accountTypeGuardian : l10n.accountTypeStudent,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            l10n.studentNumber(request.studentNo),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (isGuardian && (request.relation ?? '').isNotEmpty)
            Text(
              l10n.linkRequestRelation(request.relation!),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.linkRequestApprove,
                  isLoading: busy,
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l10n.linkRequestReject,
                  variant: AppButtonVariant.secondary,
                  onPressed: busy ? null : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
