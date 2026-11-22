import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/auth_page.dart';
import '../../auth/sign_out_action.dart';

class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthPage(
      title: title,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(body),
          const SizedBox(height: AppSpacing.lg),
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
