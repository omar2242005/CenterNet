import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/auth_page.dart';
import '../cubit/center_settings_cubit.dart';
import '../models/center_info.dart';
import '../repository/centers_repository.dart';
import '../rules/center_validation_text.dart';
import '../rules/center_validators.dart';

/// شاشة إعدادات السنتر (خطوة 2.2): الاسم والسنة ومدة التأخير. للأدمن فقط
/// (والـ Rules هي الحاسمة، ده مجرد إخفاء للواجهة).
class CenterSettingsScreen extends StatelessWidget {
  const CenterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CenterSettingsCubit(sl<CentersRepository>())..load(),
      child: const _CenterSettingsView(),
    );
  }
}

class _CenterSettingsView extends StatelessWidget {
  const _CenterSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CenterSettingsCubit, CenterSettingsState>(
      listenWhen: (prev, cur) => prev.savedTick != cur.savedTick,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.centersSaved)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.centersSettingsTitle)),
          body: SafeArea(
            child: AsyncView<CenterContext>(
              state: state.view,
              onRetry: () => context.read<CenterSettingsCubit>().load(),
              emptyMessage: l10n.centersNoCenter,
              builder: (context, ctx) {
                if (!ctx.membership.isAdmin) {
                  return Center(
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Text(l10n.centersAdminOnly),
                    ),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: _SettingsForm(
                        center: ctx.center,
                        saving: state.saving,
                        failureMessage: state.saveFailure?.message,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({
    required this.center,
    required this.saving,
    required this.failureMessage,
  });

  final CenterInfo center;
  final bool saving;
  final String? failureMessage;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.center.name,
  );
  late final TextEditingController _year = TextEditingController(
    text: widget.center.year.toString(),
  );
  late final TextEditingController _late = TextEditingController(
    text: widget.center.lateAfterMinutes.toString(),
  );

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    _late.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final year = CenterValidators.parseYear(_year.text);
    final late = CenterValidators.parseLateAfterMinutes(_late.text);
    if (year == null || late == null) return;
    context.read<CenterSettingsCubit>().save(
      name: CenterValidators.cleanName(_name.text),
      year: year,
      lateAfterMinutes: late,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: l10n.centersNameLabel,
            textInputAction: TextInputAction.next,
            enabled: !widget.saving,
            validator: (v) => CenterValidators.name(v ?? '')?.message(l10n),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _year,
            label: l10n.centersYearLabel,
            hint: l10n.centersYearHint,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            isLtr: true,
            latinDigits: true,
            enabled: !widget.saving,
            validator: (v) => CenterValidators.year(v ?? '')?.message(l10n),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _late,
            label: l10n.centersLateLabel,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            isLtr: true,
            latinDigits: true,
            enabled: !widget.saving,
            validator: (v) =>
                CenterValidators.lateAfterMinutes(v ?? '')?.message(l10n),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.centersLateHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.failureMessage != null)
            AuthErrorText(widget.failureMessage!),
          AppButton(
            label: l10n.centersSaveButton,
            isLoading: widget.saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
