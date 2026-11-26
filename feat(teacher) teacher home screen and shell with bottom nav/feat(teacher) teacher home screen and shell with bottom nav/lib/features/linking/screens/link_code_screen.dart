import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/link_code_generator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/sign_out_action.dart';
import '../cubit/link_code_cubit.dart';
import '../models/invite_code.dart';
import '../models/student_link.dart';
import '../repository/linking_repository.dart';

/// شاشة إدخال كود الربط: واحدة للطالب ولولي الأمر (حسب [kind]).
/// فيها نص الموافقة، ولازم المستخدم يوافق قبل الربط. بترجّع `true` لو الربط نجح.
class LinkCodeScreen extends StatelessWidget {
  const LinkCodeScreen({super.key, required this.kind});

  final LinkKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LinkCodeCubit(sl<LinkingRepository>(), kind),
      child: _LinkCodeView(kind: kind),
    );
  }
}

class _LinkCodeView extends StatefulWidget {
  const _LinkCodeView({required this.kind});

  final LinkKind kind;

  @override
  State<_LinkCodeView> createState() => _LinkCodeViewState();
}

class _LinkCodeViewState extends State<_LinkCodeView> {
  final _controller = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _formatOk => LinkCodeGenerator.isWellFormed(_controller.text);

  void _submit(BuildContext context) {
    if (!_formatOk || !_agreed) return;
    context.read<LinkCodeCubit>().submit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isGuardian = widget.kind == LinkKind.guardian;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.linkEnterTitle),
        // مخرج للمستخدم اللي دخل بالغلط أو ندمان: تسجيل خروج بتأكيد
        // (نفس مسار باقي الشاشات، وفيه حارس العمليات المعلّقة).
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.authSignOut,
            onPressed: () => confirmAndSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<LinkCodeCubit, LinkCodeState>(
          listener: (context, state) {
            if (state.done) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.linkSuccess)),
              );
              context.pop(true);
            } else if (state.failure != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure!.message)),
              );
            }
          },
          builder: (context, state) {
            return ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(
                  isGuardian ? l10n.linkGuardianIntro : l10n.linkStudentIntro,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _controller,
                  label: l10n.linkCodeLabel,
                  hint: l10n.linkCodeHint,
                  isLtr: true,
                  maxLength: 12,
                  enabled: !state.busy,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.linkConsentTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isGuardian
                            ? l10n.linkConsentGuardian(
                                InviteCode.maxGuardiansPerStudent,
                              )
                            : l10n.linkConsentStudent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      CheckboxListTile(
                        value: _agreed,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(l10n.linkConsentAgree),
                        onChanged: state.busy
                            ? null
                            : (v) => setState(() => _agreed = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.linkSubmit,
                  icon: Icons.link,
                  isLoading: state.busy,
                  onPressed:
                      (_formatOk && _agreed) ? () => _submit(context) : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
