import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_route_names.dart';
import '../../auth/screens/auth_page.dart';
import '../cubit/create_center_cubit.dart';
import '../repository/centers_repository.dart';
import '../rules/center_validation_text.dart';
import '../rules/center_validators.dart';

/// شاشة إنشاء سنتر (خطوة 2.2): الاسم والسنة الدراسية.
/// أي مستخدم يقدر ينشئ سنتر (من غير قائمة سماح) ويبقى أدمنه تلقائيًا.
class CreateCenterScreen extends StatelessWidget {
  const CreateCenterScreen({super.key, this.initialYear});

  /// للاختبار. الافتراضي السنة الحالية.
  final int? initialYear;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateCenterCubit(sl<CentersRepository>()),
      child: _CreateCenterView(initialYear: initialYear ?? DateTime.now().year),
    );
  }
}

class _CreateCenterView extends StatefulWidget {
  const _CreateCenterView({required this.initialYear});

  final int initialYear;

  @override
  State<_CreateCenterView> createState() => _CreateCenterViewState();
}

class _CreateCenterViewState extends State<_CreateCenterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _year = TextEditingController(
    text: widget.initialYear.toString(),
  );

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final year = CenterValidators.parseYear(_year.text);
    if (year == null) return;
    context.read<CreateCenterCubit>().create(
      name: CenterValidators.cleanName(_name.text),
      year: year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CreateCenterCubit, CreateCenterState>(
      listener: (context, state) {
        if (state.status == CreateCenterStatus.success) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AuthRoutes.signedIn);
          }
        }
      },
      builder: (context, state) {
        return AuthPage(
          title: l10n.centersCreateTitle,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.centersCreateIntro),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _name,
                  label: l10n.centersNameLabel,
                  textInputAction: TextInputAction.next,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      CenterValidators.name(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _year,
                  label: l10n.centersYearLabel,
                  hint: l10n.centersYearHint,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  isLtr: true,
                  latinDigits: true,
                  enabled: !state.isSubmitting,
                  validator: (v) =>
                      CenterValidators.year(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.status == CreateCenterStatus.failure &&
                    state.failure != null)
                  AuthErrorText(state.failure!.message),
                AppButton(
                  label: l10n.centersCreateButton,
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
