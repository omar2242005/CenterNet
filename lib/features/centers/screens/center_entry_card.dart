import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../centers_route_names.dart';
import '../cubit/my_center_cubit.dart';
import '../models/center_info.dart';
import '../models/center_member.dart';
import '../repository/centers_repository.dart';

extension MemberRoleText on MemberRole {
  String label(AppLocalizations l10n) => switch (this) {
    MemberRole.admin => l10n.centersRoleAdmin,
    MemberRole.teacher => l10n.centersRoleTeacher,
    MemberRole.assistant => l10n.centersRoleAssistant,
  };
}

/// كارت مؤقت في الشاشة الرئيسية بعد الدخول: بيبيّن سنتر المستخدم، أو زر
/// "إنشاء مركز" لو مالوش سنتر، وزر الإعدادات للأدمن.
/// خطوة 3.5 (التوجيه حسب الدور) هتستبدل الشاشة دي بشاشات الأدوار.
class CenterEntryCard extends StatelessWidget {
  const CenterEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyCenterCubit(sl<CentersRepository>())..load(),
      child: const _CenterEntryView(),
    );
  }
}

class _CenterEntryView extends StatelessWidget {
  const _CenterEntryView();

  Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<MyCenterCubit>();
    await context.push(route);
    // رجعنا من شاشة ممكن تكون غيّرت حاجة (إنشاء أو إعدادات).
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<MyCenterCubit, ViewState<CenterContext>>(
      builder: (context, state) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.centersEntryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              switch (state) {
                ViewLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  ),
                ),
                ViewFailed(:final failure) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      failure.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: l10n.retry,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.read<MyCenterCubit>().load(),
                    ),
                  ],
                ),
                ViewEmpty() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.centersNoCenter),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: l10n.centersCreateCta,
                      onPressed: () => _open(context, CentersRoutes.create),
                    ),
                  ],
                ),
                ViewSuccess(:final data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      data.center.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      l10n.centersRoleLine(data.membership.role.label(l10n)),
                    ),
                    if (data.membership.isAdmin) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.centersOpenSettings,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _open(context, CentersRoutes.settings),
                      ),
                    ],
                  ],
                ),
              },
            ],
          ),
        );
      },
    );
  }
}
