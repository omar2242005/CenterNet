import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_route_names.dart';
import '../cubit/auth_form_cubit.dart';
import '../repository/auth_repository.dart';
import 'auth_page.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(sl<AuthRepository>()),
      child: const _VerifyEmailView(),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  const _VerifyEmailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = sl<AuthRepository>();
    final email = repo.currentUser?.email ?? '';

    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        if (state.action == AuthFormAction.checkVerified &&
            state.status == AuthFormStatus.success &&
            state.emailVerified == true) {
          context.go(AuthRoutes.signedIn);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthFormCubit>();
        final notVerifiedYet = state.action == AuthFormAction.checkVerified &&
            state.status == AuthFormStatus.success &&
            state.emailVerified != true;
        final resent = state.action == AuthFormAction.resendVerification &&
            state.status == AuthFormStatus.success;

        return AuthPage(
          title: l10n.authVerifyTitle,
          showBack: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.authVerifyBody(email)),
              const SizedBox(height: AppSpacing.md),
              if (state.status == AuthFormStatus.failure &&
                  state.failure != null)
                AuthErrorText(state.failure!.message),
              if (notVerifiedYet) AuthErrorText(l10n.authVerifyNotYet),
              if (resent)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.authVerifySent,
                    style: const TextStyle(color: AppColors.success),
                  ),
                ),
              AppButton(
                label: l10n.authVerifyCheck,
                isLoading: state.isSubmitting &&
                    state.action == AuthFormAction.checkVerified,
                onPressed: cubit.checkVerified,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.authVerifyResend,
                variant: AppButtonVariant.secondary,
                isLoading: state.isSubmitting &&
                    state.action == AuthFormAction.resendVerification,
                onPressed: cubit.resendVerification,
              ),
              AppButton(
                label: l10n.authSignOut,
                variant: AppButtonVariant.text,
                onPressed: () async {
                  await repo.signOut();
                  if (context.mounted) context.go(AuthRoutes.login);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
