import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validation_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_route_names.dart';
import '../models/register_draft.dart';
import 'auth_page.dart';

/// الخطوة الأولى من التسجيل: البيانات. الخطوة التانية: اختيار نوع الحساب.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.push(
      AuthRoutes.accountType,
      extra: RegisterDraft(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: Validators.normalizeMobile(_phone.text),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthPage(
      title: l10n.authRegisterTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              label: l10n.authName,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => Validators.name(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _email,
              label: l10n.authEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              isLtr: true,
              validator: (v) => Validators.email(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phone,
              label: l10n.authPhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              isLtr: true,
              latinDigits: true,
              validator: (v) => Validators.mobile(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _password,
              label: l10n.authPassword,
              obscureText: true,
              isLtr: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => Validators.password(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.authContinue, onPressed: _next),
            AppButton(
              label: l10n.authHaveAccount,
              variant: AppButtonVariant.text,
              onPressed: () => context.go(AuthRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
