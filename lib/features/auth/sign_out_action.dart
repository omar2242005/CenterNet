import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../core/errors/failure.dart';
import '../../core/services/pending_ops_guard.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import 'auth_route_names.dart';
import 'repository/auth_repository.dart';

/// تسجيل الخروج بتأكيد، ومنع لو فيه عمليات معلّقة (مسحات لسه ماتزامنتش).
Future<void> confirmAndSignOut(BuildContext context) async {
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
    messenger.showSnackBar(
      SnackBar(content: Text(e is Failure ? e.message : l10n.authSignOutFailed)),
    );
  }
}
