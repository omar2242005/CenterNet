import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/auth_page.dart';
import '../../auth/sign_out_action.dart';

typedef HomeAction = ({String label, String route});

/// رئيسية مؤقتة لكل دور: أزرار تنقّل + تسجيل خروج.
/// بتتبدل بالرئيسيات الحقيقية في الموجة 2.
class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    super.key,
    required this.title,
    this.actions = const <HomeAction>[],
  });

  final String title;
  final List<HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthPage(
      title: title,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actions.isEmpty) Text(l10n.homeComingSoon),
          for (final a in actions) ...[
            AppButton(
              label: a.label,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(a.route),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.authSignOut,
            variant: AppButtonVariant.secondary,
            onPressed: () => confirmAndSignOut(context),
          ),
        ],
      ),
    );
  }
}
