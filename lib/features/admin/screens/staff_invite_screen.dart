import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/whatsapp_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/auth_page.dart';
import '../../linking/models/invite_code.dart';
import '../../staff/cubit/staff_invite_cubit.dart';
import '../../staff/models/staff_invite_issued.dart';
import '../../staff/models/staff_role_text.dart';
import '../../staff/repository/staff_repository.dart';

/// شاشة "إضافة معلم" أو "إضافة مساعد" (للأدمن): الاسم ← كود دعوة يتبعت واتساب
/// أو يتنسخ. الدور ثابت من المسار ومفيش اختيار دور: كل دور له شاشة دعوة
/// منفصلة.
class StaffInviteScreen extends StatelessWidget {
  const StaffInviteScreen({required this.role, super.key});

  final StaffInviteRole role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffInviteCubit(sl<StaffRepository>()),
      child: _StaffInviteView(role: role),
    );
  }
}

class _StaffInviteView extends StatefulWidget {
  const _StaffInviteView({required this.role});

  final StaffInviteRole role;

  @override
  State<_StaffInviteView> createState() => _StaffInviteViewState();
}

class _StaffInviteViewState extends State<_StaffInviteView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  StaffInviteRole get _role => widget.role;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<StaffInviteCubit>().create(name: _name.text, role: _role);
  }

  void _addAnother() {
    _name.clear();
    _phone.clear();
    context.read<StaffInviteCubit>().reset();
  }

  Future<void> _copyCode(String code) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(SnackBar(content: Text(l10n.staffInviteCopied)));
  }

  Future<void> _sendWhatsApp(StaffInviteIssued issued) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final invite = issued.invite;
    final message = l10n.staffInviteMessage(
      invite.name ?? '',
      issued.centerName,
      invite.role?.label(l10n) ?? '',
      invite.id,
    );
    try {
      await sl<WhatsAppLauncher>().open(_phone.text, message);
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<StaffInviteCubit, StaffInviteState>(
      builder: (context, state) {
        final issued = state.issued;
        return AuthPage(
          title: _role == StaffInviteRole.teacher
              ? l10n.staffInviteTeacherTitle
              : l10n.staffInviteAssistantTitle,
          child: (state.status == StaffInviteStatus.success && issued != null)
              ? _buildResult(context, l10n, issued)
              : _buildForm(context, l10n, state),
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    StaffInviteState state,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: _role == StaffInviteRole.teacher
                ? l10n.staffInviteTeacherName
                : l10n.staffInviteAssistantName,
            textInputAction: TextInputAction.next,
            enabled: !state.isSubmitting,
            validator: (v) => Validators.name(v ?? '')?.message(l10n),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            label: l10n.staffInvitePhone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            isLtr: true,
            latinDigits: true,
            enabled: !state.isSubmitting,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return null; // اختياري
              return Validators.mobile(value)?.message(l10n);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.status == StaffInviteStatus.failure &&
              state.failure != null)
            AuthErrorText(state.failure!.message),
          AppButton(
            label: l10n.staffInviteCreate,
            isLoading: state.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    AppLocalizations l10n,
    StaffInviteIssued issued,
  ) {
    final theme = Theme.of(context);
    final invite = issued.invite;
    final hasPhone = _phone.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.staffInviteReadyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${invite.name ?? ''} · ${invite.role?.label(l10n) ?? ''}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.staffInviteCodeLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                invite.id,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.staffInviteValidUntil(formatDate(l10n, invite.expiresAt)),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.staffInviteNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.staffInviteCopy,
          icon: Icons.copy,
          onPressed: () => _copyCode(invite.id),
        ),
        if (hasPhone) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.staffInviteWhatsapp,
            icon: Icons.send,
            variant: AppButtonVariant.secondary,
            onPressed: () => _sendWhatsApp(issued),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.staffInviteAnother,
          variant: AppButtonVariant.text,
          onPressed: _addAnother,
        ),
      ],
    );
  }
}
