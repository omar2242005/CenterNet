import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validation_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../repository/auth_repository.dart';
import '../../../core/widgets/app_page.dart';

/// تعديل الاسم ورقم الموبايل فقط (الإيميل مش هنا). بترجّع `true` لو اتحفظ.
class EditContactScreen extends StatefulWidget {
  const EditContactScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await sl<AuthRepository>().updateContact(
        name: _name.text,
        phone: Validators.normalizeMobile(_phone.text),
      );
      if (mounted) context.pop(true);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.editContactTitle,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            AppTextField(
              controller: _name,
              label: l10n.authName,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.name(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phone,
              label: l10n.authPhone,
              keyboardType: TextInputType.phone,
              enabled: !_saving,
              isLtr: true,
              latinDigits: true,
              validator: (v) => Validators.mobile(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.studentSave,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
