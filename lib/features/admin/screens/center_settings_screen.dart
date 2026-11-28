import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../centers/cubit/center_settings_cubit.dart';
import '../../centers/models/center_form_error.dart';
import '../../centers/models/center_info.dart';
import '../../centers/repository/centers_repository.dart';
import '../../../core/widgets/app_page.dart';

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

    return AppPage(
      title: l10n.centerSettingsTitle,
      body: BlocBuilder<CenterSettingsCubit, CenterSettingsState>(
        builder: (context, state) {
          return AsyncView<CenterInfo>(
            state: state.view,
            onRetry: context.read<CenterSettingsCubit>().load,
            emptyMessage: l10n.centerNone,
            builder: (context, center) => _SettingsForm(
              // مفتاح بالقيم عشان الفورم يتبني من جديد بعد الحفظ.
              key: ValueKey(
                '${center.id}-${center.name}-${center.year}-${center.lateAfterMinutes}',
              ),
              center: center,
              state: state,
            ),
          );
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({super.key, required this.center, required this.state});

  final CenterInfo center;
  final CenterSettingsState state;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.center.name);
  late final _year = TextEditingController(text: widget.center.year.toString());
  late final _late = TextEditingController(
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
    context.read<CenterSettingsCubit>().save(
      name: _name.text,
      year: int.parse(toLatinDigits(_year.text).trim()),
      lateAfterMinutes: int.parse(toLatinDigits(_late.text).trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              label: l10n.centerName,
              textInputAction: TextInputAction.next,
              enabled: !state.saving,
              validator: (v) => CenterValidators.name(v ?? '')?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _year,
              label: l10n.centerYear,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              isLtr: true,
              latinDigits: true,
              enabled: !state.saving,
              validator: (v) =>
                  CenterValidators.year(toLatinDigits(v ?? ''))?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _late,
              label: l10n.centerLateAfter,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              isLtr: true,
              latinDigits: true,
              enabled: !state.saving,
              validator: (v) =>
                  CenterValidators.lateAfter(toLatinDigits(v ?? ''))
                      ?.message(l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.saveFailure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  state.saveFailure!.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (state.saved)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.centerSaved,
                  style: const TextStyle(color: AppColors.success),
                ),
              ),
            AppButton(
              label: l10n.centerSave,
              isLoading: state.saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
