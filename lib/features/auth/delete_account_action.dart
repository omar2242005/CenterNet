import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/session_role.dart';
import '../../core/errors/failure.dart';
import '../../core/services/pending_ops_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'auth_route_names.dart';
import 'repository/auth_repository.dart';

/// حذف الحساب نهائيًا: منع لو فيه عمليات معلّقة، ثم نافذة تحذير + كلمة السر،
/// ثم الحذف (الـ Repository بيرفض الأدمن)، وبعدها الرجوع لشاشة الدخول.
Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final blocked = sl<PendingOpsGuard>().blockReason;
  if (blocked != null) {
    messenger.showSnackBar(SnackBar(content: Text(blocked)));
    return;
  }

  final password = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PasswordDialog(),
  );
  if (password == null || !context.mounted) return;

  try {
    await sl<AuthRepository>().deleteAccount(password: password);
    if (sl.isRegistered<SessionRole>()) sl<SessionRole>().clear();
    if (context.mounted) context.go(AuthRoutes.login);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e is Failure ? e.message : l10n.accountDeleteFailed),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.accountDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountDeleteMessage),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.authPassword),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _controller.text.isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.accountDeleteConfirm),
        ),
      ],
    );
  }
}
