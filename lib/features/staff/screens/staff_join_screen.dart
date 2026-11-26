import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/utils/link_code_generator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/screens/auth_page.dart';
import '../cubit/staff_join_cubit.dart';
import '../models/staff_join_result.dart';
import '../models/staff_role_text.dart';
import '../repository/staff_join_repository.dart';

/// شاشة إدخال كود الدعوة (للموظف): كود 8 رموز ← يبقى عضو بالدور المحدد.
class StaffJoinScreen extends StatelessWidget {
  const StaffJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffJoinCubit(sl<StaffJoinRepository>()),
      child: const _StaffJoinView(),
    );
  }
}

class _StaffJoinView extends StatefulWidget {
  const _StaffJoinView();

  @override
  State<_StaffJoinView> createState() => _StaffJoinViewState();
}

class _StaffJoinViewState extends State<_StaffJoinView> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<StaffJoinCubit>().check(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<StaffJoinCubit, StaffJoinState>(
      builder: (context, state) {
        final result = state.result;
        return AuthPage(
          title: l10n.staffJoinTitle,
          showBack: false,
          showSignOut: result == null,
          child: (state.status == StaffJoinStatus.success && result != null)
              ? _buildSuccess(context, l10n, result)
              : (state.status == StaffJoinStatus.confirm ||
                    (state.status == StaffJoinStatus.submitting &&
                        state.preview != null))
              ? _buildConfirm(context, l10n, state)
              : _buildForm(context, l10n, state),
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    StaffJoinState state,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.staffJoinIntro,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _code,
            label: l10n.staffJoinCodeLabel,
            textInputAction: TextInputAction.done,
            isLtr: true,
            latinDigits: true,
            enabled: !state.isSubmitting,
            inputFormatters: <TextInputFormatter>[
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return l10n.validationRequired;
              if (!LinkCodeGenerator.isWellFormed(toLatinDigits(value))) {
                return l10n.staffJoinCodeInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.status == StaffJoinStatus.failure && state.failure != null)
            AuthErrorText(state.failure!.message),
          AppButton(
            label: l10n.staffJoinCheckButton,
            isLoading: state.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm(
    BuildContext context,
    AppLocalizations l10n,
    StaffJoinState state,
  ) {
    final theme = Theme.of(context);
    final preview = state.preview!;
    final cubit = context.read<StaffJoinCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.staffJoinConfirmTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.staffJoinConfirmBody(preview.role.label(l10n)),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.staffJoinConfirmNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.staffJoinConfirmButton,
          isLoading: state.isSubmitting,
          onPressed: cubit.confirm,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.staffJoinChangeCode,
          variant: AppButtonVariant.secondary,
          onPressed: state.isSubmitting ? null : cubit.back,
        ),
      ],
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    AppLocalizations l10n,
    StaffJoinResult result,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.staffJoinSuccessTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.staffJoinSuccessBody(result.centerName, result.role.label(l10n)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.staffJoinContinue,
          // مؤقتًا لحد التوجيه حسب الدور (3.5).
          onPressed: () => context.go(AuthRoutes.signedIn),
        ),
      ],
    );
  }
}
