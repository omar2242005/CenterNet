import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(sl<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthFormCubit>().login(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        if (state.status == AuthFormStatus.success) {
          context.go(
            state.emailVerified == true
                ? AuthRoutes.signedIn
                : AuthRoutes.verifyEmail,
          );
        }
      },
      builder: (context, state) {
        return AuthPage(
          title: l10n.authLoginTitle,
          showBack: false,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _email,
                  label: l10n.authEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  isLtr: true,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      Validators.email(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _password,
                  label: l10n.authPassword,
                  obscureText: true,
                  isLtr: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  enabled: !state.isSubmitting,
                  // في الدخول بنتأكد إنها مش فاضية بس، والسيرفر هو الحكم.
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.validationRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.status == AuthFormStatus.failure &&
                    state.failure != null)
                  AuthErrorText(state.failure!.message),
                AppButton(
                  label: l10n.authLoginButton,
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.authForgotPassword,
                  variant: AppButtonVariant.text,
                  onPressed: () => context.push(AuthRoutes.forgotPassword),
                ),
                AppButton(
                  label: l10n.authCreateAccount,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AuthRoutes.register),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
