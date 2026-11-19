import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/pending_ops_guard.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_route_names.dart';
import '../repository/auth_repository.dart';
import 'auth_page.dart';

/// شاشة مؤقتة بعد الدخول لحد ما ييجي التوجيه حسب الدور (3.5) و"حسابي".
class SignedInScreen extends StatelessWidget {
  const SignedInScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final guard = sl<PendingOpsGuard>();
    final messenger = ScaffoldMessenger.of(context);

    final blocked = guard.blockReason;
    if (blocked != null) {
      messenger.showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: l10n.authSignOutTitle,
      message: l10n.authSignOutMessage,
      confirmLabel: l10n.authSignOut,
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await sl<AuthRepository>().signOut();
      if (context.mounted) context.go(AuthRoutes.login);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is Failure ? e.message : l10n.authSignOutFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = sl<AuthRepository>().currentUser?.email ?? '';

    return AuthPage(
      title: l10n.authSignedInTitle,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.authSignedInBody(email)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.authSignOut,
            variant: AppButtonVariant.secondary,
            onPressed: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
