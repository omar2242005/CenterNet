import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../sign_out_action.dart';
import '../../../core/widgets/app_page.dart';

/// هيكل مشترك لشاشات الـ auth: عنوان + محتوى متمركز بعرض أقصى.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.showSignOut = false,
  });

  final String title;
  final Widget child;
  final bool showBack;

  /// زرار تسجيل خروج ظاهر في الشريط (لشاشات المستخدم اللي لسه من غير سنتر).
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      automaticallyImplyLeading: showBack,
      actions: [
        if (showSignOut)
          TextButton.icon(
            onPressed: () => confirmAndSignOut(context),
            icon: const Icon(Icons.logout),
            label: Text(AppLocalizations.of(context).authSignOut),
          ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// رسالة خطأ تحت الفورم (نص عربي جاي من الـ Repository).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}
