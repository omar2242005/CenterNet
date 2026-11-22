import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/screens/auth_page.dart';
import '../cubit/create_center_cubit.dart';
import '../models/center_form_error.dart';
import '../repository/centers_repository.dart';

class CreateCenterScreen extends StatelessWidget {
  const CreateCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateCenterCubit(sl<CentersRepository>()),
      child: const _CreateCenterView(),
    );
  }
}

class _CreateCenterView extends StatefulWidget {
  const _CreateCenterView();

  @override
  State<_CreateCenterView> createState() => _CreateCenterViewState();
}

class _CreateCenterViewState extends State<_CreateCenterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateCenterCubit>().submit(
          name: _name.text,
          year: int.parse(toLatinDigits(_year.text).trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CreateCenterCubit, CreateCenterState>(
      listener: (context, state) {
        if (state.status == CreateCenterStatus.success) {
          context.go(AuthRoutes.signedIn);
        }
      },
      builder: (context, state) {
        return AuthPage(
          title: l10n.centerCreateTitle,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  label: l10n.centerName,
                  textInputAction: TextInputAction.next,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      CenterValidators.name(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _year,
                  label: l10n.centerYear,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  isLtr: true,
                  latinDigits: true,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      CenterValidators.year(toLatinDigits(v ?? ''))
                          ?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.status == CreateCenterStatus.failure &&
                    state.failure != null)
                  AuthErrorText(state.failure!.message),
                AppButton(
                  label: l10n.centerCreateButton,
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
