import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validation_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_route_names.dart';
import '../cubit/auth_form_cubit.dart';
import '../repository/auth_repository.dart';
import 'auth_page.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(sl<AuthRepository>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthFormCubit>().resetPassword(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AuthFormCubit, AuthFormState>(
      builder: (context, state) {
        final sent = state.status == AuthFormStatus.success;
        return AuthPage(
          title: l10n.authForgotTitle,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.authForgotBody),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _email,
                  label: l10n.authEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  isLtr: true,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      Validators.email(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.status == AuthFormStatus.failure &&
                    state.failure != null)
                  AuthErrorText(state.failure!.message),
                if (sent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      l10n.authResetSent,
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ),
                AppButton(
                  label: l10n.authForgotSend,
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                AppButton(
                  label: l10n.authBackToLogin,
                  variant: AppButtonVariant.text,
                  onPressed: () => context.go(AuthRoutes.login),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
