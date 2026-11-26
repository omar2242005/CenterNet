import 'package:flutter/material.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../models/account_type.dart';
import '../models/app_user.dart';
import '../repository/auth_repository.dart';
import '../delete_account_action.dart';
import '../sign_out_action.dart';

/// شاشة "حسابي": بيانات الحساب الأساسية + تسجيل الخروج.
/// متاحة لكل الأدوار (مش محتاجة سطر في حارس الصلاحيات).
class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  static String _typeLabel(AppLocalizations l10n, AccountType type) {
    return switch (type) {
      AccountType.admin => l10n.accountTypeAdmin,
      AccountType.staff => l10n.accountTypeStaff,
      AccountType.guardian => l10n.accountTypeGuardian,
      AccountType.student => l10n.accountTypeStudent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccountTitle)),
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: sl<AuthRepository>().loadProfile(),
          builder: (context, snap) {
            final user = snap.data;
            if (snap.hasError ||
                (user == null &&
                    snap.connectionState == ConnectionState.done)) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(l10n.myAccountLoadError),
                ),
              );
            }
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: AppSpacing.screenPadding,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l10n.myAccountName,
                        value: user.name,
                      ),
                      if (user.email.isNotEmpty)
                        _InfoRow(
                          icon: Icons.mail_outline,
                          label: l10n.myAccountEmail,
                          value: user.email,
                        ),
                      if (user.phone.isNotEmpty)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: l10n.myAccountPhone,
                          value: user.phone,
                        ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: l10n.myAccountType,
                        value: _typeLabel(l10n, user.accountType),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.authSignOut,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.logout,
                  onPressed: () => confirmAndSignOut(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => confirmAndDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.accountDeleteAction),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
