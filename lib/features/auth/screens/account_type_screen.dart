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
import '../models/account_type.dart';
import '../models/register_draft.dart';
import '../repository/auth_repository.dart';
import 'auth_page.dart';

extension AccountTypeText on AccountType {
  String label(AppLocalizations l10n) => switch (this) {
        AccountType.admin => l10n.accountTypeAdmin,
        AccountType.staff => l10n.accountTypeStaff,
        AccountType.guardian => l10n.accountTypeGuardian,
        AccountType.student => l10n.accountTypeStudent,
      };

  IconData get icon => switch (this) {
        AccountType.admin => Icons.admin_panel_settings_outlined,
        AccountType.staff => Icons.school_outlined,
        AccountType.guardian => Icons.family_restroom_outlined,
        AccountType.student => Icons.backpack_outlined,
      };
}

/// الخطوة التانية من التسجيل: اختيار نوع الحساب (مبيدّيش صلاحيات) وإنشاء الحساب.
class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key, required this.draft});

  final RegisterDraft draft;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(sl<AuthRepository>()),
      child: _AccountTypeView(draft: draft),
    );
  }
}

class _AccountTypeView extends StatefulWidget {
  const _AccountTypeView({required this.draft});

  final RegisterDraft draft;

  @override
  State<_AccountTypeView> createState() => _AccountTypeViewState();
}

class _AccountTypeViewState extends State<_AccountTypeView> {
  AccountType? _selected;

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
          title: l10n.authAccountTypeTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  l10n.authAccountTypeNotice,
                  style: const TextStyle(color: AppColors.onWarningContainer),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final type in AccountType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TypeTile(
                    type: type,
                    selected: _selected == type,
                    enabled: !state.isSubmitting,
                    onTap: () => setState(() => _selected = type),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              if (state.status == AuthFormStatus.failure &&
                  state.failure != null)
                AuthErrorText(state.failure!.message),
              AppButton(
                label: l10n.authCreateAccountButton,
                isLoading: state.isSubmitting,
                onPressed: _selected == null
                    ? null
                    : () => context.read<AuthFormCubit>().register(
                          draft: widget.draft,
                          accountType: _selected!,
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        minTileHeight: AppSpacing.minTouch,
        enabled: enabled,
        selected: selected,
        leading: Icon(type.icon),
        title: Text(type.label(l10n)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
